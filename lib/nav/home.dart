import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sliding_up_panel2/sliding_up_panel2.dart';
import 'package:sportistan/booking/show_slots.dart';
import 'package:sportistan/main.dart';
import 'package:sportistan/request.dart';
import 'package:sportistan/widgets/page_route.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  int currentPage = 0;
  List<dynamic> groundServices = [];

  late String dayTime;
  ValueNotifier<bool> dayLoading = ValueNotifier<bool>(false);
  ValueNotifier<bool> panelListener = ValueNotifier<bool>(false);
  ValueNotifier<bool> directionListened = ValueNotifier<bool>(false);
  ValueNotifier<bool> showCurrentAddress = ValueNotifier<bool>(false);
  PanelController panelController = PanelController();
  double? latitude;
  double? longitude;

  final _server = FirebaseFirestore.instance;

  String? groundID;
  String? locationName;
  String? groundType;

  String? distanceText;
  String? durationText;

  double? destinationLat;
  double? destinationLong;

  String? groundAddress;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.resumed:
        _getLatLng();
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
    }
  }

  @override
  void initState() {
    _getLatLng();
    WidgetsBinding.instance.addObserver(this);
    var hour = DateTime
        .now()
        .hour;
    if (hour <= 12) {
      dayTime = "Good Morning, ";
    } else if ((hour > 12) && (hour <= 16)) {
      dayTime = "Good Afternoon, ";
    } else {
      dayTime = "Good Evening, ";
    }
    dayLoading.value = true;

    super.initState();
  }

  double radiusInKm = 30;

  @override
  Widget build(BuildContext context) {
    GeoPoint location = const GeoPoint(28.6569874, 77.1179452);

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
        queryBuilder: (query) =>
            query
                .where("isVerified", isEqualTo: true)
                .where('isKYCPending', isEqualTo: false)
                .where('isAccountOnHold', isEqualTo: false),
        strictMode: true);
    return Scaffold(
      body: SafeArea(
        child: SlidingUpPanel(
          onPanelClosed: () {
            panelListener.value = false;
          },
          controller: panelController,
          maxHeight: MediaQuery
              .of(context)
              .size
              .height / 1.3,
          minHeight: 0,
          panelBuilder: () => panel(),
          body: StreamBuilder<List<DocumentSnapshot>>(
              stream: stream,
              builder: (BuildContext context, snapshot) {
                final List<DocumentSnapshot<Object?>>? docs = snapshot.data;

                return snapshot.hasData
                    ? SingleChildScrollView(
                  child: Column(
                    children: [
                      ValueListenableBuilder(
                        valueListenable: showCurrentAddress,
                        builder: (context, value, child) =>
                            Column(
                              children: [
                                value
                                    ? DelayedDisplay(
                                  child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding:
                                              const EdgeInsets.all(8.0),
                                              child: Row(
                                                children: [
                                                  Text(dayTime.toString(),
                                                      style:
                                                      const TextStyle(
                                                          fontFamily:
                                                          "DMSans",
                                                          fontSize:
                                                          22)),
                                                  const Text("👋",
                                                      style: TextStyle(
                                                          fontSize: 22)),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .only(
                                                      right: 5),
                                                  child: CircleAvatar(
                                                      backgroundColor:
                                                      Colors.green.shade900,
                                                      child: const Icon(
                                                          Icons
                                                              .location_pin,
                                                          color: Colors
                                                              .white)),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    address.toString(),
                                                    style: const TextStyle(
                                                        fontFamily:
                                                        "DMSans",
                                                        fontSize: 16,
                                                        color:
                                                        Colors.black45),
                                                    softWrap: true,
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      )),
                                )
                                    : const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      CircularProgressIndicator(
                                          strokeWidth: 1,
                                          color: Colors.black54),
                                      Text(
                                        "Getting Location",
                                        style: TextStyle(
                                            fontFamily: "DMSans"),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                      ),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: docs!.length <= 1
                                    ? Text(
                                    "  We found ${docs
                                        .length} ground in ${radiusInKm.toInt()
                                        .toString()} Kms",
                                    style: const TextStyle(
                                        fontFamily: "DMSans",
                                        fontSize: 16,
                                        color: Colors.green))
                                    : Text(
                                    "  We found ${docs
                                        .length} grounds in ${radiusInKm.toInt()
                                        .toString()} Kms  ",
                                    style: const TextStyle(
                                        fontFamily: "DMSans",
                                        fontSize: 16,
                                        color: Colors.green)),
                              ),
                              IconButton(
                                  onPressed: () {
                                    setFilter();
                                  },
                                  icon: const CircleAvatar(
                                    child: Icon(
                                      Icons.filter_list,
                                      color: Colors.white,
                                    ),
                                  )),
                            ],
                          ),
                          if (docs.isEmpty)
                            Column(
                              children: [
                                Image.asset("assets/noResults.png"),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: CupertinoButton(
                                      color: Colors.green,
                                      onPressed: () {
                                        setFilter();
                                      },
                                      child: const Text(
                                        "Add Filter",
                                        style: TextStyle(
                                            fontFamily: "DMSans"),
                                      )),
                                )
                              ],
                            )
                          else
                            ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: docs.length,
                              itemBuilder: (_, index) {
                                final doc = docs[index];
                                List<dynamic> images =
                                doc["groundImages"];
                                List<dynamic> listCount = doc['badges'];
                                groundServices = doc['groundServices'];

                                return GestureDetector(
                                  onTap: () {
                                    groundID = doc["groundID"];
                                    groundType = doc["groundType"];
                                    groundAddress = doc["locationName"];
                                    panelListener.value = true;
                                    GeoPoint geoPoint =
                                    doc["geo"]['geopoint'];
                                    destinationLat = geoPoint.latitude;
                                    destinationLong = geoPoint.longitude;
                                    getDistanceMatrix(
                                      originLat: latitude,
                                      originLong: longitude,
                                      destinationLat: destinationLat,
                                      destinationLong: destinationLong,
                                    );
                                    panelController.open();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 8.0),
                                    child: Card(
                                      color: Colors.grey.shade50,
                                      child: Column(children: [
                                        CarouselSlider.builder(
                                          itemCount: images.length,
                                          itemBuilder:
                                              (BuildContext context,
                                              int itemIndex,
                                              int pageViewIndex) {
                                            int count = itemIndex + 1;

                                            return Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(10),
                                                  child: Image.network(
                                                    doc["groundImages"]
                                                    [itemIndex],
                                                    loadingBuilder: (context,
                                                        child,
                                                        loadingProgress) {
                                                      if (loadingProgress ==
                                                          null) {
                                                        return child;
                                                      }
                                                      return Shimmer
                                                          .fromColors(
                                                        baseColor: Colors
                                                            .grey
                                                            .shade300,
                                                        highlightColor:
                                                        Colors.grey
                                                            .shade100,
                                                        enabled: true,
                                                        child: Center(
                                                          child: Image.asset(
                                                              height: MediaQuery
                                                                  .of(context)
                                                                  .size
                                                                  .height /
                                                                  8,
                                                              width: MediaQuery
                                                                  .of(context)
                                                                  .size
                                                                  .height /
                                                                  8,
                                                              "assets/logo.png"),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                Card(
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                          50)),
                                                  child: Padding(
                                                      padding:
                                                      const EdgeInsets
                                                          .only(
                                                          left: 8.0,
                                                          right: 8.0,
                                                          top: 2,
                                                          bottom: 2),
                                                      child: Text(
                                                          '$count / ${images
                                                              .length
                                                              .toString()}')),
                                                )
                                              ],
                                            );
                                          },
                                          options: CarouselOptions(
                                            height: MediaQuery
                                                .of(context)
                                                .size
                                                .height /
                                                3,
                                            enableInfiniteScroll: false,
                                            initialPage: currentPage,
                                            enlargeFactor: 0.3,
                                            scrollDirection:
                                            Axis.horizontal,
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                          const EdgeInsets.all(8.0),
                                          child: Row(
                                            children: [
                                              Text(
                                                doc.get(
                                                  "groundName",
                                                ),
                                                softWrap: true,
                                                maxLines: 3,
                                                overflow:
                                                TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontFamily: "DMSans",
                                                    fontWeight:
                                                    FontWeight.bold,
                                                    fontSize: MediaQuery
                                                        .of(
                                                        context)
                                                        .size
                                                        .width /
                                                        18),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Card(
                                              shape:
                                              RoundedRectangleBorder(
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                      50)),
                                              child: Padding(
                                                padding:
                                                const EdgeInsets.only(
                                                    left: 15,
                                                    right: 15,
                                                    top: 5,
                                                    bottom: 5),
                                                child: Text(doc.get(
                                                  "groundType",
                                                )),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.star,
                                              color: Colors.orange,
                                            ),
                                            const Text("4.1")
                                          ],
                                        ),
                                        Container(
                                          width: double.infinity,
                                          height: MediaQuery
                                              .of(context)
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
                                              itemBuilder:
                                                  (context, index) {
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
                                              itemCount:
                                              listCount.length),
                                        ),
                                        Row(
                                          children: [
                                            Card(
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      50)),
                                              child: Padding(
                                                padding:
                                                const EdgeInsets.all(8.0),
                                                child: Shimmer.fromColors(
                                                  period: const Duration(seconds: 2),
                                                  baseColor: Colors.black87,
                                                  loop: 6,
                                                  highlightColor: Colors.white,
                                                  child: Text(
                                                      'Starting Onwards : ₹${doc['onwards']}',
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontFamily: "DMSans",
                                                      )),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      ]),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                )
                    : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 1,
                        color: Colors.black38,
                      )
                    ],
                  ),
                );
              }),
        ),
      ),
    );
  }

  String? address;

  Future<void> _getLatLng() async {
    PermissionStatus permissionStatus;
    try {
      permissionStatus = await Permission.location.request();
      if (permissionStatus == PermissionStatus.granted ||
          permissionStatus == PermissionStatus.limited) {
        Position position = await Geolocator.getCurrentPosition();
        latitude = position.latitude;
        longitude = position.longitude;
        address =
        await RequestAddressMethods.searchCoordinateRequests(position);
        if (address == "Couldn't Locate") {
          showCurrentAddress.value = false;
        } else {
          showCurrentAddress.value = true;
        }
      } else {
        if (mounted) {
          PageRouter.pushRemoveUntil(context, const MyApp());
        }
      }
    } catch (error) {
      if (mounted) {
        showCurrentAddress.value = false;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Unable to find location")));
      }
    }
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
                              MediaQuery
                                  .of(context)
                                  .size
                                  .height / 35),
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
                    max: 300,
                    onChanged: (double value) {
                      setState(() {
                        radiusInKm = value.round().toDouble();
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                        "You will get results in ${radiusInKm.toInt()
                            .toString()} Kilometers",
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
                    ? ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: snapshot.data!.docChanges.length,
                  shrinkWrap: true,
                  itemBuilder: (ctx, index) {
                 List<dynamic>  services =   snapshot.data!.docChanges[index].doc.get('groundServices');

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: Colors.grey),
                            height: 5,
                            width: 40,
                          ),
                        ),
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  right: 8.0, left: 8.0),
                              child: Text(
                                snapshot.data!.docChanges[index].doc
                                    .get("groundName"),
                                style: const TextStyle(
                                    fontFamily: "DMSans",
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22),
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            snapshot.data!.docChanges[index].doc
                                .get("locationName"),
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
                              padding: EdgeInsets.only(
                                  left: 10),
                              child: Text(
                                "Description",
                                style: TextStyle(
                                    fontFamily: "DMSans",
                                    fontWeight:
                                    FontWeight.bold,
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
                              padding: EdgeInsets.only(
                                  left: 10),
                              child: Text(
                                "Amenities",
                                style: TextStyle(
                                    fontFamily: "DMSans",
                                    fontWeight:
                                    FontWeight.bold,
                                    fontSize: 24),
                              ),
                            ),
                          ],
                        ),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const BouncingScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    // number of items in each row
                                    childAspectRatio: (1 / .6),
                                    mainAxisSpacing: 8.0, // spacing between rows
                                    crossAxisSpacing: 8.0, // spacing between columns
                                  ),
                                  itemCount: services.length, // total number of items
                                  itemBuilder: (context, index) {
                                    return Center(
                                      child: Column(
                                        children: [
                                          Icon(setServiceIcon(services[index].toString())),
                                          Text(
                                            services[index],
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 18.0, color: Colors.black87),
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
                                const Row(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                          left: 10),
                                      child: Text(
                                        "Direction",
                                        style: TextStyle(
                                            fontFamily: "DMSans",
                                            fontWeight:
                                            FontWeight.bold,
                                            fontSize: 24),
                                      ),
                                    ),
                                  ],
                                ),
                                MaterialButton(
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(
                                          50)),
                                  color: Colors.green,
                                  onPressed: () {
                                    MapsLauncher.launchCoordinates(
                                        destinationLat!,
                                        destinationLong!,
                                        snapshot.data!
                                            .docChanges[index].doc
                                            .get("groundName"));
                                  },
                                  child: const Text(
                                      "Open in Maps",
                                      style: TextStyle(
                                          color: Colors.white)),
                                ),
                                const Text("Distance",style: TextStyle(fontFamily: "DMSans",color: Colors.black54)),
                                Padding(
                                  padding:
                                  const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceEvenly,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                              Icons.directions,
                                              color:
                                              Colors.green),
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
                                              color: Colors.blue),
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


                                Padding(
                                  padding:
                                  const EdgeInsets.all(8.0),
                                  child: CupertinoButton(
                                      color: Colors.indigo,
                                      onPressed: () {
                                        PageRouter.push(
                                            context,
                                            ShowSlots(
                                                groundID: groundID
                                                    .toString(),
                                                groundAddress:
                                                groundAddress
                                                    .toString(),
                                                groundName:
                                                locationName
                                                    .toString(), groundType: '',));
                                      },
                                      child: const Text(
                                        'Create a Booking',
                                        style: TextStyle(
                                            fontFamily: "DMSans"),
                                      )),
                                )
                              ],
                            )
                                : const Center(
                                child: CircularProgressIndicator());
                          },
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height/8,)
                      ],
                    );
                  },
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
          "https://maps.googleapis.com/maps/api/directions/json?origin=$originLat,$originLong&destination=$destinationLat,$destinationLong&key=${MapKey
          .mapKey}";

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
      if (kDebugMode) {
        print("Invalid");
      }
    }
  }


  IconData setServiceIcon(String serviceName) {
    switch(serviceName){
      case 'Flood Lights' : {
        return Icons.grid_on_outlined;
      }case 'Parking' : {
      return Icons.local_parking;


      }case 'Sound System' : {
      return Icons.surround_sound;

      }case 'Warm Up Area' : {
      return Icons.directions_run;
      }case 'Washroom' : {
      return Icons.wash_rounded;

      }case 'Coaching Available' : {
      return Icons.sports;

      }case 'Ball Boy' : {
      return Icons.sports_baseball;

      }case 'Sitting Area' : {
      return Icons.chair;

      }case 'Drinking Water' : {
      return Icons.local_drink;

      }case 'Locker Room' : {
      return Icons.meeting_room;
      }
    }
    return Icons.add_circle;
  }


}

class MapKey {
  static String mapKey = 'AIzaSyCHJizjCjQBbAr1D6trmyKJPzOKyHGImZE';
}
