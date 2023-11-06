import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PageRouter{

  static void push(BuildContext context, Widget className){
    if(Platform.isAndroid){
      Navigator.push(context, MaterialPageRoute(builder: (context) => className,));
    }
    if(Platform.isIOS){
      Navigator.push(context, CupertinoPageRoute(builder: (context) => className,));
    }
  }
  static void pushReplacement(BuildContext context, Widget className){
    if(Platform.isAndroid){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => className,));
    }
    if(Platform.isIOS){
      Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => className,));
    }
  }
  static void pushRemoveUntil(BuildContext context, Widget className){
    if(Platform.isAndroid){
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => className,),(route) => false,);
    }
    if(Platform.isIOS){
      Navigator.pushAndRemoveUntil(context, CupertinoPageRoute(builder: (context) => className,),(route) => false,);
    }
  }
}