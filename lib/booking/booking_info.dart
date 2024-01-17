import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sliding_up_panel2/sliding_up_panel2.dart';
import 'package:sportistan/booking/send_cloud_message.dart';
import 'package:sportistan/nav/nav_home.dart';
import 'package:sportistan/widgets/errors.dart';
import 'package:sportistan/widgets/page_route.dart';

class BookingInfo extends StatefulWidget {
  final String bookingID;

  const BookingInfo({super.key, required this.bookingID});

  @override
  State<BookingInfo> createState() => _BookingInfoState();
}

class _BookingInfoState extends State<BookingInfo> {
  String? bookingType;

  String? refDetails;

  String? userID;
  String? partnerUserID;
  String? groundName;

  String? token;

  String? date;

  String? slotTime;
  String? groundID;

 late num rating;

  var pc = PanelController();




  double? updateRating;


  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  final _server = FirebaseFirestore.instance;

  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SlidingUpPanel(
          controller: pc,
          maxHeight: MediaQuery.of(context).size.height/2,
          minHeight: 0,
          panelBuilder: () => panel(),
          body: SingleChildScrollView(
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
                        groundName = doc['groundName'];
                        rating = doc['rating'];
                        slotTime = doc['slotTime'];
                        groundID = doc['groundID'];
                        userID = doc['userID'];


                        Timestamp time = doc['bookedAt'];

                        Timestamp day = doc['bookingCreated'];
                        date = DateFormat.MMMMEEEEd().format(day.toDate());
                        DateTime booked = time.toDate();
                        bool isTeamBAvailable = doc["bothTeamBooked"];
                        return Column(
                          children: [
                            Screenshot(
                              controller: screenshotController,
                              child: Container(
                                color: Colors.white,
                                child: Column(
                                  children: [
                                    Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          children: [
                                            Text(
                                              "Booking ID",
                                              style: TextStyle(
                                                  fontFamily: "DMSans",
                                                  fontSize: MediaQuery.of(context)
                                                          .size
                                                          .height /
                                                      50),
                                            ),
                                            Text(
                                              doc["bookingID"],
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: "DMSans",
                                                  fontSize: MediaQuery.of(context)
                                                          .size
                                                          .height /
                                                      50),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ), doc["ratingGiven"]
                                        ? Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        RatingBar.builder(
                                          itemSize: MediaQuery.of(context)
                                              .size
                                              .height /
                                              40,
                                          initialRating: double.parse(rating.toString()),
                                          direction: Axis.horizontal,
                                          allowHalfRating: true,
                                          itemCount: 5,
                                          ignoreGestures: true,
                                          itemPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 4.0),
                                          itemBuilder: (context, _) =>
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                          ),
                                          onRatingUpdate:
                                              (double value) {},
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
                                    )
                                        : CupertinoButton(
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
                                              "Rate Now",
                                              style: TextStyle(
                                                  color: Colors.blue),
                                            ),
                                          ],
                                        )),
                                    Padding(
                                      padding: EdgeInsets.only(
                                        left: MediaQuery.of(context).size.width /
                                            20,
                                        right: MediaQuery.of(context).size.width /
                                            20,
                                        top: MediaQuery.of(context).size.width /
                                            20,
                                        bottom:
                                            MediaQuery.of(context).size.width /
                                                20,
                                      ),
                                      child: Image.asset(
                                        "assets/logo.png",
                                        width: MediaQuery.of(context).size.width /
                                            15,
                                        height:
                                            MediaQuery.of(context).size.width /
                                                15,
                                      ),
                                    ),
                                    Text(doc["groundName"],
                                        style: const TextStyle(
                                            fontFamily: "DMSans", fontSize: 18)),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text("Booking Generate : "),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                              "${DateFormat.yMMMMEEEEd().format(booked)} - ${DateFormat.jms().format(booked)}",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                              softWrap: true),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
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
                                                const Text("Booking Day : "),
                                                Text(
                                                  DateFormat.MMMMEEEEd()
                                                      .format(day.toDate()),
                                                  style: const TextStyle(
                                                      fontFamily: "DMSans",
                                                      fontWeight:
                                                          FontWeight.bold),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Text("Advance Received : ",
                                                  style: TextStyle(
                                                      color: Colors.green)),
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
                                          )
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
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
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
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              const Text("Contact Number :"),
                                              Text(doc["teamA"]["phoneNumber"],
                                                  style: const TextStyle(
                                                      fontSize: 22,
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: "DMSans")),
                                              InkWell(
                                                  onTap: () {
                                                    FlutterPhoneDirectCaller.callNumber(doc["teamA"]["phoneNumber"].toString());
                                                  },
                                                  child: const Icon(Icons.call,color: Colors.blue,))
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
                                              Text(doc["teamA"]["personName"],
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
                                              const Text("Notes : "),
                                              Expanded(
                                                child: Text(
                                                    doc["teamA"]["notesTeamA"],
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.visible,
                                                    style: const TextStyle(
                                                        fontSize: 18,
                                                        fontFamily: "DMSans")),
                                              ),
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
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    const Text("Team Name :"),
                                                    Text(doc["teamB"]["teamName"],
                                                        style: const TextStyle(
                                                            fontSize: 22,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontFamily:
                                                                "DMSans")),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                        "Contact Number :"),
                                                    Text(
                                                        doc["teamB"]
                                                            ["phoneNumber"],
                                                        style: const TextStyle(
                                                            fontSize: 22,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontFamily:
                                                                "DMSans")),
                                                    InkWell(
                                                        onTap: () {
                                                          FlutterPhoneDirectCaller.callNumber(doc["teamA"]["phoneNumber"].toString());
                                                        },
                                                        child: const Icon(Icons.call,color: Colors.blue,))
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    const Text("Contact Name :"),
                                                    Text(
                                                        doc["teamB"]
                                                            ["personName"],
                                                        style: const TextStyle(
                                                            fontSize: 22,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontFamily:
                                                                "DMSans")),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    const Text("Notes : "),
                                                    Expanded(
                                                      child: Text(
                                                          doc["teamB"]
                                                              ["notesTeamB"],
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .visible,
                                                          style: const TextStyle(
                                                              fontSize: 18,
                                                              fontFamily:
                                                                  "DMSans")),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ]),
                                          )
                                        : Container(),
                                    const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        "Booking Confirmed",
                                        style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 22,
                                            fontFamily: "DMSaNS"),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: CupertinoButton(
                                            color: Colors.green,
                                            onPressed: () {
                                              PageRouter.pushRemoveUntil(
                                                  context, const NavHome());
                                            },
                                            child: const Text("Home"),
                                          ),
                                        ),
                                        doc["isBookingCancelled"]
                                            ? Container() :  Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: CupertinoButton(
                                                color: Colors.indigo,
                                                onPressed: () {
                                                  takeScreenshot();
                                                },
                                                child: const Text("Share"))),
                                      ],
                                    ),
                                    doc["isBookingCancelled"]
                                        ? Container()
                                        : Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: CupertinoButton(
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (ctx) => Platform
                                                            .isAndroid
                                                        ? AlertDialog(
                                                            content: const Text(
                                                                "Would you like to cancel booking?",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black54,
                                                                    fontFamily:
                                                                        "DMSans")),
                                                            title: const Text(
                                                                "Cancel Booking",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .red,
                                                                    fontFamily:
                                                                        "DMSans")),
                                                            actions: [
                                                              TextButton(
                                                                  onPressed:
                                                                      () async {
                                                                    await _server
                                                                        .collection(
                                                                            "GroundBookings")
                                                                        .doc(
                                                                            refDetails)
                                                                        .update({
                                                                      'isBookingCancelled':
                                                                          true
                                                                    }).then((value) async =>
                                                                            {
                                                                              Navigator.pop(ctx),
                                                                              refundInit(refund: doc['bookingCommissionCharged']),
                                                                            });
                                                                  },
                                                                  child: const Text(
                                                                      "Cancel Booking",
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .red,
                                                                          fontFamily:
                                                                              "DMSans"))),
                                                              TextButton(
                                                                  onPressed: () {
                                                                    Navigator.pop(
                                                                        ctx);
                                                                  },
                                                                  child: const Text(
                                                                      "No",
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .black54,
                                                                          fontFamily:
                                                                              "DMSans"))),
                                                              TextButton(
                                                                  onPressed: () {
                                                                    const number =
                                                                        '+918591719905'; //set the number here
                                                                    FlutterPhoneDirectCaller
                                                                        .callNumber(
                                                                            number);
                                                                  },
                                                                  child: const Text(
                                                                      "Call Customer Support",
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .green,
                                                                          fontFamily:
                                                                              "DMSans"))),
                                                            ],
                                                          )
                                                        : CupertinoAlertDialog(
                                                            content: const Text(
                                                                "Would you like to cancel booking?",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black54,
                                                                    fontFamily:
                                                                        "DMSans")),
                                                            title: const Text(
                                                                "Cancel Booking Entire Day",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .red,
                                                                    fontFamily:
                                                                        "DMSans")),
                                                            actions: [
                                                              TextButton(
                                                                  onPressed:
                                                                      () async {
                                                                    await _server
                                                                        .collection(
                                                                            "GroundBookings")
                                                                        .doc(
                                                                            refDetails)
                                                                        .update({
                                                                      'isBookingCancelled':
                                                                          true
                                                                    }).then((value) async =>
                                                                            {
                                                                              Navigator.pop(ctx),
                                                                              refundInit(refund: doc['bookingCommissionCharged']),
                                                                            });
                                                                  },
                                                                  child: const Text(
                                                                      "Cancel Booking",
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .red,
                                                                          fontFamily:
                                                                              "DMSans"))),
                                                              TextButton(
                                                                  onPressed: () {
                                                                    Navigator.pop(
                                                                        ctx);
                                                                  },
                                                                  child: const Text(
                                                                      "No",
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .black54,
                                                                          fontFamily:
                                                                              "DMSans"))),
                                                              TextButton(
                                                                  onPressed: () {
                                                                    const number =
                                                                        '+918591719905'; //set the number here
                                                                    FlutterPhoneDirectCaller
                                                                        .callNumber(
                                                                            number);
                                                                  },
                                                                  child: const Text(
                                                                      "Call Customer Support",
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .green,
                                                                          fontFamily:
                                                                              "DMSans"))),
                                                            ],
                                                          ),
                                                  );
                                                },
                                                child: const Text(
                                                  "Cancel Booking",
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                )),
                                          ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    return const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 1,
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height / 12,
              )
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> takeScreenshot() async {
    await screenshotController
        .capture(delay: const Duration(milliseconds: 10))
        .then((Uint8List? image) async {
      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = await File('${directory.path}/image.png').create();
        await imagePath.writeAsBytes(image);
        await Share.shareXFiles([XFile('${directory.path}/image.jpg')],
            text:
                'Download Sportistan App for Your Sports Facility Booking https://www.isportistanapp.web.app/');
      }
    });
  }

  refundInit({
    required num refund,
  }) async {
    num sportistanCredit;
    try {
      await _server
          .collection("SportistanUsers")
          .where("userID", isEqualTo: userID)
          .get()
          .then((value) async => {
                sportistanCredit =
                    value.docChanges.first.doc.get('sportistanCredit'),
                await _server
                    .collection("SportistanUsers")
                    .doc(value.docChanges.first.doc.id)
                    .update({
                  'sportistanCredit': sportistanCredit + refund
                }).then((value) => {sendNotification()})
              });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Failed to Refund")));
      }
    }
  }

  sendNotification() async {
    String? token;
    await _server
        .collection('SportistanPartners')
        .where('groundID', isEqualTo: groundID)
        .get()
        .then((value) async => {
          partnerUserID = value.docChanges.first.doc.get('userID'),
              await _server
                  .collection('DeviceTokens')
                  .where('userID', isEqualTo: partnerUserID)
                  .get()
                  .then((v) => {token = v.docChanges.first.doc.get('token')})
            });

    if (token != null) {
      await FirebaseCloudMessaging.sendPushMessage(
              "$groundName Booking is Cancelled of Slot $slotTime and $date",
              "Booking Cancelled",
              token.toString())
          .then((value) => {
                showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (ctx) => Platform.isIOS
                      ? CupertinoAlertDialog(
                          title: const Text("Booking is Cancelled"),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.pop(context);
                              },
                              child: const Text("OK",
                                  style: TextStyle(color: Colors.black54)),
                            )
                          ],
                          content: const Text(
                              "Your Booking is Successfully Cancelled",
                              style: TextStyle(color: Colors.green)),
                        )
                      :  AlertDialog(
                    title: const Text("Booking is Cancelled"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        child: const Text("OK",
                            style: TextStyle(color: Colors.black54)),
                      )
                    ],
                    content: const Text(
                        "Your Booking is Successfully Cancelled",
                        style: TextStyle(color: Colors.green)),
                  ),
                )
              });
    }
  }

  panel() {
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("How was your experience?",
                      style: TextStyle(
                          fontFamily: "DMSans",
                          fontSize: MediaQuery.of(context).size.height / 40)),
                ),
                Text("Please Give rating.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: "DMSans",
                        fontSize: MediaQuery.of(context).size.height / 50)),
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
                  onRatingUpdate: (rate) {
                    if (rate <= 3.0) {
                      updateRating = rate;
                    } else {
                      updateRating = rate;
                    }
                  },
                ),
              ],
            ),
          ),

          CupertinoButton(
              color: Colors.green,
              onPressed: () async {
                pc.close();
                Alert.flushBarAlert(
                    message: 'Rating Updated',
                    context: context,
                    title: 'Rating');
                await _server
                    .collection("GroundBookings")
                    .doc(refDetails)
                    .update({
                  'rating': updateRating,
                  'ratingGiven': true,

                });

                try {
                  await _server
                      .collection("SportistanPartners")
                      .where("groundID", isEqualTo: groundID)
                      .get()
                      .then((value) async => {
                    if (value.docChanges.isNotEmpty)
                      {
                        await _server
                            .collection("SportistanPartners")
                            .doc(value.docChanges.first.doc.id)
                            .update({
                          'profileRating': updateRating,
                        })
                      }
                  });
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User Not Found')));
                  }
                }
              },
              child: const Text("Submit")),
        ],
      ),
    );
  }
}
