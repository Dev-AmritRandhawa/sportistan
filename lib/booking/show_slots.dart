import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:SportistanPro/booking/book_entire_day.dart';
import 'package:SportistanPro/nav/nav_home.dart';
import 'package:SportistanPro/widgets/page_route.dart';
import 'book_a_slot.dart';

class ShowSlots extends StatefulWidget {
  final String groundID;
  final String groundName;
  final String groundAddress;
  final String groundType;

  const ShowSlots(
      {super.key,
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

  Map<String, dynamic> slotsElements = {};

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

  Future<void> collectBookings(
      {required DateTime period, required bool setFilter}) async {
    if (mounted) {
      setState(() {
        listShow = false;
      });
    }
    slotsElements.clear();
    alreadyBooked.clear();
    filter.value = setFilter;
    bookingElements.clear();
    bookingList.clear();
    slotsList.clear();
    finalAvailabilityList.clear();
    checkEntireDayAvailability.clear();

    try {
      await _server
          .collection("GroundBookings")
          .where("bookingCreated",
              isLessThanOrEqualTo: setFilter
                  ? DateTime(period.year, period.month, period.day)
                  : DateTime(period.year, period.month, period.day + 30))
          .where('bookingCreated',
              isGreaterThanOrEqualTo: setFilter
                  ? DateTime(period.year, period.month, period.day)
                  : DateTime(period.year, period.month, period.day))
          .where('groundID', isEqualTo: widget.groundID)
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
                        checkEntireDayAvailability
                            .add(bookingElements[i]["date"])
                      },
                    getAllSlots(period: period, setFilter: setFilter)
                  }
                else
                  {getAllSlots(period: period, setFilter: setFilter)},
              });
    } catch (error) {
      return;
    }
  }

  @override
  void initState() {
    collectBookings(
        period: DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day),
        setFilter: false);
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
          title: Text(widget.groundName),
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
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Pull to refresh'),
                  Icon(Icons.refresh),
                ],
              ),
              InkWell(
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now().add(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 90)));
                  if (pickedDate != null) {
                    collectBookings(
                        period: DateTime(
                            pickedDate.year, pickedDate.month, pickedDate.day),
                        setFilter: true);
                  }
                },
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height / 12,
                      width: MediaQuery.of(context).size.width,
                      child: Card(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              "Select Particular Date View Slots",
                              style: TextStyle(
                                  fontFamily: "DMSans",
                                  fontSize:
                                      MediaQuery.of(context).size.height / 50),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.green,
                            )
                          ],
                        ),
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
                          Row(children: [
                            Icon(
                              Icons.rectangle,
                              color: Colors.grey,
                            ),
                            Text("Not Available")
                          ]),
                        ],
                      ),
                    ),
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
      case "Not Available":
        {
          return Colors.grey;
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

  Future<void> getAllSlots(
      {required DateTime period, required bool setFilter}) async {
    var daySlots = [];

    var collection = _server.collection('SportistanPartners');
    var docSnapshot = await collection.doc(widget.groundID).get();

    Map<String, dynamic> data = docSnapshot.data()!;
    slotsElements = data;

    late int size;
    if (setFilter) {
      size = 1;
    } else {
      size = 30;
    }
    for (int i = 0; i < size; i++) {
      DateTime date = DateTime(period.year, period.month, period.day)
          .add(Duration(days: i));
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
          availableSlots(period: period, setFilter: setFilter);
        }
      }
    }
    availableSlots(period: period, setFilter: setFilter);
  }

  void availableSlots({required DateTime period, required bool setFilter}) {
    var daySlots = [];

    late int size;
    if (setFilter) {
      size = 1;
    } else {
      size = 30;
    }
    for (int i = 0; i < size; i++) {
      DateTime date = DateTime(period.year, period.month, period.day)
          .add(Duration(days: i));
      if (slotsElements[DateFormat.EEEE().format(date)] != null) {
        daySlots = slotsElements[DateFormat.EEEE().format(date)];
      } else {
        daySlots = [];
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ground Slots Missing')));
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
            slotStatus: i == 0
                ? slotStatusCheck(
                    slotTime: bookingElements[bookingCreated]
                        ["nonFormattedTime"],
                    index: j,
                    slotStatus: bookingElements[bookingCreated]["slotStatus"],
                    setFilter: setFilter)
                : bookingElements[bookingCreated]["slotStatus"],
            slotTime: bookingElements[bookingCreated]["slotTime"],
            slotPrice: bookingElements[bookingCreated]["slotPrice"],
            feesDue: bookingElements[bookingCreated]["feesDue"],
            entireDayBooked: bookingElements[bookingCreated]
                ["entireDayBooking"],
            nonFormattedTime: bookingElements[bookingCreated]
                ["nonFormattedTime"],
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
            slotStatus: i == 0
                ? slotStatusCheck(
                    slotTime: slotsElements[DateFormat.EEEE().format(date)][j]
                        ["nonFormattedTime"],
                    slotStatus: 'Available',
                    setFilter: setFilter,
                    index: j)
                : 'Available',
            slotTime: slotsElements[DateFormat.EEEE().format(date)][j]["time"],
            slotPrice: slotsElements[DateFormat.EEEE().format(date)][j]
                ["price"],
            feesDue: slotsElements[DateFormat.EEEE().format(date)][j]["price"],
            entireDayBooked: false,
            nonFormattedTime: slotsElements[DateFormat.EEEE().format(date)][j]
                ["nonFormattedTime"],
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
    collectBookings(
        period: DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day),
        setFilter: false);
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
                                              checkStatusSlotAndMove(
                                                  bookings: bookings);
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
                                          bookings.slotStatus == 'Not Available'
                                              ? Container()
                                              : bookings.slotStatus ==
                                                      "Fees Due"
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
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .black45,
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
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .black54,
                                                              fontFamily:
                                                                  "DMSans"),
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
                                                                  fontSize: MediaQuery.of(
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
                                                                  fontSize: MediaQuery.of(
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
                                                      : bookings.slotStatus ==
                                                              "Booked"
                                                          ? Container()
                                                          : bookings.feesDue !=
                                                                  0
                                                              ? Row(
                                                                  children: [
                                                                    Text(
                                                                      bookings.entireDayBooked
                                                                          ? 'Entire Day Due '
                                                                          : "Fees Due :",
                                                                      style: TextStyle(
                                                                          fontSize: MediaQuery.of(context).size.width /
                                                                              38,
                                                                          color: bookings.entireDayBooked
                                                                              ? Colors.red
                                                                              : Colors.red[200],
                                                                          fontFamily: "DMSans"),
                                                                    ),
                                                                    Text(
                                                                      'Rs. ${bookings.feesDue}',
                                                                      style: TextStyle(
                                                                          fontSize: MediaQuery.of(context).size.width /
                                                                              38,
                                                                          color: bookings.entireDayBooked
                                                                              ? Colors.red
                                                                              : Colors.red[200],
                                                                          fontFamily: "DMSans"),
                                                                    ),
                                                                  ],
                                                                )
                                                              : Text(
                                                                  "No Due",
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          MediaQuery.of(context).size.width /
                                                                              38,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .green,
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
                                                    groundID: widget.groundID,
                                                    groundName:
                                                        widget.groundName,
                                                  ),
                                                )).then((value) => {
                                                  collectBookings(
                                                      period: DateTime(
                                                          DateTime.now().year,
                                                          DateTime.now().month,
                                                          DateTime.now().day),
                                                      setFilter: false)
                                                });
                                          }
                                          if (Platform.isIOS) {
                                            Navigator.push(
                                                context,
                                                CupertinoPageRoute(
                                                  builder: (context) =>
                                                      BookEntireDay(
                                                    date: group,
                                                    groundID: widget.groundID,
                                                    groundName:
                                                        widget.groundName,
                                                  ),
                                                )).then((value) => {
                                                  collectBookings(
                                                      period: DateTime(
                                                          DateTime.now().year,
                                                          DateTime.now().month,
                                                          DateTime.now().day),
                                                      setFilter: false)
                                                });
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
              builder: (context) => BookASlot(
                    group: bookings.group,
                    date: bookings.date,
                    slotID: bookings.slotID,
                    slotTime: bookings.slotTime,
                    slotStatus: bookings.slotStatus,
                    groundID: widget.groundID,
                    groundAddress: widget.groundAddress,
                    groundName: widget.groundName,
                    bookingID: bookings.bookingID,
                    slotPrice: bookings.slotPrice,
                    groundType: widget.groundType,
                    nonFormattedTime: bookings.nonFormattedTime,
                  ))).then((value) => {
            collectBookings(
                period: DateTime(DateTime.now().year, DateTime.now().month,
                    DateTime.now().day),
                setFilter: false)
          });
    }
    if (Platform.isIOS) {
      Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => BookASlot(
              group: bookings.group,
              date: bookings.date,
              slotID: bookings.slotID,
              slotTime: bookings.slotTime,
              slotStatus: bookings.slotStatus,
              groundID: widget.groundID,
              groundAddress: widget.groundAddress,
              groundName: widget.groundName,
              bookingID: bookings.bookingID,
              slotPrice: bookings.slotPrice,
              groundType: widget.groundType,
              nonFormattedTime: bookings.nonFormattedTime,
            ),
          )).then((value) => {
            collectBookings(
                period: DateTime(DateTime.now().year, DateTime.now().month,
                    DateTime.now().day),
                setFilter: false)
          });
    }
  }

  String slotStatusCheck(
      {required String slotTime,
      required String slotStatus,
      required int index,
      required bool setFilter}) {
    if (!setFilter) {
      DateTime now = DateTime.now();

      DateTime slotTimeSet = DateTime.parse(slotTime);
      DateTime dateTime = DateTime(now.year, now.month, now.day,
          slotTimeSet.hour, slotTimeSet.minute, 00, 00, 000);

      int difference = DateTime.now().difference(dateTime).inMinutes;
      if (difference < 0) {
        if (slotStatus == 'Half Booked') {
          checkEntireDayAvailability.add(DateTime(
            now.year,
            now.month,
            now.day,
          ).toString());
        } else if (slotStatus == 'Booked') {
          checkEntireDayAvailability.add(DateTime(
            now.year,
            now.month,
            now.day,
          ).toString());
        }
        return slotStatus;
      } else {
        checkEntireDayAvailability.add(DateTime(
          now.year,
          now.month,
          now.day,
        ).toString());

        return 'Not Available';
      }
    } else {
      return slotStatus;
    }
  }
}

class MyBookings {
  final String slotID;
  final String nonFormattedTime;
  final String group;
  final String date;
  final num slotPrice;
  final num feesDue;
  final bool entireDayBooked;
  final String slotStatus;
  final String slotTime;
  final String bookingID;

  MyBookings(
      {required this.slotID,
      required this.nonFormattedTime,
      required this.entireDayBooked,
      required this.group,
      required this.feesDue,
      required this.date,
      required this.bookingID,
      required this.slotPrice,
      required this.slotStatus,
      required this.slotTime});
}
