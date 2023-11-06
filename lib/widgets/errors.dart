import 'package:another_flushbar/flushbar.dart';
import 'package:another_flushbar/flushbar_route.dart';
import 'package:flutter/material.dart';

class Errors {
  static void flushBarAuth(String message, BuildContext context) {
    showFlushbar(
        context: context,
        flushbar: Flushbar(
          icon: const Icon(Icons.error, color: Colors.white),
          message: message,
          title: "Error",
          margin: EdgeInsets.all(MediaQuery.of(context).size.width / 25),
          duration: const Duration(seconds: 2),
          flushbarPosition: FlushbarPosition.TOP,
          messageColor: Colors.white,
          backgroundColor: Colors.red.shade900,
          borderRadius: BorderRadius.circular(15),
        )..show(context));
  }

  static void flushBarInform(
      String message, BuildContext context, String title) {
    showFlushbar(
        context: context,
        flushbar: Flushbar(
          icon: const Icon(Icons.error, color: Colors.white),
          message: message,
          title: title,
          margin: EdgeInsets.all(MediaQuery.of(context).size.width / 25),
          duration: const Duration(seconds: 2),
          flushbarPosition: FlushbarPosition.TOP,
          messageColor: Colors.white,
          backgroundColor: Colors.red.shade900,
          borderRadius: BorderRadius.circular(15),
        )..show(context));
  }
}

class Alert {
  static void flushBarAlert({required String message, required BuildContext context, required String title}) {
    showFlushbar(
        context: context,
        flushbar: Flushbar(
          icon: const Icon(Icons.warning_rounded, color: Colors.white),
          message: message,
          title: title,
          margin: EdgeInsets.all(MediaQuery.of(context).size.width / 25),
          duration: const Duration(seconds: 2),
          flushbarPosition: FlushbarPosition.TOP,
          messageColor: Colors.white,
          backgroundColor: Colors.green,
          borderRadius: BorderRadius.circular(15),
        )..show(context));
  } static void flushBarBadAlert({required String message, required BuildContext context, required String title}) {
    showFlushbar(
        context: context,
        flushbar: Flushbar(
          icon: const Icon(Icons.warning_rounded, color: Colors.white),
          message: message,
          title: title,
          margin: EdgeInsets.all(MediaQuery.of(context).size.width / 25),
          duration: const Duration(seconds: 2),
          flushbarPosition: FlushbarPosition.BOTTOM,
          messageColor: Colors.white,
          backgroundColor: Colors.red,
          borderRadius: BorderRadius.circular(15),
        )..show(context));
  }

}
