import 'dart:io';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttercontactpicker/fluttercontactpicker.dart';
import 'package:intl/intl.dart';
import 'package:sliding_up_panel2/sliding_up_panel2.dart';
import 'package:sportistan/booking/unique.dart';
import 'package:sportistan/payment/payment_gateway.dart';
import '../widgets/errors.dart';
import '../widgets/page_route.dart';
import 'booking_entire_day_info.dart';

class BookEntireDay extends StatefulWidget {
  final String date;
  final String groundID;
  final String groundName;

  const BookEntireDay(
      {super.key,
      required this.date,
      required this.groundID,
      required this.groundName});

  @override
  State<BookEntireDay> createState() => _BookEntireDayState();
}

class _BookEntireDayState extends State<BookEntireDay> {
  final _server = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List finalAvailabilityList = [];

  ValueNotifier<bool> listShow = ValueNotifier<bool>(false);
  ValueNotifier<bool> switchBuilder = ValueNotifier<bool>(false);
  ValueNotifier<bool> amountUpdater = ValueNotifier<bool>(false);
  ValueNotifier<bool> panelLoad = ValueNotifier<bool>(false);
  ValueNotifier<bool> checkBoxListener = ValueNotifier<bool>(true);

  bool updateSmsAlert = true;

  late num finalDeduction;

  late num serviceChargePay;

  late String refID;

  @override
  void initState() {
    getAllSlots();
    super.initState();
  }

  @override
  void dispose() {
    numberControllerAA.dispose();
    notesTeamAA.dispose();
    nameControllerAA.dispose();
    super.dispose();
  }

