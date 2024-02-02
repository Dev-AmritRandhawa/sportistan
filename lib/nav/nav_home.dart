import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:SportistanPro/nav/main_page.dart';
import 'package:SportistanPro/nav/nav_profile.dart';

import 'nav_history.dart';

class NavHome extends StatefulWidget {
  const NavHome({super.key});

  @override
  State<NavHome> createState() => _NavHomeState();
}

class _NavHomeState extends State<NavHome> {
  var _selectedIndex = 0;

  final _widgetOptions = [
    const MainPage(),
    const NavHistory(),
    const NavProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        themeMode: ThemeMode.light,
        theme: ThemeData.light(useMaterial3: false),
        home: Scaffold(
            bottomSheet: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GNav(
                mainAxisAlignment: MainAxisAlignment.center,
                rippleColor: Colors.grey[300]!,
                hoverColor: Colors.grey[100]!,
                activeColor: Colors.teal,
                gap: MediaQuery.of(context).size.height / 30,
                iconSize: MediaQuery.of(context).size.height / 30,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                duration: const Duration(milliseconds: 400),
                tabBackgroundColor: Colors.grey[100]!,
                color: Colors.black54,
                tabs: const [
                  GButton(
                    icon: Icons.home,
                    text: 'Home',
                  ),
                  GButton(
                    icon: Icons.history,
                    text: 'History',
                  ),
                  GButton(
                    icon: Icons.account_circle_rounded,
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
            body: _widgetOptions.elementAt(_selectedIndex)));
  }
}
