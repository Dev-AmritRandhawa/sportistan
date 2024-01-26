import 'dart:convert';
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
                  initiatePayment();
                }),
          )
        ],
      ),
    );
  }

  Future<void> initiatePayment() async {
    const String firebaseFunctionURL =
        'https://generatetxnchecksum-6k2fyesg5q-uc.a.run.app/'; // Replace with your actual Firebase Cloud Function URL

    try {
      // Make a GET request to your Firebase Cloud Function to fetch the required parameters
      final response = await http.get(Uri.parse(firebaseFunctionURL));
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        final String mid = responseData['mid'];
        final String orderId = responseData['orderId'];
        final String signature = responseData['signature'];

        // Set up the paytmParams
        final Map<String, dynamic> paytmParams = {
          'body': {
            'requestType': 'Payment',
            'mid': mid,
            'websiteName': 'DEFAULT',
            'orderId': orderId,
            'callbackUrl': 'https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=$orderId',
            'txnAmount': {'value': '1.00', 'currency': 'INR'},
            'userInfo': {'custId': 'CUST_001'},
          },
          'head': {'signature': signature}, // Replace with your actual signature
        };

        // Convert paytmParams to JSON string
        final String postData = json.encode(paytmParams);

        // Set up HTTP request options
        final http.Response paytmResponse = await http.post(
          Uri.parse(firebaseFunctionURL),
          headers: {'Content-Type': 'application/json'},
          body: postData,
        );

        print('Paytm Response: ${paytmResponse.body}');
      } else {
        print('Failed to fetch parameters. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }
}