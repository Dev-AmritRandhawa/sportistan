import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:fluttercontactpicker/fluttercontactpicker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:sportistan/booking/booking_info.dart';
import 'package:sportistan/booking/payment_mode.dart';
import 'package:sportistan/booking/sportistan_credit.dart';
import 'package:sportistan/booking/unique.dart';
import 'package:sportistan/nav/nav_profile.dart';
import 'package:sportistan/widgets/errors.dart';
import 'package:sportistan/widgets/page_route.dart';

class BookASlot extends StatefulWidget {
  final String group;
  final String slotID;
  final String bookingID;
  final String groundType;
  final String date;
  final String groundID;
  final String groundName;
  final String groundAddress;
  final num slotPrice;

  final String slotTime;
  final String slotStatus;

  const BookASlot({
    super.key,
    required this.group,
    required this.date,
    required this.slotID,
    required this.bookingID,
    required this.slotTime,
    required this.slotStatus,
    required this.slotPrice,
    required this.groundName,
    required this.groundID,
    required this.groundAddress,
    required this.groundType,
  });

  @override
  State<BookASlot> createState() => _BookASlotState();
}

class _BookASlotState extends State<BookASlot> {
  String countryCode = '+91';
  TextEditingController teamControllerA = TextEditingController();
  TextEditingController teamControllerB = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController nameControllerB = TextEditingController();
  TextEditingController nameControllerA = TextEditingController();
  TextEditingController numberControllerA = TextEditingController();
  TextEditingController numberControllerB = TextEditingController();
  GlobalKey<FormState> nameKeyA = GlobalKey<FormState>();
  GlobalKey<FormState> nameKeyB = GlobalKey<FormState>();
  GlobalKey<FormState> numberKeyA = GlobalKey<FormState>();
  GlobalKey<FormState> numberKeyB = GlobalKey<FormState>();
  GlobalKey<FormState> teamControllerKeyA = GlobalKey<FormState>();
  GlobalKey<FormState> teamControllerKeyB = GlobalKey<FormState>();

  ValueNotifier<bool> checkBoxTeamB = ValueNotifier<bool>(false);
  ValueNotifier<bool> showTeamB = ValueNotifier<bool>(false);
  ValueNotifier<bool> copyAsAbove = ValueNotifier<bool>(false);
  ValueNotifier<bool> commissionCalculateListener = ValueNotifier<bool>(false);
  ValueNotifier<bool> hideData = ValueNotifier<bool>(false);

  bool amountUpdated = false;

  final _server = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  TextEditingController notesTeamA = TextEditingController();
  TextEditingController notesTeamB = TextEditingController();

  late num updatedPrice;

  bool updateSmsAlert = true;
  bool alreadyCommissionCharged = false;
  late num commissionCharged;

  late num totalSlotPrice;

