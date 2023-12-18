import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pinput/pinput.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sliding_up_panel2/sliding_up_panel2.dart';
import 'package:sportistan/authentication/authentication.dart';
import 'package:sportistan/nav/crop.dart';
import 'package:sportistan/payment/sportistan_credit.dart';
import 'package:sportistan/widgets/errors.dart';
import 'package:sportistan/widgets/page_route.dart';
import 'package:url_launcher/url_launcher.dart';

class NavProfile extends StatefulWidget {
  const NavProfile({super.key});

  @override
  State<NavProfile> createState() => _NavProfileState();
}

class _NavProfileState extends State<NavProfile> {
  var notificationListenable = ValueNotifier(true);
  var imageListener = ValueNotifier(true);
  String countryCode = "+91";

  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _launchUniversalLinkIos(Uri url) async {
    final bool nativeAppLaunchSucceeded = await launchUrl(
      url,
      mode: LaunchMode.externalNonBrowserApplication,
    );
    if (!nativeAppLaunchSucceeded) {
      await launchUrl(
        url,
        mode: LaunchMode.inAppWebView,
      );
    }
  }
  final otpController = TextEditingController();
  final numberController = TextEditingController();
  final finalOTPController = TextEditingController();
  GlobalKey<FormState> numberKey = GlobalKey<FormState>();
  ValueNotifier<bool> loading = ValueNotifier<bool>(false);
  PanelController pc = PanelController();
  final Uri toLaunch = Uri(
      scheme: 'https', host: 'www.sportistan.co.in', path: '/');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SlidingUpPanel(controller: pc,maxHeight: MediaQuery.of(context).size.height/2,
        panelBuilder: () => panel(),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MaterialButton(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                      color: Colors.red,
                      onPressed: () {
                        FirebaseAuth.instance.signOut().then((value) => {
                              PageRouter.pushRemoveUntil(
                                  context, const PhoneAuthentication())
                            });
                      },
                      child: const Text("Logout",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontFamily: "DMSans")),
                    ),
                  ],
                ),
              ),
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('SportistanUsers')
                    .where('userID',
                        isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  return snapshot.hasData
                      ? ListView.builder(
                          itemCount: snapshot.data!.docChanges.length,
                          physics: const BouncingScrollPhysics(),
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            final doc = snapshot.data!.docs;
                            Timestamp time = doc[index]['accountCreatedAt'];
                            String date =
                                DateFormat.yMMMM().format(time.toDate());
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(doc[index].get('name'),
                                      style: const TextStyle(
                                          fontFamily: 'DMSans',
                                          color: Colors.black,
                                          fontSize: 26),
                                      softWrap: true),
                                ),
                                ValueListenableBuilder(
                                  valueListenable: imageListener,
                                  builder: (context, value, child) {
                                    return value
                                        ? Stack(
                                            alignment: Alignment.bottomRight,
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  if (Platform.isAndroid) {
                                                    Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  CropImageTool(
                                                                      ref: doc[
                                                                              index]
                                                                          .id),
                                                            ))
                                                        .then((value) => {
                                                              imageListener
                                                                  .value = true
                                                            });
                                                  }
                                                  if (Platform.isIOS) {
                                                    Navigator.push(
                                                            context,
                                                            CupertinoPageRoute(
                                                              builder: (context) =>
                                                                  CropImageTool(
                                                                      ref: doc[
                                                                              index]
                                                                          .id),
                                                            ))
                                                        .then((value) => {
                                                              imageListener
                                                                  .value = true
                                                            });
                                                  }
                                                },
                                                child: CircleAvatar(
                                                  backgroundColor:
                                                      const Color(0XFFfffbf0),
                                                  foregroundImage: NetworkImage(
                                                      doc[index].get(
                                                          'profileImageLink')),
                                                  maxRadius:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .height /
                                                          12,
                                                ),
                                              ),
                                              const CircleAvatar(
                                                child: Icon(
                                                  Icons.camera_alt_rounded,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Stack(
                                            alignment: Alignment.bottomRight,
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  if (Platform.isAndroid) {
                                                    Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  CropImageTool(
                                                                      ref: doc[
                                                                              index]
                                                                          .id),
                                                            ))
                                                        .then((value) => {
                                                              imageListener
                                                                  .value = true
                                                            });
                                                  }
                                                  if (Platform.isIOS) {
                                                    Navigator.push(
                                                            context,
                                                            CupertinoPageRoute(
                                                              builder: (context) =>
                                                                  CropImageTool(
                                                                      ref: doc[
                                                                              index]
                                                                          .id),
                                                            ))
                                                        .then((value) => {
                                                              imageListener
                                                                  .value = true
                                                            });
                                                  }
                                                },
                                                child: CircleAvatar(
                                                  backgroundColor:
                                                      Colors.orange.shade200,
                                                  maxRadius: 50,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(8.0),
                                                    child: Image.asset(
                                                        'assets/logo.png'),
                                                  ),
                                                ),
                                              ),
                                              const Icon(
                                                Icons.camera_alt_rounded,
                                              )
                                            ],
                                          );
                                  },
                                ),
                                const Text('Joined Since',
                                    style: TextStyle(
                                        fontFamily: 'DMSans',
                                        color: Colors.black54,
                                        fontSize: 16),
                                    softWrap: true),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(date,
                                      style: const TextStyle(
                                          fontFamily: 'DMSans',
                                          color: Colors.black,
                                          fontSize: 18),
                                      softWrap: true),
                                ),
                                Text('Rs.${doc[index].get('sportistanCredit')}',
                                    style: const TextStyle(
                                        fontFamily: "DMSans",
                                        fontSize: 28,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold)),
                                CupertinoButton(
                                    borderRadius: BorderRadius.zero,
                                    color: Colors.indigo,
                                    onPressed: () {
                                      PageRouter.push(
                                          context, const SportistanCredit());
                                    },
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(right: 8.0),
                                          child: Icon(
                                            Icons.account_balance_wallet,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text('View My Wallet',
                                            style:
                                                TextStyle(fontFamily: "DMSans")),
                                      ],
                                    )),
                                SizedBox(
                                  height: MediaQuery.of(context).size.height / 25,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Turn Off Notifications',
                                          style: TextStyle(
                                              fontFamily: "DMSans",
                                              color: Colors.black54,
                                              fontSize: 20)),
                                      ValueListenableBuilder(
                                        valueListenable: notificationListenable,
                                        builder: (context, value, child) {
                                          return CupertinoSwitch(
                                            value: value,
                                            onChanged: (v) {
                                              notificationListenable.value = v;
                                            },
                                          );
                                        },
                                      )
                                    ],
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Language',
                                          style: TextStyle(
                                              fontFamily: "DMSans",
                                              color: Colors.black54,
                                              fontSize: 20)),
                                      Text('English',
                                          style: TextStyle(
                                              fontFamily: "DMSans",
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black54,
                                              fontSize: 20)),
                                    ],
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Country',
                                          style: TextStyle(
                                              fontFamily: "DMSans",
                                              color: Colors.black54,
                                              fontSize: 20)),
                                      Text('India',
                                          style: TextStyle(
                                              fontFamily: "DMSans",
                                              color: Colors.black54,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20)),
                                    ],
                                  ),
                                ),
                                CupertinoButton(
                                    borderRadius: BorderRadius.zero,
                                    color: Colors.white,
                                    onPressed: () {
                                      pc.open();
                                    },
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Icon(
                                          Icons.settings,
                                          color: Colors.black,
                                        ),
                                        Text('Change Number',
                                            style: TextStyle(
                                              fontFamily: "DMSans",
                                              color: Colors.black,
                                            )),
                                      ],
                                    )),
                                CupertinoButton(
                                    borderRadius: BorderRadius.zero,
                                    color: Colors.white,
                                    onPressed: () {
                                      Platform.isIOS
                                          ? _launchUniversalLinkIos(toLaunch)
                                          : _launchInBrowser(toLaunch);
                                    },
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Icon(
                                          Icons.lock,
                                          color: Colors.black,
                                        ),
                                        Text('Privacy Policy',
                                            style: TextStyle(
                                                fontFamily: "DMSans",
                                                color: Colors.black)),
                                      ],
                                    )),
                                CupertinoButton(
                                    borderRadius: BorderRadius.zero,
                                    color: Colors.white,
                                    onPressed: () {
                                      shareApp();
                                    },
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Icon(
                                          Icons.send,
                                          color: Colors.green,
                                        ),
                                        Text('Share App',
                                            style: TextStyle(
                                                fontFamily: "DMSans",
                                                color: Colors.green)),
                                      ],
                                    )),
                              ],
                            );
                          },
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(child: CircularProgressIndicator()),
                          ],
                        );
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> shareApp() async {
    const String androidAppLink =
        'https://play.google.com/store/apps/details?id=co.in.sportistan.sportistan_partners';
    const String appleAppLink =
        'https://apps.apple.com/in/app/whatsapp-messenger/id310633997';
    if (Platform.isAndroid) {
      const String message =
          'Now You can also list your Facilities & get bookings and start earning: $androidAppLink';
      await Share.share(androidAppLink, subject: message);
    }
    if (Platform.isIOS) {
      const String message =
          'Now You can also list your Facilities & get bookings and start earning:: $appleAppLink';
      await Share.share(appleAppLink, subject: message);
    }
  }

  panel() {
    const focusedBorderColor = Colors.black;
    const fillColor = Colors.black87;
    const borderColor = Colors.black;

    final defaultPinTheme = PinTheme(
      width: MediaQuery.of(context).size.width / 10,
      height: MediaQuery.of(context).size.width / 10,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Colors.white,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: borderColor),
      ),
    );
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
                onPressed: () {
                  pc.close();
                },
                icon: const CircleAvatar(child: Icon(Icons.close)))
          ],
        ),
        const Text("Change Number Request",
            style: TextStyle(fontSize: 15, fontFamily: "DMSans")),
        ValueListenableBuilder(
          valueListenable: loading,
          builder: (BuildContext context, value, Widget? child) {
            return SizedBox(
              width: MediaQuery.of(context).size.width / 1.2,
              child: Form(
                key: numberKey,
                child: TextFormField(
                  readOnly: loading.value,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Number required.";
                    } else if (value.length <= 9) {
                      return "Enter 10 digits.";
                    } else {
                      return null;
                    }
                  },
                  controller: numberController,
                  onChanged: (data) {
                    numberKey.currentState!.validate();
                  },
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  autofillHints: const [AutofillHints.telephoneNumberLocal],
                  decoration: InputDecoration(
                    suffixIcon: InkWell(
                        onTap: () {
                          otpController.clear();
                          loading.value = false;
                        },
                        child: const Icon(Icons.edit)),
                    fillColor: Colors.white,
                    border: InputBorder.none,
                    errorStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    prefixIcon: CountryCodePicker(
                      showCountryOnly: true,
                      onChanged: (value) {
                        countryCode = value.dialCode.toString();
                      },
                      favorite: const ["IN"],
                      initialSelection: "IN",
                    ),
                    hintText: "Phone Number",
                    hintStyle: const TextStyle(color: Colors.black45),
                  ),
                ),
              ),
            );
          },
        ),
        ValueListenableBuilder(
          valueListenable: loading,
          builder: (context, value, child) {
            return value
                ? Padding(
              padding:
              EdgeInsets.all(MediaQuery.of(context).size.width / 25),
              child: Pinput(
                pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                controller: otpController,
                androidSmsAutofillMethod:
                AndroidSmsAutofillMethod.smsUserConsentApi,
                listenForMultipleSmsOnAndroid: true,
                defaultPinTheme: defaultPinTheme,
                length: 6,
                separatorBuilder: (index) => const SizedBox(width: 8),
                hapticFeedbackType: HapticFeedbackType.lightImpact,
                cursor: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 9),
                      width: 22,
                      height: 1,
                      color: focusedBorderColor,
                    ),
                  ],
                ),
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: focusedBorderColor),
                  ),
                ),
                submittedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(color: focusedBorderColor),
                  ),
                ),
                errorPinTheme: defaultPinTheme.copyBorderWith(
                  border: Border.all(color: Colors.redAccent),
                ),
              ),
            )
                : Container();
          },
        ),
        ValueListenableBuilder(
          builder: (BuildContext context, value, Widget? child) {
            return value
                ? Container()
                : Padding(
              padding: const EdgeInsets.all(8.0),
              child: CupertinoButton(
                onPressed: () async {
                  if (numberKey.currentState!.validate()) {
                    try {
                      loading.value = true;
                      _verifyByNumber(
                          countryCode, numberController.value.text);
                    } on FirebaseAuthException catch (e) {
                      if (mounted) {
                        Errors.flushBarInform(
                            e.message.toString(), context, "Sorry");
                      }
                    }
                  }
                },
                color: Colors.green,
                child: const Text(
                  "Change Number",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          },
          valueListenable: loading,
        ),
        ValueListenableBuilder(
          valueListenable: loading,
          builder: (context, value, child) {
            return value
                ? CupertinoButton(
              color: Colors.green.shade700,
              onPressed: () {
                _manualVerify(otpController.value.text);
              },
              child: const Text("Submit OTP"),
            )
                : Container();
          },
        ),
        ValueListenableBuilder(
          valueListenable: loading,
          builder: (context, value, child) {
            return value
                ? const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            )
                : Container();
          },
        ),
      ]),
    );
  }

  Future<void> _verifyNumberForDelete({required String number}) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: number,
      verificationCompleted: (PhoneAuthCredential credential) async {},
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          buttonDisable.value = false;

          _showError("'The provided phone number is not valid.'");
        } else {
          buttonDisable.value = false;

          _showError(e.message.toString());
        }
      },
      codeSent: (String verificationId, int? resendToken) async {
        finalVerification = verificationId;
      },
      timeout: const Duration(seconds: 0),
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<void> _manualVerifyNumberForDelete(String smsCode) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: finalVerification.toString(), smsCode: smsCode);
    try {
      buttonDisable.value = true;
      await _auth
          .signInWithCredential(credential)
          .then((value) => {deleteKYC()});
    } on FirebaseAuthException catch (e) {
      buttonDisable.value = false;

      _showError(e.message.toString());
    }
  }

  Future<void> _manualVerify(String smsCode) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verification.toString(), smsCode: smsCode);
    try {
      loading.value = true;
      await _auth.currentUser!.updatePhoneNumber(credential).then((value) => {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Phone Number Updated Successfully")))
      });
    } on FirebaseAuthException catch (e) {
      loading.value = false;
      if (mounted) {
        Errors.flushBarInform(e.message.toString(), context, "Sorry");
      }
    }
  }

  Future<void> _verifyByNumber(String countryCode, String number) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: countryCode + number,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          loading.value = true;
          await _auth.signInWithCredential(credential).then((value) => {});
        } on FirebaseAuthException catch (e) {
          loading.value = false;
          if (mounted) {
            Errors.flushBarInform(e.message.toString(), context, "Error");
          }
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          loading.value = false;
          Errors.flushBarInform(
              'The provided phone number is not valid.', context, "Error");
        } else {
          loading.value = false;
          Errors.flushBarInform(e.message.toString(), context, "Error");
        }
      },
      codeSent: (String verificationId, int? resendToken) async {
        verification = verificationId;
      },
      timeout: const Duration(seconds: 0),
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  _callNumber() async {
    const number = '+918591719905'; //set the number here
    FlutterPhoneDirectCaller.callNumber(number);
  }



}
