import 'dart:io';
import 'package:chips_choice/chips_choice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:otp_timer_button/otp_timer_button.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel2/sliding_up_panel2.dart';
import 'package:sportistan/authentication/set_location.dart';
import 'package:sportistan/main.dart';
import 'package:sportistan/nav/nav_home.dart';
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

  String? profileImageLink;

  String? name;
  String? number;

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

  final Uri toLaunch =
      Uri(scheme: 'https', host: 'www.sportistan.co.in', path: '/');

  @override
  void dispose() {
    numberController.dispose();
    otpController.dispose();
    _controller.dispose();
    nameController.dispose();
    super.dispose();
  }

  List<String> grounds = [
    'Cricket',
    'Football',
    'Tennis',
    'Hockey',
    'Badminton',
    'Volleyball',
    'Swimming',
  ];

  List<String> sportTags = [];

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(vsync: this);
    isSomeoneLogged();
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
  ValueNotifier<bool> loader = ValueNotifier<bool>(false);
  ValueNotifier<bool> imageShow = ValueNotifier<bool>(true);
  ValueNotifier<bool> isSomeonePreviouslyLoggedIn = ValueNotifier<bool>(false);
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
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                shrinkWrap: true,
                addAutomaticKeepAlives: true,
                children: <Widget>[
                  const Text(
                    "Choose Your Sports",
                    style: TextStyle(
                      fontFamily: "DMSans",
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                      fontSize: 18.0,
                    ),
                  ),
                  ChipsChoice<String>.multiple(
                    value: sportTags,
                    onChanged: (val) => setState(() => sportTags = val),
                    choiceItems: C2Choice.listFrom<String, String>(
                      source: grounds,
                      value: (i, v) => v,
                      label: (i, v) => v,
                      tooltip: (i, v) => v,
                    ),
                    choiceCheckmark: true,
                    choiceStyle: C2ChipStyle.filled(
                      color: Colors.white,
                      selectedStyle: const C2ChipStyle(
                        borderRadius: BorderRadius.all(
                          Radius.circular(25),
                        ),
                      ),
                    ),
                    wrapped: true,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height / 4,
              child: Lottie.asset(
                "assets/createAccount.json",
                controller: _controller,
                onLoaded: (composition) {
                  _controller
                    ..duration = composition.duration
                    ..repeat();
                },
              ),
            ),
            ValueListenableBuilder(
                valueListenable: loader,
                builder: (context, value, child) => value
                    ? const Center(
                        child: CircularProgressIndicator(
                        strokeWidth: 1,
                        backgroundColor: Colors.white,
                      ))
                    : CupertinoButton(
                        color: Colors.green,
                        onPressed: () {
                          if (nameKey.currentState!.validate()) {
                            if (sportTags.isEmpty) {
                              Errors.flushBarInform(
                                  'Select Your Interest',
                                  context,
                                  "Please Choose Sport Grounds According to Your Interest");
                            } else {
                              createAccount();
                            }
                          }
                        },
                        child: const Text("Create an Account"))),
          ],
        ),
      ),
    );
  }

  Future<void> _checkUserExistence() async {
    _server
        .collection("SportistanUsers")
        .where('userID', isEqualTo: _auth.currentUser!.uid)
        .get()
        .then((value) async => {
              if (value.docChanges.isNotEmpty)
                {
                  if (value.docChanges.first.doc.get('isAccountOnHold'))
                    {
                      PageRouter.pushRemoveUntil(
                          context, const ErrorAccountHold())
                    }
                  else
                    {
                      await saveProfile(
                          name: value.docChanges.first.doc.get('name'),
                          number: value.docChanges.first.doc.get('phoneNumber'),
                          profileLink: value.docChanges.first.doc
                              .get('profileImageLink')),
                    }
                }
              else
                {pc.open()}
            });
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/logo.png',
                height: MediaQuery.of(context).size.height / 8),
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
                    maxLength: 10,
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
                        errorStyle: const TextStyle(color: Colors.red),
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
            valueListenable: loading,
            builder: (context, value, child) {
              return value
                  ? const CircularProgressIndicator(
                      strokeWidth: 1,
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
                        backgroundColor: Colors.orangeAccent,
                        radius: 50,
                        buttonType: ButtonType.elevated_button,
                        controller: controller,
                        onPressed: () {
                          requestOtp();
                        },
                        text: const Text('Resend OTP',
                            style: TextStyle(
                                color: Colors.black, fontFamily: "DMSans")),
                        duration: 30,
                      ),
                    )
                  : Container();
            },
          ),
          ValueListenableBuilder(
              valueListenable: isSomeonePreviouslyLoggedIn,
              builder: (context, value, child) => value
                  ? Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            const Text(
                              'Welcome Back',
                              style: TextStyle(
                                  fontFamily: "DMSans",
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.black45),
                            ),
                            Text(
                              name.toString(),
                              style: const TextStyle(
                                  fontFamily: "DMSans", fontSize: 18),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircleAvatar(
                                backgroundColor: const Color(0XFFfffbf0),
                                foregroundImage:
                                    NetworkImage(profileImageLink.toString()),
                                maxRadius:
                                    MediaQuery.of(context).size.height / 15,
                              ),
                            ),
                            CupertinoButton(
                              color: Colors.indigo,
                              child: Text(
                                'Continue with $number',
                                style: const TextStyle(fontFamily: "DMSans"),
                              ),
                              onPressed: () {
                                numberController.text = number.toString();
                                if (numberKey.currentState!.validate()) {
                                  isSomeonePreviouslyLoggedIn.value = false;
                                  loading.value = true;
                                  buttonDisable.value = true;
                                  _verifyByNumber(
                                      countryCode,
                                      numberController.value.text
                                          .trim()
                                          .toString());
                                }
                              },
                            )
                          ],
                        ),
                      ),
                    )
                  : Container()),
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
          Padding(
            padding: const EdgeInsets.all(10.0),
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
                    fontFamily: "DMSans",
                    fontSize: MediaQuery.of(context).size.width / 30,
                  ),
                  children: [
                    TextSpan(
                      text: 'Terms,',
                      style: TextStyle(
                        fontFamily: "DMSans",
                        color: Colors.blue,
                        fontSize: MediaQuery.of(context).size.width / 30,
                      ),
                    ),
                    TextSpan(
                      text: ' Privacy Policy',
                      style: TextStyle(
                        fontFamily: "DMSans",
                        color: Colors.blue,
                        fontSize: MediaQuery.of(context).size.width / 30,
                      ),
                    ),
                    TextSpan(
                      text: ' and ',
                      style: TextStyle(
                        fontFamily: "DMSans",
                        color: Colors.black,
                        fontSize: MediaQuery.of(context).size.width / 30,
                      ),
                    ),
                    TextSpan(
                      text: 'Cookies Policy',
                      style: TextStyle(
                        fontFamily: "DMSans",
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
    const fillColor = Colors.black;
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
      timeout: const Duration(seconds: 0),
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

  String? token;

  Future<void> createAccount() async {
    loader.value = true;
    SharedPreferences pref = await SharedPreferences.getInstance();
    try {
      await _server.collection("SportistanUsers").add({
        'accountCreatedAt': DateTime.now(),
        'profileRating': 4.0,
        'profileRatingTags': [],
        'token': '',
        'sportInterest': sportTags,
        'phoneNumber': numberController.value.text.trim().toString(),
        'profileImageLink':
            'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png',
        'sportistanCredit': 0,
        'name': nameController.value.text.toString(),
        'isAccountOnHold': false,
        'userID': _auth.currentUser!.uid
      }).then((value) => {
            pref.setString('name', nameController.value.text.toString()),
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Account Created Successfully",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: "DMSans",
                  )),
              backgroundColor: Colors.black87,
            )),
            PageRouter.pushRemoveUntil(context, const NavHome())
          });
    } catch (error) {
      loader.value = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.black87,
        ));
      }
    }
  }

  Future<void> isSomeoneLogged() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    bool? result = preferences.getBool('isSomeoneLoggedInBefore');
    if (result != null) {
      if (result) {
        name = preferences.getString('name');
        number = preferences.getString('number');
        profileImageLink = preferences.getString('profileImageLink');
        isSomeonePreviouslyLoggedIn.value = true;
      }
    }
  }

  Future<void> saveProfile(
      {required String name,
      required String number,
      required String profileLink}) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setBool('isSomeoneLoggedInBefore', true);
    preferences.setString('name', name);
    preferences.setString('number', number);
    preferences.setString('profileImageLink', profileLink);
    setLocationNext();
  }

  void setLocationNext() async {
      PageRouter.pushRemoveUntil(context, const SetLocation());
  }
}