  Future<void> serverInit() async {
    try {
      if (widget.bookingID.isNotEmpty) {
        await _server
            .collection("GroundBookings")
            .where("bookingID", isEqualTo: widget.bookingID)
            .get()
            .then((value) => {
                  if (value.docs.isNotEmpty)
                    {
                      updatedPrice = value.docs[0]["feesDue"],
                      teamControllerA.text =
                          value.docs.first["teamA"]["teamName"],
                      teamControllerB.text =
                          value.docs.first["teamB"]["teamName"],
                      numberControllerA.text =
                          value.docs.first["teamA"]["phoneNumber"],
                      numberControllerB.text =
                          value.docs.first["teamB"]["phoneNumber"],
                      nameControllerA.text =
                          value.docs.first["teamA"]["personName"],
                      nameControllerB.text =
                          value.docs.first["teamB"]["personName"],
                      notesTeamA.text = value.docs.first["teamA"]["notesTeamA"],
                      notesTeamB.text = value.docs.first["teamB"]["notesTeamB"],
                      updatedPrice = value.docs.first["slotPrice"],
                      priceController.text =
                          value.docs.first["totalSlotPrice"].toString(),
                      totalSlotPrice = value.docs.first["totalSlotPrice"],
                      checkBoxTeamB.value = true,
                      hideData.value = true,
                      showTeamB.value = true,
                      alreadyCommissionCharged = true,
                      commissionCharged =
                          value.docs.first["bookingCommissionCharged"],
                    },
                  _checkBalance(false)
                });
      } else {
        priceController.text = widget.slotPrice.toString();
        totalSlotPrice = widget.slotPrice;
        updatedPrice = widget.slotPrice;
        double newAmount = updatedPrice / 2.toInt().round();
        priceController.text = newAmount.round().toInt().toString();
        _checkBalance(false);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CupertinoButton(
            borderRadius: BorderRadius.zero,
            color: Colors.green,
            onPressed: () {
              if (nameKeyA.currentState!.validate() &
                  numberKeyA.currentState!.validate() &
                  teamControllerKeyA.currentState!.validate()) {
                if (checkBoxTeamB.value) {
                  if (nameKeyB.currentState!.validate() &
                      numberKeyB.currentState!.validate() &
                      teamControllerKeyB.currentState!.validate()) {
                    _bookSlot();
                  } else {
                    Errors.flushBarInform(
                        "Field Required for Team B*", context, "Enter field");
                  }
                } else {
                  _bookSlot();
                }
              } else {
                Errors.flushBarInform(
                    "Field Required for Team A*", context, "Enter field");
              }
            },
            child: const Text(
              "Book Slot",
              style: TextStyle(color: Colors.white),
            )),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Back'),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              Card(
                color: Colors.green.shade900,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        children: [
                          const Text("Slot Time :",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text(widget.slotTime,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: [
                          const Text("Date :",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text(
                              DateFormat.yMMMd()
                                  .format(DateTime.parse(widget.group)),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              ValueListenableBuilder(
                valueListenable: hideData,
                builder: (context, value, child) {
                  return Column(children: [
                    SizedBox(
                        width: double.infinity,
                        child: Card(
                            color: Colors.grey.shade100,
                            child: Column(children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Form(
                                  key: teamControllerKeyA,
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 1.2,
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
                                      enabled: !value,
                                      obscureText: value,
                                      decoration: const InputDecoration(
                                          fillColor: Colors.white,
                                          border: InputBorder.none,
                                          errorStyle:
                                              TextStyle(color: Colors.red),
                                          labelText: "Team A Name*",
                                          filled: true,
                                          labelStyle:
                                              TextStyle(color: Colors.black)),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Form(
                                  key: nameKeyA,
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 1.2,
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
                                      keyboardType: TextInputType.name,
                                      enabled: !value,
                                      obscureText: value,
                                      decoration: const InputDecoration(
                                          fillColor: Colors.white,
                                          labelText: "Contact Person*",
                                          border: InputBorder.none,
                                          errorStyle:
                                              TextStyle(color: Colors.red),
                                          filled: true,
                                          labelStyle:
                                              TextStyle(color: Colors.black)),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Form(
                                  key: numberKeyA,
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 1.2,
                                    child: TextFormField(
                                      maxLength: 10,
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return "Number required.";
                                        } else if (value.length != 10) {
                                          return "Enter 10 digits.";
                                        } else {
                                          return null;
                                        }
                                      },
                                      enabled: !value,
                                      obscureText: value,
                                      controller: numberControllerA,
                                      onChanged: (data) {
                                        numberKeyA.currentState!.validate();
                                      },
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                            RegExp('[0-9]')),
                                      ],
                                      autofillHints: const [
                                        AutofillHints.telephoneNumberLocal
                                      ],
                                      decoration: InputDecoration(
                                          fillColor: Colors.white,
                                          border: InputBorder.none,
                                          errorStyle: const TextStyle(
                                              color: Colors.red),
                                          filled: true,
                                          prefixIcon: IconButton(
                                              onPressed: () async {
                                                checkPermissionForContacts(
                                                    numberControllerA);
                                              },
                                              icon: const Icon(
                                                  Icons.contacts_rounded)),
                                          suffixIcon: IconButton(
                                              onPressed: () async {
                                                if (numberControllerA
                                                    .value.text.isEmpty) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(const SnackBar(
                                                          content: Text(
                                                              "No Number Available")));
                                                } else {
                                                  FlutterPhoneDirectCaller
                                                      .callNumber(
                                                          numberControllerA
                                                              .value.text);
                                                }
                                              },
                                              icon: const Icon(
                                                Icons.call,
                                                color: Colors.blue,
                                              )),
                                          labelText: "Contact Number*",
                                          labelStyle: const TextStyle(
                                              color: Colors.black)),
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
                                        errorStyle:
                                            TextStyle(color: Colors.red),
                                        filled: true,
                                        hintText: "Notes (Optional)",
                                        hintStyle:
                                            TextStyle(color: Colors.black45),
                                        contentPadding:
                                            EdgeInsets.symmetric(vertical: 40),
                                      ),
                                      enabled: !value,
                                      obscureText: value,
                                    ),
                                  ))
                            ])))
                  ]);
                },
              ),
              Column(
                children: [
                  ValueListenableBuilder(
                    valueListenable: showTeamB,
                    builder: (context, value, child) {
                      return value
                          ? Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Form(
                                    key: teamControllerKeyB,
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width /
                                          1.2,
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
                                        controller: teamControllerB,
                                        onChanged: (data) {
                                          nameKeyB.currentState!.validate();
                                        },
                                        decoration: const InputDecoration(
                                            fillColor: Colors.white,
                                            border: InputBorder.none,
                                            errorStyle:
                                                TextStyle(color: Colors.red),
                                            labelText: "Team B Name*",
                                            filled: true,
                                            labelStyle:
                                                TextStyle(color: Colors.black)),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Form(
                                    key: nameKeyB,
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width /
                                          1.2,
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
                                        controller: nameControllerB,
                                        onChanged: (data) {
                                          nameKeyB.currentState!.validate();
                                        },
                                        decoration: const InputDecoration(
                                            fillColor: Colors.white,
                                            labelText: "Contact Person*",
                                            border: InputBorder.none,
                                            errorStyle:
                                                TextStyle(color: Colors.red),
                                            filled: true,
                                            labelStyle:
                                                TextStyle(color: Colors.black)),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Form(
                                    key: numberKeyB,
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width /
                                          1.2,
                                      child: TextFormField(
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return "Number required.";
                                          } else if (value.length != 10) {
                                            return "Enter 10 digits.";
                                          } else {
                                            return null;
                                          }
                                        },
                                        maxLength: 10,
                                        controller: numberControllerB,
                                        onChanged: (data) {
                                          numberKeyB.currentState!.validate();
                                        },
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp('[0-9]')),
                                        ],
                                        autofillHints: const [
                                          AutofillHints.telephoneNumberLocal
                                        ],
                                        decoration: InputDecoration(
                                            fillColor: Colors.white,
                                            border: InputBorder.none,
                                            errorStyle: const TextStyle(
                                                color: Colors.red),
                                            filled: true,
                                            prefixIcon: IconButton(
                                                onPressed: () async {
                                                  checkPermissionForContacts(
                                                      numberControllerB);
                                                },
                                                icon: const Icon(
                                                    Icons.contacts_rounded)),
                                            suffixIcon: IconButton(
                                                onPressed: () async {
                                                  if (numberControllerB
                                                      .value.text.isEmpty) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                            const SnackBar(
                                                                content: Text(
                                                                    "No Number Available")));
                                                  } else {
                                                    FlutterPhoneDirectCaller
                                                        .callNumber(
                                                            numberControllerB
                                                                .value.text);
                                                  }
                                                },
                                                icon: const Icon(
                                                  Icons.call,
                                                  color: Colors.blue,
                                                )),
                                            labelText: "Contact Number*",
                                            labelStyle: const TextStyle(
                                                color: Colors.black)),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SizedBox(
                                    child: TextFormField(
                                      controller: notesTeamB,
                                      decoration: const InputDecoration(
                                        fillColor: Colors.white,
                                        border: InputBorder.none,
                                        errorStyle:
                                            TextStyle(color: Colors.red),
                                        filled: true,
                                        hintText: "Notes (Optional)",
                                        hintStyle:
                                            TextStyle(color: Colors.black45),
                                        contentPadding:
                                            EdgeInsets.symmetric(vertical: 40),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Container();
                    },
                  ),
                  ValueListenableBuilder(
                    valueListenable: commissionCalculateListener,
                    builder: (context, value, child) => value
                        ? Center(
                            child: Column(
                              children: [
                                Text(
                                    "Please Pay ₹${serverCommissionCharge.round().toString()}",
                                    style: const TextStyle(
                                        fontFamily: "DMSans",
                                        fontSize: 22,
                                        color: Colors.green)),
                                checkBoxTeamB.value
                                    ? Text(
                                        "Slot Price is  For Both Team ₹ ${priceController.value.text.toString()}",
                                        style: const TextStyle(
                                          fontFamily: "DMSans",
                                          fontSize: 22,
                                        ))
                                    : Text(
                                        "Slot Price is For One Team ₹ ${priceController.value.text.toString()}",
                                        style: const TextStyle(
                                          fontFamily: "DMSans",
                                          fontSize: 22,
                                        )),
                                Card(
                                    child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.account_balance_wallet,
                                        color: Colors.brown,
                                      ),
                                      Text(
                                          'Your Current Balance is ₹ ${balance.toString()}',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontFamily: "DMSans")),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CupertinoButton(
                                              color: Colors.green,
                                              onPressed: () {
                                                PageRouter.push(context,
                                                    const NavProfile());
                                              },
                                              child: const Text("My Wallet")),
                                        ],
                                      )
                                    ],
                                  ),
                                )),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ValueListenableBuilder(
                                      valueListenable: checkBoxTeamB,
                                      builder:
                                          (context, value, child) => SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    2,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    CupertinoSwitch(
                                                        value: value,
                                                        onChanged:
                                                            widget.bookingID
                                                                    .isNotEmpty
                                                                ? null
                                                                : (result) {
                                                                    if (nameKeyA.currentState!.validate() &
                                                                        numberKeyA
                                                                            .currentState!
                                                                            .validate() &
                                                                        teamControllerKeyA
                                                                            .currentState!
                                                                            .validate()) {
                                                                      _checkBalance(
                                                                          false);
                                                                      checkBoxTeamB
                                                                              .value =
                                                                          result;
                                                                      teamControllerB
                                                                              .text =
                                                                          teamControllerA
                                                                              .value
                                                                              .text;
                                                                      nameControllerB
                                                                              .text =
                                                                          nameControllerA
                                                                              .value
                                                                              .text;
                                                                      numberControllerB
                                                                              .text =
                                                                          numberControllerA
                                                                              .value
                                                                              .text;
                                                                      showTeamB
                                                                              .value =
                                                                          result;
                                                                      if (result) {
                                                                        setState(
                                                                            () {
                                                                          num newAmount =
                                                                              updatedPrice;
                                                                          priceController.text =
                                                                              newAmount.toString();
                                                                        });
                                                                      } else {
                                                                        setState(
                                                                            () {
                                                                          double
                                                                              newAmount =
                                                                              updatedPrice / 2.toInt().round();
                                                                          priceController.text = newAmount
                                                                              .round()
                                                                              .toInt()
                                                                              .toString();
                                                                        });
                                                                      }
                                                                    }
                                                                  }),
                                                    const Text(
                                                      "Book for both Teams",
                                                      style: TextStyle(
                                                          fontFamily: "DMSans"),
                                                    )
                                                  ],
                                                ),
                                              )),
                                ),
                              ],
                            ),
                          )
                        : const CircularProgressIndicator(strokeWidth: 1),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  late List<DocumentChange<Map<String, dynamic>>> data;

  Future<void> _bookSlot() async {
    try {
      _server
          .collection("SportistanUsers")
          .where('userID', isEqualTo: _auth.currentUser!.uid)
          .get()
          .then((value) => {
                if (value.docChanges.isNotEmpty)
                  {data = value.docChanges, _checkBalance(true)}
              });
    } catch (e) {
      return;
    }
  }

  Future<void> sendSms({required String number}) async {
    String url =
        'http://api.bulksmsgateway.in/sendmessage.php?user=sportslovez&password=7788330&mobile=$number&message=Your Booking is Confirmed for ${widget.groundName} on ${DateFormat.yMMMd().format(DateTime.parse(widget.group))} at ${widget.slotTime} Thanks for Choosing Facility on Sportistan&sender=SPTNOT&type=3&template_id=1407170003612415391';
    await http.post(Uri.parse(url));
  }

  Future<void> alertUser({required String bookingID}) async {
    if (updateSmsAlert) {
      if (numberControllerA.value.text.isNotEmpty) {
        await sendSms(number: numberControllerA.value.text);
        if (numberControllerB.value.text.isNotEmpty) {
          if (numberControllerA.value.text != numberControllerB.value.text) {
            await sendSms(number: numberControllerB.value.text);
          }
        }
      }
    }
    updateSmsAlert = false;
    moveToReceipt(bookingID: bookingID);
  }

  moveToReceipt({required String bookingID}) async {
    PageRouter.pushReplacement(context, BookingInfo(bookingID: bookingID));
  }

  late double serverCommissionCharge;
  late num balance;

  Future<void> _checkBalance(bool wannaBook) async {
    commissionCalculateListener.value = false;
    QuerySnapshot<Map<String, dynamic>> user = await _server
        .collection('SportistanUsers')
        .where('userID', isEqualTo: _auth.currentUser!.uid)
        .get();
    balance = user.docChanges.first.doc.get("sportistanCredit");
    QuerySnapshot<Map<String, dynamic>> partner = await _server
        .collection('SportistanPartners')
        .where('groundID', isEqualTo: widget.groundID.toString())
        .get();
    num commission = partner.docChanges.first.doc.get("commission");
    double result = double.parse(priceController.value.text.trim()) / 100;
    double newCommissionCharge = result * commission.toInt();
    if (checkBoxTeamB.value) {
      serverCommissionCharge = newCommissionCharge / 2;
      commissionCalculateListener.value = true;
    } else {
      serverCommissionCharge = newCommissionCharge;
      commissionCalculateListener.value = true;
    }

    if (wannaBook) {
      if (serverCommissionCharge <= balance) {
        if (widget.bookingID.isEmpty) {
          String uniqueID = UniqueID.generateRandomString();
          try {
            await _server.collection("GroundBookings").add({
              'slotTime': widget.slotTime,
              'bookingPerson': 'Ground Owner',
              'groundName': widget.groundName,
              'bookingCreated': DateTime.parse(widget.date),
              'bookedAt': DateTime.now(),
              'groundType': widget.groundType,
              'shouldCountInBalance': false,
              'isBookingCancelled': false,
              'userID': _auth.currentUser!.uid,
              'bookingCommissionCharged': serverCommissionCharge,
              'feesDue': calculateFeesDue(),
              'paymentMode': PaymentMode.type,
              'ratingGiven': false,
              'rating': 3.0,
              'ratingTags': [],
              'groundID': widget.groundID,
              'TeamA': alreadyCommissionCharged
                  ? commissionCharged
                  : serverCommissionCharge,
              'TeamB': checkBoxTeamB.value
                  ? serverCommissionCharge
                  : 'NotApplicable',
              "teamA": {
                'teamName': teamControllerA.value.text,
                'personName': nameControllerA.value.text,
                'phoneNumber': numberControllerA.value.text,
                "notesTeamA": notesTeamA.value.text.isNotEmpty
                    ? notesTeamA.value.text.toString()
                    : "",
              },
              "teamB": {
                'teamName':
                    checkBoxTeamB.value ? teamControllerB.value.text : '',
                'personName':
                    checkBoxTeamB.value ? nameControllerB.value.text : '',
                'phoneNumber':
                    checkBoxTeamB.value ? numberControllerB.value.text : '',
                "notesTeamB": notesTeamB.value.text.isNotEmpty
                    ? notesTeamB.value.text.toString()
                    : "",
              },
              'slotPrice': int.parse(priceController.value.text.toString()),
              'totalSlotPrice': updatedPrice,
              'advancePayment': advancePaymentCalculate(),
              'slotStatus': slotStatus(),
              'bothTeamBooked': checkBoxTeamB.value,
              'slotID': widget.slotID,
              'bookingID': widget.bookingID,
              'date': widget.date,
            }).then((value) async => {
                  await _server
                      .collection("SportistanUsers")
                      .doc(user.docChanges.first.doc.id)
                      .update({
                    'sportistanCredit': balance - serverCommissionCharge
                  }).then((value) => {alertUser(bookingID: uniqueID)})
                });
          } on SocketException catch (e) {
            if (mounted) {
              Errors.flushBarInform(
                  e.toString(), context, "Internet Connectivity");
            }
          } catch (e) {
            if (mounted) {
              Errors.flushBarInform(e.toString(), context, "Error");
            }
          }
        } else {
          try {
            var refDetails = await _server
                .collection("GroundBookings")
                .where("bookingID", isEqualTo: widget.bookingID)
                .get();
            await _server
                .collection("GroundBookings")
                .doc(refDetails.docs.first.id)
                .update({
              'slotTime': widget.slotTime,
              'bookingPerson': 'Ground Owner',
              'groundName': widget.groundName,
              'bookingCreated': DateTime.parse(widget.date),
              'bookedAt': DateTime.now(),
              'groundType': widget.groundType,
              'shouldCountInBalance': false,
              'isBookingCancelled': false,
              'userID': _auth.currentUser!.uid,
              'bookingCommissionCharged': serverCommissionCharge,
              'feesDue': calculateFeesDue(),
              'paymentMode': PaymentMode.type,
              'ratingGiven': false,
              'rating': 3.0,
              'ratingTags': [],
              'groundID': widget.groundID,
              'TeamA': alreadyCommissionCharged
                  ? commissionCharged
                  : serverCommissionCharge,
              'TeamB': checkBoxTeamB.value
                  ? serverCommissionCharge
                  : 'NotApplicable',
              "teamA": {
                'teamName': teamControllerA.value.text,
                'personName': nameControllerA.value.text,
                'phoneNumber': numberControllerA.value.text,
                "notesTeamA": notesTeamA.value.text.isNotEmpty
                    ? notesTeamA.value.text.toString()
                    : "",
              },
              "teamB": {
                'teamName':
                    checkBoxTeamB.value ? teamControllerB.value.text : '',
                'personName':
                    checkBoxTeamB.value ? nameControllerB.value.text : '',
                'phoneNumber':
                    checkBoxTeamB.value ? numberControllerB.value.text : '',
                "notesTeamB": notesTeamB.value.text.isNotEmpty
                    ? notesTeamB.value.text.toString()
                    : "",
              },
              'slotPrice': int.parse(priceController.value.text.toString()),
              'totalSlotPrice': updatedPrice,
              'advancePayment': advancePaymentCalculate(),
              'slotStatus': slotStatus(),
              'bothTeamBooked': checkBoxTeamB.value,
              'slotID': widget.slotID,
              'bookingID': widget.bookingID,
              'date': widget.date,
            }).then((value) async => {
                      await _server
                          .collection("SportistanUsers")
                          .doc(user.docChanges.first.doc.id)
                          .update({
                        'sportistanCredit': balance - serverCommissionCharge
                      }).then((value) =>
                              {alertUser(bookingID: widget.bookingID)})
                    });
          } on SocketException catch (e) {
            if (mounted) {
              Errors.flushBarInform(
                  e.toString(), context, "Internet Connectivity");
            }
          } catch (e) {
            if (mounted) {
              Errors.flushBarInform(e.toString(), context, "Error");
            }
          }
        }
      } else {
        if (mounted) {
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Low Balance",
                      style: TextStyle(
                          fontFamily: "DMSans",
                          fontSize: 22,
                          color: Colors.red),
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
                      style:
                          const TextStyle(fontFamily: "DMSans", fontSize: 16),
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
                        style: const TextStyle(
                            fontSize: 50, color: Colors.redAccent),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Our commitment to assist you better we are charging ${commission.toString()}% commission from you which is Rs.${serverCommissionCharge.toString()} Please add credits to continue booking services on Sportistan",
                      style: const TextStyle(
                          fontSize: 22,
                          color: Colors.black54,
                          fontFamily: "Nunito"),
                    ),
                  ),
                  CupertinoButton(
                      color: Colors.green,
                      child: const Text("Add Credits"),
                      onPressed: () {
                        PageRouter.push(context, const SportistanCredit());
                      })
                ],
              );
            },
          );
        }
      }
    }
  }

  String slotStatus() {
    if (checkBoxTeamB.value) {
      return 'Booked';
    } else {
      return 'Half Booked';
    }
  }

  num advancePaymentCalculate() {
    if (alreadyCommissionCharged) {
      return commissionCharged + serverCommissionCharge;
    } else {
      return serverCommissionCharge;
    }
  }

  num calculateFeesDue() {
    return totalSlotPrice - serverCommissionCharge;
  }
}

class Content extends StatefulWidget {
  final String title;
  final Widget child;

  const Content({
    super.key,
    required this.title,
    required this.child,
  });

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
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontFamily: "DMSans",
                  fontSize: 18,
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
