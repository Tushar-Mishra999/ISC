import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../user-info.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({Key? key}) : super(key: key);

  @override
  _FaqScreenState createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  var questionAnswer = {};
  var isExpanded = List<bool>.filled(2, false);
  late Future myFuture;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    myFuture = getData();
  }

  Future<void> getData() async {
    String JWTtoken = StudentInfo.jwtToken;
    try {
      var response = await http.get(Uri.parse(kIpAddress + '/faq'),
          headers: {"x-access-token": JWTtoken});
      var jsonData = await jsonDecode(response.body);
      questionAnswer = jsonData['message'];
      print(jsonData);
    } catch (e) {
      print(e);
      return Future.error(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: Center(
            child: FutureBuilder(
                future: myFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return GestureDetector(
                      onTap: () async {
                        if (!(await InternetConnectionChecker()
                            .hasConnection)) {
                          Fluttertoast.showToast(
                              msg: "Please check your internet connection");
                        } else {
                         
                          setState(() { myFuture = getData();});
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
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: size.height * 0.05,
                        ),
                        Text(
                          'FAQs',
                          style: TextStyle(
                              fontSize: 35, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: size.height * 0.1,
                        ),
                        Container(
                          width: size.width * 0.9,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: MediaQuery.of(context).platformBrightness ==
                                    Brightness.light
                                ? Colors.white
                                : Colors.grey.shade900,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    MediaQuery.of(context).platformBrightness ==
                                            Brightness.light
                                        ? Colors.grey
                                        : Colors.grey.shade900,
                                blurRadius: 2.0,
                                spreadRadius: 0.0,
                                offset: Offset(
                                    1.0, 5.0), // shadow direction: bottom right
                              )
                            ],
                          ),
                          child: ListView.builder(
                              shrinkWrap: true,
                              physics: AlwaysScrollableScrollPhysics(),
                              itemCount: questionAnswer.length,
                              itemBuilder: (context, index) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                      dividerColor: Colors.transparent),
                                  child: Container(
                                    margin: EdgeInsets.all(5),
                                    child: ExpansionTile(
                                      iconColor: Colors.purple,
                                      collapsedIconColor: Colors.purple,
                                      title: Container(
                                          margin: EdgeInsets.only(left: 5),
                                          child: AutoSizeText(
                                            questionAnswer.keys
                                                .elementAt(index),
                                            style: TextStyle(
                                                fontSize: 20,
                                                color: Color(0xFFD655D0),
                                                fontWeight: FontWeight.bold),
                                          )),
                                      children: [
                                        Container(
                                            padding: EdgeInsets.only(
                                                top: 5, bottom: 20),
                                            margin: EdgeInsets.only(
                                                left: 20, right: 20),
                                            child: AutoSizeText(
                                              questionAnswer.values
                                                  .elementAt(index),
                                              style: TextStyle(fontSize: 17),
                                            )),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                        )
                      ],
                    );
                  }
                })),
      ),
    );
  }
}
