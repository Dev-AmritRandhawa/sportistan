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
                  initiatePayment(amount: 5.00);
                }),
          )
        ],
      ),
    );
  }
Future<void> initiatePayment({required double amount}) async {
  final url = Uri.parse('https://your-firebase-project-url/initiatePayment');
  final response = await http.post(url,
    headers: {'Content-Type': 'application/json'},
    body: '{"amount": $amount}',
  );
if(response.statusCode ==200){
  print(response.body);
  }

}
}
