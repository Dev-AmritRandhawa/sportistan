import 'package:http/http.dart' as http;
import 'package:chips_choice/chips_choice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttercontactpicker/fluttercontactpicker.dart';
import 'package:intl/intl.dart';
import 'package:sportistan/booking/payment_mode.dart';
import 'package:sportistan/booking/unique.dart';

import '../payment/sportistan_credit.dart';
import '../widgets/errors.dart';
import '../widgets/page_route.dart';
import 'book_a_slot.dart';
import 'booking_entire_day_info.dart';

class BookEntireDay extends StatefulWidget {
  final String date;
  final String groundID;
  final String groundName;

  const BookEntireDay({super.key,
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

  bool updateSmsAlert = true;

  String? refID;

  @override
  void initState() {
    getAllSlots();
    super.initState();
  }

  @override
  void dispose() {
    teamControllerA.dispose();
    numberControllerA.dispose();
    notesTeamA.dispose();
    nameControllerA.dispose();
    super.dispose();
  }

  TextEditingController teamControllerA = TextEditingController();
  TextEditingController numberControllerA = TextEditingController();
  TextEditingController nameControllerA = TextEditingController();
  GlobalKey<FormState> nameKeyA = GlobalKey<FormState>();
  GlobalKey<FormState> numberKeyA = GlobalKey<FormState>();
  GlobalKey<FormState> teamControllerKeyA = GlobalKey<FormState>();
  TextEditingController notesTeamA = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            foregroundColor: Colors.black54,
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text("Book for Entire Day")),
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
                          style:
                          TextStyle(fontSize: 16, fontFamily: "DMSans")),
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
            )));
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
                        "${DateFormat.yMMMd().format(
                            DateTime.parse(widget.date))} (${DateFormat.EEEE()
                            .format(DateTime.parse(widget.date))})",
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
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
                                          fontSize: MediaQuery
                                              .of(context)
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
                          key: teamControllerKeyA,
                          child: SizedBox(
                            width: MediaQuery
                                .of(context)
                                .size
                                .width / 1.2,
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
                              controller: teamControllerA,
                              onChanged: (data) {
                                nameKeyA.currentState!.validate();
                              },
                              decoration: const InputDecoration(
                                  fillColor: Colors.white,
                                  border: InputBorder.none,
                                  errorStyle: TextStyle(color: Colors.red),
                                  labelText: "Team Name*",
                                  filled: true,
                                  labelStyle: TextStyle(color: Colors.black)),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Form(
                          key: nameKeyA,
                          child: SizedBox(
                            width: MediaQuery
                                .of(context)
                                .size
                                .width / 1.2,
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
                              controller: nameControllerA,
                              onChanged: (data) {
                                nameKeyA.currentState!.validate();
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
                          key: numberKeyA,
                          child: SizedBox(
                            width: MediaQuery
                                .of(context)
                                .size
                                .width / 1.2,
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
                              controller: numberControllerA,
                              onChanged: (data) {
                                numberKeyA.currentState!.validate();
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
                                            numberControllerA);
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
                            controller: notesTeamA,
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
                      ListView(
                        physics: const BouncingScrollPhysics(),
                        shrinkWrap: true,
                        addAutomaticKeepAlives: true,
                        children: <Widget>[
                          Content(
                            title: 'Choose Mode Of Payment',
                            child: ChipsChoice<String>.single(
                              value: PaymentMode.type,
                              onChanged: (val) =>
                                  setState(() => PaymentMode.type = val),
                              choiceItems: C2Choice.listFrom<String, String>(
                                source: PaymentMode.paymentOptions,
                                value: (i, v) => v,
                                label: (i, v) => v,
                                tooltip: (i, v) => v,
                              ),
                              choiceCheckmark: true,
                              choiceStyle: C2ChipStyle.filled(
                                color: Colors.blue,
                                selectedStyle: const C2ChipStyle(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(25),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              CupertinoButton(
                  color: Colors.indigo,
                  child: const Text("Book For Entire Day"),
                  onPressed: () {
                    if (nameKeyA.currentState!.validate() &
                    numberKeyA.currentState!.validate() &
                    teamControllerKeyA.currentState!.validate()) {
                      _checkBalance();
                    } else {
                      Errors.flushBarInform(
                          "Please Fill The Details", context, "Error");
                    }
                  }),
              SizedBox(
                height: MediaQuery
                    .of(context)
                    .size
                    .height / 8,
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
  late String groundType;
  late num advancePay;
  late num updatedBalance;

  Future<void> _checkBalance() async {
    try {
      await _server
          .collection('SportistanUsers')
          .where('userID', isEqualTo: _auth.currentUser!.uid)
          .get()
          .then((value) =>
      {
        balance = value.docChanges.first.doc.get('sportistanCredits'),
      });

      double result = entireDayAmount / 100;
      advancePay = result * partnerCommission.toInt();
      if (advancePay <= balance) {
        createBooking();
      } else {
        showError();
      }
    } catch (e) {
      return;
    }
  }

  Future<void> getAllSlots() async {
    await _server
        .collection("SportistanPartners")
        .where('groundID', isEqualTo: widget.groundID)
        .get()
        .then((value) =>
    {
      allData = value.docChanges.first.doc
          .get(DateFormat.EEEE().format(DateTime.parse(widget.date))),
      refID = value.docChanges.first.doc.id,
      partnerCommission = value.docChanges.first.doc.get('commission'),
      groundType = value.docChanges.first.doc.get('groundType'),
      entireDayAmount = value.docChanges.first.doc.get(
          '${DateFormat.EEEE().format(DateTime.parse(widget.date))}EntireDay'),
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Booking is creating"),
      backgroundColor: Colors.green,
    ));

    for (int i = 0; i < allData.length; i++) {
      bookingID.add(UniqueID.generateRandomString());
      includeSlots.add(allData[i]["time"]);
    }
    for (int j = 0; j < allData.length; j++) {
      await _server.collection("GroundBookings").add({
        'bookingPerson': 'Ground Owner',
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
        'bookingCommissionCharged': advancePay,
        'entireDayBookingID': bookingID,
        'includeSlots': includeSlots,
        'feesDue': entireDayAmount  - advancePay,
        'ratingGiven': false,
        'rating': 3.0,
        'TeamA': 'Not Applicable',
        'TeamB': "Not Applicable",
        'advancePayment':
        advancePay,
        'bothTeamBooked': true,
        'groundID': widget.groundID,
        "teamA": {
          'teamName': teamControllerA.value.text,
          'personName': nameControllerA.value.text,
          'phoneNumber': numberControllerA.value.text,
          "notesTeamA": notesTeamA.value.text.isNotEmpty
              ? notesTeamA.value.text.toString()
              : "",
        },
        "teamB": {
          'teamName': teamControllerA.value.text,
          'personName': nameControllerA.value.text,
          'phoneNumber': numberControllerA.value.text,
          "notesTeamB": notesTeamA.value.text.toString(),
        },
        'slotPrice':entireDayAmount,
        'slotStatus': "Booked",
        'slotTime': allData[j]["time"],
        'slotID': allData[j]["slotID"],
        'bookingID': bookingID[j],
        'date': widget.date,
      });
    }
    await _server
        .collection('SportistanUsers')
        .where('userID', isEqualTo: _auth.currentUser!.uid)
        .get()
        .then((value) =>
    {
      updatedBalance = value.docChanges.first.doc.get('sportistanCredits'),
    }).then((value) async => {
      await _server
          .collection("SportistanUsers")
          .doc(refID)
          .update({'sportistanCredit': updatedBalance - advancePay}).then(
              (value) =>
          {
            if (mounted) {alertUser(bookingID: bookingID[0])}
          })
    });

  }

  Future<void> sendSms({required String number}) async {
    String url =
        'http://api.bulksmsgateway.in/sendmessage.php?user=sportslovez&password=7788330&mobile=$number&message=Your Booking is Confirmed at ${widget
        .groundName} on ${DateFormat.yMMMd().format(DateTime.parse(widget
        .date))} for Entire Day Thanks for Choosing Facility on Sportistan&sender=SPTNOT&type=3&template_id=1407170003612415391';
    await http.post(Uri.parse(url));
  }

  Future<void> alertUser({required String bookingID}) async {
    if (updateSmsAlert) {
      if (numberControllerA.value.text.isNotEmpty) {
        await sendSms(number: numberControllerA.value.text);
        if (numberControllerA.value.text.isNotEmpty) {
          if (numberControllerA.value.text != numberControllerA.value.text) {
            await sendSms(number: numberControllerA.value.text);
          }
        }
      }
    }
    updateSmsAlert = false;
    moveToReceipt(bookingID: bookingID);
  }

  moveToReceipt({required String bookingID}) async {
    PageRouter.pushReplacement(
        context, BookingEntireDayInfo(bookingID: bookingID));
  }

  void showError() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Low Balance",
                  style: TextStyle(
                      fontFamily: "DMSans", fontSize: 22, color: Colors.red),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Not Able to create booking due to low balance",
                  style: TextStyle(fontFamily: "DMSans", fontSize: 16),
                ),
              ),
              Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      widget.groundName,
                      softWrap: true,
                      style: const TextStyle(
                          fontFamily: "DMSans", fontSize: 16),
                    ),
                  )),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Rs.',
                    style: TextStyle(fontSize: 20),
                  ),
                  Text(
                    balance.toString(),
                    style:
                    const TextStyle(fontSize: 50, color: Colors.redAccent),
                  ),
                ],
              ),
              CupertinoButton(
                  color: Colors.green,
                  child: const Text("Add Credits"),
                  onPressed: () {
                    PageRouter.push(context, const SportistanCredit());
                  }),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Our commitment to assist you better Please Pay ${advancePay
                      .toString()}  Please add credits to continue booking services on Sportistan to Complete this Booking",
                  style: const TextStyle(
                      fontSize: 22,
                      color: Colors.black54,
                      fontFamily: "Nunito"),
                ),
              ),
              SizedBox(
                height: MediaQuery
                    .of(context)
                    .size
                    .height / 5,
              )
            ],
          ),
        );
      },
    );
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

  MySlots({required this.slotID,
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
