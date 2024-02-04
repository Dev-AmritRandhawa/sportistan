import 'dart:convert';
import 'package:SportistanPro/booking/unique.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:paytm_allinonesdk/paytm_allinonesdk.dart';

class Gateway extends StatefulWidget {
  final num amount;
  final bool addInWallet;

  const Gateway({
    super.key,
    required this.amount,
    required this.addInWallet,
  });

  @override
  State<Gateway> createState() => _GatewayState();
}

class _GatewayState extends State<Gateway> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  bool paymentInit = true;
  ValueNotifier<bool> loading = ValueNotifier(true);
  String failedMsg = 'Failed';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          ValueListenableBuilder(
              valueListenable: loading,
              builder: (context, value, child) => value
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height / 4,
                            width: MediaQuery.of(context).size.width / 2,
                            child: Lottie.asset(
                              'assets/wallet.json',
                              controller: _controller,
                              onLoaded: (composition) {
                                _controller
                                  ..duration = composition.duration
                                  ..forward().then((value) => {
                                      initiatePaytmTransaction()
                                  });
                              },
                            ),
                          ),
                          const CircularProgressIndicator(strokeWidth: 1,),
                          const Text(
                            "Processing Payment",
                            style:
                                TextStyle(fontFamily: "DMSans", fontSize: 20),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              "Please don't close page we will auto verify payment",
                              style:
                                  TextStyle(fontFamily: "DMSans", fontSize: 16,color: Colors.black45),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CupertinoButton(
                                color: Colors.green,
                                child: const Text("Cancel"),
                                onPressed: () async {
                                 Navigator.pop(context);
                                }),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              textAlign: TextAlign.center,
                              "Your Transaction is failed if any amount is deducted please contact customer support",
                              style:
                                  TextStyle(fontFamily: "DMSans", fontSize: 20),
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height / 3,
                            child: Lottie.asset(
                              'assets/paymentError.json',
                              controller: _controller,
                              onLoaded: (composition) {
                                _controller
                                  ..duration = composition.duration
                                  ..repeat();
                              },
                            ),
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
    final orderID = UniqueID.generateRandomString();

    try {
      const String firebaseFunctionUrl =
          'https://initiatepaytmtransaction-kyawqf5yqa-uc.a.run.app';

      final Map<String, dynamic> requestBody = {
        "amount": widget.amount,
        "userID": FirebaseAuth.instance.currentUser!.uid,
        "orderId": orderID,
      };

      final http.Response response = await http.post(
        Uri.parse(firebaseFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final txnToken = data['body']["txnToken"];
        try {
          final res = AllInOneSdk.startTransaction(
              'SPORTS33075460479694',
              orderID,
              widget.amount.toString(),
              txnToken,
              "https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=$orderID",
              false,
              true,
              false);
          res.then((value) {
            _statusTransaction(orderID: orderID);
          }).catchError((onError) {
            loading.value = false;
          });
        } catch (err) {
          loading.value = false;
          return;
        }
      } else {
        loading.value = false;
      }
    } catch (e) {
      loading.value = false;
    }
  }

  Future<void> _statusTransaction({required String orderID}) async {
    try {
      const String firebaseFunctionUrl =
          'https://statuspaytmtransaction-kyawqf5yqa-uc.a.run.app';
      final Map<String, dynamic> requestBody = {
        "mid": 'SPORTS33075460479694',
        "orderId": orderID,
      };

      final http.Response response = await http.post(
        Uri.parse(firebaseFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      final data = jsonDecode(response.body);
      if (data['body']['resultInfo']['resultStatus'] == 'TXN_SUCCESS' &&
          data['body']['resultInfo']['resultCode'] == '01') {
        if (widget.addInWallet) {
          await _checkBalance();
        } else {
          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      } else {
        failedMsg = data['body']['resultInfo']['resultMsg'];
        loading.value = false;
      }
    } catch (e) {
      loading.value = false;
    }
  }

  Future<void> _checkBalance() async {
    await FirebaseFirestore.instance
        .collection("SportistanUsers")
        .where("userID", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((value) => {
              if (value.docChanges.isNotEmpty)
                {
                  updateBalance(
                      current:
                          value.docChanges.first.doc.get('sportistanCredit'),
                      id: value.docChanges.first.doc.id)
                }
            });
  }

  Future<void> updateBalance({required num current, required String id}) async {
    await FirebaseFirestore.instance
        .collection("SportistanUsers")
        .doc(id)
        .update({'sportistanCredit': widget.amount + current}).then((value) => {
              showModalBottomSheet(
                isDismissible: false,
                isScrollControlled: false,
                enableDrag: false,
                showDragHandle: true,
                context: context,
                builder: (ctx) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const Text(
                        "Success",
                        style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 22,
                            color: Colors.green),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Transaction is Completed. Amount Rs.${widget.amount} added successfully in your wallet",
                          style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 20,
                              color: Colors.black54),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 4,
                        width: MediaQuery.of(context).size.width / 2,
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
                        color: Colors.green,
                        child: const Text("Ok"),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                      )
                    ],
                  );
                },
              )
            });
  }


}
