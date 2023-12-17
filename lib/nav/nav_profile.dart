import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sportistan/authentication/authentication.dart';
import 'package:sportistan/payment/sportistan_credit.dart';
import 'package:sportistan/widgets/page_route.dart';

class NavProfile extends StatefulWidget {
  const NavProfile({super.key});

  @override
  State<NavProfile> createState() => _NavProfileState();
}

class _NavProfileState extends State<NavProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SafeArea(
          child: Column(children: [
            MaterialButton(
              color: Colors.red,
              onPressed: (){
              FirebaseAuth.instance.signOut().then((value) => {
                PageRouter.pushRemoveUntil(context, const PhoneAuthentication())
              });
            },child: const Text("Logout"),),
            MaterialButton(
              color: Colors.red,
              onPressed: (){
                PageRouter.push(context, const SportistanCredit());
            },child: const Text("ddsd"),)
          ]),
        ),
      ),
    );
  }
}