  PanelController pc = PanelController();
  TextEditingController numberControllerAA = TextEditingController();
  TextEditingController nameControllerAA = TextEditingController();
  GlobalKey<FormState> nameKeyAA = GlobalKey<FormState>();
  GlobalKey<FormState> numberKeyAA = GlobalKey<FormState>();
  TextEditingController notesTeamAA = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CupertinoButton(
              color: Colors.indigo,
              child: const Text("Book For Entire Day"),
              onPressed: () {
                if (nameKeyAA.currentState!.validate() &
                    numberKeyAA.currentState!.validate() ) {
                  _checkBalance();
                } else {
                  Errors.flushBarInform(
                      "Please Fill The Details", context, "Error");
                }
              }),
        ),
        appBar: AppBar(
            foregroundColor: Colors.black54,
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text("Book for Entire Day")),
        body: SlidingUpPanel(
          panelBuilder: () => panel(),
          minHeight: 0,
          maxHeight: MediaQuery.of(context).size.height,
          controller: pc,
          body: SafeArea(
              child: ValueListenableBuilder(
            valueListenable: listShow,
            builder: (context, value, child) {
              return value
                  ? SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          const Text("Entire Day Price",
                              style: TextStyle(
                                  fontSize: 16, fontFamily: "DMSans")),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Rs.${entireDayAmount.toString()}',
                                style: const TextStyle(fontSize: 24)),
                          ),
                          dataList()
                        ],
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                      strokeWidth: 1,
                    ));
            },
          )),
        ));
  }

  dataList() {
    Map groupItemsByCategory(List items) {
      return groupBy(items, (item) => item.group);
    }

    Map groupedItems = groupItemsByCategory(finalAvailabilityList);

    return SingleChildScrollView(
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
                                    onPressed: null,
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
                                ],
                              ));
                        }),
                  ),
                ],
              );
            },
          ),
          Column(
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                child: Card(
                  color: Colors.grey.shade100,
                  child: Column(
                    children: [

                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Form(
                          key: nameKeyAA,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width / 1.2,
                            child: TextFormField(
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return "Name required.";
                                } else if (value.length <= 2) {
                                  return "Enter Correct Name.";
                                } else {
                                  return null;
                                }
                              },
                              controller: nameControllerAA,
                              onChanged: (data) {
                                nameKeyAA.currentState!.validate();
                              },
                              decoration: const InputDecoration(
                                  fillColor: Colors.white,
                                  labelText: "Contact Person*",
                                  border: InputBorder.none,
                                  errorStyle: TextStyle(color: Colors.red),
                                  filled: true,
                                  labelStyle: TextStyle(color: Colors.black)),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Form(
                          key: numberKeyAA,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width / 1.2,
                            child: TextFormField(
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return "Number required.";
                                } else if (value.length <= 9) {
                                  return "Enter 10 digits.";
                                } else {
                                  return null;
                                }
                              },
                              controller: numberControllerAA,
                              onChanged: (data) {
                                numberKeyAA.currentState!.validate();
                              },
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              autofillHints: const [
                                AutofillHints.telephoneNumberLocal
                              ],
                              decoration: InputDecoration(
                                  prefixIcon: IconButton(
                                      onPressed: () {
                                        checkPermissionForContacts(
                                            numberControllerAA);
                                      },
                                      icon: const Icon(Icons.contacts,
                                          color: Colors.blue)),
                                  fillColor: Colors.white,
                                  border: InputBorder.none,
                                  errorStyle:
                                      const TextStyle(color: Colors.red),
                                  filled: true,
                                  labelText: "Contact Number*",
                                  labelStyle:
                                      const TextStyle(color: Colors.black)),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          child: TextFormField(
                            controller: notesTeamAA,
                            decoration: const InputDecoration(
                              fillColor: Colors.white,
                              border: InputBorder.none,
                              errorStyle: TextStyle(color: Colors.red),
                              filled: true,
                              hintText: "Notes (Optional)",
                              hintStyle: TextStyle(color: Colors.black45),
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 40),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height / 8,
              )
            ],
          ),
        ],
      ),
    );
  }

  List allData = [];
  late num entireDayAmount;
  late num balance;
  late num partnerCommission;
  late num serviceCharge;
  late String groundType;
  late String name;
  late num result;

  Future<void> _checkBalance() async {
    try {
      await _server
          .collection('SportistanUsers')
          .where('userID', isEqualTo: _auth.currentUser!.uid)
          .get()
          .then((value) => {
                balance = value.docChanges.first.doc.get('sportistanCredit'),
                refID = value.docChanges.first.doc.id,
                name = value.docChanges.first.doc.get('name'),
              });

      result = entireDayAmount / 100;
      serviceCharge = result * partnerCommission.toInt();

      pc.open();
      panelLoad.value = true;
    } catch (e) {
      return;
    }
  }

  panel() {
    return Scaffold(
      body: SingleChildScrollView(
        child: ValueListenableBuilder(
          valueListenable: panelLoad,
          builder: (context, value, child) => value
              ? Column(children: [
                  const Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Text(
                          'Payment Summary',
                          style: TextStyle(
                              fontFamily: "DMSans",
                              fontSize: 25,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      child: Column(children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Date',
                                style: TextStyle(
                                  fontFamily: "DMSans",
                                  fontSize: 20,
                                  color: Colors.black,
                                ),
                                softWrap: true,
                              ),
                              Text(
                                DateFormat.yMMMMEEEEd()
                                    .format(DateTime.parse((widget.date))),
                                style: const TextStyle(
                                  fontFamily: "DMSans",
                                  fontSize: 20,
                                  color: Colors.black,
                                ),
                                softWrap: true,
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Sub Total",
                          style: TextStyle(
                            fontFamily: "DMSans",
                            fontSize: 18,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          "₹$entireDayAmount",
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "GST",
                          style: TextStyle(
                            fontFamily: "DMSans",
                            fontSize: 18,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          "₹0",
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Grand Total",
                          style: TextStyle(
                            fontFamily: "DMSans",
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          "₹$entireDayAmount",
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Payable Later",
                          style: TextStyle(
                            fontFamily: "DMSans",
                            fontSize: 18,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          "₹${entireDayAmount - serviceCharge}",
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Service Charged",
                          style: TextStyle(
                            fontFamily: "DMSans",
                            fontSize: 18,
                            color: Colors.orangeAccent,
                          ),
                        ),
                        Text(
                          "₹$serviceCharge",
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.orangeAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Text(
                              "Payable Now",
                              style: TextStyle(
                                fontFamily: "DMSans",
                                fontSize: 18,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            ValueListenableBuilder(
                              valueListenable: checkBoxListener,
                              builder: (context, value, child) {
                                serviceChargePay = serviceCharge;
                                if (value) {
                                  if (serviceChargePay <= balance) {
                                    serviceChargePay = 0;

                                    finalDeduction = balance - serviceChargePay;
                                  } else {
                                    serviceChargePay =
                                        serviceChargePay - balance;
                                    finalDeduction = serviceChargePay - balance;
                                  }
                                } else {
                                  finalDeduction = balance;
                                }

                                return value
                                    ? Text(
                                        "₹$serviceChargePay ",
                                        style: const TextStyle(
                                          fontSize: 22,
                                          color: Colors.green,
                                        ),
                                      )
                                    : Text(
                                        "₹$serviceCharge",
                                        style: const TextStyle(
                                          fontSize: 22,
                                          color: Colors.green,
                                        ),
                                      );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: checkBoxListener,
                    builder: (context, value, child) => value
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                                Padding(
                                  padding: EdgeInsets.only(right: 8.0),
                                  child: Text('Credits Applied',
                                      style: TextStyle(color: Colors.green)),
                                )
                              ])
                        : const Text(''),
                  ),
                  Card(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Text('Sportistan Credits'),
                          ),
                          Row(
                            children: [
                              Text('₹$balance'),
                              ValueListenableBuilder(
                                valueListenable: checkBoxListener,
                                builder: (context, valueBox, child) => Checkbox(
                                    activeColor: Colors.green,
                                    value: valueBox,
                                    onChanged: (v) {
                                      checkBoxListener.value = v!;
                                    }),
                              ),
                            ],
                          ),
                        ]),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height / 8),
                  CupertinoButton(
                      color: Colors.green,
                      onPressed: () async {
                        if (serviceChargePay == 0) {
                          await createBooking();
                        } else {
                          if (Platform.isAndroid) {
                            final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const Gateway(),
                                ));

                            if (result) {
                              if (mounted) {
                                createBooking();
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Payment Failed")));
                              }
                            }
                          } else {
                            final result = await Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => const Gateway(),
                                ));
                            if (result) {
                              if (mounted) {
                                createBooking();
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Payment Failed")));
                              }
                            }
                          }
                        }
                      },
                      child: ValueListenableBuilder(
                          valueListenable: checkBoxListener,
                          builder: (context, value, child) => serviceChargePay ==
                                  0
                              ? const Text('Book Now')
                              : Text(
                                  'Pay ₹${serviceChargePay.round().toString()}'))),
                  TextButton(
                      onPressed: () {
                        showModalBottomSheet(
                            context: context,
                            builder: (ctx) {
                              return const Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Refund & Cancellation Policy',
                                        style: TextStyle(
                                            fontSize: 22, color: Colors.red)),
                                  ),
                                  Icon(Icons.warning, color: Colors.orange),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                        'The booking amount is non-refundable if the booking is cancelled rest of the payment must be paid before the start of booked slot paid.\nRain policy for outdoor sports\nif rain comes before the start of booked slot time then 100% of booking amount will be refunded to your sportistan wallet.\nif rain comes before the half time of booked slot ,then half payment (50%) will be charged of that particular booking & 50% will be refunded by ground owner.\nif rain comes after half time of booked slot, then customer has to pay 100 % of booked slot & no amount will be refunded.',
                                        style: TextStyle(
                                            fontFamily: "DMSans",
                                            fontSize: 16)),
                                  )
                                ],
                              );
                            });
                      },
                      child: const Text(
                        'View Cancellation Policy',
                        style: TextStyle(fontFamily: "DMSans", fontSize: 16),
                      )),
                ])
              : const CircularProgressIndicator(),
        ),
      ),
    );
  }

  Future<void> getAllSlots() async {
    await _server
        .collection("SportistanPartners")
        .where('groundID', isEqualTo: widget.groundID)
        .get()
        .then((value) => {
              allData = value.docChanges.first.doc
                  .get(DateFormat.EEEE().format(DateTime.parse(widget.date))),
              partnerCommission = value.docChanges.first.doc.get('commission'),
              groundType = value.docChanges.first.doc.get('groundType'),
              entireDayAmount = num.parse(value.docChanges.first.doc.get(
                  '${DateFormat.EEEE().format(DateTime.parse(widget.date))}EntireDay')),
            });

    for (int j = 0; j < allData.length; j++) {
      if (allData.isNotEmpty) {
        finalAvailabilityList.add(MySlots(
          slotID: allData[j]["slotID"],
          group: widget.date,
          date: widget.date,
          bookingID: UniqueID.generateRandomString(),
          slotStatus: 'Available',
          slotTime: allData[j]["time"],
          slotPrice: allData[j]["price"],
          feesDue: allData[j]["price"],
          nonFormattedTime: allData[j]["nonFormattedTime"],
        ));
      }
    }
    listShow.value = true;
  }

  List<String> bookingID = [];
  List<String> includeSlots = [];

  PhoneContact? _phoneContact;

  checkPermissionForContacts(TextEditingController controller) async {
    final granted = await FlutterContactPicker.hasPermission();
    if (granted) {
      final PhoneContact contact =
          await FlutterContactPicker.pickPhoneContact();
      setState(() {
        _phoneContact = contact;
      });
      if (_phoneContact!.phoneNumber != null) {
        if (_phoneContact!.phoneNumber!.number!.length > 10) {
          controller.text = _phoneContact!.phoneNumber!.number!
              .substring(3)
              .split(" ")
              .join("");
        } else {
          controller.text =
              _phoneContact!.phoneNumber!.number!.split(" ").join("");
        }
      }
    } else {
      requestPermission(controller);
    }
  }

  requestPermission(controller) async {
    await FlutterContactPicker.requestPermission();
    checkPermissionForContacts(controller);
  }

  String groupID = UniqueID.generateRandomString();

  Future<void> createBooking() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Text("Please Wait",
                style: TextStyle(fontFamily: "DMSans", fontSize: 22)),
            Image.asset('assets/logo.png',
                height: MediaQuery.of(context).size.height / 8),
            AnimatedTextKit(animatedTexts: [
              TyperAnimatedText("We are confirming your booking..",
                  textStyle: const TextStyle(fontSize: 22)),
            ]),
            const CircularProgressIndicator(
                strokeWidth: 1, color: Colors.green),
            CupertinoButton(
                onPressed: () {
                  Navigator.pop(ctx);
                },
                child: const Text('Cancel'))
          ],
        );
      },
    );
    for (int i = 0; i < allData.length; i++) {
      bookingID.add(UniqueID.generateRandomString());
      includeSlots.add(allData[i]["time"]);
    }
    for (int j = 0; j < allData.length; j++) {
      await _server.collection("GroundBookings").add({
        'bookingPerson': name,
        'groundName': widget.groundName,
        'bookingCreated': DateTime.parse(widget.date),
        'bookedAt': DateTime.now(),
        'userID': _auth.currentUser!.uid,
        'group': widget.date,
        'groundType': groundType,
        'isBookingCancelled': false,
        'entireDayBooking': true,
        'groupID': groupID,
        'shouldCountInBalance': false,
        'bookingCommissionCharged': serviceCharge,
        'entireDayBookingID': bookingID,
        'includeSlots': includeSlots,
        'feesDue': entireDayAmount - serviceCharge,
        'ratingGiven': false,
        'rating': 3.0,
        'TeamA': 'Not Applicable',
        'TeamB': "Not Applicable",
        'advancePayment': serviceCharge,
        'bothTeamBooked': true,
        'groundID': widget.groundID,
        "teamA": {
          'teamName': '${nameControllerAA.value.text} Team',
          'personName': nameControllerAA.value.text,
          'phoneNumber': numberControllerAA.value.text,
          "notesTeamA": notesTeamAA.value.text.isNotEmpty
              ? notesTeamAA.value.text.toString()
              : "",
        },
        "teamB": {
          'teamName': '${nameControllerAA.value.text} Team',
          'personName': nameControllerAA.value.text,
          'phoneNumber': numberControllerAA.value.text,
          "notesTeamB": notesTeamAA.value.text.toString(),
        },
        'slotPrice': entireDayAmount,
        'slotStatus': "Booked",
        'slotTime': allData[j]["time"],
        'nonFormattedTime': allData[j]["nonFormattedTime"],
        'slotID': allData[j]["slotID"],
        'bookingID': bookingID[j],
        'date': widget.date,
      });
    }
    await serviceBook();
  }

  Future<void> sendSms({required String number}) async {
    String url =
        'http://api.bulksmsgateway.in/sendmessage.php?user=sportslovez&password=7788330&mobile=$number&message=Your Booking is Confirmed at ${widget.groundName} on ${DateFormat.yMMMd().format(DateTime.parse(widget.date))} for Entire Day Thanks for Choosing Facility on Sportistan&sender=SPTNOT&type=3&template_id=1407170003612415391';
     try {
      await http.post(Uri.parse(url));
      moveToReceipt(bookingID: bookingID[0]);
    } catch (e) {
      moveToReceipt(bookingID: bookingID[0]);
    }

  }

  moveToReceipt({required String bookingID}) async {
    PageRouter.pushReplacement(
        context, BookingEntireDayInfo(bookingID: bookingID));
  }

  Future<void> serviceBook() async {
    if (checkBoxListener.value) {
      await _server.collection("SportistanUsers").doc(refID).update({
        'sportistanCredit': balance - serviceChargePay,
      });
    } else {
      sendSms(number: numberControllerAA.value.text.trim().toString());
    }
    sendSms(number: numberControllerAA.value.text.trim().toString());
  }
}

class MySlots {
  final String slotID;
  final String group;
  final String date;
  final int slotPrice;
  final int feesDue;
  final String slotStatus;
  final String nonFormattedTime;
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
      required this.nonFormattedTime,
      required this.slotTime});

  Map groupItemsByGroup(List items) {
    return groupBy(items, (item) => item.group);
  }
}
