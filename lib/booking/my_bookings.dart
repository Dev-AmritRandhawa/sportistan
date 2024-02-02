import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sliding_up_panel2/sliding_up_panel2.dart';
import 'package:SportistanPro/booking/booking_info.dart';
import 'package:SportistanPro/widgets/page_route.dart';

class Bookings extends StatefulWidget {
  const Bookings({super.key});

  @override
  State<Bookings> createState() => _BookingsState();
}

class _BookingsState extends State<Bookings> {
  final _server = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  DateTime dateTime = DateTime.now();
  ValueNotifier<bool> myBookings = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.green,
        body: SlidingUpPanel(
          borderRadius: const BorderRadius.only(
              topRight: Radius.circular(30), topLeft: Radius.circular(30)),
          minHeight: MediaQuery.of(context).size.height / 1.2,
          maxHeight: MediaQuery.of(context).size.height / 1.2,
          panelBuilder: () => panel(),
          body: SafeArea(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.calendar_today, color: Colors.white),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("Bookings",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: "DMSans",
                            fontSize: MediaQuery.of(context).size.height / 25,
                          ) //TextStyle
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }

  Color setStatusColor(String result) {
    switch (result) {
      case "Booked":
        {
          return Colors.red;
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
    return Colors.green;
  }

  panel() {
    return ValueListenableBuilder(
      valueListenable: myBookings,
      builder: (context, value, child) {
        return StreamBuilder<QuerySnapshot>(
            stream: _server
                .collection("GroundBookings")
                .where("bookingCreated",
                    isLessThanOrEqualTo:
                        DateTime(dateTime.year, dateTime.month, dateTime.day)
                            .add(const Duration(days: 30)))
                .where('userID', isEqualTo: _auth.currentUser!.uid)
                .orderBy('bookingCreated', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              return snapshot.hasData
                  ? snapshot.data!.docs.isEmpty
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(
                              child: Text("No Bookings Found"),
                            )
                          ],
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            DocumentSnapshot doc = snapshot.data!.docs[index];

                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: InkWell(
                                onTap: doc["isBookingCancelled"]
                                    ? null
                                    : () {
                                        PageRouter.push(
                                            context,
                                            BookingInfo(
                                              bookingID: doc["bookingID"],
                                            ));
                                      },
                                child: Card(
                                  elevation: 1.0,
                                  child: Column(
                                    children: [
                                      const Text(
                                        "Booked by",
                                        style: TextStyle(
                                            fontFamily: "DMSans",
                                            color: Colors.black45),
                                      ),
                                      Text(
                                        doc["bookingPerson"],
                                        style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.black87,
                                            fontFamily: "DMSans",
                                            fontWeight: FontWeight.bold),
                                      ),
                                      doc["isBookingCancelled"]
                                          ? const Text(
                                              "Cancelled",
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.red,
                                                  fontFamily: "DMSans",
                                                  fontWeight: FontWeight.bold),
                                            )
                                          : Container(),
                                      ListTile(
                                        title: Text(doc["slotTime"],
                                            style:
                                                const TextStyle(fontSize: 20)),
                                        subtitle: Text(DateFormat.yMMMMEEEEd()
                                            .format(
                                                DateTime.parse(doc["group"]))),
                                        trailing:
                                            const Icon(Icons.arrow_forward_ios),
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              setStatusColor(doc["slotStatus"]),
                                          child: const Icon(
                                              Icons.calendar_today,
                                              color: Colors.white),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(doc["slotStatus"],
                                                style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: "DMSans")),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: doc["feesDue"] == 0
                                                ? const Text(
                                                    "Paid",
                                                    style: TextStyle(
                                                        color: Colors.green),
                                                  )
                                                : Row(
                                                    children: [
                                                      Text(
                                                        "Due Amount : Rs.",
                                                        style: TextStyle(
                                                          color: Colors
                                                              .red.shade200,
                                                        ),
                                                      ),
                                                      Text(
                                                          doc["feesDue"]
                                                              .toString(),
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .red.shade200,
                                                              fontSize: 15,
                                                              fontFamily:
                                                                  "DMSans")),
                                                    ],
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          })
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "No Bookings Found",
                          style: TextStyle(fontFamily: "DMSans"),
                        )
                      ],
                    );
            });
      },
    );
  }
}
