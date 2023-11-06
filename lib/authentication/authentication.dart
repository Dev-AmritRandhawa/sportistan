import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:otp_timer_button/otp_timer_button.dart';
import 'package:pinput/pinput.dart';
import 'package:sliding_up_panel2/sliding_up_panel2.dart';
import 'package:sportistan/home/home.dart';
import 'package:sportistan/widgets/errors.dart';
import 'package:sportistan/widgets/page_route.dart';
import 'package:url_launcher/url_launcher.dart';

class PhoneAuthentication extends StatefulWidget {
  const PhoneAuthentication({super.key});

  @override
  State<PhoneAuthentication> createState() => _PhoneAuthenticationState();
}

class _PhoneAuthenticationState extends State<PhoneAuthentication>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;

  String countryCode = "+91";
  String? verification;

  final _auth = FirebaseAuth.instance;
  final _server = FirebaseFirestore.instance;
  PanelController pc = PanelController();

  int resendOtpCounter = 0;

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

  final Uri toLaunch = Uri(
      scheme: 'https', host: 'www.sportslovez.in', path: 'Terms&Conditions/');

  @override
  void dispose() {
    numberController.dispose();
    otpController.dispose();
    _controller.dispose();
    nameController.dispose();
    _server.terminate();
    super.dispose();
  }


  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(vsync: this);
    _handleSignOut();
    super.initState();
  }

  TextEditingController numberController = TextEditingController();
  final otpController = TextEditingController();
  final nameController = TextEditingController();
  GlobalKey<FormState> nameKey = GlobalKey<FormState>();
  GlobalKey<FormState> numberKey = GlobalKey<FormState>();
  GlobalKey<FormState> otpKey = GlobalKey<FormState>();
  ValueNotifier<bool> loading = ValueNotifier<bool>(false);
  ValueNotifier<bool> buttonDisable = ValueNotifier<bool>(false);
  ValueNotifier<bool> imageShow = ValueNotifier<bool>(true);
  OtpTimerButtonController controller = OtpTimerButtonController();

  requestOtp() {
    controller.loading();
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        loading.value = true;
        await _verifyByNumber(
            countryCode, numberController.value.text.toString());
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          Errors.flushBarInform(e.code, context, "Error");
        }
      }
      controller.startTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SlidingUpPanel(
            borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20), topLeft: Radius.circular(20)),
            controller: pc,
            onPanelClosed: () {
            },
            panelBuilder: () => _panel(),
            maxHeight: MediaQuery.of(context).size.height / 1.1,
            minHeight: 0,
            isDraggable: false,
            body: _body()));
  }

  Widget _panel() {
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, colors: [
        Color(0XFF41295a),
        Color(0XFF2F0743),
      ])),
      child: Column(
        children: <Widget>[
          const SizedBox(
            height: 12.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 30,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius:
                        const BorderRadius.all(Radius.circular(12.0))),
              ),
            ],
          ),
          const SizedBox(
            height: 18.0,
          ),
          const Center(
            child: Text(
              "No Account Associated",
              style: TextStyle(
                color: Colors.white,
                fontFamily: "DMSans",
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                "Create an Account",
                style: TextStyle(
                  fontFamily: "DMSans",
                  color: Colors.white,
                  fontWeight: FontWeight.normal,
                  fontSize: 24.0,
                ),
              ),
            ],
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width / 1.2,
            child: Form(
              key: nameKey,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  readOnly: loading.value,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Name required.";
                    } else if (value.length <= 2) {
                      return "Enter Correct Name.";
                    } else {
                      return null;
                    }
                  },
                  controller: nameController,
                  decoration: const InputDecoration(
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    errorStyle: TextStyle(color: Colors.white),
                    filled: true,
                    hintText: "Contact Name",
                    hintStyle: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
            ),
          ),
          Lottie.asset(
            "assets/createAccount.json",
            controller: _controller,
            onLoaded: (composition) {
              _controller
                ..duration = composition.duration
                ..repeat();
            },
          ),
          CupertinoButton(
              color: Colors.green,
              onPressed: () {
                if(nameKey.currentState!.validate()){
                createAccount();

                }
              },
              child: const Text("Create an Account")),
        ],
      ),
    );
  }

  Future<void> _checkUserExistence() async {
    CollectionReference collectionReference = _server
        .collection("SportistanUsers")
        .doc()
        .collection("Account");
    QuerySnapshot querySnapshot = await collectionReference.get();
    if (querySnapshot.docs.isEmpty) {
      pc.open();
    } else {
      _moveToHome();
    }
  }

  void _moveToHome() {
    PageRouter.pushRemoveUntil(context, const Home());
  }

  _body() {
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, colors: [
        Color(0XFFC9D6FF),
        Color(0XFFE2E2E2),
      ])),
      child: SafeArea(
        child:
            Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Text("Welcome to Sportistan",
              style: TextStyle(
                fontFamily: "DMSans",
                fontWeight: FontWeight.bold,
                fontSize: MediaQuery.of(context).size.width / 15,
              )),
          const Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(30))),
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Continue with Phone Number"),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: loading,
            builder: (BuildContext context, value, Widget? child) {
              return SizedBox(
                width: MediaQuery.of(context).size.width / 1.2,
                child: Form(
                  key: numberKey,
                  child: TextFormField(
                    onTap: () {
                      imageShow.value = false;
                    },
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
                              loading.value = false;
                              otpController.clear();
                              numberController.clear();
                            },
                            child: const Icon(Icons.edit)),
                        fillColor: Colors.white,
                        border: const OutlineInputBorder(),
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
                        hintStyle: const TextStyle(color: Colors.black),
                        labelStyle: const TextStyle(color: Colors.black)),
                  ),
                ),
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: loading,
            builder: (context, value, child) {
              return value ? pinput() : Container();
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
                              await _verifyByNumber(countryCode,
                                  numberController.value.text.toString());
                            } on FirebaseAuthException catch (e) {
                              if (mounted) {
                                Errors.flushBarInform(e.code, context, "Error");
                              }
                            }
                          }
                        },
                        color: Colors.green,
                        child: const Text(
                          "Continue with Phone Number",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
            },
            valueListenable: loading,
          ),
          ValueListenableBuilder(
            valueListenable: loading,
            builder: (BuildContext context, bool value, Widget? child) {
              return value
                  ? SizedBox(
                      width: MediaQuery.of(context).size.width / 2,
                      child: OtpTimerButton(
                        buttonType: ButtonType.elevated_button,
                        controller: controller,
                        onPressed: () {
                          requestOtp();
                        },
                        text: const Text('Resend OTP',
                            style: TextStyle(
                                color: Colors.white, fontFamily: "DMSans")),
                        duration: 30,
                      ),
                    )
                  : Container();
            },
          ),
          ValueListenableBuilder(
            valueListenable: buttonDisable,
            builder: (context, value, child) {
              return value
                  ? const CircularProgressIndicator(
                      color: Colors.black54,
                      strokeWidth: 2,
                    )
                  : Container();
            },
          ),
          Flexible(
            child: Lottie.asset(
              "assets/phone_verification.json",
              controller: _controller,
              onLoaded: (composition) {
                _controller
                  ..duration = composition.duration
                  ..repeat();
              },
            ),
          ),
          CupertinoButton(
              color: Colors.indigo,
              onPressed: () {
                _handleSignIn();
              },
              child: const Text("Continue with Google Account")),
          Padding(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.width / 8,
                left: MediaQuery.of(context).size.width / 30,
                right: MediaQuery.of(context).size.width / 30),
            child: GestureDetector(
              onTap: () async {
                Platform.isIOS
                    ? _launchUniversalLinkIos(toLaunch)
                    : _launchInBrowser(toLaunch);
              },
              child: RichText(
                text: TextSpan(
                  text: 'By pressing continue, you agree to our ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: MediaQuery.of(context).size.width / 30,
                  ),
                  children: [
                    TextSpan(
                      text: 'Terms,',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: MediaQuery.of(context).size.width / 30,
                      ),
                    ),
                    TextSpan(
                      text: ' Privacy Policy',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: MediaQuery.of(context).size.width / 30,
                      ),
                    ),
                    TextSpan(
                      text: ' and ',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: MediaQuery.of(context).size.width / 30,
                      ),
                    ),
                    TextSpan(
                      text: 'Cookies Policy',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: MediaQuery.of(context).size.width / 30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget pinput() {
    const focusedBorderColor = Colors.black;
    const fillColor = Colors.black54;
    const borderColor = Colors.black54;

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
    return Padding(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width / 25),
      child: Pinput(
        controller: otpController,
        androidSmsAutofillMethod: AndroidSmsAutofillMethod.smsUserConsentApi,
        listenForMultipleSmsOnAndroid: true,
        defaultPinTheme: defaultPinTheme,
        length: 6,
        separatorBuilder: (index) => const SizedBox(width: 8),
        hapticFeedbackType: HapticFeedbackType.lightImpact,
        onCompleted: (pin) {
          _manualVerify(pin);
        },
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
    );
  }

  Future<void> _verifyByNumber(String countryCode, String number) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: countryCode + number,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          buttonDisable.value = true;
          await _auth
              .signInWithCredential(credential)
              .then((value) => {_checkUserExistence()});
        } on FirebaseAuthException catch (e) {
          buttonDisable.value = false;
          if (mounted) {
            Errors.flushBarInform(e.message.toString(), context, "Error");
          }
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          buttonDisable.value = false;
          if (mounted) {
            Errors.flushBarInform(
                "The provided phone number is not valid.", context, "Error");
          }
        } else {
          buttonDisable.value = false;

          if (mounted) {
            Errors.flushBarInform(e.message.toString(), context, "Error");
          }
        }
      },
      codeSent: (String verificationId, int? resendToken) async {
        verification = verificationId;
      },
      timeout: const Duration(seconds: 60),
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<void> _manualVerify(String smsCode) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verification.toString(), smsCode: smsCode);
    try {
      buttonDisable.value = true;
      await _auth
          .signInWithCredential(credential)
          .then((value) => {_checkUserExistence()});
    } on FirebaseAuthException catch (e) {
      buttonDisable.value = false;
      if (mounted) {
        Errors.flushBarInform(e.message.toString(), context, "Error");
      }
    }
  }

  GoogleSignInAccount? currentUser;

  GoogleSignIn googleSignIn = GoogleSignIn(
    clientId: '100473162886811688440',
  );
  late String urls;

  Future<void> _handleSignIn() async {
    try {
      currentUser = await googleSignIn.signIn();
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      // Obtain the auth details from the request.
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
      // Create a new credential.
      final OAuthCredential googleCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(googleCredential);
      await _checkUserExistence();
    } catch (error) {
      _handleSignOut();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _handleSignOut() async {
    if (currentUser != null) {
      googleSignIn.disconnect();
    }
  }

  Future<void> createAccount() async {

    try{
      await _server
          .collection("SportistanUsers")
          .doc(_auth.currentUser!.uid)
          .collection("Account")
          .doc()
          .set({
        'accountCreatedAt': DateTime.now(),
        'deviceID': [],
        'rating': 3.0,
        'ratingTags': [],
        'isAccountOnHold': false
      }).then((value) => {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Account Created",style: TextStyle(color: Colors.green,fontFamily: "DMSans",)),
      backgroundColor: Colors.black87,
      )),
        _moveToHome()});
    }catch(error){
      if(mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.toString()),
        backgroundColor: Colors.black87,
      ));
    }
    }

  }
}
