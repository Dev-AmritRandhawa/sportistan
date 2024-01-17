import 'dart:io';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:chips_choice/chips_choice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:fluttercontactpicker/fluttercontactpicker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:sliding_up_panel2/sliding_up_panel2.dart';
import 'package:sportistan/booking/booking_info.dart';
import 'package:sportistan/booking/send_cloud_message.dart';
import 'package:sportistan/booking/unique.dart';
import 'package:sportistan/nav/nav_profile.dart';
import 'package:sportistan/payment/gateway.dart';
import 'package:sportistan/widgets/errors.dart';
import 'package:sportistan/widgets/page_route.dart';

class BookASlot extends StatefulWidget {
  final String group;
  final String slotID;
  final String bookingID;
  final String groundType;
  final String date;
  final String nonFormattedTime;
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
    required this.nonFormattedTime,
  });

  @override
  State<BookASlot> createState() => _BookASlotState();
}

class _BookASlotState extends State<BookASlot> {
  late BuildContext buildContextWaiting;
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
  ValueNotifier<bool> checkBoxListener = ValueNotifier<bool>(false);
  ValueNotifier<bool> showTeamB = ValueNotifier<bool>(false);
  ValueNotifier<bool> panelLoading = ValueNotifier<bool>(true);
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

  int teamALevelTag = 1;
  int teamBLevelTag = 1;
  List<String> teamALevelTagOptions = [
    'Beginner',
    'Intermediate',
    'Advance',
    'Pro',
  ];
  List<String> teamBLevelTagOptions = [
    'Beginner',
    'Intermediate',
    'Advance',
    'Pro',
  ];

  PanelController pc = PanelController();

  late num finalDeduction;

