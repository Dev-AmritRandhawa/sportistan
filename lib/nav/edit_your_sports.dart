import 'package:chips_choice/chips_choice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:SportistanPro/widgets/errors.dart';

class EditYourSports extends StatefulWidget {
  final List<String> prefs;
  const EditYourSports({super.key, required this.prefs});

  @override
  State<EditYourSports> createState() => _EditYourSportsState();
}

class _EditYourSportsState extends State<EditYourSports>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
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

  ValueNotifier<bool> loader = ValueNotifier<bool>(false);

  final _server = FirebaseFirestore.instance;

  String? refId;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    sportTags = widget.prefs;
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Your Sports"),backgroundColor: Colors.white,elevation: 0,foregroundColor: Colors.black),
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
               const Padding(
                 padding: EdgeInsets.all(8.0),
                 child: Text("Your Sport Interest",style: TextStyle(color: Colors.green)),
               ),
               Text(sportTags.length.toString()),
                  ListView(
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
                        choiceStyle: C2ChipStyle.toned(
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
                ],
              ),
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
                        if (sportTags.isEmpty) {
                          Errors.flushBarInform('Select Your Interest', context,
                              "Please Choose Sport Grounds According to Your Interest");
                        } else {
                          createAccount();
                        }
                      },
                      child: const Text("Update Your Interest"))),
        ]),
      ),
    );
  }

  Future<void> createAccount() async {
    loader.value = true;
    try {
      await _server.collection("SportistanUsers").where('userID',isEqualTo: FirebaseAuth.instance.currentUser!.uid).get().then((value) => {
        refId = value.docChanges.first.doc.id
      });
      await _server.collection("SportistanUsers").doc(refId).update({
        'sportInterest': sportTags,
      }).then((value) => {Navigator.pop(context,true)});
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
}
