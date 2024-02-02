import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:lottie/lottie.dart';
import 'package:sportistan/booking/unique.dart';
import 'package:sportistan/payment/payment_gateway.dart';
import 'package:sportistan/widgets/page_route.dart';

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
    _checkBalance();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final _server = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  ValueNotifier<bool> showError = ValueNotifier<bool>(false);
  ValueNotifier<bool> loading = ValueNotifier<bool>(true);
  TextEditingController addBalanceController = TextEditingController();
  GlobalKey<FormState> addBalanceControllerKey = GlobalKey<FormState>();
  late num balance;

  Future<void> _checkBalance() async {
    try {
      await _server
          .collection("SportistanUsers")
          .where("userID", isEqualTo: _auth.currentUser!.uid)
          .get()
          .then((value) => {
                if (value.docChanges.isNotEmpty)
                  {
                    balance =
                        value.docChanges.first.doc.get('sportistanCredit'),
                    addBalanceController.text = '1000',
                    loading.value = false
                  }
              });
    } on SocketException {
      loading.value = false;

      showError.value = true;
    } catch (e) {
      loading.value = false;
      showError.value = true;
      return;
    }
  }

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
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ValueListenableBuilder(
                    valueListenable: loading,
                    builder: (context, value, child) => value
                        ? const Card(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(7.0),
                                  child: CircularProgressIndicator(
                                    color: Colors.black45,
                                    strokeWidth: 1,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Center(
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
                                  "Rs.$balance",
                                  style: TextStyle(
                                      fontFamily: "DMSans",
                                      fontSize:
                                          MediaQuery.of(context).size.height /
                                              20,
                                      fontWeight: FontWeight.w500,
                                      color: balance < 10
                                          ? Colors.redAccent
                                          : Colors.green),
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
                                          if (num.parse(value.toString()) >
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
                          )),
                ValueListenableBuilder(
                    valueListenable: showError,
                    builder: (context, value, child) => value
                        ? Column(
                            children: [
                              const Text(
                                'Something went wrong',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontFamily: "DMSans",
                                    fontSize: 220),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: MaterialButton(
                                  onPressed: () {
                                    loading.value = true;
                                    _checkBalance();
                                  },
                                  color: Colors.red,
                                  child: const Text('Try Again'),
                                ),
                              )
                            ],
                          )
                        : Container()),
                SizedBox(
                  height: MediaQuery.of(context).size.height / 5,
                  child: Lottie.asset(
                    'assets/walletAdding.json',
                    controller: _controller,
                    onLoaded: (composition) {
                      _controller
                        ..duration = composition.duration
                        ..forward();
                    },
                  ),
                ),
                CupertinoButton(
                    color: Colors.green.shade900,
                    onPressed: () {
                      if (addBalanceControllerKey.currentState!.validate()) {
                        PageRouter.push(
                            context,
                            Gateway(
                              amount:
                                  addBalanceController.value.text.toString(),
                              orderID: UniqueID.generateRandomString(),
                              userID: FirebaseAuth.instance.currentUser!.uid
                                  .toString(),
                            ));
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
              ]),
        ),
      ),
    );
  }
}
