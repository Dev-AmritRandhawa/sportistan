import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportistan/booking/book_entire_day.dart';
import 'package:sportistan/nav/nav_home.dart';
import 'package:sportistan/widgets/page_route.dart';
import 'book_a_slot.dart';

class ShowSlots extends StatefulWidget {
  final String groundID;
  final String groundName;
  final String groundAddress;
  final String groundType;

  const ShowSlots({super.key,
    required this.groundID,
    required this.groundName,
    required this.groundType,
    required this.groundAddress});

  @override
  State<ShowSlots> createState() => _ShowSlotsState();
}

class _ShowSlotsState extends State<ShowSlots> {
  final PageController _pageController = PageController(initialPage: 0);
  List bookingElements = [];
  List<MyBookings> finalAvailabilityList = [];
  List bookingList = [];
  List slotsList = [];
  final _server = FirebaseFirestore.instance;
  ValueNotifier<bool> filter = ValueNotifier<bool>(false);
  bool listShow = false;
  bool show = false;

  late Map<String, dynamic> slotsElements;

  List<String> alreadyBooked = [];

  List checkEntireDayAvailability = [];

  List<String> refID = [];
  List<int> onwards = [];

  final GlobalKey<LiquidPullToRefreshState> _refreshIndicatorKey =
  GlobalKey<LiquidPullToRefreshState>();

  int bookingCreated = 0;

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
    if (mounted) {
      setState(() {
        listShow = false;
      });
    }
    alreadyBooked.clear();
    filter.value = false;
    bookingElements.clear();
    bookingList.clear();
    slotsList.clear();
    finalAvailabilityList.clear();
    checkEntireDayAvailability.clear();