  late num calculateDeduction;
  late num newAmount;

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
                    checkBoxTeamB.value = true,
                    hideData.value = true,
                    showTeamB.value = true,
                    alreadyCommissionCharged = true,
                    commissionCharged =
                        value.docs.first["bookingCommissionCharged"],
                    teamALevelTag = value.docs.first["teamASkill"],
                    teamBLevelTag = value.docs.first["teamBSkill"],
                  },
              });
    } else {
      updatedPrice = widget.slotPrice;
      double newAmount = updatedPrice / 2.toInt().round();
      priceController.text = newAmount.round().toInt().toString();
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.groundName),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      resizeToAvoidBottomInset: false,
      body: SlidingUpPanel(
        minHeight: 0,
        maxHeight: MediaQuery.of(context).size.height,
        controller: pc,
        panelBuilder: () => panel(),
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
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
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
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
                                            controller: teamControllerA,
                                            onChanged: (data) {
                                              nameKeyA.currentState!.validate();
                                            },
                                            enabled: !value,
                                            obscureText: !hideData.value,
                                            decoration: const InputDecoration(
                                                fillColor: Colors.white,
                                                border: InputBorder.none,
                                                errorStyle: TextStyle(
                                                    color: Colors.red),
                                                labelText: "Team A Name*",
                                                filled: true,
                                                labelStyle: TextStyle(
                                                    color: Colors.black)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Form(
                                        key: nameKeyA,
                                        child: SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
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
                                            controller: nameControllerA,
                                            onChanged: (data) {
                                              nameKeyA.currentState!
                                                  .validate();
                                            },
                                            keyboardType: TextInputType.name,
                                            enabled: !value,
                                            obscureText: hideData.value,
                                            decoration: const InputDecoration(

                                                fillColor: Colors.white,
                                                labelText: "Contact Person*",
                                                border: InputBorder.none,
                                                errorStyle: TextStyle(
                                                    color: Colors.red),
                                                filled: true,
                                                labelStyle: TextStyle(
                                                    color: Colors.black)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Form(
                                        key: numberKeyA,
                                        child: SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              1.2,
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
                                            obscureText: hideData.value,
                                            controller: numberControllerA,
                                            onChanged: (data) {
                                              numberKeyA.currentState!
                                                  .validate();
                                            },
                                            keyboardType: TextInputType.phone,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .allow(RegExp('[0-9]')),
                                            ],
                                            autofillHints: const [
                                              AutofillHints
                                                  .telephoneNumberLocal
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
                                                    icon: const Icon(Icons
                                                        .contacts_rounded)),
                                                suffixIcon: IconButton(
                                                    onPressed: () async {
                                                      if (numberControllerA
                                                          .value
                                                          .text
                                                          .isEmpty) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                                const SnackBar(
                                                                    content: Text(
                                                                        "No Number Available")));
                                                      } else {
                                                        FlutterPhoneDirectCaller
                                                            .callNumber(
                                                                numberControllerA
                                                                    .value
                                                                    .text);
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
                                    hideData.value
                                        ? Column(
                                            children: [
                                              const Text("Team A Skill Level",
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      fontFamily: "DMSans")),
                                              const Icon(
                                                  Icons.stacked_bar_chart,
                                                  color: Colors.indigo),
                                              Card(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                      teamALevelTagOptions[
                                                              teamALevelTag]
                                                          .toString(),
                                                      style: const TextStyle(
                                                          fontFamily: "DMSans",
                                                          fontSize: 18)),
                                                ),
                                              )
                                            ],
                                          )
                                        : ListView(
                                            shrinkWrap: true,
                                            addAutomaticKeepAlives: true,
                                            children: <Widget>[
                                                Content(
                                                  title: 'Skill Level',
                                                  child:
                                                      ChipsChoice<int>.single(
                                                    value: teamALevelTag,
                                                    onChanged: hideData.value
                                                        ? (v) => {}
                                                        : (val) => setState(
                                                            () =>
                                                                teamALevelTag =
                                                                    val),
                                                    choiceItems: C2Choice
                                                        .listFrom<int, String>(
                                                      source:
                                                          teamALevelTagOptions,
                                                      value: (i, v) => i,
                                                      label: (i, v) => v,
                                                      tooltip: (i, v) => v,
                                                    ),
                                                    choiceCheckmark: true,
                                                    choiceStyle:
                                                        C2ChipStyle.filled(
                                                      selectedStyle:
                                                          const C2ChipStyle(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                          Radius.circular(25),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ]),
                                    Visibility(
                                      visible: !hideData.value,
                                      child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: SizedBox(
                                            child: TextFormField(
                                              controller: notesTeamA,
                                              decoration: const InputDecoration(
                                                fillColor: Colors.white,
                                                border: InputBorder.none,
                                                errorStyle: TextStyle(
                                                    color: Colors.red),
                                                filled: true,
                                                hintText: "Notes (Optional)",
                                                hintStyle: TextStyle(
                                                    color: Colors.black45),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        vertical: 40),
                                              ),
                                              enabled: !value,
                                              obscureText: value,
                                            ),
                                          )),
                                    )
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
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
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
                                                nameKeyB.currentState!
                                                    .validate();
                                              },
                                              decoration: const InputDecoration(
                                                  fillColor: Colors.white,
                                                  border: InputBorder.none,
                                                  errorStyle: TextStyle(
                                                      color: Colors.red),
                                                  labelText: "Team B Name*",
                                                  filled: true,
                                                  labelStyle: TextStyle(
                                                      color: Colors.black)),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Form(
                                          key: nameKeyB,
                                          child: SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
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
                                                nameKeyB.currentState!
                                                    .validate();
                                              },
                                              decoration: const InputDecoration(
                                                  fillColor: Colors.white,
                                                  labelText: "Contact Person*",
                                                  border: InputBorder.none,
                                                  errorStyle: TextStyle(
                                                      color: Colors.red),
                                                  filled: true,
                                                  labelStyle: TextStyle(
                                                      color: Colors.black)),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Form(
                                          key: numberKeyB,
                                          child: SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
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
                                                numberKeyB.currentState!
                                                    .validate();
                                              },
                                              keyboardType: TextInputType.phone,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .allow(RegExp('[0-9]')),
                                              ],
                                              autofillHints: const [
                                                AutofillHints
                                                    .telephoneNumberLocal
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
                                                      icon: const Icon(Icons
                                                          .contacts_rounded)),
                                                  suffixIcon: IconButton(
                                                      onPressed: () async {
                                                        if (numberControllerB
                                                            .value
                                                            .text
                                                            .isEmpty) {
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
                                                                      .value
                                                                      .text);
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
                                      ListView(
                                          shrinkWrap: true,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          addAutomaticKeepAlives: true,
                                          children: <Widget>[
                                            Content(
                                              title: 'Skill Level',
                                              child: ChipsChoice<int>.single(
                                                value: teamBLevelTag,
                                                onChanged: (val) => setState(
                                                    () => teamBLevelTag = val),
                                                choiceItems: C2Choice.listFrom<
                                                    int, String>(
                                                  source: teamBLevelTagOptions,
                                                  value: (i, v) => i,
                                                  label: (i, v) => v,
                                                  tooltip: (i, v) => v,
                                                ),
                                                choiceCheckmark: true,
                                                choiceStyle: C2ChipStyle.filled(
                                                  selectedStyle:
                                                      const C2ChipStyle(
                                                    borderRadius:
                                                        BorderRadius.all(
                                                      Radius.circular(25),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ]),
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
                                              hintStyle: TextStyle(
                                                  color: Colors.black45),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      vertical: 40),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Container();
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ValueListenableBuilder(
                              valueListenable: checkBoxTeamB,
                              builder: (context, value, child) => SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 2,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CupertinoSwitch(
                                            value: value,
                                            onChanged: widget
                                                    .bookingID.isNotEmpty
                                                ? null
                                                : (result) {
                                                    if (nameKeyA.currentState!
                                                            .validate() &
                                                        numberKeyA.currentState!
                                                            .validate() &
                                                        teamControllerKeyA
                                                            .currentState!
                                                            .validate()) {
                                                      checkBoxTeamB.value =
                                                          result;
                                                      teamControllerB.text =
                                                          teamControllerA
                                                              .value.text;
                                                      nameControllerB.text =
                                                          nameControllerA
                                                              .value.text;
                                                      numberControllerB.text =
                                                          numberControllerA
                                                              .value.text;
                                                      showTeamB.value = result;
                                                      if (result) {
                                                        setState(() {
                                                          num newAmount =
                                                              updatedPrice;
                                                          priceController.text =
                                                              newAmount
                                                                  .toString();
                                                        });
                                                      } else {
                                                        setState(() {
                                                          double newAmount =
                                                              updatedPrice /
                                                                  2
                                                                      .toInt()
                                                                      .round();
                                                          priceController.text =
                                                              newAmount
                                                                  .round()
                                                                  .toInt()
                                                                  .toString();
                                                        });
                                                      }
                                                    }
                                                  }),
                                        const Text(
                                          "Book for both Teams",
                                          style:
                                              TextStyle(fontFamily: "DMSans"),
                                        )
                                      ],
                                    ),
                                  )),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height / 4,
                    )
                  ],
                ),
              ),
              Positioned(
                left: MediaQuery.of(context).size.width / 8,
                right: MediaQuery.of(context).size.width / 8,
                bottom: MediaQuery.of(context).size.height / 6,
                child: CupertinoButton(
                    color: Colors.indigo,
                    onPressed: () {
                      if (hideData.value) {
                        if (nameKeyB.currentState!.validate() &
                            numberKeyB.currentState!.validate() &
                            teamControllerKeyB.currentState!.validate()) {
                          _bookSlot();
                        } else {
                          Errors.flushBarInform("Field Required for Team B*",
                              context, "Enter field");
                        }
                      } else {
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
                                  "Field Required for Team B*",
                                  context,
                                  "Enter field");
                            }
                          } else {
                            _bookSlot();
                          }
                        } else {
                          Errors.flushBarInform("Field Required for Team A*",
                              context, "Enter field");
                        }
                      }
                    },
                    child: const Text(
                      "Book Slot",
                      style: TextStyle(color: Colors.white),
                    )),
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
      await _server
          .collection("SportistanUsers")
          .where('userID', isEqualTo: _auth.currentUser!.uid)
          .get()
          .then((value) => {
                if (value.docChanges.isNotEmpty)
                  {data = value.docChanges, _checkBalance()}
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
            await sendSms(number: numberControllerA.value.text);
          }
        }
      }
    }
    updateSmsAlert = false;
    await notifyPartner();
    moveToReceipt(bookingID: bookingID);
  }

  moveToReceipt({required String bookingID}) async {
    PageRouter.pushRemoveUntil(context, BookingInfo(bookingID: bookingID));
  }

  late num serverCommissionCharge;
  late num balance;

  createBooking() async {
    if (widget.bookingID.isEmpty) {
      String uniqueID = UniqueID.generateRandomString();
      try {
        await _server.collection("GroundBookings").add({
          'slotTime': widget.slotTime.toString(),
          'nonFormattedTime': widget.nonFormattedTime.toString(),
          'bookingPerson': data.first.doc.get('name'),
          'groundName': widget.groundName,
          'bookingCreated': DateTime.parse(widget.date),
          'bookedAt': DateTime.now(),
          'groundType': widget.groundType,
          'shouldCountInBalance': false,
          'isBookingCancelled': false,
          'entireDayBooking': false,
          'userID': _auth.currentUser!.uid,
          'bookingCommissionCharged': serverCommissionCharge,
          'feesDue': calculateFeesDue(),
          'ratingGiven': false,
          'rating': 3.0,
          'ratingTags': [],
          'teamASkill': teamALevelTag.toInt(),
          'teamBSkill': showTeamB.value ? teamBLevelTag.toInt() : 1,
          'groundID': widget.groundID,
          'TeamA': alreadyCommissionCharged
              ? commissionCharged
              : serverCommissionCharge,
          'TeamB':
              checkBoxTeamB.value ? serverCommissionCharge : 'NotApplicable',
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
          'slotPrice': checkBoxTeamB.value
              ? updatedPrice
              : updatedPrice / 2.toInt().round(),
          'totalSlotPrice': updatedPrice,
          'advancePayment': advancePaymentCalculate(),
          'slotStatus': slotStatus(),
          'bothTeamBooked': checkBoxTeamB.value,
          'slotID': widget.slotID,
          'bookingID': uniqueID,
          'date': widget.date,
        }).then((value) async => {
              await _server
                  .collection("SportistanUsers")
                  .doc(data.first.doc.id)
                  .update({
                'sportistanCredit': balance - serverCommissionCharge
              }).then((value) => {alertUser(bookingID: uniqueID)})
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
        var refDetails = await _server
            .collection("GroundBookings")
            .where("bookingID", isEqualTo: widget.bookingID)
            .get();
        await _server
            .collection("GroundBookings")
            .doc(refDetails.docs.first.id)
            .update({
          'slotTime': widget.slotTime.toString(),
          'nonFormattedTime': widget.nonFormattedTime.toString(),
          'bookingPerson': data.first.doc.get('name'),
          'groundName': widget.groundName,
          'bookingCreated': DateTime.parse(widget.date),
          'bookedAt': DateTime.now(),
          'groundType': widget.groundType,
          'shouldCountInBalance': false,
          'isBookingCancelled': false,
          'userID': _auth.currentUser!.uid,
          'bookingCommissionCharged': serverCommissionCharge,
          'feesDue': calculateFeesDue(),
          'ratingGiven': false,
          'entireDayBooking': false,
          'rating': 3.0,
          'ratingTags': [],
          'groundID': widget.groundID,
          'TeamA': alreadyCommissionCharged
              ? commissionCharged
              : serverCommissionCharge,
          'TeamB':
              checkBoxTeamB.value ? serverCommissionCharge : 'NotApplicable',
          'teamASkill': teamALevelTag.toInt(),
          'teamBSkill': showTeamB.value ? teamBLevelTag.toInt() : 1,
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
          'slotPrice': checkBoxTeamB.value
              ? updatedPrice
              : updatedPrice / 2.toInt().round(),
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
                      .doc(data.first.doc.id)
                      .update({'sportistanCredit': finalDeduction}).then(
                          (value) => {alertUser(bookingID: widget.bookingID)})
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

  Future<void> _checkBalance() async {
    balance = data.first.doc.get("sportistanCredit");
    QuerySnapshot<Map<String, dynamic>> partner = await _server
        .collection('SportistanPartners')
        .where('groundID', isEqualTo: widget.groundID.toString())
        .get();
    num commission = partner.docChanges.first.doc.get("commission");
    num result = int.parse(priceController.value.text.trim()) / 100;
    num newCommissionCharge = result * commission.toInt();

    if (alreadyCommissionCharged) {
      serverCommissionCharge = newCommissionCharge;
      serverCommissionCharge = serverCommissionCharge - commissionCharged;
    } else {
      serverCommissionCharge = newCommissionCharge;
    }
    pc.open();

    panelLoading.value = false;
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
      return updatedPrice / 2.toInt().round() - serverCommissionCharge;
    }
  }

  num calculateFeesDue() {
    if (checkBoxTeamB.value) {
      return updatedPrice - serverCommissionCharge;
    }
    return updatedPrice / 2 - serverCommissionCharge;
  }

  panel() {
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: panelLoading,
        builder: (context, value, child) => value
            ? Center(
                child: Column(children: [
                  CircularProgressIndicator(
                    strokeWidth: 1,
                    color: Colors.grey.shade200,
                  )
                ]),
              )
            : Center(
                child: SingleChildScrollView(
                  child: Column(children: [
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
                                  'Slot Time',
                                  style: TextStyle(
                                    fontFamily: "DMSans",
                                    fontSize: 20,
                                    color: Colors.black,
                                  ),
                                  softWrap: true,
                                ),
                                Text(
                                  widget.slotTime,
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
                    InkWell(
                      onTap: () {
                        PageRouter.push(context, const NavProfile());
                      },
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              const Icon(Icons.privacy_tip_sharp,color: Colors.orange),
                              const Text('Your are logged in',
                                  style: TextStyle(
                                      fontFamily: "DMSans",
                                      color: Colors.green,
                                      fontSize: 18)),
                              Text(
                                  FirebaseAuth.instance.currentUser!.phoneNumber
                                      .toString(),
                                  style: const TextStyle(
                                      fontFamily: "DMSans", fontSize: 18)),
                            ],
                          ),
                        ),
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
                            "₹$updatedPrice",
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
                            "₹$updatedPrice",
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
                            "₹${calculateFeesDue()}",
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    checkBoxTeamB.value
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Team A Advance",
                                  style: TextStyle(
                                    fontFamily: "DMSans",
                                    fontSize: 18,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  "₹$commissionCharged",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Booking Amount",
                            style: TextStyle(
                              fontFamily: "DMSans",
                              fontSize: 18,
                              color: Colors.orangeAccent,
                            ),
                          ),
                          Text(
                            "₹$serverCommissionCharge",
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
                                  newAmount = serverCommissionCharge;

                                  if (value) {
                                    if (newAmount <= balance) {
                                      newAmount = 0;
                                      finalDeduction = balance - newAmount;
                                    } else {
                                      newAmount = newAmount - balance;
                                      finalDeduction = newAmount - balance;
                                    }
                                  } else {
                                    finalDeduction = balance;
                                    newAmount = serverCommissionCharge;
                                  }

                                  return value
                                      ? Text(
                                          "₹$newAmount ",
                                          style: const TextStyle(
                                            fontSize: 22,
                                            color: Colors.green,
                                          ),
                                        )
                                      : Text(
                                          "₹$serverCommissionCharge ",
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
                                  builder: (context, valueBox, child) =>
                                      Checkbox(
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
                          if (newAmount == 0) {
                            showModalBottomSheet(
                              context: context,
                              builder: (buildContextWaiting) {
                                return Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    const Text("Please Wait",
                                        style: TextStyle(
                                            fontFamily: "DMSans",
                                            fontSize: 22)),
                                    Image.asset('assets/logo.png',
                                        height:
                                            MediaQuery.of(context).size.height /
                                                8),
                                    AnimatedTextKit(animatedTexts: [
                                      TyperAnimatedText(
                                          "We are confirming your booking..",
                                          textStyle:
                                              const TextStyle(fontSize: 22)),
                                    ]),
                                    const CircularProgressIndicator(
                                        strokeWidth: 1, color: Colors.green),
                                    CupertinoButton(
                                        onPressed: () {
                                          Navigator.pop(buildContextWaiting);
                                        },
                                        child: const Text('Cancel'))
                                  ],
                                );
                              },
                            );
                            await createBooking();
                          } else {
                            if (Platform.isAndroid) {
                              final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Gateway(
                                      amount: newAmount.toString(),
                                      groundID: FirebaseAuth
                                          .instance.currentUser!.uid,
                                    ),
                                  ));

                              if (result) {
                                if (mounted) {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (buildContextWaiting) {
                                      return Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          const Text("Please Wait",
                                              style: TextStyle(
                                                  fontFamily: "DMSans",
                                                  fontSize: 22)),
                                          Image.asset('assets/logo.png',
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height /
                                                  8),
                                          AnimatedTextKit(animatedTexts: [
                                            TyperAnimatedText(
                                                "We are confirming your booking..",
                                                textStyle: const TextStyle(
                                                    fontSize: 22)),
                                          ]),
                                          const CircularProgressIndicator(
                                              strokeWidth: 1,
                                              color: Colors.green),
                                          CupertinoButton(
                                              onPressed: () {
                                                Navigator.pop(
                                                    buildContextWaiting);
                                              },
                                              child: const Text('Cancel'))
                                        ],
                                      );
                                    },
                                  );
                                  createBooking();
                                }
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text("Payment Failed",
                                        style: TextStyle(color: Colors.white)),
                                    backgroundColor: Colors.red,
                                  ));
                                }
                              }
                            } else {
                              final result = await Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) => Gateway(
                                      amount: newAmount.toString(),
                                      groundID: FirebaseAuth
                                          .instance.currentUser!.uid,
                                    ),
                                  ));
                              if (result) {
                                if (mounted) {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (buildContextWaiting) {
                                      return Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          const Text("Please Wait",
                                              style: TextStyle(
                                                  fontFamily: "DMSans",
                                                  fontSize: 22)),
                                          Image.asset('assets/logo.png',
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height /
                                                  8),
                                          AnimatedTextKit(animatedTexts: [
                                            TyperAnimatedText(
                                                "We are confirming your booking..",
                                                textStyle: const TextStyle(
                                                    fontSize: 22)),
                                          ]),
                                          const CircularProgressIndicator(
                                              strokeWidth: 1,
                                              color: Colors.green),
                                          CupertinoButton(
                                              onPressed: () {
                                                Navigator.pop(
                                                    buildContextWaiting);
                                              },
                                              child: const Text('Cancel'))
                                        ],
                                      );
                                    },
                                  );
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
                            builder: (context, value, child) => newAmount == 0
                                ? const Text('Payable Now')
                                : Text(
                                    'Pay ₹${newAmount.round().toString()}'))),
                    TextButton(
                        onPressed: () {
                          showModalBottomSheet(
                              context: context,
                              builder: (buildContextWaiting) {
                                return const Column(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                          'Refund & Cancellation Policy',
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
                  ]),
                ),
              ),
      ),
    );
  }

  Future<void> notifyPartner() async {
    String date = DateFormat.yMMMMEEEEd().format(DateTime.parse((widget.date)));
    await _server
        .collection("SportistanPartners")
        .where('groundID', isEqualTo: widget.groundID)
        .get()
        .then((value) => {
              if (value.docChanges.isNotEmpty)
                {
                  FirebaseCloudMessaging.sendPushMessage(
                      'Hello ${widget.groundName}, You have received a booking for $date at ${widget.slotTime} tap to see more details.',
                      "You received a booking",
                      value.docChanges.first.doc.get('token'))
                }
            });
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
    return Column(
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
    );
  }
}
