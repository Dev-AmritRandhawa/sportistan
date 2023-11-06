import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class BookEntireDay extends StatefulWidget {
  final String date;

  final String groundID;

  const BookEntireDay({super.key, required this.date, required this.groundID});

  @override
  State<BookEntireDay> createState() => _BookEntireDayState();
}

class _BookEntireDayState extends State<BookEntireDay> {
  final _server = FirebaseFirestore.instance;

  List finalAvailabilityList = [];

  ValueNotifier<bool> listShow = ValueNotifier<bool>(false);

  int total = 0;

  @override
  void initState() {
    getAllSlots();
    super.initState();
  }

  List daySlots = [];
  TextEditingController priceController = TextEditingController();
  GlobalKey<FormState> priceKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CupertinoButton(
          borderRadius: BorderRadius.zero,
          color: Colors.green,
          onPressed: (){

          }, child: const Text("Create Booking")),
      appBar: AppBar(foregroundColor: Colors.black54,backgroundColor: Colors.white,elevation: 0
          ,title: const Text("Book for Entire Day")
      ),
      body: SafeArea(
          child: ValueListenableBuilder(
            valueListenable: listShow,
            builder: (context, value, child) {
              return value
                  ? dataList()
                  : const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 1,
                  ));
            },
          )),
    );
  }

  dataList() {
    Map groupItemsByCategory(List items) {
      return groupBy(items, (item) => item.group);
    }

    Map groupedItems = groupItemsByCategory(finalAvailabilityList);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          ListView.builder(
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            itemCount: groupedItems.length,
            itemBuilder: (BuildContext context, int index) {
              String group = groupedItems.keys.elementAt(index);
              List bookingGroup = groupedItems[group]!;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8, left: 8),
                    child: Text(
                        "${DateFormat.yMMMd().format(DateTime.parse(widget.date))} (${DateFormat.EEEE().format(DateTime.parse(widget.date))})",
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
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
                          MySlots bookings = bookingGroup[index];
                          return Padding(
                              padding: const EdgeInsets.only(left: 2, right: 2),
                              child: Column(
                                children: [
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(
                                          color: Colors.green, width: 2),
                                    ),
                                    onPressed: () {},
                                    child: Text(
                                      bookings.slotTime,
                                      style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: MediaQuery.of(context)
                                              .size
                                              .width /
                                              30),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "Slot ${index + 1} :",
                                        style: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                .size
                                                .width /
                                                38,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                            fontFamily: "DMSans"),
                                      ),
                                      Text(
                                        bookings.slotPrice.toString(),
                                        style: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                .size
                                                .width /
                                                38,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                            fontFamily: "DMSans"),
                                      ),
                                    ],
                                  ),
                                ],
                              ));
                        }),
                  ),
                ],
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: listShow,
            builder: (context, value, child) {
              listShow.value = true;
              return value
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("Amount to pay for entire day \nRs.${total.toString()}",
                            style: const TextStyle(
                                fontSize: 22, fontFamily: "DMSans")),
                      )),
                ],
              )
                  : Container();
            },
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: priceKey,
              child: SizedBox(
                width: MediaQuery.of(context).size.width / 1.2,
                child: TextFormField(
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Team name required.";
                    } else if (value.length <= 2) {
                      return "Enter Correct Name.";
                    } else {
                      return null;
                    }
                  },
                  controller: priceController,
                  onChanged: (data) {
                    priceKey.currentState!.validate();
                  },
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                      fillColor: Colors.white,
                      border: InputBorder.none,
                      errorStyle: TextStyle(color: Colors.white),
                      labelText: "Amount*",
                      filled: true,
                      labelStyle: TextStyle(color: Colors.black)),
                ),
              ),
            ),
          ),  const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Would you like to update amount?",
                style: TextStyle(
                    fontSize: 16, fontFamily: "DMSans")),
          ), MaterialButton(
              elevation: 0,
              color: Colors.green,
              shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                      25)),
              onPressed: () {

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                    const SnackBar(
                      content:
                      Text("Amount Updated"),
                      backgroundColor: Colors.green,
                    ));
              },
              child: const Text(
                "Update Amount",
                style: TextStyle(
                    color: Colors.white),
              )),
        ],
      ),
    );
  }

  Future<void> getAllSlots() async {
    var collection = _server.collection('SportistanPartners');
    var docSnapshot = await collection.doc(widget.groundID).get();

    Map<String, dynamic> data = docSnapshot.data()!;

    daySlots = data[DateFormat.EEEE().format(DateTime.parse(widget.date))];

    for (int j = 0; j < daySlots.length; j++) {
      if (daySlots.isNotEmpty) {
        int slotAmount =
        data[DateFormat.EEEE().format(DateTime.parse(widget.date))][j]
        ["price"];
        total = slotAmount;
        total + total;
        finalAvailabilityList.add(MySlots(
          slotID: data[DateFormat.EEEE().format(DateTime.parse(widget.date))][j]
          ["slotID"],
          group: data.toString(),
          date: data.toString(),
          bookingID: '',
          slotStatus: 'Available',
          slotTime: data[DateFormat.EEEE().format(DateTime.parse(widget.date))]
          [j]["time"],
          slotPrice: data[DateFormat.EEEE().format(DateTime.parse(widget.date))]
          [j]["price"],
          feesDue: data[DateFormat.EEEE().format(DateTime.parse(widget.date))]
          [j]["price"],
        ));
      }
    }

    listShow.value = true;
  }
}

class MySlots {
  final String slotID;
  final String group;
  final String date;
  final int slotPrice;
  final int feesDue;
  final String slotStatus;
  final String slotTime;
  final String bookingID;

  MySlots(
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
