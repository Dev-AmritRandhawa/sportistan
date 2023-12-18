import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportistan/widgets/errors.dart';
import 'package:sportistan/widgets/local_notifications.dart';
import 'package:sportistan/widgets/page_route.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'authentication/authentication.dart';
import 'firebase_options.dart';
import 'nav/nav_home.dart';
import 'onboarding/onboarding.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

final messaging = FirebaseMessaging.instance;

Future<void> requestPermission() async {
  final settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    registerFCM();
  }
}

Future<void> registerFCM() async {
  Notifications.init();
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttest);
  initializeDateFormatting('en', '').then((value) => null);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    requestPermission();

    runApp(const MaterialApp(home: MyApp()));
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: false),
      themeMode: ThemeMode.light,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final _auth = FirebaseAuth.instance;

  final _server = FirebaseFirestore.instance;

  bool isAccountOnHold = false;

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

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(
            (_) => Future.delayed(const Duration(milliseconds: 3000), () async {
          _auth.authStateChanges().listen((User? user) async {
            if (user != null) {
              try {
                _server
                    .collection("SportistanUsers")
                    .where('userID', isEqualTo: _auth.currentUser!.uid)
                    .get()
                    .then((value) => {
                  if (value.docChanges.isEmpty)
                    {
                      if (mounted)
                        {
                          PageRouter.pushRemoveUntil(
                              context, const PhoneAuthentication())
                        }
                    }
                  else
                    {
                      if (mounted)
                        {
                          PageRouter.pushRemoveUntil(
                              context,
                              BeforeHome(
                                value: value,
                              ))
                        }
                    }
                });
              } on SocketException catch (e) {
                if (mounted) {
                  Errors.flushBarInform(
                      e.message, context, "Connectivity Error");
                }
                _userStateSave();
              } catch (e) {
                _userStateSave();
              }
            } else {
              _userStateSave();
            }
          });
        }));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(),
              SizedBox(
                height: MediaQuery.of(context).size.height / 4,
                width: MediaQuery.of(context).size.width / 2,
                child: Lottie.asset(
                  'assets/loading.json',
                  controller: _controller,
                  onLoaded: (composition) {
                    _controller
                      ..duration = composition.duration
                      ..repeat();
                  },
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  _moveToDecision(Widget widget) async {
    if (mounted) {
      PageRouter.pushRemoveUntil(context, widget);
    }
  }

  Future<void> _userStateSave() async {
    final value = await SharedPreferences.getInstance();
    final bool? result = value.getBool('onBoarding');
    if (result != null) {
      if (result) {
        _moveToDecision(const PhoneAuthentication());
      } else {
        _moveToDecision(const OnBoard());
      }
    } else {
      _moveToDecision(const OnBoard());
    }
  }
}

class BeforeHome extends StatefulWidget {
  const BeforeHome({super.key, required this.value});

  final QuerySnapshot<Map<String, dynamic>> value;

  @override
  State<BeforeHome> createState() => _BeforeHomeState();
}

class _BeforeHomeState extends State<BeforeHome> {
  bool accountOnHold = false;
  ValueNotifier<bool> accountOnHoldListener = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(
            (_) => Future.delayed(const Duration(milliseconds: 3500), () async {
          if (mounted) {
            checkHealth();
          }
        }));
    return Scaffold(
        body: ValueListenableBuilder(
          valueListenable: accountOnHoldListener,
          builder: (context, value, child) => value
              ? Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Your Account is On Hold",
                    style: TextStyle(
                      fontFamily: "DMSans",
                      fontSize: 22,
                    ),
                    softWrap: true),
              ),
              Icon(Icons.warning,
                  color: Colors.red,
                  size: MediaQuery.of(context).size.height / 5),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                    "Your Account is On Hold Due to Some Reasons Please Contact Customer Support if You Think This is a Mistake Write an Email Support@Sportistan.co.in or Call +918591719905",
                    style: TextStyle(fontFamily: "DMSans", fontSize: 16),
                    softWrap: true),
              ),
            ],
          )
              : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 1,
                    color: Colors.green,
                  )
                ],
              )),
        ));
  }

  void checkHealth() {
    for (int i = 0; i < widget.value.docChanges.length; i++) {
      if (widget.value.docChanges[i].doc.get('isAccountOnHold')) {
        accountOnHold = true;
        accountOnHoldListener.value = true;
        break;
      } else {
        continue;
      }
    }
    if (!accountOnHold) {
      PageRouter.pushRemoveUntil(context, const NavHome());
    }
  }
}
