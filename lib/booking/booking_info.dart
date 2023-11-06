import 'dart:io';
import 'package:chips_choice/chips_choice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:sliding_up_panel2/sliding_up_panel2.dart';

class BookingInfo extends StatefulWidget {
  final String bookingID;

  const BookingInfo({super.key, required this.bookingID});

  @override
  State<BookingInfo> createState() => _BookingInfoState();
}

class _BookingInfoState extends State<BookingInfo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  PanelController pc = PanelController();
  String? bookingType;

  List<String> ratingTags = [];

  List<String> ratingOptions = [
    'Punctual',
    'Cleanliness',
    'Payment',
    'Bad Behaviour',
    'No Sportsman Spirit',
    'Last Moment Cancelled',
  ];

  ValueNotifier<bool> ratingListenable = ValueNotifier<bool>(false);

  double? updateRating;

  String? refDetails;

  String? userID;

  @override
  void dispose() {
    _server.terminate();
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _server.enableNetwork();
    _controller = AnimationController(vsync: this);
    super.initState();
  }

  final _server = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  int counter = 0;
  late Uint8List? imageFile;

  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SlidingUpPanel(
      borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25), topRight: Radius.circular(25)),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(children: [
            StreamBuilder(
              stream: _server
                  .collection("GroundBookings")
                  .where("bookingID", isEqualTo: widget.bookingID)
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data!.docs.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      DocumentSnapshot doc = snapshot.data!.docs[index];
                      bookingType = doc['bookingPerson'];
                      refDetails = doc.id;
                      userID = doc['userID'];

                      if (!doc["ratingGiven"]) {
                        pc.open();
                      }
                      Timestamp time = doc['bookedAt'];

                      Timestamp day = doc['bookingCreated'];
                      DateTime booked = time.toDate();
                      bool isTeamBAvailable = doc["bothTeamBooked"];
                      return Screenshot(
                        controller: screenshotController,
                        child: Column(children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Text(
                                    "Booking ID",
                                    style: TextStyle(
                                        fontFamily: "DMSans",
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                                50),
                                  ),
                                  Text(
                                    doc["bookingID"],
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: "DMSans",
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                                50),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              left: MediaQuery.of(context).size.width / 20,
                              right: MediaQuery.of(context).size.width / 20,
                              top: MediaQuery.of(context).size.width / 20,
                            ),
                            child: Image.asset(
                              "assets/logo.png",
                              width: MediaQuery.of(context).size.width / 15,
                              height: MediaQuery.of(context).size.width / 15,
                            ),
                          ),
                          doc["ratingGiven"]
                              ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      const Text("Rating",
                                          style: TextStyle(
                                            fontFamily: "DMSans",
                                          )),
                                      RatingBar.builder(
                                        itemSize:
                                            MediaQuery.of(context).size.height /
                                                40,
                                        // initialRating: 3.0, pending chane
                                        initialRating: 3.0,
                                        direction: Axis.horizontal,
                                        itemCount: 5,
                                        ignoreGestures: true,
                                        itemPadding: const EdgeInsets.symmetric(
                                            horizontal: 4.0),
                                        itemBuilder: (context, _) => const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                        ),
                                        onRatingUpdate: (rating) {},
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          pc.open();
                                        },
                                        child: const Text("Edit",
                                            style: TextStyle(
                                              fontFamily: "DMSans",
                                            )),
                                      )
                                    ],
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: CupertinoButton(
                                      onPressed: () {
                                        pc.open();
                                      },
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: Colors.orange,
                                          ),
                                          Text(
                                            "Rate Booking",
                                            style: TextStyle(
                                                color: Colors.black54),
                                          ),
                                        ],
                                      )),
                                ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Booking Generate : "),
                              Text(
                                  "${DateFormat.yMMMMEEEEd().format(booked)} - ${DateFormat.jms().format(booked)}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Card(
                            child: Padding(
                              padding: EdgeInsets.all(
                                MediaQuery.of(context).size.width / 20,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        "Slot : ",
                                      ),
                                      Text(
                                        doc["slotTime"],
                                        style: const TextStyle(
                                            fontFamily: "DMSans",
                                            fontWeight: FontWeight.bold),
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Text("Booking Day : "),
                                      Text(
                                        DateFormat.MMMMEEEEd()
                                            .format(day.toDate()),
                                        style: const TextStyle(
                                            fontFamily: "DMSans",
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(
                              MediaQuery.of(context).size.width / 20,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Row(
                                  children: [
                                    const Text("Advance Received : ",
                                        style: TextStyle(color: Colors.green)),
                                    Text(
                                      "Rs. ${doc["advancePayment"]}",
                                      style: const TextStyle(
                                          fontFamily: "DMSans",
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold),
                                    )
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Text("Slot Amount : "),
                                    Text(
                                      "Rs. ${doc["slotPrice"]}",
                                      style: const TextStyle(
                                          fontFamily: "DMSans",
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Fees Due : "),
                              Text(
                                "Rs. ${doc["feesDue"]}",
                                style: TextStyle(
                                    color: Colors.red.shade200,
                                    fontFamily: "DMSans",
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Card(
                            child: Column(children: [
                              const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text("Team A"),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const Text("Team Name :"),
                                    Text(doc["teamA"]["teamName"],
                                        style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: "DMSans")),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const Text("Contact Number :"),
                                    Text(doc["teamA"]["phoneNumber"],
                                        style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: "DMSans")),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const Text("Contact Name :"),
                                    Text(doc["teamA"]["personName"],
                                        style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: "DMSans")),
                                    Text(doc["teamA"]["notesTeamA"],
                                        style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: "DMSans")),
                                  ],
                                ),
                              ),
                            ]),
                          ),
                          isTeamBAvailable
                              ? Card(
                                  child: Column(children: [
                                    const Card(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text("Team B"),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          const Text("Team Name :"),
                                          Text(doc["teamB"]["teamName"],
                                              style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: "DMSans")),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          const Text("Contact Number :"),
                                          Text(doc["teamB"]["phoneNumber"],
                                              style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: "DMSans")),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          const Text("Contact Name :"),
                                          Text(doc["teamB"]["personName"],
                                              style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: "DMSans")),
                                        ],
                                      ),
                                    ),
                                  ]),
                                )
                              : Container(),
                          SizedBox(
                            height: MediaQuery.of(context).size.height / 5,
                            width: MediaQuery.of(context).size.height / 5,
                            child: Lottie.asset(
                              "assets/checkMark.json",
                              controller: _controller,
                              onLoaded: (composition) {
                                _controller
                                  ..duration = composition.duration
                                  ..repeat();
                              },
                            ),
                          ),
                          Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CupertinoButton(
                                  color: Colors.indigo,
                                  onPressed: () {
                                    takeScreenshot();
                                  },
                                  child: const Text("Share Booking"))),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CupertinoButton(
                              color: Colors.green,
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text("Go Home"),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CupertinoButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => Platform.isAndroid
                                        ? AlertDialog(
                                            content: const Text(
                                                "Would you like to cancel booking?",
                                                style: TextStyle(
                                                    color: Colors.black54,
                                                    fontFamily: "DMSans")),
                                            title: const Text("Cancel Booking",
                                                style: TextStyle(
                                                    color: Colors.red,
                                                    fontFamily: "DMSans")),
                                            actions: [
                                              TextButton(
                                                  onPressed: () {
                                                    _server
                                                        .collection(
                                                            "SportistanPartnersProfile")
                                                        .doc(_auth
                                                            .currentUser!.uid)
                                                        .collection("Bookings")
                                                        .doc(refDetails)
                                                        .update({
                                                      'isBookingCancelled': true
                                                    }).whenComplete(() => {
                                                              if (mounted)
                                                                {
                                                                  ScaffoldMessenger.of(
                                                                          context)
                                                                      .showSnackBar(
                                                                    const SnackBar(
                                                                      content: Text(
                                                                          "Cancelled"),
                                                                      backgroundColor:
                                                                          Colors
                                                                              .red,
                                                                    ),
                                                                  ),
                                                                  Navigator.pop(
                                                                      ctx),
                                                                  Navigator.pop(
                                                                      context),
                                                                }
                                                            });
                                                  },
                                                  child: const Text(
                                                      "Cancel Booking",
                                                      style: TextStyle(
                                                          color: Colors.red,
                                                          fontFamily:
                                                              "DMSans"))),
                                              TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(ctx);
                                                  },
                                                  child: const Text("No",
                                                      style: TextStyle(
                                                          color: Colors.black54,
                                                          fontFamily:
                                                              "DMSans"))),
                                              TextButton(
                                                  onPressed: () {
                                                    const number =
                                                        '+918591719905'; //set the number here
                                                    FlutterPhoneDirectCaller
                                                        .callNumber(number);
                                                  },
                                                  child: const Text(
                                                      "Call Customer Support",
                                                      style: TextStyle(
                                                          color: Colors.green,
                                                          fontFamily:
                                                              "DMSans"))),
                                            ],
                                          )
                                        : CupertinoAlertDialog(
                                            content: const Text(
                                                "Would you like to cancel booking?",
                                                style: TextStyle(
                                                    color: Colors.black54,
                                                    fontFamily: "DMSans")),
                                            title: const Text("Cancel Booking",
                                                style: TextStyle(
                                                    color: Colors.red,
                                                    fontFamily: "DMSans")),
                                            actions: [
                                              TextButton(
                                                  onPressed: () {},
                                                  child: const Text(
                                                      "Cancel Booking",
                                                      style: TextStyle(
                                                          color: Colors.red,
                                                          fontFamily:
                                                              "DMSans"))),
                                              TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(ctx);
                                                  },
                                                  child: const Text("No",
                                                      style: TextStyle(
                                                          color: Colors.black54,
                                                          fontFamily:
                                                              "DMSans"))),
                                              TextButton(
                                                  onPressed: () {
                                                    const number =
                                                        '+918591719905'; //set the number here
                                                    FlutterPhoneDirectCaller
                                                        .callNumber(number);
                                                  },
                                                  child: const Text(
                                                      "Call Customer Support",
                                                      style: TextStyle(
                                                          color: Colors.green,
                                                          fontFamily:
                                                              "DMSans"))),
                                            ],
                                          ),
                                  );
                                },
                                child: const Text(
                                  "Cancel Booking",
                                  style: TextStyle(color: Colors.red),
                                )),
                          ),
                        ]),
                      );
                    },
                  );
                } else {
                  return const CircularProgressIndicator(
                    strokeWidth: 1,
                  );
                }
              },
            ),
          ]),
        ),
      ),
      minHeight: 0,
      maxHeight: MediaQuery.of(context).size.height / 2,
      panelBuilder: () => _panel(),
      controller: pc,
    ));
  }

  _panel() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: MediaQuery.of(context).size.width / 15,
              height: MediaQuery.of(context).size.width / 60,
              decoration: BoxDecoration(
                  color: Colors.grey, borderRadius: BorderRadius.circular(50)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text("How was your experience?",
                    style: TextStyle(
                        fontFamily: "DMSans",
                        fontSize: MediaQuery.of(context).size.height / 40)),
                RatingBar.builder(
                  initialRating: 3.5,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rating) {
                    if (rating <= 3.0) {
                      updateRating = rating;
                      ratingListenable.value = true;
                    } else {
                      updateRating = rating;
                      ratingListenable.value = false;
                    }
                  },
                ),
              ],
            ),
          ),
          ValueListenableBuilder(
            valueListenable: ratingListenable,
            builder: (context, value, child) {
              return value
                  ? Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("What went wrong?",
                              style: TextStyle(
                                  fontFamily: "DMSans",
                                  fontSize:
                                      MediaQuery.of(context).size.height / 40)),
                        ),
                        ChipsChoice<String>.multiple(
                          value: ratingTags,
                          onChanged: (val) => setState(() => ratingTags = val),
                          choiceItems: C2Choice.listFrom<String, String>(
                            source: ratingOptions,
                            value: (i, v) => v,
                            label: (i, v) => v,
                            tooltip: (i, v) => v,
                          ),
                          choiceCheckmark: true,
                          wrapped: true,
                        ),
                      ],
                    )
                  : Container();
            },
          ),
          CupertinoButton(
              color: Colors.green,
              onPressed: () async {
                _server.collection("GroundBookings").doc(refDetails).update({
                  'ratingGiven': true,
                  'rating': updateRating,
                  'ratingTags': ratingTags
                }).then((value) =>
                    {pc.close(), if (userID != _auth.currentUser!.uid) {}});
              },
              child: const Text("Submit")),
          SizedBox(
            height: MediaQuery.of(context).size.height / 4,
            width: MediaQuery.of(context).size.height / 4,
            child: Lottie.asset(
              "assets/rating.json",
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
    );
  }

  void takeScreenshot() {
    screenshotController
        .capture()
        .then((value) => {imageFile = value, saveImage()});
  }

  saveImage() async {
    await screenshotController
        .capture(delay: const Duration(milliseconds: 10))
        .then((value) async {
      if (value != null) {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = await File('${directory.path}/image.png').create();
        await imagePath.writeAsBytes(value);

        await FlutterShare.shareFile(
          title: "Booking Receipt",
          filePath: imagePath.path,
        );
      }
    });
  }
}
