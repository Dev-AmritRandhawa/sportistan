import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sportistan/main.dart';
import 'package:sportistan/widgets/page_route.dart';
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  int currentPage = 0;

  late String dayTime;
  ValueNotifier<bool> dayLoading = ValueNotifier<bool>(false);

  double? latitude;
  double? longitude;

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
    var hour = DateTime.now().hour;
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
            query.where("isVerified", isEqualTo: true).where('isKYCPending',isEqualTo: false),
        strictMode: true);
    return StreamBuilder<List<DocumentSnapshot>>(
        stream: stream,
        builder: (BuildContext context, snapshot) {
          final List<DocumentSnapshot<Object?>>? docs = snapshot.data;
          return snapshot.hasData
              ? Column(
            children: [
              Form(
                  child: DelayedDisplay(
                      child: Card(
                        elevation: 5.0,
                        child: TextFormField(
                          onTap: () {
                          },
                          readOnly: true,
                          decoration: InputDecoration(
                              hintText: dayTime,
                              hintStyle: const TextStyle(
                                  color: Colors.black38, fontFamily: "Nunito"),
                              fillColor: Colors.white,
                              suffixIcon: const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: Icon(
                                  Icons.search,
                                  color: Colors.black,
                                ),
                              ),
                              filled: true,
                              border: const OutlineInputBorder(
                                borderSide: BorderSide.none,
                              )),
                        ),
                      ))),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: docs!.length <= 1
                            ? Text(
                            "  We found ${docs.length} ground in ${radiusInKm.toInt().toString()} Kms",
                            style: const TextStyle(
                                fontFamily: "DMSans", fontSize: 16))
                            : Text(
                            "  We found ${docs.length} grounds in ${radiusInKm.toInt().toString()} Kms  ",
                            style: const TextStyle(
                                fontFamily: "DMSans", fontSize: 16)),
                      ),
                      IconButton(
                          onPressed: () {
                            setFilter();
                          },
                          icon: const Icon(
                            Icons.filter_list,
                            color: Colors.black87,
                          )),
                    ],
                  ),
                  docs.isEmpty
                      ? Column(
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
                              style:
                              TextStyle(fontFamily: "DMSans"),
                            )),
                      )
                    ],
                  )
                      : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: docs.length,
                    itemBuilder: (_, index) {
                      final doc = docs[index];
                      List<dynamic> images = doc["groundImages"];

                      return GestureDetector(
                        onTap: () {
                          showSlotsBefore(
                              doc.get(
                                "groundName",
                              ),
                              doc['locationName']);
                        },
                        child: Padding(
                          padding:
                          const EdgeInsets.only(bottom: 8.0),
                          child: Card(
                            color: Colors.grey.shade50,
                            child: Column(children: [
                              CarouselSlider.builder(
                                itemCount: images.length,
                                itemBuilder: (BuildContext context,
                                    int itemIndex,
                                    int pageViewIndex) =>
                                    Stack(
                                      children: [
                                        Image.network(
                                          doc["groundImages"]
                                          [itemIndex],
                                          errorBuilder: (context, error,
                                              stackTrace) {
                                            return const Text(
                                                "Network Error");
                                          },
                                          loadingBuilder: (context,
                                              child, loadingProgress) {
                                            if (loadingProgress ==
                                                null) {
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
                                      ],
                                    ),
                                options: CarouselOptions(
                                  initialPage: currentPage,
                                  enlargeFactor: 0.3,
                                  scrollDirection: Axis.horizontal,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                                  children: [
                                    Text(
                                      doc.get(
                                        "groundName",
                                      ),
                                      maxLines: 3,
                                      softWrap: true,
                                      overflow:
                                      TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontFamily: "DMSans",
                                          fontWeight:
                                          FontWeight.bold,
                                          fontSize:
                                          MediaQuery.of(context)
                                              .size
                                              .width /
                                              18),
                                    ),
                                    const Row(
                                      children: [
                                        Icon(Icons.star,
                                            color: Colors
                                                .orangeAccent),
                                        Text("4.5")
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 8.0, left: 8.0),
                                child: Text(doc["locationName"],
                                    style: const TextStyle(
                                        fontFamily: "DMSans",
                                        color: Colors.black54)),
                              ),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
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
        });
  }

  Future<void> _getLatLng() async {
    PermissionStatus permissionStatus;
    try {
      permissionStatus = await Permission.location.request();
      if (permissionStatus == PermissionStatus.granted ||
          permissionStatus == PermissionStatus.limited) {
        Position position = await Geolocator.getCurrentPosition();
        latitude = position.latitude;
        longitude = position.longitude;
        setState(() {});
      } else {
        if (mounted) {
          PageRouter.pushRemoveUntil(context, const MyApp());
        }
      }
    } catch (error) {
      if (mounted) {
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

  void showSlotsBefore(String groundName, String groundID) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return  Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text(
                    groundName,
                    style: TextStyle(
                        fontFamily: "DMSans",
                        fontSize: MediaQuery.of(context).size.height / 35),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
