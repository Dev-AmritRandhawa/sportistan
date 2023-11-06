import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sportistan/booking/book_a_slot.dart';
import 'package:sportistan/booking/book_entire_day.dart';
import 'package:sportistan/widgets/page_route.dart';

class ShowSlots extends StatefulWidget {
  final String groundID;
  final String groundAddress;
  final String groundName;

  const ShowSlots(
      {super.key,
      required this.groundID,
      required this.groundAddress,
      required this.groundName});

  @override
  State<ShowSlots> createState() => _ShowSlotsState();
}

class _ShowSlotsState extends State<ShowSlots> {
  final PageController _pageController = PageController(initialPage: 0);
  List bookingElements = [];
  List finalAvailabilityList = [];
  List bookingList = [];
  List slotsList = [];

  final _server = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  ValueNotifier<bool> filter = ValueNotifier<bool>(false);
  bool listShow = false;
  bool show = false;
  String? dayTime;

  late Map<String, dynamic> slotsElements;

  List<String> alreadyBooked = [];

  List checkEntireDayAvailability = [];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  getFilterData(DateTime date) async {
    if (mounted) {
      setState(() {
        listShow = false;
      });
    }
    filter.value = true;

    collectBookingsWithFilter(date);
  }

  Future<void> collectBookings() async {
    DateTime now = DateTime.now();
    await _server
        .collection("GroundBookings")
        .where("bookingCreated",
            isLessThanOrEqualTo: DateTime(now.year, now.month, now.day).add(const Duration(days: 30)))
        .where("isBookingCancelled", isEqualTo: false)
        .get()
        .then((value) => {
              bookingElements = value.docs,
              if (value.docs.isNotEmpty)
                {
                  for (int i = 0; i < bookingElements.length; i++)
                    {
                      bookingList.add(bookingElements[i]["slotID"] +
                          bookingElements[i]["date"]),
                      checkEntireDayAvailability.add(bookingElements[i]["date"])
                    },
                  getAllSlots()
                }
              else
                {getAllSlots()},
            });
  }

