import 'dart:convert';
import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:chips_choice/chips_choice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sliding_up_panel2/sliding_up_panel2.dart';
import 'package:SportistanPro/authentication/set_location.dart';
import 'package:SportistanPro/booking/show_slots.dart';
import 'package:SportistanPro/nav/edit_your_sports.dart';
import 'package:SportistanPro/nav/search_grounds_by_algolia.dart';
import 'package:SportistanPro/widgets/errors.dart';
import 'package:SportistanPro/widgets/page_route.dart';

class MapKey {
  static String mapKey = 'AIzaSyB3UX-i3zW0iDWnsaOLHDIN6CeE6IqTBEg';
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  String? onwards;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    initServer();
    super.initState();
  }

  ValueNotifier<bool> dayLoading = ValueNotifier<bool>(false);
  String? address;
  String? name;
  ValueNotifier<bool> showCurrentAddress = ValueNotifier<bool>(false);

  late double latitude;
  late double longitude;
  int currentPage = 0;
  List<dynamic> groundServices = [];
  double radiusInKm = 30;
  ValueNotifier<bool> panelListener = ValueNotifier<bool>(false);
  ValueNotifier<bool> directionListened = ValueNotifier<bool>(false);
  ValueNotifier<int> dotsListener = ValueNotifier<int>(0);
  PanelController panelController = PanelController();

  final _server = FirebaseFirestore.instance;

  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> init() {
    GeoPoint location = GeoPoint(latitude, longitude);
    GeoFirePoint center = GeoFirePoint(location);
    const String field = 'geo';

    final CollectionReference<Map<String, dynamic>> collectionReference =
        FirebaseFirestore.instance.collection("SportistanPartners");

    GeoPoint geopointFrom(Map<String, dynamic> data) =>
        (data['geo'] as Map<String, dynamic>)['geopoint'] as GeoPoint;

    final Stream<List<DocumentSnapshot<Map<String, dynamic>>>> stream =
        GeoCollectionReference<Map<String, dynamic>>(collectionReference)
            .subscribeWithin(
                center: center,
                radiusInKm: radiusInKm,
                field: field,
                geopointFrom: geopointFrom,
                queryBuilder: (query) => query
                    .where("isVerified", isEqualTo: true)
                    .where('isKYCPending', isEqualTo: false)
                    .where('isAccountOnHold', isEqualTo: false)
                    .where('groundType', isEqualTo: sportTags.toString()),
                strictMode: true);
    return stream;
  }

  String? groundID;
  String? groundName;
  String? groundType;

  String? distanceText;
  String? durationText;

  double? destinationLat;
  double? destinationLong;

  String? groundAddress;

  List<String> grounds = [
    'Cricket',
    'Football',
    'Tennis',
    'Hockey',
    'Badminton',
    'Volleyball',
    'Swimming',
  ];

  String? sportTags;

  List<String> sportTagsOptions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SlidingUpPanel(
            controller: panelController,
            minHeight: 0,
            disableDraggableOnScrolling: true,
            maxHeight: MediaQuery.of(context).size.height,
            panelBuilder: () => panel(),
            body: CustomScrollView(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              slivers: <Widget>[
                SliverAppBar(
                  backgroundColor: Colors.white,
                  expandedHeight: MediaQuery.of(context).size.height / 4.8,
                  snap: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: ValueListenableBuilder(
                      valueListenable: dayLoading,
                      builder: (context, value, child) => value
                          ? Column(
                              children: [
                                const Row(
                                  children: [
                                    Padding(
                                      padding:
                                          EdgeInsets.only(left: 8.0, top: 5.0),
                                      child: Text("Hi ",
                                          style: TextStyle(
                                            fontFamily: "DMSans",
                                            fontSize: 18,
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w400,
                                          )),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        child: Text('$name,',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontFamily: "DMSans",
                                                fontSize: 26,
                                                color: Colors.black),
                                            softWrap: true),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Text("You are in",
                                        style: TextStyle(
                                          fontFamily: "DMSans",
                                        )),
                                    const Icon(
                                      Icons.location_pin,
                                      color: Colors.redAccent,
                                    ),
                                    InkWell(
                                      onTap: () {
                                        PageRouter.push(
                                            context, const SetLocation());
                                      },
                                      child: Text(address.toString(),
                                          style: const TextStyle(
                                              fontFamily: "DMSans",
                                              fontWeight: FontWeight.bold,
                                              fontSize: 26,
                                              color: Colors.blue)),
                                    ),
                                    const Icon(
                                      Icons.arrow_drop_down_outlined,
                                      color: Colors.blue,
                                    )
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: InkWell(
                                    onTap: () {
                                      PageRouter.push(
                                          context,
                                          SearchGroundsByAlgolia(
                                            originLat: latitude,
                                            originLong: longitude,
                                          ));
                                    },
                                    child: TextFormField(
                                      style:
                                          const TextStyle(color: Colors.black),
                                      decoration: InputDecoration(
                                          hintText: "Search Ground, Location, Near Me",
                                          fillColor: Colors.grey.shade200,
                                          filled: true,
                                          enabled: false,
                                          suffixIcon: const Icon(Icons.search),
                                          border: const OutlineInputBorder(
                                              borderSide: BorderSide.none,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(50)))),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Shimmer.fromColors(
                              baseColor: Colors.grey,
                              highlightColor: Colors.white,
                              child: const Center(
                                  child: CircularProgressIndicator(
                                strokeWidth: 1,
                              ))),
                    ),
                  ), //FlexibleSpaceBar

                  //IconButton
                  //<Widget>[]
                ),

                SliverToBoxAdapter(
                  child: ValueListenableBuilder(
                    valueListenable: dayLoading,
                    builder: (context, value, child) {
                      return value
                          ? SingleChildScrollView(
                              child: Column(children: [
                                StreamBuilder<List<DocumentSnapshot>>(
                                    stream: init(),
                                    builder: (BuildContext context, snapshot) {
                                      final List<DocumentSnapshot<Object?>>?
                                          docs = snapshot.data;
                                      return snapshot.hasData
                                          ? SingleChildScrollView(
                                              child: Column(
                                                children: [
                                                  SingleChildScrollView(
                                                    physics:
                                                        const BouncingScrollPhysics(),
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    child: Row(
                                                      children: [
                                                        ChipsChoice<
                                                            String>.single(
                                                          value: sportTags,
                                                          onChanged: (val) =>
                                                              setState(() =>
                                                                  sportTags =
                                                                      val),
                                                          choiceItems:
                                                              C2Choice.listFrom<
                                                                  String,
                                                                  String>(
                                                            source:
                                                                sportTagsOptions,
                                                            value: (i, v) => v,
                                                            label: (i, v) => v,
                                                            tooltip: (i, v) =>
                                                                v,
                                                          ),
                                                          choiceStyle:
                                                              C2ChipStyle.toned(
                                                                  selectedStyle:
                                                                      C2ChipStyle
                                                                          .toned(
                                                            foregroundColor:
                                                                Colors.black,
                                                          )),
                                                          wrapped: true,
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  right: 8.0),
                                                          child: OutlinedButton(
                                                              onPressed: () {
                                                                if (Platform
                                                                    .isAndroid) {
                                                                  Navigator
                                                                      .push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                            builder: (context) =>
                                                                                EditYourSports(prefs: sportTagsOptions),
                                                                          )).then(
                                                                      (value) =>
                                                                          {
                                                                            if (value ==
                                                                                true)
                                                                              {
                                                                                initServer()
                                                                              }
                                                                          });
                                                                }
                                                                if (Platform
                                                                    .isIOS) {
                                                                  Navigator
                                                                      .push(
                                                                          context,
                                                                          CupertinoPageRoute(
                                                                            builder: (context) =>
                                                                                EditYourSports(prefs: sportTagsOptions),
                                                                          )).then(
                                                                      (value) =>
                                                                          {
                                                                            if (value ==
                                                                                true)
                                                                              {
                                                                                initServer()
                                                                              }
                                                                          });
                                                                }
                                                              },
                                                              child: const Text(
                                                                "Add Sports +",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .green),
                                                              )),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      docs!.length <= 1
                                                          ? Text(
                                                              "  We found ${docs.length} ground in ${radiusInKm.toInt().toString()} Kms",
                                                              style: const TextStyle(
                                                                  fontFamily:
                                                                      "DMSans",
                                                                  fontSize: 16,
                                                                  color: Colors
                                                                      .green))
                                                          : Text(
                                                              "  We found ${docs.length} grounds in ${radiusInKm.toInt().toString()} Kms  ",
                                                              style: const TextStyle(
                                                                  fontFamily:
                                                                      "DMSans",
                                                                  fontSize: 16,
                                                                  color: Colors
                                                                      .green)),
                                                      IconButton(
                                                          onPressed: () {
                                                            setFilter();
                                                          },
                                                          icon:
                                                              const CircleAvatar(
                                                            child: Icon(
                                                              Icons.filter_list,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          )),
                                                    ],
                                                  ),
                                                  if (docs.isEmpty)
                                                    Column(
                                                      children: [
                                                        Image.asset(
                                                            "assets/noResults.png",
                                                            height: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .height /
                                                                4),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child:
                                                              CupertinoButton(
                                                                  color: Colors
                                                                      .green,
                                                                  onPressed:
                                                                      () {
                                                                    setFilter();
                                                                  },
                                                                  child:
                                                                      const Text(
                                                                    "Change Distance",
                                                                    style: TextStyle(
                                                                        fontFamily:
                                                                            "DMSans"),
                                                                  )),
                                                        )
                                                      ],
                                                    )
                                                  else
                                                    ListView.builder(
                                                      physics:
                                                          const BouncingScrollPhysics(),
                                                      shrinkWrap: true,
                                                      itemCount: docs.length,
                                                      itemBuilder: (_, index) {

                                                        List<dynamic> images =
                                                            docs[index]["groundImages"];
                                                        List<dynamic>
                                                            listCount =
                                                        docs[index]['badges'];
                                                        groundServices = docs[index][
                                                            'groundServices'];

                                                        onwards = docs[index]['onwards']
                                                            .toString();

                                                        return GestureDetector(
                                                          onTap: () async {
                                                            groundID =
                                                                docs[index]["groundID"];
                                                            groundType = docs[index][
                                                                "groundType"];
                                                            groundAddress = docs[index][
                                                                "locationName"];
                                                            groundName = docs[index][
                                                                "groundName"];
                                                            panelListener
                                                                .value = true;
                                                            GeoPoint geoPoint =
                                                            docs[index]["geo"][
                                                                    'geopoint'];
                                                            destinationLat =
                                                                geoPoint
                                                                    .latitude;
                                                            destinationLong =
                                                                geoPoint
                                                                    .longitude;
                                                            directionListened
                                                                .value = false;
                                                            await getDistanceMatrix(
                                                              originLat:
                                                                  latitude,
                                                              originLong:
                                                                  longitude,
                                                              destinationLat:
                                                                  destinationLat,
                                                              destinationLong:
                                                                  destinationLong,
                                                            );
                                                            panelController
                                                                .open();
                                                          },
                                                          child: Column(
                                                              children: [
                                                                listCount
                                                                        .isNotEmpty
                                                                    ? Container(
                                                                        width: double
                                                                            .infinity,
                                                                        height:
                                                                            MediaQuery.of(context).size.height /
                                                                                20,
                                                                        alignment:
                                                                            Alignment.topCenter,
                                                                        child: ListView.builder(
                                                                            shrinkWrap: true,
                                                                            physics: const BouncingScrollPhysics(),
                                                                            scrollDirection: Axis.horizontal,
                                                                            itemBuilder: (context, index) {
                                                                              return Row(
                                                                                children: [
                                                                                  Padding(
                                                                                    padding: const EdgeInsets.all(8.0),
                                                                                    child: Row(
                                                                                      children: [
                                                                                        Text("🏅${listCount[index]}", style: const TextStyle(fontFamily: "DMSans")),
                                                                                      ],
                                                                                    ),
                                                                                  )
                                                                                ],
                                                                              );
                                                                            },
                                                                            itemCount: listCount.length),
                                                                      )
                                                                    : Container(),
                                                                CarouselSlider
                                                                    .builder(
                                                                  itemCount:
                                                                      images
                                                                          .length,
                                                                  itemBuilder: (BuildContext
                                                                          context,
                                                                      int itemIndex,
                                                                      int pageViewIndex) {
                                                                    return Stack(
                                                                      children: [
                                                                        ClipRRect(
                                                                          borderRadius:
                                                                              BorderRadius.circular(10),
                                                                          child:
                                                                              Image.network(
                                                                                docs[index]["groundImages"][itemIndex],
                                                                            loadingBuilder: (context,
                                                                                child,
                                                                                loadingProgress) {
                                                                              if (loadingProgress == null) {
                                                                                return child;
                                                                              }
                                                                              return Shimmer.fromColors(
                                                                                baseColor: Colors.grey.shade300,
                                                                                highlightColor: Colors.grey.shade100,
                                                                                enabled: true,
                                                                                child: Center(
                                                                                  child: Image.asset(height: MediaQuery.of(context).size.height / 6, width: MediaQuery.of(context).size.height / 6, "assets/logo.png"),
                                                                                ),
                                                                              );
                                                                            },
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    );
                                                                  },
                                                                  options:
                                                                      CarouselOptions(
                                                                    height: MediaQuery.of(context)
                                                                            .size
                                                                            .height /
                                                                        4.5,
                                                                    enableInfiniteScroll:
                                                                        false,
                                                                    initialPage:
                                                                        currentPage,
                                                                    onPageChanged:
                                                                        (index,
                                                                            reason) {
                                                                      dotsListener
                                                                              .value =
                                                                          index;
                                                                    },
                                                                    enlargeFactor:
                                                                        0.3,
                                                                    scrollDirection:
                                                                        Axis.horizontal,
                                                                  ),
                                                                ),
                                                                ValueListenableBuilder(
                                                                  builder: (context,
                                                                          value,
                                                                          child) =>
                                                                      DotsIndicator(
                                                                    dotsCount:
                                                                        images
                                                                            .length,
                                                                    position:
                                                                        value,
                                                                  ),
                                                                  valueListenable:
                                                                      dotsListener,
                                                                ),
                                                                Card(
                                                                  color: const Color(
                                                                      0xfffffefa),
                                                                  child: Column(
                                                                      children: [
                                                                        Row(
                                                                          children: [
                                                                            Expanded(
                                                                              child: Padding(
                                                                                padding: const EdgeInsets.only(left: 8.0),
                                                                                child: Text(
                                                                                  docs[index].get('groundName'),
                                                                                  softWrap: true,
                                                                                  maxLines: 3,
                                                                                  overflow: TextOverflow.ellipsis,
                                                                                  style: TextStyle(fontFamily: "DMSans", fontWeight: FontWeight.w900, fontSize: MediaQuery.of(context).size.width / 15),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            const Padding(
                                                                              padding: EdgeInsets.all(8.0),
                                                                              child: Icon(
                                                                                Icons.star,
                                                                                color: Colors.orange,
                                                                              ),
                                                                            ),
                                                                            Padding(
                                                                              padding: const EdgeInsets.only(right: 8.0),
                                                                              child: Text(docs[index].get('profileRating').toString()),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        Row(
                                                                          children: [
                                                                            Padding(
                                                                              padding: const EdgeInsets.only(left: 8.0),
                                                                              child: Shimmer.fromColors(
                                                                                period: const Duration(seconds: 2),
                                                                                baseColor: Colors.black87,
                                                                                loop: 6,
                                                                                highlightColor: Colors.white,
                                                                                child: Row(
                                                                                  children: [
                                                                                    const Text('Starting Onwards : ', style: TextStyle()),
                                                                                    Text("₹${docs[index]['onwards']}",
                                                                                        style: const TextStyle(
                                                                                          fontSize: 18,
                                                                                          fontFamily: "Nunito",
                                                                                        )),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ]),
                                                                )
                                                              ]),
                                                        );
                                                      },
                                                    ),
                                                ],
                                              ),
                                            )
                                          : Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                  const Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Text(
                                                      'Searching Grounds Near You',
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        color: Colors.black54,
                                                        fontFamily: "DMSans",
                                                      ),
                                                      softWrap: true,
                                                    ),
                                                  ),
                                                  Center(
                                                    child: SizedBox(
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height /
                                                              3.5,
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height /
                                                              3.5,
                                                      child: Lottie.asset(
                                                        'assets/searching.json',
                                                        controller: _controller,
                                                        onLoaded:
                                                            (composition) {
                                                          _controller
                                                            ..duration =
                                                                composition
                                                                    .duration
                                                            ..repeat();
                                                        },
                                                      ),
                                                    ),
                                                  )
                                                ]);
                                    }),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height / 5,
                                )
                              ]),
                            )
                          : Container();
                    },
                  ),
                ),
                //SliverList
              ], //<Widget>[]
            ),
          ),
        ) //

        );
  }

  String? token;

  Future<void> initServer() async {
    sportTagsOptions.clear();
    showCurrentAddress.value = false;
    panelListener.value = false;
    dayLoading.value = false;
    directionListened.value = false;
    dotsListener.value = 0;
    var count = [];
    SharedPreferences pref = await SharedPreferences.getInstance();
    name = pref.getString('name');
    address = pref.getString('address');
    latitude = pref.getDouble('latitude')!;
    longitude = pref.getDouble('longitude')!;
    await FirebaseFirestore.instance
        .collection('SportistanUsers')
        .where('userID', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((value) async => {
              count = value.docChanges.first.doc.get('sportInterest'),
              await FirebaseMessaging.instance
                  .getToken()
                  .then((value) => {token = value.toString()}),
              await _server
                  .collection("SportistanUsers")
                  .doc(value.docChanges.first.doc.id)
                  .update({
                'token': token,
              })
            });

    for (int i = 0; i < count.length; i++) {
      sportTagsOptions.add(count[i]);
    }
    sportTags = sportTagsOptions[0];

    dayLoading.value = true;
  }

  IconData tileIcons(String type) {
    switch (type) {
      case 'Cricket':
        {
          return Icons.sports_cricket;
        }
      case 'Football':
        {
          return Icons.sports_basketball;
        }
      case 'Tennis':
        {
          return Icons.sports_tennis;
        }
      case 'Hockey':
        {
          return Icons.sports_hockey;
        }
      case 'Badminton':
        {
          return Icons.sports;
        }
      case 'Volleyball':
        {
          return Icons.sports_volleyball;
        }
    }
    return Icons.water_sharp;
  }

  void setFilter() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FractionallySizedBox(
              heightFactor: 0.60,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Add Filter",
                          style: TextStyle(
                              fontFamily: "DMSans",
                              fontSize:
                                  MediaQuery.of(context).size.height / 35),
                        ),
                        const Icon(
                          Icons.filter_list,
                          color: Colors.green,
                        )
                      ],
                    ),
                  ),
                  Slider(
                    value: radiusInKm,
                    min: 1,
                    max: 100,
                    onChanged: (double value) {
                      setState(() {
                        radiusInKm = value.round().toDouble();
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                        "You will get results in ${radiusInKm.toInt().toString()} Kilometers",
                        style: const TextStyle(fontFamily: "DMSans")),
                  ),
                  CupertinoButton(
                      color: Colors.blue,
                      onPressed: () {
                        Navigator.pop(ctx);
                      },
                      child: const Text("Set Filter"))
                ],
              ),
            );
          },
        );
      },
    ).then((value) => {setState(() {})});
  }

  panel() {
    return Scaffold(
        body: ValueListenableBuilder(
      valueListenable: panelListener,
      builder: (context, value, child) {
        return value
            ? StreamBuilder(
                stream: _server
                    .collection('SportistanPartners')
                    .where('groundID', isEqualTo: groundID)
                    .snapshots(),
                builder: (context, snapshot) {
                  return snapshot.hasData
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: snapshot.data!.docChanges.length,
                              shrinkWrap: true,
                              itemBuilder: (ctx, index) {
                                List<dynamic> services = snapshot
                                    .data!.docChanges[index].doc
                                    .get('groundServices');
                                List<dynamic> listCount = snapshot
                                    .data!.docChanges[index].doc
                                    .get('badges');
                                List<dynamic> images = snapshot
                                    .data!.docChanges[index].doc
                                    .get('groundImages');

                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        CupertinoButton(
                                            onPressed: () {
                                              panelController.close();
                                            },
                                            child: const Text(
                                              'Close',
                                              style: TextStyle(
                                                  fontFamily: 'DMSans'),
                                            ))
                                      ],
                                    ),
                                    CarouselSlider.builder(
                                      itemCount: images.length,
                                      itemBuilder: (BuildContext context,
                                          int itemIndex, int pageViewIndex) {
                                        return Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.network(
                                                images[itemIndex],
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  }
                                                  return Shimmer.fromColors(
                                                    baseColor:
                                                        Colors.grey.shade300,
                                                    highlightColor:
                                                        Colors.grey.shade100,
                                                    enabled: true,
                                                    child: Center(
                                                      child: Image.asset(
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .height /
                                                              8,
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .height /
                                                              8,
                                                          "assets/logo.png"),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                      options: CarouselOptions(
                                        height:
                                            MediaQuery.of(context).size.height /
                                                4.5,
                                        enableInfiniteScroll: false,
                                        initialPage: currentPage,
                                        onPageChanged: (index, reason) {
                                          dotsListener.value = index;
                                        },
                                        enlargeFactor: 0.3,
                                        scrollDirection: Axis.horizontal,
                                      ),
                                    ),
                                    ValueListenableBuilder(
                                      builder: (context, value, child) =>
                                          DotsIndicator(
                                        dotsCount: images.length,
                                        position: value,
                                      ),
                                      valueListenable: dotsListener,
                                    ),
                                    listCount.isEmpty
                                        ? Container()
                                        : Container(
                                            width: double.infinity,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                20,
                                            alignment: Alignment.topCenter,
                                            child: ListView.builder(
                                                shrinkWrap: true,
                                                physics:
                                                    const BouncingScrollPhysics(),
                                                scrollDirection:
                                                    Axis.horizontal,
                                                itemBuilder: (context, index) {
                                                  return Row(
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Row(
                                                          children: [
                                                            Text(
                                                                "🏅${listCount[index]}",
                                                                style: const TextStyle(
                                                                    fontFamily:
                                                                        "DMSans")),
                                                          ],
                                                        ),
                                                      )
                                                    ],
                                                  );
                                                },
                                                itemCount: listCount.length),
                                          ),
                                    Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            snapshot.data!.docChanges[index].doc
                                                .get("groundName"),
                                            style: const TextStyle(
                                                fontFamily: "DMSans",
                                                color: Colors.black54,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 22),
                                            softWrap: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Row(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(left: 10),
                                          child: Text(
                                            "Description",
                                            softWrap: true,
                                            style: TextStyle(
                                                fontFamily: "DMSans",
                                                fontWeight: FontWeight.bold,
                                                fontSize: 24),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        snapshot.data!.docChanges[index].doc
                                            .get("description"),
                                        style: const TextStyle(
                                            fontFamily: "DMSans",
                                            color: Colors.black54,
                                            fontSize: 18),
                                        softWrap: true,
                                      ),
                                    ),
                                    const Row(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(
                                            "Amenities",
                                            style: TextStyle(
                                                fontFamily: "DMSans",
                                                fontWeight: FontWeight.bold,
                                                fontSize: 24),
                                          ),
                                        ),
                                      ],
                                    ),
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.all(8.0),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        // number of items in each row
                                        childAspectRatio: (1 / .6),
                                        mainAxisSpacing:
                                            8.0, // spacing between rows
                                        crossAxisSpacing:
                                            8.0, // spacing between columns
                                      ),
                                      itemCount: services.length,
                                      // total number of items
                                      itemBuilder: (context, index) {
                                        return Center(
                                          child: Column(
                                            children: [
                                              Icon(setServiceIcon(
                                                  services[index].toString())),
                                              Text(
                                                services[index],
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                    fontSize: 18.0,
                                                    color: Colors.black87),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    ValueListenableBuilder(
                                      valueListenable: directionListened,
                                      builder: (context, value, child) {
                                        return value
                                            ? Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      const Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                          left: 10,
                                                        ),
                                                        child: Text(
                                                          "Direction",
                                                          style: TextStyle(
                                                              fontFamily:
                                                                  "DMSans",
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 24),
                                                        ),
                                                      ),
                                                      TextButton(
                                                          onPressed: () {
                                                            MapsLauncher.launchCoordinates(
                                                                destinationLat!,
                                                                destinationLong!,
                                                                snapshot
                                                                    .data!
                                                                    .docChanges[
                                                                        index]
                                                                    .doc
                                                                    .get(
                                                                        "groundName"));
                                                          },
                                                          child: const Text(
                                                              "Get Directions"))
                                                    ],
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                      snapshot.data!
                                                          .docChanges[index].doc
                                                          .get("locationName"),
                                                      style: const TextStyle(
                                                          fontFamily: "DMSans",
                                                          color: Colors.black54,
                                                          fontSize: 18),
                                                      softWrap: true,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            const Icon(
                                                                Icons
                                                                    .directions,
                                                                color: Colors
                                                                    .indigo),
                                                            Text(
                                                                distanceText
                                                                    .toString(),
                                                                style:
                                                                    const TextStyle(
                                                                        fontSize:
                                                                            18)),
                                                          ],
                                                        ),
                                                        Row(
                                                          children: [
                                                            const Icon(
                                                                Icons
                                                                    .directions_walk,
                                                                color: Colors
                                                                    .green),
                                                            Text(
                                                                durationText
                                                                    .toString(),
                                                                style:
                                                                    const TextStyle(
                                                                        fontSize:
                                                                            18)),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : const Center(
                                                child: Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.green,
                                                  strokeWidth: 1,
                                                ),
                                              ));
                                      },
                                    ),
                                    CupertinoButton(
                                        onPressed: () {
                                          panelController.close();
                                        },
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.close),
                                            Text(
                                              'Close',
                                              style: TextStyle(
                                                  fontFamily: 'DMSans'),
                                            ),
                                          ],
                                        )),
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height /
                                              4,
                                    )
                                  ],
                                );
                              },
                            ),
                            Positioned(
                              bottom: MediaQuery.of(context).size.height / 6,
                              child: CupertinoButton(
                                  color: Colors.green,
                                  onPressed: () {
                                    PageRouter.push(
                                        context,
                                        ShowSlots(
                                          groundID: groundID.toString(),
                                          groundAddress:
                                              groundAddress.toString(),
                                          groundName: groundName.toString(),
                                          groundType: groundType.toString(),
                                        ));
                                    panelController.close();
                                  },
                                  child: Text(
                                      "Book Now Onwards ₹${onwards.toString()}")), //Icon
                            ),
                          ],
                        )
                      : const Center(
                          child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                              strokeWidth: 1, color: Colors.black38),
                        ));
                },
              )
            : Container();
      },
    ));
  }

  Future<void> getDistanceMatrix({
    required double? originLat,
    required double? originLong,
    required double? destinationLat,
    required double? destinationLong,
  }) async {
    try {
      String url =
          "https://maps.googleapis.com/maps/api/directions/json?origin=$originLat,$originLong&destination=$destinationLat,$destinationLong&key=${MapKey.mapKey}";

      http.Response httpResponse = await http.get(Uri.parse(url));
      if (httpResponse.statusCode == 200) {
        String jsonData = httpResponse.body;
        var response = jsonDecode(jsonData);
        if (response["status"] == "OK") {
          distanceText = response["routes"][0]["legs"][0]["distance"]["text"];
          durationText = response["routes"][0]["legs"][0]["duration"]["text"];
          directionListened.value = true;
        }
      }
    } catch (e) {
      if (mounted) {
        Errors.flushBarInform(e.toString(), context, "Error While Reaching");
      }
    }
  }

  IconData setServiceIcon(String serviceName) {
    switch (serviceName) {
      case 'Flood Lights':
        {
          return Icons.grid_on_outlined;
        }
      case 'Parking':
        {
          return Icons.local_parking;
        }
      case 'Sound System':
        {
          return Icons.surround_sound;
        }
      case 'Warm Up Area':
        {
          return Icons.directions_run;
        }
      case 'Washroom':
        {
          return Icons.wash_rounded;
        }
      case 'Coaching Available':
        {
          return Icons.sports;
        }
      case 'Ball Boy':
        {
          return Icons.sports_baseball;
        }
      case 'Sitting Area':
        {
          return Icons.chair;
        }
      case 'Drinking Water':
        {
          return Icons.local_drink;
        }
      case 'Locker Room':
        {
          return Icons.meeting_room;
        }
    }
    return Icons.add_circle;
  }
}
