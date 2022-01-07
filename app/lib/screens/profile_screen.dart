import 'package:flutter/material.dart';
import 'package:isc/components/bottom_navi_bar.dart';
import 'package:isc/constants.dart';
import 'package:isc/provider/theme_provider.dart';
import 'package:isc/screens/setting_screen.dart';
import 'package:isc/screens/welcome_screen.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    dynamic theme = Provider.of<ThemeProvider>(context).themeMode;
    Color checkTheme(Color first, Color second) {
      print(ThemeMode.system);
      if (theme == ThemeMode.light) {
        return first;
      } else if (theme == ThemeMode.dark) {
        return second;
      } else {
        if (MediaQuery.of(context).platformBrightness == Brightness.light) {
          return first;
        } else {
          return second;
        }
      }
    }

    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: checkTheme(Colors.white, Colors.black),
        leading: BackButton(color: kPrimaryColor),
        centerTitle: true,
        title: Text("Profile", style: TextStyle(color: kPrimaryColor)),
      ),
      bottomNavigationBar: BottomNaviBar('profile'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
                margin: EdgeInsets.all(size.height * 0.05),
                child: CircleAvatar(
                  backgroundColor: Colors.grey,
                  radius: size.width * 0.15,
                )),
            ProfileCard(
                size: size,
                text: 'Account',
                icon: Icons.account_box_outlined,
                func: () {}),
            ProfileCard(
                size: size,
                text: 'Bookings',
                icon: Icons.my_library_books_sharp,
                func: () {}),
            ProfileCard(
                size: size,
                text: 'Settings',
                icon: Icons.settings,
                func: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => SettingScreen()));
                }),
            ProfileCard(
                size: size,
                text: 'Help Center',
                icon: Icons.help_center,
                func: () {}),
            ProfileCard(
              size: size,
              text: 'Log Out',
              icon: Icons.login_outlined,
              func: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => WelcomeScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    Key? key,
    required this.size,
    required this.text,
    required this.icon,
    required this.func,
  }) : super(key: key);

  final Size size;
  final String text;
  final IconData icon;
  final Function func;

  @override
  Widget build(BuildContext context) {
    dynamic theme = Provider.of<ThemeProvider>(context).themeMode;
    Color checkTheme(Color first, Color second) {
      print(ThemeMode.system);
      if (theme == ThemeMode.light) {
        return first;
      } else if (theme == ThemeMode.dark) {
        return second;
      } else {
        if (MediaQuery.of(context).platformBrightness == Brightness.light) {
          return first;
        } else {
          return second;
        }
      }
    }

    return GestureDetector(
      onTap: () {
        func();
      },
      //  theme == ThemeMode.light ? Colors.grey[100] : Colors.purple[700],
      child: Container(
        margin: EdgeInsets.all(10),
        padding: EdgeInsets.all(10),
        width: size.width * 0.9,
        height: size.height * 0.07,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: checkTheme(Colors.grey.shade100, Colors.purple.shade700)),
        child: Row(children: [
          Icon(
            icon,
            color: checkTheme(kPrimaryColor, Colors.purple.shade100),
            size: size.width * 0.08,
          ),
          Expanded(
            child: Container(
                margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Text(
                  text,
                  style: TextStyle(
                      fontSize: 20,
                      color: checkTheme(Colors.black, Colors.white)),
                )),
          ),
          Icon(
            Icons.navigate_next_outlined,
            color: checkTheme(kPrimaryColor, Colors.purple.shade100),
            size: size.width * 0.09,
          ),
        ]),
      ),
    );
  }
}
