import 'dart:collection';
import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:isc/components/student_detail.dart';
import 'package:isc/constants.dart';
import 'package:isc/status_enum.dart';
import 'package:isc/user-info.dart';
import 'package:http/http.dart' as http;

import '../routes.dart';

class DetailScreen extends StatefulWidget {
  @override
  _DetailScreenState createState() => _DetailScreenState();
}

var weekday = {
  'Monday': 1,
  'Tuesday': 2,
  'Wednesday': 3,
  'Thursday': 4,
  'Friday': 5,
  'Saturday': 6,
  'Sunday': 7,
};
SplayTreeMap dateWeekday = SplayTreeMap();

class _DetailScreenState extends State<DetailScreen> {
  TextEditingController? firstNameController;
  final _formKey = GlobalKey<FormState>();
  String firstName = '';
  late Future myFuture1;
  Future? myFuture2;
  TextEditingController? firstEmailController;
  String currEmail = '';
  late int maxLength;
  dynamic rollNo;
  String date = '';
  var _controller = List.generate(StudentInfo.dayChoosen.length,
      (i) => List.generate(8, (j) => TextEditingController()),
      growable: false);
  var length = List<int>.filled(StudentInfo.dayChoosen.length, 1);
  var slotsRemaining = List<int>.filled(StudentInfo.dayChoosen.length, 0);
  var downArrow = List<bool>.filled(StudentInfo.dayChoosen.length, true);
  var errorMessage = List.generate(
      StudentInfo.dayChoosen.length, (i) => List.generate(8, (j) => ""),
      growable: false);
  List<List<BookingStatus>> bookingStatus = List.generate(
      StudentInfo.dayChoosen.length,
      (i) => List.generate(8, (j) => BookingStatus.None),
      growable: false);
  DateTime? todayDate;
  @override
  void initState() {
    super.initState();
    todayDate = DateTime.now();
    myFuture1 = getData();
  }

