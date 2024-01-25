import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Gateway extends StatefulWidget {
  const Gateway({super.key});

  @override
  State<Gateway> createState() => _GatewayState();
}

class _GatewayState extends State<Gateway> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: CupertinoButton(
                color: Colors.green,
                child: const Text("Generate"),
                onPressed: () async {
                  makeRequest();
                }),
          )
        ],
      ),
    );
  }

  Future<void> makeRequest() async {
    const url =
        'https://us-central1-oursportistan.cloudfunctions.net/loginFunction'; // Replace with the actual URL of your Firebase Cloud Function
    const customAmount = 200.0; // Replace with your custom amount
    try {
      final response = await http.get(Uri.parse('$url?amount=$customAmount'));
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final orderID = responseData['paytmParams']['ORDERID'];
        final signature = responseData['signature'];
        final headers = {
          'Content-Type': 'application/json',
        };

        final data =
            '{"body":{"requestType":"Payment","mid":"{SPORTS33075460479694}","websiteName":"{DEFAULT}","orderId":"$orderID","txnAmount":{"value":"1.00","currency":"INR"},"userInfo":{"custId":"${FirebaseAuth.instance.currentUser!.uid.toString()}"},"callbackUrl":"https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=$orderID"},"head":{"signature":"{$signature}"}}';

        final url = Uri.parse(
            'https://securegw.paytm.in/theia/api/v1/initiateTransaction?mid=SPORTS33075460479694&orderId=$orderID');

        final res = await http.post(url, headers: headers, body: data);

        if (res.statusCode == 200) {
          final responseData = json.decode(response.body);
          print(responseData);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Failed")));
        }
      }
    } catch (e) {
      return;
    }
  }
}
