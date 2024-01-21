import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paytm_allinonesdk/paytm_allinonesdk.dart';

class PaymentGateway extends StatefulWidget {
  const PaymentGateway({super.key});

  @override
  State<PaymentGateway> createState() => _PaymentGatewayState();
}

class _PaymentGatewayState extends State<PaymentGateway> {
  String? result;

  @override
  Widget build(BuildContext context) {
    return  Scaffold(

      appBar: AppBar(elevation: 0,backgroundColor: Colors.white,),
      body: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(result.toString()),
          CupertinoButton(onPressed: (){
            startTransaction();

            setState(() {

});
          }, child: const Text("Start"))
        ],
      ),),
    );
  }

  void startTransaction() {
    try {
      var response = AllInOneSdk.startTransaction(
          "mid", "orderId", "1000", "fe795335ed3049c78a57271075f2199e1526969112097", "", true, true);
      response.then((value) {
        print(value);
        setState(() {
          result = value.toString();
        });
      }).catchError((onError) {
        if (onError is PlatformException) {
          setState(() {
            result = "${onError.message} \n  ${onError.details}";
          });
        } else {
          setState(() {
            result = onError.toString();
          });
        }
      });
    } catch (err) {
      result = err.toString();
    }
  }
}