  Future<void> postData() async {
    bookingStatus = List.generate(StudentInfo.dayChoosen.length,
        (i) => List.generate(8, (j) => BookingStatus.None),
        growable: false);
    errorMessage = List.generate(
        StudentInfo.dayChoosen.length, (i) => List.generate(8, (j) => ""),
        growable: false);
    for (var i = 0; i < length.length; i++) {
      for (var j = 0; j < length[i] * 2; j++) {
        print(_controller[i][j].text);
        print(_controller[i][j + 1].text);
      }
    }

    Map<String, List<dynamic>> emailWiseBooking = {};
    for (var i = 0; i < StudentInfo.dayChoosen.length; i++) {
      for (var j = 0; j < (length[i] * 2); j = j + 2) {
        emailWiseBooking[_controller[i][j + 1].text] = [];
      }
    }
    for (var i = 0; i < StudentInfo.dayChoosen.length; i++) {
      for (var j = 0; j < (length[i] * 2); j = j + 2) {
        emailWiseBooking[_controller[i][j + 1].text]
            ?.add((StudentInfo.dayChoosen[i]));
      }
    }

    print(emailWiseBooking);

    Map<dynamic, dynamic> dateWiseBooking = {};
    for (var i = 0; i < StudentInfo.dayChoosen.length; i++) {
      Map<dynamic, dynamic> mp = {};
      for (var j = 0; j < (length[i] * 2); j = j + 2) {
        mp[_controller[i][j].text] = _controller[i][j + 1].text;
      }
      dateWiseBooking[StudentInfo.dayChoosen[i]] = mp;
    }

    print(dateWiseBooking);

    var body = jsonEncode({
      "sports_name": StudentInfo.gameChoosen,
      "slot": StudentInfo.slotChoosen,
      "Bookings": dateWiseBooking,
      "Check": emailWiseBooking,
    });
    print(body);

    try {
      final response = await http.post(
        Uri.parse(kIpAddress + '/book'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': '*/*',
          'Accept-Encoding': 'gzip, deflate, br',
          'Access-Control-Allow-Origin': ' *',
          "x-access-token": StudentInfo.jwtToken,
        },
        body: body,
      );
      Map<dynamic, dynamic> jsonData = await jsonDecode(response.body);
      print("details");
      print(jsonData);
      if (jsonData.containsKey('errors')) {
        for (var errorM in jsonData['errors'].keys) {
          for (var emailName in jsonData['errors'][errorM].keys) {
            var dateList = jsonData['errors'][errorM][emailName];
            print(dateList);
            for (var dateM in dateList) {
              int x = StudentInfo.dayChoosen.indexOf(dateM);
              int y = 0;
              for (var i = 0; i < _controller[x].length; i++) {
                if (_controller[x][i].text == emailName) {
                  y = i;
                  y--;
                  break;
                }
              }
              bookingStatus[x][y] = BookingStatus.Error;
              bookingStatus[x][y + 1] = BookingStatus.Error;
              errorMessage[x][y] = errorM;
            }
          }
        }
      } else {
        for (var dateIndex in jsonData['message'].keys) {
          for (var j = 0;
              j < _controller[int.parse(dateIndex)].length;
              j += 2) {
            var i = int.parse(dateIndex);
            if (jsonData['message'][dateIndex] == 'All slots have finished') {
              bookingStatus[i][j] = BookingStatus.Error;
              bookingStatus[i][j + 1] = BookingStatus.Error;
              errorMessage[i][j] = jsonData['message'][dateIndex];
            } else {
              bookingStatus[i][j] = BookingStatus.Confirm;
              bookingStatus[i][j + 1] = BookingStatus.Confirm;
              errorMessage[i][j] = jsonData['message'][dateIndex];
            }
          }
        }
      }
    } catch (e) {
      bool hasInternet = await InternetConnectionChecker().hasConnection;
      if (!hasInternet) {
        Fluttertoast.showToast(msg: "Please check your internet connection");
      } else {
        Fluttertoast.showToast(msg: "Something went wrong.Please retry.");
      }
      print(e);
    }
  }

  Future<void> getData() async {
    try {
      var response = await http.get(Uri.parse(kIpAddress + '/max-person'));
      Map<String, dynamic> jsonData = await jsonDecode(response.body);
      maxLength = jsonData[StudentInfo.gameChoosen];

      int i = 0;
      for (var item in StudentInfo.dayChoosen) {
        slotsRemaining[i] = StudentInfo.gameData[item][StudentInfo.slotChoosen];
        i++;
      }
      currEmail = StudentInfo.emailId;
      firstName = StudentInfo.name;
      firstNameController = TextEditingController(text: firstName);
      firstEmailController = TextEditingController(text: currEmail);

      for (var i = 0; i < StudentInfo.dayChoosen.length; i++) {
        _controller[i][0].text = StudentInfo.name;
        _controller[i][1].text = StudentInfo.emailId;

        int? bookingDayNum = weekday[StudentInfo.dayChoosen[i]];
        int todayNum = todayDate!.weekday;
        if (todayDate!.weekday == StudentInfo.resetWeekday &&
            todayDate!.hour >= StudentInfo.resetHour &&
            todayDate!.minute >= StudentInfo.resetMinute) {
          todayNum = 0;
        }
        DateTime? bookingDate =
            todayDate?.add(Duration(days: bookingDayNum! - todayNum));
        var dateParse = DateTime.parse(bookingDate.toString());
        var formattedDate =
            "${dateParse.year}-${dateParse.month}-${dateParse.day}";
        dateWeekday[formattedDate] = StudentInfo.dayChoosen[i];
        StudentInfo.dayChoosen[i] = formattedDate;
      }
      print(dateWeekday);
      StudentInfo.dayChoosen.sort();
    } catch (e) {
      print(e);
      return Future.error(e.toString());
    }
  }

  final sNames = [
    'First Student Name',
    'SNU ID',
    'Second Student Name',
    'SNU ID',
    'Third Student Name',
    'SNU ID',
    'Fourth Student Name',
    'SNU ID'
  ];

  @override
  Widget build(BuildContext context) {
    print(currEmail);
    Size size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
          appBar: AppBar(
            title: Text('Please fill in your details'),
            backgroundColor: Colors.purple,
            centerTitle: true,
          ),
          body: FutureBuilder(
              future: myFuture1,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return GestureDetector(
                    onTap: () async {
                      if (!(await InternetConnectionChecker().hasConnection)) {
                        Fluttertoast.showToast(
                            msg: "Please check your internet connection");
                      } else {
                        setState(() {
                          myFuture1 = getData();
                        });
                      }
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
                  );
                } else if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(
                    color: Colors.purple,
                  ));
                } else {
                  return Stack(children: [
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(
                            height: size.height * 0.01,
                          ),
                          Form(
                            key: _formKey,
                            child: ListView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: (StudentInfo.dayChoosen.length),
                              itemBuilder: (context, i) {
                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: size.width * 0.02,
                                        ),
                                        IconButton(
                                            onPressed: () {
                                              downArrow[i] = !downArrow[i];
                                              setState(() {});
                                            },
                                            icon: Icon(
                                              downArrow[i]
                                                  ? Icons.keyboard_arrow_down
                                                  : Icons.keyboard_arrow_right,
                                              size: size.width * 0.07,
                                            )),
                                        SizedBox(
                                          width: size.width * 0.03,
                                        ),
                                        AutoSizeText(
                                          dateWeekday[
                                              StudentInfo.dayChoosen[i]],
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Spacer(),
                                        IconButton(
                                            onPressed: () {
                                              print(
                                                  "Slots remianing ${slotsRemaining[i]}");
                                              print("Maxlenght $maxLength");
                                              if (length[i] ==
                                                  slotsRemaining[i]) {
                                                Fluttertoast.showToast(
                                                    msg:
                                                        "Sorry no more slots are available");
                                              } else if (length[i] ==
                                                  maxLength) {
                                                Fluttertoast.showToast(
                                                    msg:
                                                        "Sorry you cannot book more than ${length[i]} slots for this game");
                                              } else {
                                                length[i]++;
                                                setState(() {});
                                              }
                                            },
                                            icon: Icon(
                                              Icons.add,
                                              size: size.width * 0.07,
                                            )),
                                        SizedBox(
                                          width: size.width * 0.06,
                                        ),
                                        IconButton(
                                            onPressed: () {
                                              if (length[i] == 1) {
                                                Fluttertoast.showToast(
                                                    msg:
                                                        "Minimum 1 student credetials should be there");
                                              } else {
                                                length[i]--;
                                                setState(() {});
                                              }
                                            },
                                            icon: Icon(
                                              Icons.remove,
                                              size: size.width * 0.07,
                                            )),
                                        SizedBox(
                                          width: size.width * 0.05,
                                        ),
                                      ],
                                    ),
                                    downArrow[i]
                                        ? ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                NeverScrollableScrollPhysics(),
                                            itemCount: (length[i]) * 2,
                                            itemBuilder: (context, j) {
                                              return StudentDetail(
                                                title: sNames[j],
                                                controller: _controller[i][j],
                                                index: j,
                                                bookingStatus: bookingStatus[i]
                                                    [j],
                                                errorMessage: errorMessage[i]
                                                    [j],
                                              );
                                            })
                                        : Container(),
                                  ],
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            height: size.height * 0.03,
                          ),
                          GestureDetector(
                            onTap: () async {
                              FocusManager.instance.primaryFocus?.unfocus();
                              if (_formKey.currentState!.validate()) {
                                myFuture2 = postData();
                                setState(() {});
                              }
                            },
                            child: Container(
                              width: size.width * 0.9,
                              height: size.height * 0.05,
                              decoration: BoxDecoration(
                                  color: Colors.purple,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Center(
                                child: AutoSizeText(
                                  "SUBMIT",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: size.height * 0.01,
                          ),
                        ],
                      ),
                    ),
                    FutureBuilder(
                        future: myFuture2,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                                child: CircularProgressIndicator(
                              color: Colors.purple,
                            ));
                          } else {
                            return Container();
                          }
                        })
                  ]);
                }
              })),
    );
  }
}
