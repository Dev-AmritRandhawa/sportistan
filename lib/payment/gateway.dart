import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';

class Gateway extends StatefulWidget {
  final String amount;
  final String groundID;

  const Gateway({super.key, required this.amount, required this.groundID});

  @override
  State<Gateway> createState() => _GatewayState();
}

class _GatewayState extends State<Gateway> with SingleTickerProviderStateMixin {
  String body = '';
  String callback = "https://webhook.site/36ddddba-692c-4dbc-ada8-cb992620d2d5";
  String checksum = '';
  Map<String, String> headers = {};
  bool enableLogs = true;
  Object? result;
  String environmentValue = 'PRODUCTION';
  String appId = "b607c458044c489a9f51329e52aed81d";
  String merchantId = "M1DWMSERHVFP";

  String? transactionID;

  String saltKey = '9dc92909-f9a1-4785-b505-4fc64276fdae';

  //provided by phonePe for testing use '1'
  String keyIndex = "1";
  String packageName = "net.one97.paytm";

  void initPhonePeSdk() {
    PhonePePaymentSdk.init(environmentValue, appId, merchantId, enableLogs)
        .then((isInitialized) => {
              setState(() {
                result = 'PhonePe SDK Initialized - $isInitialized';
              })
            })
        .catchError((error) {
      handleError(error);
      return <dynamic>{};
    });
  }

  void isPhonePeInstalled() {
    PhonePePaymentSdk.isPhonePeInstalled()
        .then((isPhonePeInstalled) => {
              setState(() {
                result = 'PhonePe Installed - $isPhonePeInstalled';
              })
            })
        .catchError((error) {
      handleError(error);
      return <dynamic>{};
    });
  }

  void isGpayInstalled() {
    PhonePePaymentSdk.isGPayAppInstalled()
        .then((isGpayInstalled) => {
              setState(() {
                result = 'GPay Installed - $isGpayInstalled';
              })
            })
        .catchError((error) {
      handleError(error);
      return <dynamic>{};
    });
  }

  void isPaytmInstalled() {
    PhonePePaymentSdk.isPaytmAppInstalled()
        .then((isPaytmInstalled) => {
              setState(() {
                result = 'Paytm Installed - $isPaytmInstalled';
              })
            })
        .catchError((error) {
      handleError(error);
      return <dynamic>{};
    });
  }

  void getPackageSignatureForAndroid() {
    if (Platform.isAndroid) {
      PhonePePaymentSdk.getPackageSignatureForAndroid()
          .then((packageSignature) => {
                setState(() {
                  result = 'getPackageSignatureForAndroid - $packageSignature';
                })
              })
          .catchError((error) {
        handleError(error);
        return <dynamic>{};
      });
    }
  }

  void getInstalledUpiAppsForiOS() {
    if (Platform.isIOS) {
      PhonePePaymentSdk.getInstalledUpiAppsForiOS()
          .then((apps) => {
                setState(() {
                  result = 'getUPIAppsInstalledForIOS - $apps';

                  // For Usage
                  List<String> stringList = apps
                          ?.whereType<
                              String>() // Filters out null and non-String elements
                          .toList() ??
                      [];

                  // Check if the string value 'Orange' exists in the filtered list
                  String searchString = 'PHONEPE';
                  bool isStringExist = stringList.contains(searchString);

                  if (isStringExist) {
                    print('$searchString app exist in the device.');
                  } else {
                    print('$searchString app does not exist in the list.');
                  }
                })
              })
          .catchError((error) {
        handleError(error);
        return <dynamic>{};
      });
    }
  }

  void getInstalledApps() {
    if (Platform.isAndroid) {
      getInstalledUpiAppsForAndroid();
    } else {
      getInstalledUpiAppsForiOS();
    }
  }

  void getInstalledUpiAppsForAndroid() {
    PhonePePaymentSdk.getInstalledUpiAppsForAndroid()
        .then((apps) => {
              setState(() {
                if (apps != null) {
                  Iterable l = json.decode(apps);
                  List<UPIApp> upiApps = List<UPIApp>.from(
                      l.map((model) => UPIApp.fromJson(model)));
                  String appString = '';
                  for (var element in upiApps) {
                    appString +=
                        "${element.applicationName} ${element.version} ${element.packageName}";
                  }
                  result = 'Installed Upi Apps - $appString';
                } else {
                  result = 'Installed Upi Apps - 0';
                }
              })
            })
        .catchError((error) {
      handleError(error);
      return <dynamic>{};
    });
  }

  getChecksumForOtherOptions() {
    transactionID = DateTime.now().millisecondsSinceEpoch.toString();
    int result = int.parse(widget.amount) * 100;
    String amount = result.toString();
    final response = {
      "merchantId": merchantId,
      "merchantTransactionId": transactionID,
      "merchantUserId": widget.groundID,
      "amount": amount,
      "callbackUrl": callback,
      "mobileNumber": FirebaseAuth.instance.currentUser!.phoneNumber,
      "deviceContext": {"deviceOS": "ANDROID"},
      "paymentInstrument": {
        "type": "UPI_INTENT",
        "targetApp": "net.one97.paytm"
      }
    };
    String base64Body = base64Encode(utf8.encode(jsonEncode(response)));
    checksum =
        "${sha256.convert(utf8.encode('$base64Body/pg/v1/pay$saltKey')).toString()}###$keyIndex";
    return base64Body;
  }

  void startTransaction() async {
    body = getChecksumForOtherOptions();
    try {
      PhonePePaymentSdk.startTransaction(body, callback, checksum, packageName)
          .then((response) => {
                setState(() {
                  if (response != null) {
                    String status = response['status'].toString();
                    String error = response['error'].toString();
                    if (status == 'SUCCESS') {
                      result = "Flow Completed - Status: Success!";
                    } else {
                      result =
                          "Flow Completed - Status: $status and Error: $error";
                    }
                  } else {
                    result = "Flow Incomplete";
                  }
                })
              })
          .catchError((error) {
        handleError(error);
        return <dynamic>{};
      });
    } catch (error) {
      handleError(error);
    }
  }

  void handleError(error) {
    setState(() {
      if (error is Exception) {
        result = error.toString();
      } else {
        result = {"error": error};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            body: Column(mainAxisAlignment: MainAxisAlignment.center,children: <Widget>[
              Center(
                child: ElevatedButton(
                    onPressed: startTransaction,
                    child: const Text('Start Transaction')),
              ),
            ])));
  }
}

class UPIApp {
  final String? packageName;
  final String? applicationName;
  final String? version;

  UPIApp(this.packageName, this.applicationName, this.version);

  factory UPIApp.fromJson(Map<String, dynamic> parsedJson) {
    return UPIApp(parsedJson['packageName'], parsedJson['applicationName'],
        parsedJson['version'].toString());
  }
}
