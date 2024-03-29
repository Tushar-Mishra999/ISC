import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:isc/components/admin_detail_card.dart';
import 'package:isc/user-info.dart';
import '../constants.dart';

class AdminSlotScreen extends StatefulWidget {
  const AdminSlotScreen({Key? key}) : super(key: key);

  @override
  _AdminSlotScreenState createState() => _AdminSlotScreenState();
}

class _AdminSlotScreenState extends State<AdminSlotScreen> {
  dynamic pendingList = [];
  bool emptyList = false;
  late bool toggleValue;
  late var slotData;
  late bool hasInternet;
  late Future myFuture;
  late TextEditingController slotNumberController;

  @override
  void initState() {
    super.initState();
      myFuture = getData();
  }

  Future<void> changeSlot() async {
    var body = jsonEncode({
      "game": StudentInfo.gameChoosen,
      "date": StudentInfo.dateChoosen,
      "slot": StudentInfo.slotChoosen,
      "capacity": slotNumberController.text,
    });
    print(body);
    try {
      final response = await http.post(
        Uri.parse(kIpAddress + '/slot-capacity-change'),
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
      final jsonData = jsonDecode(response.body);
      Fluttertoast.showToast(
          msg: jsonData["message"], toastLength: Toast.LENGTH_LONG);
      setState(() {});
    } catch (e) {
      if (!(await InternetConnectionChecker().hasConnection)) {
        Fluttertoast.showToast(msg: "Please check you internet connection");
      } else {
        Fluttertoast.showToast(msg: "Please try again.");
      }
      print(e);
    }
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
                    "category": "slot",
                    "game": StudentInfo.gameChoosen,
                    "date": StudentInfo.dateChoosen,
                    "slot": StudentInfo.slotChoosen,
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
                    Navigator.of(context).pop();
                    print(disableResponse.body);
                    toggleValue = true;
                    setState(() {});
                  } catch (e) {
                    if (!(await InternetConnectionChecker().hasConnection)) {
                      Fluttertoast.showToast(
                          msg: "Please check you internet connection");
                    } else {
                      Fluttertoast.showToast(msg: "Please try again.");
                    }
                    print(e);
                  }
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
              "/booking-count?category=slot&game=" +
              StudentInfo.gameChoosen +
              "&date=" +
              StudentInfo.dateChoosen +
              "&slot=" +
              StudentInfo.slotChoosen),
          headers: {"x-access-token": StudentInfo.jwtToken});

      final responseJsonData = await jsonDecode(slotResponse.body);
      String slotsAvailable = responseJsonData['message'];
      bool isSlotAvailable = false;
      print("Sport ke slot = $slotsAvailable");
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
      "category": "slot",
      "game": StudentInfo.gameChoosen,
      "date": StudentInfo.dateChoosen,
      "slot": StudentInfo.slotChoosen,
    });

    print(body);
    try {
      final response = await http.post(
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
      toggleValue = false;
      setState(() {});
    } catch (e) {
      if (!(await InternetConnectionChecker().hasConnection)) {
        Fluttertoast.showToast(msg: "Please check you internet connection");
      } else {
        Fluttertoast.showToast(msg: "Please try again.");
      }
      print(e);
    }
  }

  Future<void> getData() async {
    try {
      var response = await http.get(
          Uri.parse(kIpAddress +
              '/admin-bookings/${StudentInfo.gameChoosen}/${StudentInfo.dateChoosen}/${StudentInfo.slotChoosen}'),
          headers: {
            "x-access-token": StudentInfo.jwtToken,
            "admin-header": "YES"
          });
      var jsonData = await jsonDecode(response.body);
      var slotResponse = await http.get(
          Uri.parse(kIpAddress +
              "/slot-capacity-change?game=${StudentInfo.gameChoosen}&date=${StudentInfo.dateChoosen}&slot=${StudentInfo.slotChoosen}"),
          headers: {
            "x-access-token": StudentInfo.jwtToken,
            "admin-header": "YES"
          });
      slotData = jsonDecode(slotResponse.body);
      print(jsonData);
      print(slotData);
      slotNumberController =
          TextEditingController(text: slotData['message'].toString());
      pendingList = jsonData["message"];
      toggleValue = !jsonData["isEnabled"];
      if (pendingList.length == 0) {
        emptyList = true;
      } else {
        emptyList = false;
      }
    } catch (e) {
      print(e);
      return Future.error(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
          appBar: AppBar(
            backgroundColor: kPrimaryColor,
            centerTitle: true,
            title: Text('BOOKINGS'),
          ),
          body: Center(
            child: FutureBuilder(
                      future:myFuture,
                      builder:(context,snapshot){
                       if(snapshot.hasError){
                          return GestureDetector(
                      onTap: () {
                        myFuture = getData();
                        setState(() {});
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
                       }
                       else if(snapshot.connectionState==ConnectionState.waiting){
                          return Center(
                child: CircularProgressIndicator(
                color: Colors.purple,
              ));
                       }
                        else{
                          return  RefreshIndicator(
                          onRefresh: getData,
                          child: ListView(
                            physics: AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: size.height * 0.03),
                              Row(
                                children: [
                                  Spacer(),
                                  Container(
                                    width: size.width * 0.25,
                                    height: size.width * 0.15,
                                    child: TextFormField(
                                        controller: slotNumberController,
                                        textInputAction: TextInputAction.done,
                                        onFieldSubmitted: (value) async {
                                          print(value);
                                          await changeSlot();
                                        },
                                        decoration: InputDecoration(
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            borderSide: BorderSide(
                                                color: Colors.purple, width: 1.5),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: BorderSide(
                                                color: Colors.purple, width: 1.5),
                                          ),
                                          contentPadding: EdgeInsets.only(
                                              left:
                                                  20), // add padding to adjust text
                                          suffixIcon: Icon(
                                            Icons.edit,
                                            color: Colors.black,
                                          ),
                                        )),
                                  ),
                                  Spacer(
                                    flex: 5,
                                  ),
                                  FlutterSwitch(
                                    width: 70.0,
                                    height: 35.0,
                                    activeColor: Colors.red,
                                    inactiveColor: Colors.green,
                                    activeIcon: Icon(
                                      Icons.lock_outlined,
                                      size: 30,
                                      color: Colors.red,
                                    ),
                                    inactiveIcon: Icon(
                                      Icons.lock_outlined,
                                      size: 30,
                                      color: Colors.green,
                                    ),
                                    toggleSize: 25.0,
                                    value: toggleValue,
                                    borderRadius: 30.0,
                                    padding: 5.0,
                                    showOnOff: false,
                                    onToggle: (state) async {
                                      if (state) {
                                        await disbaleSlot();
                                        getData();
                                      } else {
                                        await enableSlot();
                                        getData();
                                      }
                                      setState(() {});
                                    },
                                  ),
                                  Spacer(),
                                ],
                              ),
                              SizedBox(height: size.height * 0.03),
                              Expanded(
                                child: emptyList == true
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            height: size.width * 0.3,
                                          ),
                                          AutoSizeText(
                                            'No bookings',
                                            style: TextStyle(fontSize: 20),
                                          ),
                                        ],
                                      )
                                    : ListView.builder(
                                        physics: NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        itemCount: pendingList.length,
                                        itemBuilder: (context, index) {
                                          return AdminSlotCard(
                                            size: size,
                                            bookingId: pendingList[index]
                                                ['Booking_ID'],
                                            studentName: pendingList[index]
                                                ['Student_Name'],
                                            snuId: pendingList[index]['SNU_ID'],
                                          );
                                        }),
                              ),
                            ],
                          ),
                        );
                        }
                      }
                    ),
          )),
    );
  }
}
