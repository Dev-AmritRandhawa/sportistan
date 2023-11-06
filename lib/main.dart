import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportistan/home/home.dart';
import 'package:sportistan/onboarding/onboarding.dart';
import 'package:sportistan/widgets/page_route.dart';
import 'package:sportistan/widgets/permission_check.dart';
import 'authentication/authentication.dart';
import 'firebase_options.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(const MaterialApp(home: MyApp()));
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
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

  final _server = FirebaseFirestore.instance;

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
  Future<void> getLocationPermission() async {
    PermissionStatus permissionStatus;
    try {
      permissionStatus = await Permission.location.request();
      if (permissionStatus == PermissionStatus.granted ||
          permissionStatus == PermissionStatus.limited) {
        if(mounted){
          PageRouter.pushRemoveUntil(context, const Home());
        }
      }
     else if (permissionStatus == PermissionStatus.denied) {
        if(mounted){
        PageRouter.pushRemoveUntil(context, const PermissionCheck(result: false,));
        }
      }   else if (permissionStatus == PermissionStatus.permanentlyDenied) {
        if(mounted){
          PageRouter.pushRemoveUntil(context, const PermissionCheck(result: true,));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(
            (_) => Future.delayed(const Duration(milliseconds: 3500), () async {
          FirebaseAuth.instance.authStateChanges().listen((User? user) async {
            if (user != null) {
                CollectionReference collectionReference = _server
                    .collection("SportistanUsers")
                    .doc(user.uid)
                    .collection("Account");
                QuerySnapshot querySnapshot = await collectionReference.get();
                if (querySnapshot.docs.isEmpty) {
                  _moveToDecision(const PhoneAuthentication());
                } else {
                  getLocationPermission();
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
              SizedBox(
                height: MediaQuery.of(context).size.height / 5,
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