  @override
  void initState() {
    finalAvailabilityList.clear();
    collectBookings();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Map groupItemsByCategory(List items) {
      return groupBy(items, (item) => item.group);
    }

    Map groupedItems = groupItemsByCategory(finalAvailabilityList);
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.green),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            InkWell(
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)));
                if (pickedDate != null) {
                  getFilterData(pickedDate);
                }
              },
              child: Card(
                color: Colors.grey.shade100,
                elevation: 0,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height / 15,
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        "Select Particular Date View Slots",
                        style: TextStyle(
                            fontFamily: "DMSans",
                            fontSize: MediaQuery.of(context).size.height / 50),
                      ),
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.black,
                      )
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Row(children: [
                    Icon(
                      Icons.rectangle_outlined,
                      color: Colors.green,
                    ),
                    Text("Available")
                  ]),
                  const Row(children: [
                    Icon(
                      Icons.rectangle,
                      color: Colors.green,
                    ),
                    Text("Booked")
                  ]),
                  const Row(children: [
                    Icon(
                      Icons.rectangle,
                      color: Colors.orangeAccent,
                    ),
                    Text("Half Booked")
                  ]),
                  Row(children: [
                    Icon(
                      Icons.rectangle,
                      color: Colors.red[200],
                    ),
                    const Text("Fees Due")
                  ]),
                ],
              ),
            ),
            ValueListenableBuilder(
              valueListenable: filter,
              builder: (context, value, child) => Card(
                color: Colors.green.shade800,
                child: value
                    ? InkWell(
                        onTap: () {
                          setState(() {
                            listShow = false;
                            finalAvailabilityList.clear();
                            filter.value = false;
                            collectBookings();
                          });
                        },
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text("Clear Filter",
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.height /
                                              40,
                                      color: Colors.white,
                                      fontFamily: "DMSans",
                                    )),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(Icons.clear,
                                    color: Colors.white,
                                    size: MediaQuery.of(context).size.height /
                                        35),
                              )
                            ]),
                      )
                    : Container(),
              ),
            ),
            listShow
                ? ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: groupedItems.length,
                    itemBuilder: (BuildContext context, int index) {
                      String group = groupedItems.keys.elementAt(index);
                      List bookingGroup = groupedItems[group]!;
                      return Card(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(right: 8, left: 8),
                                  child: Text(
                                      "${DateFormat.yMMMd().format(DateTime.parse(group))} (${DateFormat.EEEE().format(DateTime.parse(group))})",
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18)),
                                ),
                              ],
                            ),
                            Container(
                              width: double.infinity,
                              height: MediaQuery.of(context).size.height / 12,
                              alignment: Alignment.topCenter,
                              child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const BouncingScrollPhysics(),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: bookingGroup.length,
                                  itemBuilder: (context, index) {
                                    MyBookings bookings = bookingGroup[index];
                                    return Padding(
                                        padding: const EdgeInsets.only(
                                            left: 2, right: 2),
                                        child: Column(
                                          children: [
                                            OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                backgroundColor:
                                                    setSlotStatusColor(
                                                        bookings.slotStatus),
                                                side: BorderSide(
                                                    color: setSlotOutlineColor(
                                                        bookings.slotStatus),
                                                    width: 2),
                                              ),
                                              onPressed: () {
                                                if (bookings.slotStatus ==
                                                    "Half Booked") {
                                                  PageRouter.push(
                                                      context,
                                                      BookASlot(
                                                        group: bookings.group,
                                                        date: bookings.date,
                                                        slotID: bookings.slotID,
                                                        slotTime:
                                                            bookings.slotTime,
                                                        slotStatus:
                                                            bookings.slotStatus,
                                                        groundID:
                                                            widget.groundID,
                                                        groundAddress: widget
                                                            .groundAddress,
                                                        groundName:
                                                            widget.groundName,
                                                        bookingID:
                                                            bookings.bookingID,
                                                        slotPrice:
                                                            bookings.slotPrice,
                                                      ));
                                                } else {
                                                  if (Platform.isIOS) {
                                                    Navigator.push(
                                                        context,
                                                        CupertinoPageRoute(
                                                            builder:
                                                                (context) =>
                                                                    BookASlot(
                                                                      group: bookings
                                                                          .group,
                                                                      date: bookings
                                                                          .date,
                                                                      slotID: bookings
                                                                          .slotID,
                                                                      slotTime:
                                                                          bookings
                                                                              .slotTime,
                                                                      slotStatus:
                                                                          bookings
                                                                              .slotStatus,
                                                                      groundID:
                                                                          widget
                                                                              .groundID,
                                                                      groundAddress:
                                                                          widget
                                                                              .groundAddress,
                                                                      groundName:
                                                                          widget
                                                                              .groundName,
                                                                      bookingID:
                                                                          bookings
                                                                              .bookingID,
                                                                      slotPrice:
                                                                          bookings
                                                                              .slotPrice,
                                                                    ))).then(
                                                        (value) => {reInit()});
                                                  }
                                                  if (Platform.isAndroid) {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder:
                                                                (context) =>
                                                                    BookASlot(
                                                                      bookingID:
                                                                          bookings
                                                                              .bookingID,
                                                                      group: bookings
                                                                          .group,
                                                                      date: bookings
                                                                          .date,
                                                                      slotID: bookings
                                                                          .slotID,
                                                                      slotTime:
                                                                          bookings
                                                                              .slotTime,
                                                                      slotStatus:
                                                                          bookings
                                                                              .slotStatus,
                                                                      groundID:
                                                                          widget
                                                                              .groundID,
                                                                      groundAddress:
                                                                          widget
                                                                              .groundAddress,
                                                                      groundName:
                                                                          widget
                                                                              .groundName,
                                                                      slotPrice:
                                                                          bookings
                                                                              .slotPrice,
                                                                    ))).then(
                                                        (value) => {reInit()});
                                                  }
                                                }
                                              },
                                              child: Text(
                                                bookings.slotTime,
                                                style: TextStyle(
                                                    color: setSlotFontColor(
                                                        bookings.slotStatus),
                                                    fontSize:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            30),
                                              ),
                                            ),
                                            bookings.slotStatus == "Fees Due"
                                                ? Row(
                                                    children: [
                                                      Text(
                                                        "Fees Due :",
                                                        style: TextStyle(
                                                            fontSize: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width /
                                                                38,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Colors.black45,
                                                            fontFamily:
                                                                "DMSans"),
                                                      ),
                                                      Text(
                                                        bookings.feesDue
                                                            .toString(),
                                                        style: TextStyle(
                                                            fontSize: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width /
                                                                38,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Colors.black54,
                                                            fontFamily:
                                                                "DMSans"),
                                                      ),
                                                    ],
                                                  )
                                                : Row(
                                                    children: [
                                                      Text(
                                                        "Slot ${index + 1} :",
                                                        style: TextStyle(
                                                            fontSize: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width /
                                                                38,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Colors.black54,
                                                            fontFamily:
                                                                "DMSans"),
                                                      ),
                                                      Text(
                                                        bookings.slotPrice
                                                            .toString(),
                                                        style: TextStyle(
                                                            fontSize: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width /
                                                                38,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Colors.black54,
                                                            fontFamily:
                                                                "DMSans"),
                                                      ),
                                                    ],
                                                  ),
                                          ],
                                        ));
                                  }),
                            ),
                            checkEntireDayAvailability.contains(group)
                                ? Container()
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                          onPressed: () {
                                            PageRouter.push(
                                                context,
                                                BookEntireDay(
                                                  date: group,
                                                  groundID: widget.groundID,
                                                ));
                                          },
                                          child: const Text(
                                            "BOOK ENTIRE DAY",
                                            style:
                                                TextStyle(color: Colors.green),
                                          )),
                                    ],
                                  )
                          ],
                        ),
                      );
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset("assets/logo.png",
                            color: Colors.black12,
                            height: MediaQuery.of(context).size.height / 8),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Loading",style: TextStyle(color: Colors.black12)),
                        )

                      ],
                    ),
                  )
          ],
        ),
      ),
    );
  }

  Color setSlotStatusColor(String result) {
    switch (result) {
      case "Booked":
        {
          return Colors.green;
        }
      case "Half Booked":
        {
          return Colors.orangeAccent;
        }
      case "Fees Due":
        {
          return Colors.red.shade200;
        }
    }
    return Colors.white;
  }

  Color setSlotOutlineColor(String result) {
    if (result == "Available") {
      return Colors.green;
    } else {
      return Colors.white;
    }
  }

  Color setSlotFontColor(String result) {
    if (result == "Available") {
      return Colors.black;
    } else {
      return Colors.white;
    }
  }

  Future<void> getAllSlots() async {
    var daySlots = [];

    var collection = _server.collection('SportistanPartners');
    var docSnapshot = await collection.doc(widget.groundID).get();

    Map<String, dynamic> data = docSnapshot.data()!;
    slotsElements = data;

    DateTime now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      DateTime date =
          DateTime(now.year, now.month, now.day).add(Duration(days: i));
      daySlots = data[DateFormat.EEEE().format(date)];
      for (int j = 0; j < daySlots.length; j++) {
        slotsList.add(data[DateFormat.EEEE().format(date)][j]["slotID"] +
            date.toString());
      }
    }
    for (int l = 0; l < bookingList.length; l++) {
      for (int k = 0; k < slotsList.length; k++) {
        if (bookingList.isNotEmpty) {
          if (slotsList[k] == bookingList[l]) {
            alreadyBooked
                .add(bookingElements[l]["slotID"] + bookingElements[l]["date"]);

            finalAvailabilityList.add(MyBookings(
                slotID: bookingElements[l]["slotID"],
                group: bookingElements[l]["group"],
                date: bookingElements[l]["date"],
                bookingID: bookingElements[l]["bookingID"],
                slotStatus: bookingElements[l]["slotStatus"],
                slotTime: bookingElements[l]["slotTime"],
                slotPrice: bookingElements[l]["slotPrice"],
                feesDue: bookingElements[l]["feesDue"]));
          }
        } else {
          availableSlots();
        }
      }
    }
    availableSlots();
  }

  void availableSlots() {
    var daySlots = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      DateTime date =
          DateTime(now.year, now.month, now.day).add(Duration(days: i));
      daySlots = slotsElements[DateFormat.EEEE().format(date)];
      for (int j = 0; j < daySlots.length; j++) {
        String uniqueID = slotsElements[DateFormat.EEEE().format(date)][j]
                ["slotID"] +
            date.toString();

        if (alreadyBooked.isNotEmpty) {
          if (alreadyBooked.contains(uniqueID)) {
            continue;
          } else {
            createAvailableSlots(date: date, j: j);
          }
        } else {
          createAvailableSlots(date: date, j: j);
        }
      }
    }
    if (mounted) {
      setState(() {
        listShow = true;
      });
    }
  }

  void createAvailableSlots({required DateTime date, required int j}) {
    finalAvailabilityList.add(MyBookings(
      slotID: slotsElements[DateFormat.EEEE().format(date)][j]["slotID"],
      group: date.toString(),
      date: date.toString(),
      bookingID: '',
      slotStatus: 'Available',
      slotTime: slotsElements[DateFormat.EEEE().format(date)][j]["time"],
      slotPrice: slotsElements[DateFormat.EEEE().format(date)][j]["price"],
      feesDue: slotsElements[DateFormat.EEEE().format(date)][j]["price"],
    ));
  }

  reInit() {
    finalAvailabilityList.clear();
    bookingElements.clear();
    finalAvailabilityList.clear();
    bookingList.clear();
    slotsList.clear();
    setState(() {
      listShow = false;
      collectBookings();
    });
  }

  Future<void> collectBookingsWithFilter(DateTime now) async {
    await _server
        .collection("SportistanPartnersProfile")
        .doc(_auth.currentUser!.uid)
        .collection("Bookings")
        .where("bookingCreated",
            isLessThanOrEqualTo: DateTime(now.year, now.month, now.day))
        .get()
        .then((value) => {
              bookingElements = value.docs,
              if (value.docs.isNotEmpty)
                {
                  for (int i = 0; i < bookingElements.length; i++)
                    {
                      bookingList.add(bookingElements[i]["slotID"] +
                          bookingElements[i]["date"])
                    },
                  getFilterSlots(now)
                }
              else
                {getFilterSlots(now)},
            });
  }

  getFilterSlots(DateTime date) async {
    finalAvailabilityList.clear();
    bookingElements.clear();
    finalAvailabilityList.clear();
    bookingList.clear();
    slotsList.clear();
    setState(() {
      listShow = false;
    });
    var daySlots = [];
    var collection = _server.collection('SportistanPartners');
    var docSnapshot = await collection.doc(widget.groundID).get();
    Map<String, dynamic> data = docSnapshot.data()!;
    slotsElements = data;
    daySlots = data[DateFormat.EEEE().format(date)];
    for (int j = 0; j < daySlots.length; j++) {
      slotsList.add(
          data[DateFormat.EEEE().format(date)][j]["slotID"] + date.toString());
    }
    for (int l = 0; l < bookingList.length; l++) {
      for (int k = 0; k < slotsList.length; k++) {
        if (bookingList.isNotEmpty) {
          if (slotsList[k] == bookingList[l]) {
            alreadyBooked
                .add(bookingElements[l]["slotID"] + bookingElements[l]["date"]);

            finalAvailabilityList.add(MyBookings(
              slotID: bookingElements[l]["slotID"],
              group: bookingElements[l]["group"],
              date: bookingElements[l]["date"],
              bookingID: bookingElements[l]["bookingID"],
              slotStatus: bookingElements[l]["slotStatus"],
              slotTime: bookingElements[l]["slotTime"],
              slotPrice: bookingElements[l]["slotPrice"],
              feesDue: bookingElements[l]["feesDue"],
            ));
          }
        } else {
          availableFilterSlots(date);
        }
      }
    }
    availableFilterSlots(date);
  }

  void availableFilterSlots(DateTime date) {
    var daySlots = [];
    daySlots = slotsElements[DateFormat.EEEE().format(date)];
    for (int j = 0; j < daySlots.length; j++) {
      String uniqueID = slotsElements[DateFormat.EEEE().format(date)][j]
              ["slotID"] +
          date.toString();
      if (alreadyBooked.isNotEmpty) {
        if (alreadyBooked.contains(uniqueID)) {
          continue;
        } else {
          createAvailableSlots(date: date, j: j);
        }
      } else {
        createAvailableSlots(date: date, j: j);
      }
    }
    setState(() {
      listShow = true;
    });
  }
}

class MyBookings {
  final String slotID;
  final String group;
  final String date;
  final int slotPrice;
  final int feesDue;
  final String slotStatus;
  final String slotTime;
  final String bookingID;

  MyBookings(
      {required this.slotID,
      required this.group,
      required this.feesDue,
      required this.date,
      required this.bookingID,
      required this.slotPrice,
      required this.slotStatus,
      required this.slotTime});

  Map groupItemsByGroup(List items) {
    return groupBy(items, (item) => item.group);
  }
}
