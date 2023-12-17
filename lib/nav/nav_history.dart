import 'package:flutter/material.dart';

class NavHistory extends StatefulWidget {
  const NavHistory({super.key});

  @override
  State<NavHistory> createState() => _NavHistoryState();
}

class _NavHistoryState extends State<NavHistory> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,

      ),
      body: SafeArea(child: Column(children: [

      ])),
    );
  }
}
