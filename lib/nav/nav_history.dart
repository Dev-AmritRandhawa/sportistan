import 'package:chips_choice/chips_choice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sportistan/booking/booking_entire_day_info.dart';
import 'package:sportistan/booking/booking_info.dart';
import 'package:sportistan/widgets/page_route.dart';


class NavHistory extends StatefulWidget {
  const NavHistory({super.key});

  @override
  State<NavHistory> createState() => _NavHistoryState();
}

class _NavHistoryState extends State<NavHistory> {
  final _server = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  DateTime dateTime = DateTime.now();
  ValueNotifier<bool> showFilter = ValueNotifier<bool>(false);
  var options = [
    "Today",
    "Yesterday",
    "Tomorrow",
    "Past 30 Days",
    "Next 30 Days"
  ];
  var tag = 3;
  var options3 = [
    'Cricket',
    'Football',
    'Tennis',
    'Hockey',
    'Badminton',
    'Volleyball',
    'Swimming',
  ];
  var tag3 = 0;
  var filterDuplicate = [];
  ValueNotifier<bool> bookingDataListener = ValueNotifier<bool>(false);

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    streamOfBookings();
    super.initState();
  }

  List<BookingsData> bookingData = [];
  List<dynamic> allSlotsRef = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.calendar_today, color: Colors.black),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("Booking History",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontFamily: "DMSans",
                              fontSize: MediaQuery.of(context).size.height / 25,
                            ) //TextStyle),
                        ),
                      ),
                    ],
                  ),
                  ValueListenableBuilder(
                    valueListenable: showFilter,
                    builder: (context, value, child) => value
                        ? DelayedDisplay(
                      child: Column(
                        children: [
                          ContentNew(
                            title: 'Select Time Range',
                            child: ChipsChoice<int>.single(
                              value: tag,
                              onChanged: (val) {
                                setState(() {
                                  tag = val;
                                  streamOfBookings();
                                });
                              },
                              choiceItems: C2Choice.listFrom<int, String>(
                                source: options,
                                value: (i, v) => i,
                                label: (i, v) => v,
                                tooltip: (i, v) => v,
                              ),
                              choiceStyle: C2ChipStyle.toned(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(5),
                                ),
                              ),
                              wrapped: true,
                            ),
                          ),
                          ContentNew(
                            title: 'Sports Type',
                            child: ChipsChoice<int>.single(
                              value: tag3,
                              onChanged: (val) => setState(() {
                                tag3 = val;
                                streamOfBookings();
                              }),
                              choiceItems: C2Choice.listFrom<int, String>(
                                source: options3,
                                value: (i, v) => i,
                                label: (i, v) => v,
                                tooltip: (i, v) => v,
                              ),
                              choiceStyle: C2ChipStyle.toned(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(5),
                                ),
                              ),
                              wrapped: true,
                            ),
                          ),
                          Card(
                            color: Colors.red.shade400,
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("   Close Filter Tray",
                                      style: TextStyle(color: Colors.white)),
                                  IconButton(
                                      onPressed: () {
                                        showFilter.value = false;
                                      },
                                      icon: const Icon(
                                        Icons.clear,
                                        color: Colors.white,
                                      )),
                                ]),
                          )
                        ],
                      ),
                    )
                        : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 15.0),
                            child: Text(
                              "Filter",
                              style:
                              TextStyle(fontFamily: "DMSans", fontSize: 18),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 15),
                            child: CircleAvatar(
                              child: IconButton(
                                  onPressed: () {
                                    showFilter.value = true;
                                  },
                                  icon: const Icon(Icons.filter_alt_outlined)),
                            ),
                          )
                        ]),
                  ),
                  const Divider(),
                  ValueListenableBuilder(
                    valueListenable: bookingDataListener,
                    builder: (context, value, child) {
                      return value
                          ? bookingData.isEmpty
                          ? const Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.error,
                              color: Colors.orange,
                              size: 50,
                            ),
                            Text(" No Bookings",
                                style: TextStyle(
                                    fontFamily: "DMSans",
                                    fontSize: 22,
                                    color: Colors.orange)),
                          ],
                        ),
                      )
                          : Column(
                        children: [
                          ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: bookingData.length,
                              itemBuilder: (context, index) {
                                int bookingIndex = index + 1;
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: InkWell(
                                    onTap: bookingData[index]
                                        .isBookingCancelled
                                        ? null
                                        : () {
                                      checkBookingType(
                                          entireDayBooked:
                                          bookingData[index]
                                              .entireDayBooking,
                                          bookingID: bookingData[index]
                                              .bookingID);
                                    },
                                    child: Card(
                                      color: Colors.grey.shade50,
                                      child: Column(
                                        children: [
                                          CircleAvatar(
                                              backgroundColor:
                                              bookingData[index]
                                                  .isBookingCancelled
                                                  ? Colors.red
                                                  : Colors.green,
                                              child: Text(
                                                bookingIndex.toString(),
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              )),
                                          const Text(
                                            "Booked by",
                                            style: TextStyle(
                                                fontFamily: "DMSans",
                                                color: Colors.black45),
                                          ),
                                          Text(
                                            bookingData[index].bookingPerson,
                                            style: const TextStyle(
                                                fontSize: 18,
                                                color: Colors.black87,
                                                fontFamily: "DMSans",
                                                fontWeight: FontWeight.bold),
                                          ),
                                          bookingData[index]
                                              .isBookingCancelled
                                              ? const Text(
                                            "Cancelled",
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.red,
                                                fontFamily: "DMSans",
                                                fontWeight:
                                                FontWeight.bold),
                                          )
                                              : Container(),
                                          Padding(
                                            padding:
                                            const EdgeInsets.all(8.0),
                                            child: Text(
                                                bookingData[index].groundName,
                                                style: const TextStyle(
                                                    fontFamily: "DMSans"),softWrap: true),
                                          ),
                                          Card(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(8.0),
                                              child: Text(
                                                  bookingData[index]
                                                      .groundType,
                                                  style: const TextStyle(
                                                      fontFamily: "DMSans")),
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            children: [
                                              const Text("Paid : ",
                                                  style: TextStyle(
                                                      fontFamily: 'DMSans',
                                                      color: Colors.green)),
                                              Text(
                                                  DateFormat.yMEd()
                                                      .format(
                                                      bookingData[index]
                                                          .bookedDate)
                                                      .toString(),
                                                  style: const TextStyle(
                                                    color: Colors.black45,
                                                  )),
                                              Text(
                                                  ' ${DateFormat.jms().format(bookingData[index].bookedDate)}',
                                                  style: const TextStyle(
                                                    color: Colors.black45,
                                                  )),
                                            ],
                                          ),
                                          bookingData[index].entireDayBooking
                                              ? Card(
                                              color: Colors.indigo,
                                              child: Padding(
                                                padding:
                                                const EdgeInsets.all(
                                                    8.0),
                                                child: Text(
                                                    "Entire Day Booked - ${DateFormat.yMMMMEEEEd().format(bookingData[index].bookingCreated)}",
                                                    style:
                                                    const TextStyle(
                                                        color: Colors
                                                            .white)),
                                              ))
                                              : Container(),
                                          bookingData[index].entireDayBooking
                                              ? Container()
                                              : ListTile(
                                            title: Text(
                                                bookingData[index]
                                                    .slotTime,
                                                style: const TextStyle(
                                                    fontSize: 25)),
                                            subtitle: Text(
                                              DateFormat.yMMMMEEEEd()
                                                  .format(bookingData[
                                              index]
                                                  .bookingCreated),
                                              style: const TextStyle(
                                                  fontFamily: "DMSans",
                                                  fontSize: 20),
                                            ),
                                            trailing: const Icon(
                                                Icons.info_outline),
                                          ),
                                          bookingData[index].entireDayBooking
                                              ? Container()
                                              : Row(
                                            children: [
                                              Padding(
                                                padding:
                                                const EdgeInsets
                                                    .all(8.0),
                                                child: Text(
                                                    '(${bookingData[index].slotStatus})',
                                                    style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                        FontWeight
                                                            .bold,
                                                        color: setStatusColor(
                                                            bookingData[
                                                            index]
                                                                .slotStatus),
                                                        fontFamily:
                                                        "DMSans")),
                                              ),
                                              Padding(
                                                padding:
                                                const EdgeInsets
                                                    .all(8.0),
                                                child: bookingData[
                                                index]
                                                    .feesDue ==
                                                    0
                                                    ? const Text(
                                                  "Paid",
                                                  style: TextStyle(
                                                      color: Colors
                                                          .green),
                                                )
                                                    : Row(
                                                  children: [
                                                    Text(
                                                      "Due Amount : Rs.",
                                                      style:
                                                      TextStyle(
                                                        color: Colors
                                                            .red
                                                            .shade200,
                                                      ),
                                                    ),
                                                    Text(
                                                        bookingData[
                                                        index]
                                                            .feesDue
                                                            .toString(),
                                                        style: TextStyle(
                                                            color: Colors
                                                                .red
                                                                .shade200,
                                                            fontSize:
                                                            15,
                                                            fontFamily:
                                                            "DMSans")),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          bookingData[index].entireDayBooking
                                              ? SizedBox(
                                            width: double.infinity,
                                            height:
                                            MediaQuery.of(context)
                                                .size
                                                .height /
                                                15,
                                            child: ListView.builder(
                                              scrollDirection:
                                              Axis.horizontal,
                                              shrinkWrap: true,
                                              itemCount:
                                              bookingData[index]
                                                  .allSlotsRef
                                                  .length,
                                              itemBuilder:
                                                  (context, count) {
                                                return Padding(
                                                  padding:
                                                  const EdgeInsets
                                                      .all(8.0),
                                                  child: OutlinedButton(
                                                      onPressed: null,
                                                      child: Text(bookingData[
                                                      index]
                                                          .allSlotsRef[
                                                      count]
                                                          .toString())),
                                                );
                                              },
                                            ),
                                          )
                                              : Container(),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                          SizedBox(
                            height: MediaQuery.of(context).size.height / 6,
                          )
                        ],
                      )
                          : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                                strokeWidth: 1, color: Colors.green),
                          ],
                        ),
                      );
                    },
                  )
                ],
              ),
            )));
  }

  Color setStatusColor(String result) {
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

  void checkBookingType(
      {required bool entireDayBooked, required String bookingID}) {
    if (entireDayBooked) {
      PageRouter.push(
          context,
          BookingEntireDayInfo(
            bookingID: bookingID,
          ));
    } else {
      PageRouter.push(
          context,
          BookingInfo(
            bookingID: bookingID,
          ));
    }
  }

  streamOfBookings() async {
    await _server
        .collection("GroundBookings")
        .where('bookingCreated',
        isLessThanOrEqualTo: createFilterIsLessThanEqualTo(tag))
        .where('bookingCreated',
        isGreaterThanOrEqualTo: createFilterIsGreaterThanEqualTo(tag))
        .where('userID', isEqualTo: _auth.currentUser!.uid)
        .where('groundType', isEqualTo: createFilterForSportsType(tag3))
        .get()
        .then((value) => {collection(value)});
  }

  createFilterForSportsType(int val) {
    switch (val) {
      case 0:
        {
          return 'Cricket';
        }
      case 1:
        {
          return 'Football';
        }
      case 2:
        {
          return 'Tennis';
        }
      case 3:
        {
          return 'Hockey';
        }
      case 4:
        {
          return 'Badminton';
        }
      case 5:
        {
          return 'Volleyball';
        }
      case 6:
        {
          return 'Swimming';
        }
    }
  }

  collection(QuerySnapshot<Map<String, dynamic>> value) {
    bookingDataListener.value = false;
    bookingData.clear();
    filterDuplicate.clear();
    allSlotsRef.clear();
    for (int i = 0; i < value.docChanges.length; i++) {
      DateTime dt =
      (value.docChanges[i].doc.get('bookedAt') as Timestamp).toDate();
      DateTime dt2 =
      (value.docChanges[i].doc.get('bookingCreated') as Timestamp).toDate();
      if (value.docChanges[i].doc.get('entireDayBooking')) {
        if (!filterDuplicate.contains(value.docChanges[i].doc.get('groupID'))) {
          filterDuplicate.add(value.docChanges[i].doc.get('groupID'));
          bookingData.add(BookingsData(
              isBookingCancelled:
              value.docChanges[i].doc.get('isBookingCancelled'),
              entireDayBooking: value.docChanges[i].doc.get('entireDayBooking'),
              bookingID: value.docChanges[i].doc.get('bookingID'),
              slotTime: value.docChanges[i].doc.get('slotTime'),
              bookingPerson: value.docChanges[i].doc.get('bookingPerson'),
              bookedDate: dt,
              feesDue: value.docChanges[i].doc.get('feesDue'),
              allSlotsRef: value.docChanges[i].doc.get('includeSlots'),
              slotStatus: value.docChanges[i].doc.get('slotStatus'),
              groundName: value.docChanges[i].doc.get('groundName'),
              bookingCreated: dt2,
              groundType: value.docChanges[i].doc.get('groundType')));
        }
      } else {
        bookingData.add(BookingsData(
            isBookingCancelled:
            value.docChanges[i].doc.get('isBookingCancelled'),
            entireDayBooking: value.docChanges[i].doc.get('entireDayBooking'),
            bookingID: value.docChanges[i].doc.get('bookingID'),
            slotTime: value.docChanges[i].doc.get('slotTime'),
            bookingPerson: value.docChanges[i].doc.get('bookingPerson'),
            bookedDate: dt,
            feesDue: value.docChanges[i].doc.get('feesDue'),
            allSlotsRef: [],
            slotStatus: value.docChanges[i].doc.get('slotStatus'),
            groundName: value.docChanges[i].doc.get('groundName'),
            bookingCreated: dt2,
            groundType: value.docChanges[i].doc.get('groundType')));
      }
    }
    bookingDataListener.value = true;
  }

  createFilterIsLessThanEqualTo(int val) {
    switch (val) {
    //today
      case 0:
        {
          return DateTime(DateTime.now().year, DateTime.now().month,
              DateTime.now().day);
        }
    //yesterday
      case 1:
        {
          return DateTime(
              DateTime.now().year, DateTime.now().month, DateTime.now().day-1);
        }

    //tomorrow
      case 2:
        {
          return DateTime(DateTime.now().year, DateTime.now().month,
              DateTime.now().day + 1);
        }
      case 3:
        {
          return DateTime(DateTime.now().year, DateTime.now().month,
              DateTime.now().day-1);
        }
      case 4:
        {
          return DateTime(DateTime.now().year, DateTime.now().month,
              DateTime.now().day + 31);
        }
    }
  }

  createFilterIsGreaterThanEqualTo(int val) {
    switch (val) {
      case 0:
        {
          return DateTime(
              DateTime.now().year, DateTime.now().month, DateTime.now().day);
        }
      case 1:
        {
          return DateTime(DateTime.now().year, DateTime.now().month,
              DateTime.now().day - 1);
        }
      case 2:
        {
          return DateTime(DateTime.now().year, DateTime.now().month,
              DateTime.now().day + 1);
        }
      case 3:
        {
          return DateTime(DateTime.now().year, DateTime.now().month,
              DateTime.now().day - 31);
        }
      case 4:
        {
          return DateTime(DateTime.now().year, DateTime.now().month,
              DateTime.now().day+1);
        }
    }
  }
}

class ContentNew extends StatefulWidget {
  const ContentNew({super.key, required this.child, required this.title});

  final Widget child;
  final String title;

  @override
  State<ContentNew> createState() => _ContentNewState();
}

class _ContentNewState extends State<ContentNew> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                  child: Text(widget.title,
                      style: const TextStyle(
                          fontFamily: "DMSans", color: Colors.black54)),
                ),
              ],
            ),
            Flexible(fit: FlexFit.loose, child: widget.child),
          ],
        ),
      ),
    );
  }
}

class BookingsData {
  final bool isBookingCancelled;
  final bool entireDayBooking;
  final String bookingID;
  final String groundName;
  final String groundType;
  final String slotTime;
  final String bookingPerson;
  final String slotStatus;
  final DateTime bookedDate;
  final DateTime bookingCreated;
  final num feesDue;
  final List<dynamic> allSlotsRef;

  BookingsData(
      {required this.isBookingCancelled,
        required this.entireDayBooking,
        required this.bookingID,
        required this.slotTime,
        required this.groundName,
        required this.groundType,
        required this.slotStatus,
        required this.bookingPerson,
        required this.bookedDate,
        required this.bookingCreated,
        required this.feesDue,
        required this.allSlotsRef});
}
