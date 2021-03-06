import 'dart:async';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:isc/constants.dart';
import 'package:isc/components/slot_card.dart';
import 'package:http/http.dart' as http;
import 'package:isc/provider/theme_provider.dart';
import 'package:isc/user-info.dart';
import 'package:provider/provider.dart';
// import 'package:switcher/core/switcher_size.dart';
// import 'package:switcher/switcher.dart';

class TimeSlot extends StatefulWidget {
  TimeSlot();

  @override
  _TimeSlotState createState() => _TimeSlotState();
}

class _TimeSlotState extends State<TimeSlot> {
  bool isDisabled = true;
  int calendarRange = 0;
  bool isLoading = false;
  bool circP = true;
  bool isDateChoosen = false;
  String gameChoosen = " ";
  Response? oldResponse;
  bool _decideWhichDayToEnable(DateTime day) {
    if ((day.isAfter(DateTime.now().subtract(Duration(days: 1))) &&
        day.isBefore(DateTime.now().add(Duration(days: 7 - calendarRange))))) {
      return true;
    }
    return false;
  }

  DateTime? selectedDate;
  String slotDetail = '';
  final slotAvailable = [];
  Map<String, dynamic> sport = {};
  Map<String, dynamic> jsonData = {};
  bool tapToRefresh = false;
  Response? response;
  final weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    gameChoosen = StudentInfo.gameChoosen;
    getData();
  }

  Future<void> showConfirmationDialog(isSlotAvailable) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: isSlotAvailable
                ? Text(
                    'There are some bookings for this slot.Do you want to still disable it?')
                : Text('Do you want to disable the slot?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('No'),
              ),
              TextButton(
                onPressed: () async {
                  var body = jsonEncode({
                    "category": "date",
                    "game": gameChoosen,
                    "date": StudentInfo.dateChoosen,
                  });

                  print(body);
                  try {
                    final disableResponse = await http.post(
                      Uri.parse(kIpAddress + '/stop'),
                      headers: {
                        'Content-Type': 'application/json',
                        'Accept': '*/*',
                        'Accept-Encoding': 'gzip, deflate, br',
                        'Access-Control-Allow-Origin': ' *',
                        "x-access-token": StudentInfo.jwtToken,
                        "admin-header": "YES"
                      },
                      body: body,
                    );
                    isDisabled = false;
                    print(disableResponse.body);
                  } catch (e) {
                    if (!(await InternetConnectionChecker().hasConnection)) {
                      Fluttertoast.showToast(
                          msg: "Please check you internet connection");
                    } else {
                      Fluttertoast.showToast(msg: "Please try again.");
                    }
                    print(e);
                  }
                  Navigator.of(context).pop();
                },
                child: Text('Yes'),
              ),
            ],
          );
        });
  }

  Future<void> disbaleSlot() async {
    try {
      final slotResponse = await http.get(
          Uri.parse(kIpAddress +
              "/booking-count?category=date&game=" +
              gameChoosen +
              "&date=" +
              StudentInfo.dateChoosen),
          headers: {"x-access-token": StudentInfo.jwtToken});

      final responseJsonData = await jsonDecode(slotResponse.body);
      String slotsAvailable = responseJsonData['message'];
      bool isSlotAvailable = false;
      if (slotsAvailable != '0') {
        isSlotAvailable = true;
      }
      await showConfirmationDialog(isSlotAvailable);
    } catch (e) {
      if (!(await InternetConnectionChecker().hasConnection)) {
        Fluttertoast.showToast(msg: "Please check you internet connection");
      } else {
        Fluttertoast.showToast(msg: "Please try again.");
      }
      print(e);
    }
  }

  Future<void> enableSlot() async {
    var body = jsonEncode({
      "category": "date",
      "game": gameChoosen,
      "date": StudentInfo.dateChoosen,
    });

    print(body);
    try {
      final enableResponse = await http.post(
        Uri.parse(kIpAddress + '/unstop'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': '*/*',
          'Accept-Encoding': 'gzip, deflate, br',
          'Access-Control-Allow-Origin': ' *',
          "x-access-token": StudentInfo.jwtToken,
          "admin-header": "YES"
        },
        body: body,
      );

      print(enableResponse.body);
    } catch (e) {
      print("hl");
      if (!(await InternetConnectionChecker().hasConnection)) {
        Fluttertoast.showToast(msg: "Please check you internet connection");
      } else {
        Fluttertoast.showToast(msg: "Please try again.");
      }
      print(e);
    }
  }

  Future<void> getData() async {
    //print(JWTtoken);
    try {
      response = await http.get(
          Uri.parse(kIpAddress + '/slots' + '?game=' + StudentInfo.gameChoosen),
          headers: {
            "x-access-token": StudentInfo.jwtToken,
            "admin-header": "yes"
          });
      jsonData = await jsonDecode(response!.body);
      tapToRefresh = false;
      print(jsonData);
      circP = false;
      setState(() {});
    } catch (e) {
      circP = false;
      tapToRefresh = true;
      setState(() {});
      print(e);
    }
    // oldResponse = response;
  }

  Future<void> getSlot(String day) async {
    print(jsonData);
    print("game name=" + gameChoosen);
    sport = jsonData[gameChoosen][day];
    isDisabled = jsonData['isEnabled'][day];
    print(response!.statusCode);
    print(sport);
    slotAvailable.clear();
    sport.forEach((k, v) {
      slotAvailable.add(k);
    });
    setState(() {
      print('setState called');
    });
  }

  selectDate(context) async {
    final initialDate = DateTime.now();
    calendarRange = initialDate.weekday;
    if (calendarRange == 7) {
      calendarRange = 0;
    }
    final newDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(initialDate.year - 5),
        lastDate: DateTime(initialDate.year + 10),
        selectableDayPredicate: _decideWhichDayToEnable);
    if (newDate != null) {
      selectedDate = newDate;
      print(weekDays[selectedDate!.weekday - 1]);
      await getSlot(weekDays[selectedDate!.weekday - 1]);
      StudentInfo.dateChoosen =
          '${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}';
      isDateChoosen = true;
      setState(() {});
    }
  }

  Widget build(BuildContext context) {
    ThemeProvider theme = Provider.of<ThemeProvider>(context);
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        appBar: AppBar(
          backgroundColor: kPrimaryColor,
          centerTitle: true,
          title: AutoSizeText(
            "Select your timeslot",
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        body: circP
            ? Center(
                child: CircularProgressIndicator(
                color: Colors.blue,
              ))
            : tapToRefresh
                ? GestureDetector(
                    onTap: () async {
                      circP = true;
                      tapToRefresh = false;
                      setState(() {});
                      await getData();
                    },
                    child: Container(
                        child: Center(
                            child: AutoSizeText(
                      "Tap To Refresh",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ))),
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          Spacer(),
                          GestureDetector(
                            onTap: () {
                              selectDate(context);
                            },
                            child: Container(
                              alignment: Alignment.center,
                              height: size.height * 0.05,
                              width: size.width * 0.4,
                              margin: EdgeInsets.only(top: 5),
                              padding: EdgeInsets.all(15),
                              decoration: BoxDecoration(color: kPrimaryColor),
                              child: AutoSizeText(
                                selectedDate == null
                                    ? "CHOOSE YOUR DATE"
                                    : '${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ),
                          Spacer(flex: 4),
                          GestureDetector(
                            onTap: () async {
                              if (isDateChoosen) {
                                if (isDisabled) {
                                  await disbaleSlot();
                                } else {
                                  await enableSlot();
                                  isDisabled = true;
                                }
                                await getData();
                                print("latest");
                                await getSlot(
                                    weekDays[selectedDate!.weekday - 1]);
                              }
                            },
                            child: Container(
                              alignment: Alignment.center,
                              width: size.width * 0.4,
                              height: size.height * 0.05,
                              margin: EdgeInsets.only(top: 5),
                              padding: EdgeInsets.all(15),
                              decoration: isDisabled
                                  ? BoxDecoration(color: Colors.red)
                                  : BoxDecoration(color: Colors.green),
                              child: isDisabled
                                  ? AutoSizeText(
                                      'Disable',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    )
                                  : AutoSizeText(
                                      'Enable',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                            ),
                          ),
                          Spacer(),
                        ],
                      ),
                      SizedBox(
                        height: size.height * 0.05,
                      ),
                      Expanded(
                        child: Container(
                          width: size.width * 0.8,
                          child: ListView.builder(
                              physics: ScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: slotAvailable.length,
                              itemBuilder: (context, index) {
                                return SlotCard(
                                  slotTime: slotAvailable[index],
                                  color: sport[slotAvailable[index]] > 0
                                      ? theme.checkTheme(Colors.green,
                                          Colors.green.shade600, context)
                                      : Colors.grey,
                                  isDisabled: isDisabled,
                                );
                              }),
                        ),
                      )
                    ],
                  ));
  }
}
