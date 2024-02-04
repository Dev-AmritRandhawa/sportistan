import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:lottie/lottie.dart';
import 'package:SportistanPro/payment/payment_gateway.dart';

class SportistanCredit extends StatefulWidget {
  const SportistanCredit({super.key, required this.groundID});
  final String groundID;
  @override
  State<SportistanCredit> createState() => _SportistanCreditState();
}

class _SportistanCreditState extends State<SportistanCredit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  String? result;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    addBalanceController.text = '500';
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final _server = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  TextEditingController addBalanceController = TextEditingController();
  GlobalKey<FormState> addBalanceControllerKey = GlobalKey<FormState>();

  final _focusNode = FocusNode();

  KeyboardActionsConfig _buildConfig(BuildContext context) {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      keyboardBarColor: Colors.white,
      nextFocus: true,
      actions: [
        KeyboardActionsItem(
          focusNode: _focusNode,
        ),
        KeyboardActionsItem(focusNode: _focusNode, toolbarButtons: [
          (node) {
            return TextButton(
                onPressed: () {
                  node.unfocus();
                },
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 18),
                ));
          }
        ])
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Back'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: KeyboardActions(
        config: _buildConfig(context),
        child: SafeArea(
          child: StreamBuilder(
            stream: _server
                .collection("SportistanUsers")
                .where("userID", isEqualTo: _auth.currentUser!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              return snapshot.hasData
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                          Center(
                            child: Column(
                              children: [
                                Image.asset('assets/logo.png',
                                    height: MediaQuery.of(context).size.height /
                                        15),
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Sportistan',
                                    style: TextStyle(
                                        fontFamily: "DMSans",
                                        fontSize: 20,
                                        color: Colors.black54),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Your Balance',
                                    style: TextStyle(
                                        fontFamily: "DMSans",
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                                20,
                                        color: Colors.black54),
                                  ),
                                ),
                                Text(
                                  "Rs.${snapshot.data!.docChanges.first.doc.get('sportistanCredit')}",
                                  style: TextStyle(
                                    fontFamily: "DMSans",
                                    fontSize:
                                        MediaQuery.of(context).size.height / 20,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Form(
                                    key: addBalanceControllerKey,
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width /
                                          1.5,
                                      child: TextFormField(
                                        cursorColor: Colors.black54,
                                        controller: addBalanceController,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                        focusNode: _focusNode,
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return 'Enter Amount';
                                          } else if (num.parse(
                                                      value.toString()) >
                                                  50000 ||
                                              num.parse(value.toString()) <=
                                                  0) {
                                            return 'Min Rs.1 to Max Rs.50000';
                                          } else {
                                            return null;
                                          }
                                        },
                                        decoration: const InputDecoration(
                                            prefixIcon: Icon(Icons.add),
                                            border: OutlineInputBorder(),
                                            filled: true,
                                            fillColor: Colors.white),
                                      ),
                                    ))
                              ],
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height / 4,
                            child: Lottie.asset(
                              'assets/wallet.json',
                              controller: _controller,
                              onLoaded: (composition) {
                                _controller
                                  ..duration = composition.duration
                                  ..repeat();
                              },
                            ),
                          ),
                          CupertinoButton(
                              color: Colors.green.shade900,
                              onPressed: () async {
                                if (addBalanceControllerKey.currentState!
                                    .validate()) {
                                  if (Platform.isAndroid) {
                                    final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => Gateway(
                                                  amount: num.parse(
                                                      addBalanceController
                                                          .value.text
                                                          .toString()),
                                                  addInWallet: true,
                                                )));

                                    if (result == null) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content:
                                                    Text("Payment Cancelled")));
                                      }
                                    }
                                  } else {
                                    final result = await Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                          builder: (context) => Gateway(
                                            amount: num.parse(
                                                addBalanceController.value.text
                                                    .toString()),
                                            addInWallet: true,
                                          ),
                                        ));
                                    if (result == null) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content:
                                                    Text("Payment Cancelled")));
                                      }
                                    }
                                  }
                                }
                              },
                              child: const Text('Add Credits')),
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              "Your Payment is 100% Secure",
                              style: TextStyle(
                                  fontFamily: "DMSans",
                                  fontSize: 20,
                                  color: Colors.black54),
                            ),
                          )
                        ])
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                            child: CircularProgressIndicator(
                          strokeWidth: 1,
                        ))
                      ],
                    );
            },
          ),
        ),
      ),
    );
  }
}
