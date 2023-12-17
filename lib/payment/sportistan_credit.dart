import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sportistan/widgets/errors.dart';

class SportistanCredit extends StatefulWidget {
  const SportistanCredit({super.key});

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
                    loading.value = false
                  }
              });
    } on SocketException catch (e) {
      loading.value = false;
      showError.value = true;
    } catch (e) {
      loading.value = false;
      showError.value = true;
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
        SafeArea(
          child: ValueListenableBuilder(
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Your Balance',
                            style: TextStyle(
                                fontFamily: "DMSans",
                                fontSize: 20,color: Colors.black54),
                          ),Text(
                            balance.toString(),
                            style: const TextStyle(
                                fontFamily: "DMSans",
                                fontSize: 22,
                                fontWeight: FontWeight.w500),
                          ),
                          CupertinoButton(
                              color: Colors.green.shade900,
                              onPressed: (){

                          }, child: const Text('Add More Credits')),

                        ],
                      ),
                    )),
        ),
        ValueListenableBuilder(
            valueListenable: showError,
            builder: (context, value, child) => value
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
        Lottie.asset(
          'assets/wallet.json',
          controller: _controller,
          onLoaded: (composition) {
            _controller
              ..duration = composition.duration
              ..forward();
          },
        ),
      ]),
    );
  }
}
