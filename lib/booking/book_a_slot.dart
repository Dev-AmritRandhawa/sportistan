import 'dart:io';
import 'package:chips_choice/chips_choice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:fluttercontactpicker/fluttercontactpicker.dart';
import 'package:intl/intl.dart';
import 'package:sliding_up_panel2/sliding_up_panel2.dart';
import 'package:sportistan/booking/booking_info.dart';
import 'package:sportistan/booking/payment_mode.dart';
import 'package:sportistan/booking/unique.dart';
import 'package:sportistan/widgets/errors.dart';
import 'package:sportistan/widgets/page_route.dart';

class BookASlot extends StatefulWidget {
  final String group;

  final String slotID;
  final String bookingID;
  final String groundID;
  final String date;
  final String groundName;
  final String groundAddress;
  final int slotPrice;
  final String slotTime;
  final String slotStatus;

  const BookASlot({
    super.key,
    required this.group,
    required this.date,
    required this.slotID,
    required this.bookingID,
    required this.groundID,
    required this.slotTime,
    required this.slotStatus,
    required this.slotPrice,
    required this.groundName,
    required this.groundAddress,
  });

  @override
  State<BookASlot> createState() => _BookASlotState();
}

class _BookASlotState extends State<BookASlot> {
  String countryCode = '+91';
  TextEditingController teamControllerA = TextEditingController();
  TextEditingController teamControllerB = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController advancePaymentController = TextEditingController();
  TextEditingController nameControllerB = TextEditingController();
  TextEditingController nameControllerA = TextEditingController();
  TextEditingController numberControllerA = TextEditingController();
  TextEditingController numberControllerB = TextEditingController();
  GlobalKey<FormState> nameKeyA = GlobalKey<FormState>();
  GlobalKey<FormState> nameKeyB = GlobalKey<FormState>();
  GlobalKey<FormState> numberKeyA = GlobalKey<FormState>();
  GlobalKey<FormState> numberKeyB = GlobalKey<FormState>();
  GlobalKey<FormState> advancePaymentKey = GlobalKey<FormState>();
  GlobalKey<FormState> teamControllerKeyA = GlobalKey<FormState>();
  GlobalKey<FormState> teamControllerKeyB = GlobalKey<FormState>();

  ValueNotifier<bool> checkBoxTeamB = ValueNotifier<bool>(false);
  ValueNotifier<bool> showTeamB = ValueNotifier<bool>(false);
  ValueNotifier<bool> amountUpdateListener = ValueNotifier<bool>(false);

  bool amountUpdated = false;

  final _server = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  TextEditingController notesTeamA = TextEditingController();
  TextEditingController notesTeamB = TextEditingController();

  late int updatedPrice;

  Future<void> serverInit() async {
    if (widget.bookingID.isNotEmpty) {
      await _server
          .collection("GroundBookings")
          .where("bookingID", isEqualTo: widget.bookingID)
          .get()
          .then((value) => {
                if (value.docs.isNotEmpty)
                  {
                    updatedPrice = value.docs[0]["feesDue"],
                    advancePaymentController.text =
                        value.docs[0]["advancePayment"].toString(),
                    teamControllerA.text = value.docs[0]["teamA"]["teamName"],
                    teamControllerB.text = value.docs[0]["teamB"]["teamName"],
                    numberControllerA.text =
                        value.docs[0]["teamA"]["phoneNumber"],
                    numberControllerB.text =
                        value.docs[0]["teamB"]["phoneNumber"],
                    nameControllerA.text = value.docs[0]["teamA"]["personName"],
                    nameControllerB.text = value.docs[0]["teamB"]["personName"],
                    notesTeamA.text = value.docs[0]["teamA"]["notesTeamA"],
                    notesTeamB.text = value.docs[0]["teamB"]["notesTeamB"],
                    updatedPrice = value.docs[0]["slotPrice"],
                    priceController.text =
                        value.docs[0]["slotPrice"].toString(),
                  }
              });
    } else {
      priceController.text = widget.slotPrice.toString();
      updatedPrice = widget.slotPrice;
    }
    setState(() {
      double newAmount = updatedPrice / 2.toInt().round();
      priceController.text = newAmount.round().toInt().toString();
    });
  }

