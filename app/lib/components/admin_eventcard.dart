import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:isc/provider/theme_provider.dart';
import 'package:isc/routes.dart';

import 'package:isc/screens/time_slot.dart';
import 'package:http/http.dart' as http;
import 'package:isc/user-info.dart';
import 'package:provider/provider.dart';

import 'package:transparent_image/transparent_image.dart';

import '../constants.dart';

class AdminEventCard extends StatefulWidget {
  String title;
  String uri;

  AdminEventCard({required this.title, required this.uri});

  @override
  _AdminEventCardState createState() => _AdminEventCardState();
}

class _AdminEventCardState extends State<AdminEventCard> {
  double opacity = 0.5;
  String JWTtoken = '';
  //String game = '';
  bool toggleValue = false;
  late bool hasInternet;

  double spreadRadius = 5;
  bool value = true;

  double blurRadius = 7;
  void disbaleSlot() async {
    JWTtoken = await FirebaseAuth.instance.currentUser!.getIdToken();
    final slotResponse = await http.get(
        Uri.parse(
            kIpAddress + "/booking-count?category=game&game=" + widget.title),
        headers: {"x-access-token": JWTtoken});

    final responseJsonData = jsonDecode(slotResponse.body);
    String slotsAvailable = responseJsonData['message'];
    bool isSlotAvailable = false;
    print("Sport ke slot = $slotsAvailable");
    if (slotsAvailable != '0') {
      isSlotAvailable = true;
    }
    await showDialog(
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
                  Navigator.of(context).pop();
                  var body = jsonEncode({
                    "category": "game",
                    "game": widget.title,
                  });
                  toggleValue = true;
                  setState(() {});
                  print(body);
                  try {
                    final response = await http.post(
                      Uri.parse(kIpAddress + '/stop'),
                      headers: {
                        'Content-Type': 'application/json',
                        'Accept': '*/*',
                        'Accept-Encoding': 'gzip, deflate, br',
                        'Access-Control-Allow-Origin': ' *',
                        "x-access-token": JWTtoken,
                        "admin-header": "YES"
                      },
                      body: body,
                    );
                    print("Disbale ka");
                    print(response.body);
                  } catch (e) {
                    print(e);
                  }
                },
                child: Text('Yes'),
              ),
            ],
          );
        });
  }

  void enableSlot() async {
    JWTtoken = await FirebaseAuth.instance.currentUser!.getIdToken();

    var body = jsonEncode({
      "category": "game",
      "game": widget.title,
    });
    toggleValue = false;
    setState(() {});

    print(body);
    try {
      final response = await http.post(
        Uri.parse(kIpAddress + '/unstop'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': '*/*',
          'Accept-Encoding': 'gzip, deflate, br',
          'Access-Control-Allow-Origin': ' *',
          "x-access-token": JWTtoken,
          "admin-header": "YES"
        },
        body: body,
      );
      print("Enable ka");
      print(response.body);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    dynamic theme = Provider.of<ThemeProvider>(context);
    return GestureDetector(
      onLongPress: () {},
      onTap: (){
           StudentInfo.gameChoosen = widget.title;
          Navigator.pushNamed(context, AppRoutes.studentTime);
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: theme.checkTheme(Colors.grey.withOpacity(0.5),
                  Colors.purple.shade500, context),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 5), // changes position of shadow
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
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
                hasInternet = await InternetConnectionChecker().hasConnection;
                if (hasInternet) {
                  setState(() {
                    if (state) {
                      disbaleSlot();
                    } else {
                      enableSlot();
                    }
                  });
                } else {
                  Fluttertoast.showToast(
                      msg: "Please check your internet connection");
                }
              },
            ),
            Expanded(
              child: Center(
                child: FadeInImage.memoryNetwork(
                  image: widget.uri,
                  placeholder: kTransparentImage,
                ),
              ),
            ),
            Center(
              child: Text(
                widget.title,
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color:
                        theme.checkTheme(Colors.black, Colors.purple, context)),
              ),
            )
          ],
        ),
      ),
    );
  }
}