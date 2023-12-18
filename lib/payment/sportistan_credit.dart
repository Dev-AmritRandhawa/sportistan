import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';
import 'package:sportistan/widgets/page_route.dart';

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
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
                                      MediaQuery.of(context).size.height / 20,
                                  color: Colors.black54),
                            ),
                          ),
                          Text(
                            "Rs.$balance",
                            style: TextStyle(
                                fontFamily: "DMSans",
                                fontSize:
                                    MediaQuery.of(context).size.height / 20,
                                fontWeight: FontWeight.w500,
                                color: balance < 10
                                    ? Colors.redAccent
                                    : Colors.green),
                          ),
                          Form(
                              key: addBalanceControllerKey,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width / 1.5,
                                child: TextFormField(
                                  cursorColor: Colors.black54,
                                  controller: addBalanceController,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (num.parse(value.toString()) > 50000 ||
                                        num.parse(value.toString()) <= 0) {
                                      return 'Enter Minimum Rs.1 to Maximum Rs.50000';
                                    } else {
                                      return null;
                                    }
                                  },
                                  decoration: const InputDecoration(prefixIcon: Icon(Icons.add),
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.white),
                                ),
                              ))
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
        CupertinoButton(
            color: Colors.green.shade900,
            onPressed: () {
              if (addBalanceControllerKey.currentState!.validate()) {
                PageRouter.push(context, const Gateway());

              }
            },
            child: const Text('Add Credits')),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "Your Payment is 100% Secure",
            style: TextStyle(
                fontFamily: "DMSans", fontSize: 20, color: Colors.black54),
          ),
        )
      ]),
    );
  }
}



class Gateway extends StatefulWidget {
  const Gateway({super.key});

  @override
  State<Gateway> createState() => _GatewayState();
}

class _GatewayState extends State<Gateway> {
  // possible values: UAT_SIM, PRODUCTION
  String environment = 'UAT_SIM';

  // Pass Empty String for testing
  String appId = '';

  // provided by phonePe for testing purpose use PGTESTPAYUAT
  String merchantId = 'PGTESTPAYUAT';

  //Depend on you if you want log pass true else false
  bool enableLogging = true;

  Object? result;

  // Create using sha256 with package crypto
  String? checksum;

  //provided by phonePe for testing use '099eb0cd-02cf-4e2a-8aca-3e6c6aff0399'
  String saltKey = '099eb0cd-02cf-4e2a-8aca-3e6c6aff0399';

  //provided by phonePe for testing use '1'
  String keyIndex = "1";

  String callBackURL =
      "https://webhook.site/04fd67c2-a4e4-4b8e-ab92-f951ab285bda";

  String? body;

  ValueNotifier<bool> statusListener = ValueNotifier<bool>(false);

  getChecksum() {
    final response = {
      "merchantId": merchantId,
      "merchantTransactionId": "transaction_123",
      "merchantUserId": "90223250",
      "amount": 100,
      "mobileNumber": "9999999999",
      "callbackUrl": callBackURL,
      "paymentInstrument": {
        "type": "PAY_PAGE",
      },
    };
    String base64Body = base64Encode(utf8.encode(jsonEncode(response)));
    checksum =
    "${sha256.convert(utf8.encode('$base64Body/pg/v1/pay$saltKey')).toString()}###$keyIndex";
    return base64Body;
  }

  @override
  void initState() {
    initPaymentGateway();
    body = getChecksum().toString();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
          child: Column(
            children: [
              ValueListenableBuilder(
                valueListenable: statusListener,
                builder: (context, value, child) {
                  return value
                      ? Center(child: Text(result!.toString()))
                      : const Center(child: CircularProgressIndicator());
                },
              ),
              CupertinoButton(
                  color: Colors.green,
                  onPressed: () {
                    startPGTransaction();
                  },
                  child: const Text("Start Transaction"))
            ],
          )),
    );
  }

  // initialize gateway
  initPaymentGateway() {
    PhonePePaymentSdk.init(environment, appId, merchantId, enableLogging)
        .then((val) => {
      result = 'PhonePe SDK Initialized - $val',
      statusListener.value = true
    })
        .catchError((error) {
      result = error;
      statusListener.value = true;
      return error;
    });
  }

  Future<Map<dynamic, dynamic>?> startPGTransaction() async {
    try {
      var response = PhonePePaymentSdk.startPGTransaction(
          body.toString(), callBackURL, checksum.toString(), {}, '/pg/v1/pay', '');
      response
          .then((val) => {
        setState(() {
          result = val;
        })
      })
          .catchError((error) {
        result = error;
        statusListener.value = true;
        return <dynamic>{};
      });
    } catch (error) {
      result = error;
      statusListener.value = true;
    }
    return null;
  }
}