  @override
  void dispose() {
    priceController.dispose();
    teamControllerA.dispose();
    teamControllerB.dispose();
    numberControllerA.dispose();
    numberControllerB.dispose();
    nameControllerA.dispose();
    nameControllerB.dispose();
    super.dispose();
  }

  @override
  void initState() {
    serverInit();
    super.initState();
  }

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
        controller.text = _phoneContact!.phoneNumber!.number!;
      }
    } else {
      requestPermission();
    }
  }

  requestPermission() async {
    await FlutterContactPicker.requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SlidingUpPanel(
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        minHeight: MediaQuery.of(context).size.height / 1.4,
        maxHeight: MediaQuery.of(context).size.height / 1.4,
        panelBuilder: () => _panel(),
        body: SafeArea(
          child: Card(
            child: Column(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Row(
                            children: [
                              const Text("Slot Time :",
                                  style: TextStyle(
                                      color: Colors.black45,
                                      fontWeight: FontWeight.bold)),
                              Text(widget.slotTime,
                                  style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            children: [
                              const Text("Date :",
                                  style: TextStyle(
                                      color: Colors.black45,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                  DateFormat.yMMMd()
                                      .format(DateTime.parse(widget.group)),
                                  style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      CupertinoButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Back",
                            style: TextStyle(color: Colors.red),
                          )),
                      CupertinoButton(
                          color: Colors.green.shade800,
                          onPressed: () {
                            if (nameKeyA.currentState!.validate() &
                                numberKeyA.currentState!.validate() &
                                teamControllerKeyA.currentState!.validate()) {
                              if (checkBoxTeamB.value) {
                                if (nameKeyB.currentState!.validate() &
                                    numberKeyB.currentState!.validate() &
                                    teamControllerKeyB.currentState!
                                        .validate()) {
                                  if (advancePaymentKey.currentState!
                                      .validate()) {
                                    _bookSlot();
                                  }
                                } else {
                                  Errors.flushBarInform(
                                      "Field Required for Team B*",
                                      context,
                                      "Enter field");
                                }
                              } else {
                                if (advancePaymentKey.currentState!
                                    .validate()) {
                                  _bookSlot();
                                }
                              }
                            } else {
                              Errors.flushBarInform(
                                  "Field Required for Team A*",
                                  context,
                                  "Enter field");
                            }
                          },
                          child: const Text("Book Slot")),
                    ],
                  ),
                ),
                Text(
                 overflow: TextOverflow.ellipsis,
                  widget.groundName,
                  style: TextStyle(
                      color: Colors.black54,
                      fontFamily: "DMSans",
                      fontSize: MediaQuery.of(context).size.height / 35),
                ),
                Text(
                  textAlign: TextAlign.center,
                  widget.groundAddress,
                  style: const TextStyle(color: Colors.black54),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  _panel() {
    return MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ValueListenableBuilder(
                    valueListenable: checkBoxTeamB,
                    builder: (context, value, child) => SizedBox(
                          width: MediaQuery.of(context).size.width / 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CupertinoSwitch(
                                  value: value,
                                  onChanged: (result) {
                                    checkBoxTeamB.value = result;
                                    teamControllerB.text =
                                        teamControllerA.value.text;
                                    nameControllerB.text =
                                        nameControllerA.value.text;
                                    numberControllerB.text =
                                        numberControllerA.value.text;
                                    showTeamB.value = result;
                                    if (result) {
                                      setState(() {
                                        int newAmount = updatedPrice;
                                        priceController.text =
                                            newAmount.toString();
                                      });
                                    } else {
                                      setState(() {
                                        double newAmount =
                                            updatedPrice / 2.toInt().round();
                                        priceController.text = newAmount
                                            .round()
                                            .toInt()
                                            .toString();
                                      });
                                    }
                                  }),
                              const Text(
                                "Book for both Teams",
                                style: TextStyle(fontFamily: "DMSans"),
                              )
                            ],
                          ),
                        )),
              ),
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
                                  fillColor: Colors.white,
                                  border: InputBorder.none,
                                  errorStyle:
                                      const TextStyle(color: Colors.red),
                                  filled: true,
                                  prefixIcon: IconButton(
                                      onPressed: () async {
                                        checkPermissionForContacts(
                                            numberControllerB);
                                      },
                                      icon: const Icon(Icons.contacts_rounded)),
                                  suffixIcon: IconButton(
                                      onPressed: () async {
                                        if (numberControllerA
                                            .value.text.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      "No Number Available")));
                                        } else {
                                          FlutterPhoneDirectCaller.callNumber(
                                              numberControllerA.value.text);
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.call,
                                        color: Colors.blue,
                                      )),
                                  labelText: "Contact Number*",
                                  labelStyle:
                                      const TextStyle(color: Colors.black)),
                            ),
                          ),
                        ),
                      ),
                      ValueListenableBuilder(
                        valueListenable: amountUpdateListener,
                        builder: (BuildContext context, value, Widget? child) {
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 3,
                                    child: Form(
                                      key: advancePaymentKey,
                                      child: TextFormField(
                                        controller: advancePaymentController,
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return "Enter Advance";
                                          } else if (double.parse(
                                                      advancePaymentController
                                                          .value.text)
                                                  .round()
                                                  .toInt() >
                                              double.parse(priceController
                                                      .value.text)
                                                  .round()
                                                  .toInt()) {
                                            return "Can't  More Slot Amount";
                                          } else {
                                            return null;
                                          }
                                        },
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                        autofillHints: const [
                                          AutofillHints.telephoneNumberLocal
                                        ],
                                        decoration: const InputDecoration(
                                          fillColor: Colors.white,
                                          border: InputBorder.none,
                                          errorStyle:
                                              TextStyle(color: Colors.red),
                                          filled: true,
                                          hintText: "Booking Amt?",
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 3,
                                    child: TextFormField(
                                      onTap: () {
                                        amountUpdateListener.value = true;
                                      },
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      controller: priceController,
                                      decoration: const InputDecoration(
                                        suffixIcon: Icon(Icons.edit,
                                            color: Colors.blue),
                                        prefix: Text("₹",
                                            style:
                                                TextStyle(color: Colors.green)),
                                        fillColor: Colors.white,
                                        border: InputBorder.none,
                                        filled: true,
                                        label: Text("Slot Price"),
                                        hintStyle:
                                            TextStyle(color: Colors.black),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              value
                                  ? Padding(
                                      padding: const EdgeInsets.only(right: 50),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          MaterialButton(
                                              elevation: 0,
                                              color: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          25)),
                                              onPressed: () {
                                                amountUpdateListener.value =
                                                    false;
                                                priceController.text =
                                                    priceController.value.text;
                                                updatedPrice = double.parse(
                                                        priceController
                                                            .value.text)
                                                    .round()
                                                    .toInt();
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
                                                    color: Colors.blue),
                                              )),
                                        ],
                                      ),
                                    )
                                  : Container(),
                              ListView(
                                physics: const BouncingScrollPhysics(),
                                shrinkWrap: true,
                                addAutomaticKeepAlives: true,
                                children: <Widget>[
                                  Content(
                                    title: 'Choose Mode Of Payment',
                                    child: ChipsChoice<String>.single(
                                      value: PaymentMode.type,
                                      onChanged: (val) => setState(
                                          () => PaymentMode.type = val),
                                      choiceItems:
                                          C2Choice.listFrom<String, String>(
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
                          );
                        },
                      ),
                      Column(
                        children: [
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
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Future<void> _bookSlot() async {
    if (widget.bookingID.isEmpty) {
      String uniqueID = UniqueID.generateRandomString();
      try {
        await _server
            .collection("GroundBookings")
            .add({
          'slotTime': widget.slotTime,
          'bookingPerson': 'Ground Owner',
          'bookingCreated': DateTime.parse(widget.date),
          'bookedAt': DateTime.now(),
          'userID': _auth.currentUser!.uid,
          'group': widget.group,
          'isBookingCancelled': false,
          'feesDue':
          updatedPrice - int.parse(advancePaymentController.value.text),
          'ratingGiven': false,
          'rating': 3.0,
          'bothTeamBooked': checkBoxTeamB.value,
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
            'teamName': checkBoxTeamB.value ? teamControllerB.value.text : '',
            'personName': checkBoxTeamB.value ? nameControllerB.value.text : '',
            'phoneNumber':
            checkBoxTeamB.value ? numberControllerB.value.text : '',
            "notesTeamB": notesTeamB.value.text.isNotEmpty
                ? notesTeamB.value.text.toString()
                : "",
          },
          'slotPrice': updatedPrice,
          'advancePayment':
          double.parse(advancePaymentController.value.text).round().toInt(),
          'slotStatus': slotStatus(),
          'slotID': widget.slotID,
          'bookingID': uniqueID,
          'date': widget.date,
        }).then((value) => {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Creating a Booking"))),
          PageRouter.pushReplacement(
              context, BookingInfo(bookingID: uniqueID))
        });
      } on SocketException catch (e) {
        if (mounted) {
          Errors.flushBarInform(e.toString(), context, "Internet Connectivity");
        }
      } catch (e) {
        if (mounted) {
          Errors.flushBarInform(e.toString(), context, "Error");
        }
      }
    } else {
      try {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Creating a Booking")));
        var refDetails = await
        _server
            .collection("GroundBookings")
            .where("bookingID", isEqualTo: widget.bookingID)
            .get();
        await  _server
            .collection("GroundBookings")
            .doc(refDetails.docs.first.id)
            .update({
          'slotTime': widget.slotTime,
          'bookingPerson': 'Ground Owner',
          'bookingCreated': DateTime.parse(widget.date),
          'bookedAt': DateTime.now(),
          'isBookingCancelled': false,
          'userID': _auth.currentUser!.uid,
          'feesDue':
          updatedPrice - int.parse(advancePaymentController.value.text),

          'ratingGiven': false,
          'rating': 3.0,
          'ratingTags': [],
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
            'teamName': checkBoxTeamB.value ? teamControllerB.value.text : '',
            'personName': checkBoxTeamB.value ? nameControllerB.value.text : '',
            'phoneNumber':
            checkBoxTeamB.value ? numberControllerB.value.text : '',
            "notesTeamB": notesTeamB.value.text.isNotEmpty
                ? notesTeamB.value.text.toString()
                : "",
          },
          'slotPrice': updatedPrice,
          'advancePayment':
          double.parse(advancePaymentController.value.text).round().toInt(),
          'slotStatus': slotStatus(),
          'bothTeamBooked': checkBoxTeamB.value,
          'slotID': widget.slotID,
          'bookingID': widget.bookingID,
          'date': widget.date,
        }).then((value) => {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Booking Created"))),
          PageRouter.pushReplacement(
              context, BookingInfo(bookingID: widget.bookingID))
        });
      } on SocketException catch (e) {
        if (mounted) {
          Errors.flushBarInform(e.toString(), context, "Internet Connectivity");
        }
      } catch (e) {
        if (mounted) {
          Errors.flushBarInform(e.toString(), context, "Error");
        }
      }
    }
  }


  String slotStatus() {
    if (!checkBoxTeamB.value) {
      if (double.parse(priceController.value.text).round().toInt() !=
          double.parse(advancePaymentController.value.text).round().toInt()) {
        return "Fees Due";
      } else {
        return "Half Booked";
      }
    }
    if (checkBoxTeamB.value) {
      if (double.parse(priceController.value.text).round().toInt() !=
          double.parse(advancePaymentController.value.text).round().toInt()) {
        return "Fees Due";
      } else {
        return "Booked";
      }
    }
    return "";
  }
}

class Content extends StatefulWidget {
  final String title;
  final Widget child;

  const Content({
    Key? key,
    required this.title,
    required this.child,
  }) : super(key: key);

  @override
  ContentState createState() => ContentState();
}

class ContentState extends State<Content> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(5),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontFamily: "DMSans",
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Flexible(fit: FlexFit.loose, child: widget.child),
        ],
      ),
    );
  }
}
