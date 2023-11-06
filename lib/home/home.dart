import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:sportistan/booking/my_bookings.dart';
import 'package:sportistan/booking/payment_mode.dart';
import 'package:sportistan/home/nav_home.dart';
import 'package:sportistan/home/nav_profile.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget>[
    NavHome(),
    Bookings(),
    Payments(),
    Profile(),
  ];
  @override
  Widget build(BuildContext context) {

          return Scaffold(
              bottomSheet: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GNav(
                  rippleColor: Colors.grey[300]!,
                  hoverColor: Colors.grey[100]!,
                  gap: 8,
                  activeColor: Colors.green,
                  iconSize: 24,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  duration: const Duration(milliseconds: 400),
                  tabBackgroundColor: Colors.grey[100]!,
                  color: Colors.black54,
                  tabs: const [
                    GButton(
                      icon: Icons.home,
                      text: 'Home',
                    ),GButton(
                      icon: Icons.local_play,
                      text: 'My Bookings',
                    ),
                    GButton(
                      icon: Icons.payments,
                      text: 'Payments',
                    ),

                    GButton(
                      icon: Icons.people,
                      text: 'Profile',
                    ),
                  ],
                  selectedIndex: _selectedIndex,
                  onTabChange: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                ),
              ),
              resizeToAvoidBottomInset: false,
              backgroundColor: Colors.grey[200],
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                title: Text("Sportistan",
                    style: TextStyle(
                        color: Colors.green.shade800, fontFamily: "DMSans")),
              ),
              body:  _widgetOptions.elementAt(_selectedIndex));
}
}