    try {
      DateTime now = DateTime.now();
      await _server
          .collection("GroundBookings")
          .where("bookingCreated",
          isLessThanOrEqualTo: DateTime(now.year, now.month, now.day + 30))
          .where('bookingCreated',
          isGreaterThanOrEqualTo: DateTime(now.year, now.month, now.day))
          .where('groundID', isEqualTo: widget.groundID)
          .where("isBookingCancelled", isEqualTo: false)
          .get()
          .then((value) =>
      {
        bookingElements = value.docs,
        if (value.docs.isNotEmpty)
          {
            for (int i = 0; i < bookingElements.length; i++)
              {
                bookingList.add(bookingElements[i]["slotID"] +
                    bookingElements[i]["date"]),
                checkEntireDayAvailability
                    .add(bookingElements[i]["date"])
              },
            getAllSlots()
          }
        else
          {getAllSlots()},
      });
    } catch (error) {
      getAllSlots();
    }
  }

  @override
  void initState() {
    collectBookings();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CupertinoButton(
            color: Colors.green.shade900,
            borderRadius: BorderRadius.circular(4),
            onPressed: () {
              PageRouter.pushRemoveUntil(context, const NavHome());
            },
            child: const Text('Home')),
      ),
      appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black54,
          title: const Text("Back"),
          elevation: 0),

      body: LiquidPullToRefresh(
        onRefresh: _handleRefresh,
        showChildOpacityTransition: false,
        backgroundColor: Colors.green,
        springAnimationDurationInMilliseconds: 500,
        color: Colors.white,
        key: _refreshIndicatorKey,
        child: SingleChildScrollView(
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
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery
                            .of(context)
                            .size
                            .height / 15,
                        width: MediaQuery
                            .of(context)
                            .size
                            .width,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              "Select Particular Date View Slots",
                              style: TextStyle(
                                  fontFamily: "DMSans",
                                  fontSize:
                                  MediaQuery
                                      .of(context)
                                      .size
                                      .height / 50),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.black,
                            )
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Row(children: [
                              Icon(
                                Icons.rectangle_outlined,
                                color: Colors.green,
                              ),
                              Text("Available")
                            ]),
                            Row(children: [
                              Icon(
                                Icons.rectangle,
                                color: Colors.green,
                              ),
                              Text("Booked")
                            ]),
                            Row(children: [
                              Icon(
                                Icons.rectangle,
                                color: Colors.orangeAccent,
                              ),
                              Text("Half Booked")
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ValueListenableBuilder(
                valueListenable: filter,
                builder: (context, value, child) =>
                    Card(
                      color: Colors.green.shade800,
                      child: value
                          ? InkWell(
                        onTap: () {
                          reInit();
                        },
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text("Clear Filter",
                                    style: TextStyle(
                                      fontSize:
                                      MediaQuery
                                          .of(context)
                                          .size
                                          .height /
                                          40,
                                      color: Colors.white,
                                      fontFamily: "DMSans",
                                    )),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(Icons.clear,
                                    color: Colors.white,
                                    size: MediaQuery
                                        .of(context)
                                        .size
                                        .height /
                                        35),
                              )
                            ]),
                      )
                          : Container(),
                    ),
              ),
              _panel()
            ],
          ),
        ),
      ), //Scaffold
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
      if (data[DateFormat.EEEE().format(date)] != null) {
        daySlots = data[DateFormat.EEEE().format(date)];
      } else {
        daySlots = [];
        break;
      }

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
      if (slotsElements[DateFormat.EEEE().format(date)] != null) {
        daySlots = slotsElements[DateFormat.EEEE().format(date)];
      } else {
        daySlots = [];
        break;
      }
      for (int j = 0; j < daySlots.length; j++) {
        if (alreadyBooked.contains(slotsElements[DateFormat.EEEE().format(date)]
        [j]["slotID"] +
            date.toString())) {
          finalAvailabilityList.add(MyBookings(
            slotID: bookingElements[bookingCreated]["slotID"],
            group: date.toString(),
            date: bookingElements[bookingCreated]["date"],
            bookingID: bookingElements[bookingCreated]["bookingID"],
            slotStatus: bookingElements[bookingCreated]["slotStatus"],
            slotTime: bookingElements[bookingCreated]["slotTime"],
            slotPrice: bookingElements[bookingCreated]["slotPrice"],
            feesDue: bookingElements[bookingCreated]["feesDue"],
            entireDayBooked: bookingElements[bookingCreated]["entireDayBooking"],
          ));
          alreadyBooked.remove(slotsElements[DateFormat.EEEE().format(date)][j]
          ["slotID"] +
              date.toString());

          bookingCreated++;
        } else {
          finalAvailabilityList.add(MyBookings(
            slotID: slotsElements[DateFormat.EEEE().format(date)][j]["slotID"],
            group: date.toString(),
            date: date.toString(),
            bookingID: '',
            slotStatus: 'Available',
            slotTime: slotsElements[DateFormat.EEEE().format(date)][j]["time"],
            slotPrice: slotsElements[DateFormat.EEEE().format(date)][j]
            ["price"],
            feesDue: slotsElements[DateFormat.EEEE().format(date)][j]["price"],
            entireDayBooked: false,
          ));
        }
      }
    }
    if (mounted) {
      bookingCreated = 0;
      setState(() {
        listShow = true;
      });
    }
  }

  reInit() {
    collectBookings();
  }

  Future<void> _handleRefresh() async {
    reInit();
  }

  _panel() {
    Map groupItemsByCategory(List items) {
      return groupBy(items, (item) => item.group);
    }

    Map groupedItems = groupItemsByCategory(finalAvailabilityList);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
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
                              "${DateFormat.yMMMd().format(
                                  DateTime.parse(group))} (${DateFormat.EEEE()
                                  .format(DateTime.parse(group))})",
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                        ),
                      ],
                    ),
                    Container(
                      width: double.infinity,
                      height: MediaQuery
                          .of(context)
                          .size
                          .height / 12,
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
                                        checkStatusSlotAndMove(bookings: bookings);
                                      },
                                      child: Text(
                                        bookings.slotTime,
                                        style: TextStyle(
                                            color: setSlotFontColor(
                                                bookings.slotStatus),
                                            fontSize:
                                            MediaQuery
                                                .of(context)
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
                                              fontSize: MediaQuery
                                                  .of(
                                                  context)
                                                  .size
                                                  .width /
                                                  38,
                                              fontWeight:
                                              FontWeight.bold,
                                              color: Colors.black45,
                                              fontFamily: "DMSans"),
                                        ),
                                        Text(
                                          bookings.feesDue
                                              .toString(),
                                          style: TextStyle(
                                              fontSize: MediaQuery
                                                  .of(
                                                  context)
                                                  .size
                                                  .width /
                                                  38,
                                              fontWeight:
                                              FontWeight.bold,
                                              color: Colors.black54,
                                              fontFamily: "DMSans"),
                                        ),
                                      ],
                                    )
                                        : bookings.slotStatus ==
                                        'Available'
                                        ? Row(
                                      children: [
                                        Text(
                                          "Slot ${index + 1} :",
                                          style: TextStyle(
                                              fontSize: MediaQuery
                                                  .of(
                                                  context)
                                                  .size
                                                  .width /
                                                  38,
                                              fontWeight:
                                              FontWeight
                                                  .bold,
                                              color: Colors
                                                  .black54,
                                              fontFamily:
                                              "DMSans"),
                                        ),
                                        Text(
                                          bookings.slotPrice
                                              .toString(),
                                          style: TextStyle(
                                              fontSize: MediaQuery
                                                  .of(
                                                  context)
                                                  .size
                                                  .width /
                                                  38,
                                              fontWeight:
                                              FontWeight
                                                  .bold,
                                              color: Colors
                                                  .black54,
                                              fontFamily:
                                              "DMSans"),
                                        ),
                                      ],
                                    )
                                        : bookings.feesDue != 0
                                        ? Row(
                                      children: [
                                        Text(
                                          bookings.entireDayBooked
                                              ? 'Entire Day Due '
                                              : "Fees Due :",
                                          style: TextStyle(
                                              fontSize: MediaQuery
                                                  .of(
                                                  context)
                                                  .size
                                                  .width /
                                                  38,
                                              color: bookings
                                                  .entireDayBooked
                                                  ? Colors
                                                  .red
                                                  : Colors.red[
                                              200],
                                              fontFamily:
                                              "DMSans"),
                                        ),
                                        Text(
                                          'Rs. ${bookings.feesDue}',
                                          style: TextStyle(
                                              fontSize: MediaQuery
                                                  .of(
                                                  context)
                                                  .size
                                                  .width /
                                                  38,
                                              color: bookings
                                                  .entireDayBooked
                                                  ? Colors
                                                  .red
                                                  : Colors.red[
                                              200],
                                              fontFamily:
                                              "DMSans"),
                                        ),
                                      ],
                                    )
                                        : Text(
                                      "No Due",
                                      style: TextStyle(
                                          fontSize: MediaQuery
                                              .of(
                                              context)
                                              .size
                                              .width /
                                              38,
                                          fontWeight:
                                          FontWeight
                                              .bold,
                                          color:
                                          Colors.green,
                                          fontFamily:
                                          "DMSans"),
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
                              if (Platform.isAndroid) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          BookEntireDay(
                                            date: group,
                                            groundID:
                                            widget.groundID, groundName: widget.groundName,
                                          ),
                                    ))
                                    .then((value) =>
                                {collectBookings()});
                              }
                              if (Platform.isIOS) {
                                Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) =>
                                          BookEntireDay(
                                            date: group,
                                            groundID:
                                            widget.groundID, groundName: widget.groundName,
                                          ),
                                    ))
                                    .then((value) =>
                                {collectBookings()});
                              }
                            },
                            child: const Text(
                              "BOOK ENTIRE DAY",
                              style: TextStyle(color: Colors.green),
                            )),
                      ],
                    )
                  ],
                ),
              );
            },
          )
              : Platform.isIOS
              ? const Padding(
            padding: EdgeInsets.all(8.0),
            child: CupertinoActivityIndicator(),
          )
              : const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.black54,
            ),
          )
        ],
      ),
    );
  }

  Future<void> groundStateSave(String id) async {
    final data = await SharedPreferences.getInstance();
    data.setString("groundID", id);
  }

  void checkStatusSlotAndMove({required MyBookings bookings}) {
    switch (bookings.slotStatus) {
      case "Half Booked":
        {
          moveToPages(bookings: bookings);
        }
      case "Available":
        {
          moveToPages(bookings: bookings);
        }
    }
  }

  moveToPages({required MyBookings bookings}) {
    if (Platform.isAndroid) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  BookASlot(
                    group: bookings.group,
                    date: bookings.date,
                    slotID: bookings.slotID,
                    slotTime: bookings.slotTime,
                    slotStatus: bookings.slotStatus,
                    groundID: widget.groundID,
                    groundAddress: widget.groundAddress,
                    groundName: widget.groundName,
                    bookingID: bookings.bookingID,
                    slotPrice: bookings.slotPrice, groundType: widget.groundType,
                  ))).then((value) => {collectBookings()});
    }
    if (Platform.isIOS) {
      Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) =>
                BookASlot(
                  group: bookings.group,
                  date: bookings.date,
                  slotID: bookings.slotID,
                  slotTime: bookings.slotTime,
                  slotStatus: bookings.slotStatus,
                  groundID: widget.groundID,
                  groundAddress: widget.groundAddress,
                  groundName: widget.groundName,
                  bookingID: bookings.bookingID,
                  slotPrice: bookings.slotPrice, groundType:  widget.groundType,
                ),
          )).then((value) => {collectBookings()});
    }
  }

  Future<void> collectBookingsWithFilter(DateTime now) async {
    bookingElements.clear();
    slotsElements.clear();
    bookingList.clear();
    slotsList.clear();
    finalAvailabilityList.clear();

    setState(() {
      listShow = false;
    });
    await _server
        .collection("GroundBookings")
        .where("bookingCreated",
        isLessThanOrEqualTo: DateTime(now.year, now.month, now.day)
            .add(const Duration(days: 30)))
        .get()
        .then((value) =>
    {
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
    if (data[DateFormat.EEEE().format(date)] != null) {
      daySlots = data[DateFormat.EEEE().format(date)];
    } else {
      daySlots = [];
    }
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
              entireDayBooked: false,
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
    if (slotsElements[DateFormat.EEEE().format(date)] != null) {
      daySlots = slotsElements[DateFormat.EEEE().format(date)];
    } else {
      daySlots = [];
    }
    for (int j = 0; j < daySlots.length; j++) {
      String uniqueID = slotsElements[DateFormat.EEEE().format(date)][j]
      ["slotID"] +
          date.toString();
      if (alreadyBooked.isNotEmpty) {
        if (alreadyBooked.contains(uniqueID)) {
          continue;
        } else {
          createAvailableFilterSlots(date: date, j: j);
        }
      } else {
        createAvailableFilterSlots(date: date, j: j);
      }
    }
  }

  void createAvailableFilterSlots({required DateTime date, required int j}) {
    if (alreadyBooked.contains(slotsElements[DateFormat.EEEE().format(date)][j]
    ["slotID"] +
        date.toString())) {
      finalAvailabilityList.add(MyBookings(
        slotID: bookingElements[bookingCreated]["slotID"],
        group: date.toString(),
        date: bookingElements[bookingCreated]["date"],
        bookingID: bookingElements[bookingCreated]["bookingID"],
        slotStatus: bookingElements[bookingCreated]["slotStatus"],
        slotTime: bookingElements[bookingCreated]["slotTime"],
        slotPrice: bookingElements[bookingCreated]["slotPrice"],
        feesDue: bookingElements[bookingCreated]["feesDue"],
        entireDayBooked: bookingElements[bookingCreated]["entireDayBooking"],
      ));
      alreadyBooked.remove(slotsElements[DateFormat.EEEE().format(date)][j]
      ["slotID"] +
          date.toString());

      bookingCreated++;
    } else {
      finalAvailabilityList.add(MyBookings(
        slotID: slotsElements[DateFormat.EEEE().format(date)][j]["slotID"],
        group: date.toString(),
        date: date.toString(),
        bookingID: '',
        slotStatus: 'Available',
        slotTime: slotsElements[DateFormat.EEEE().format(date)][j]["time"],
        slotPrice: slotsElements[DateFormat.EEEE().format(date)][j]["price"],
        feesDue: slotsElements[DateFormat.EEEE().format(date)][j]["price"],
        entireDayBooked: false,
      ));
    }
    if (mounted) {
      bookingCreated = 0;
      setState(() {
        listShow = true;
      });
    }
  }
}

class MyBookings {
  final String slotID;
  final String group;
  final String date;
  final int slotPrice;
  final num feesDue;
  final bool entireDayBooked;
  final String slotStatus;
  final String slotTime;
  final String bookingID;

  MyBookings({required this.slotID,
    required this.entireDayBooked,
    required this.group,
    required this.feesDue,
    required this.date,
    required this.bookingID,
    required this.slotPrice,
    required this.slotStatus,
    required this.slotTime});
}
