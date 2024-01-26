import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:paytm_allinonesdk/paytm_allinonesdk.dart';

class Gateway extends StatefulWidget {
  final String amount;
  final String orderID;
  final String userID;
  const Gateway(
      {super.key,
      required this.amount,
      required this.orderID,
      required this.userID});

  @override
  State<Gateway> createState() => _GatewayState();
}

class _GatewayState extends State<Gateway> {
  bool paymentInit = true;
  ValueNotifier<bool> loading = ValueNotifier(true);
  @override
  void initState() {
    if (paymentInit) {
      initiatePaytmTransaction();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ValueListenableBuilder(
              valueListenable: loading,
              builder: (context, value, child) => value
                  ? const Center(
                      child: CircularProgressIndicator(
                      strokeWidth: 1,
                    ))
                  : Center(
                      child: Column(
                        children: [
                          const Text(
                            "Payment Failed",
                            style:
                                TextStyle(fontFamily: "DMSans", fontSize: 20),
                          ),
                          CupertinoButton(
                              color: Colors.green,
                              child: const Text("Try Again"),
                              onPressed: () async {
                                loading.value = true;
                                initiatePaytmTransaction();
                              }),
                        ],
                      ),
                    ))
        ],
      ),
    );
  }

  Future<void> initiatePaytmTransaction() async {
    paymentInit = false;
    try {
      const String firebaseFunctionUrl =
          'https://initiatepaytmtransaction-6k2fyesg5q-uc.a.run.app'; // Replace with your actual Firebase Cloud Function URL

      final Map<String, dynamic> requestBody = {
        "amount": widget.amount
            .toString(), // Replace with the actual amount you want to pass
        "userID": widget.userID
            .toString(), // Replace with the actual amount you want to pass
        "orderId": widget.orderID
            .toString(), // Replace with the actual amount you want to pass
      };

      final http.Response response = await http.post(
        Uri.parse(firebaseFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final txnToken = data['txnToken'];
        _startTransaction(
            txnToken: txnToken,
            orderID: widget.orderID,
            amount: widget.amount,
            callbackUrl:
                'https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=${widget.orderID}');
      } else {
        loading.value = false;
      }
    } catch (e) {
      loading.value = false;
    }
  }

  Future<void> _startTransaction({
    required String txnToken,
    required String orderID,
    required String amount,
    required String callbackUrl,
  }) async {

    try {
      var response = AllInOneSdk.startTransaction('SPORTS33075460479694',
          orderID, amount, txnToken, callbackUrl, false, true, false);
      response.then((value) {
        print(value);

      }).catchError((onError) {
        if (onError is PlatformException) {
          loading.value = false;
        } else {
          loading.value = false;
        }
      });
    } catch (err) {
      loading.value = false;
      return;
    }
  }
}
