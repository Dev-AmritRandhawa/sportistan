import 'dart:convert';
import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sliding_up_panel2/sliding_up_panel2.dart';
import 'package:sportistan/booking/show_slots.dart';
import 'package:sportistan/widgets/page_route.dart';

import '../widgets/errors.dart';
import 'main_page.dart';

class SearchGroundsByAlgolia extends StatefulWidget {
  final double originLat;
  final double originLong;

  const SearchGroundsByAlgolia(
      {super.key, required this.originLat, required this.originLong});

  @override
  State<SearchGroundsByAlgolia> createState() => _SearchGroundsByAlgoliaState();
}

class _SearchGroundsByAlgoliaState extends State<SearchGroundsByAlgolia>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  var currentPage = 0;

  String? groundID;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    hitsSearcher.dispose();
    super.dispose();
  }
  ValueNotifier<int> dotsListener = ValueNotifier<int>(0);
  final hitsSearcher = HitsSearcher(
    applicationID: '9W2OJ32UHH',
    apiKey: '68e494b082ebbd33fcaf79b5383e7c14',
    indexName: 'SportistanPartners',
  );
  ValueNotifier<bool> panelListener = ValueNotifier<bool>(false);
  ValueNotifier<bool> directionListened = ValueNotifier<bool>(false);
  ValueNotifier<bool> dataListener = ValueNotifier<bool>(false);
  PanelController panelController = PanelController();
  final _server = FirebaseFirestore.instance;

  String? groundAddress;

  String? groundName;
  String? groundType;
  String? distanceText;
  String? durationText;
  double? destinationLat;
  double? destinationLong;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("Back"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Scaffold(
          backgroundColor: Colors.white,
          body: SlidingUpPanel(
            controller: panelController,
            minHeight: 0,
            maxHeight: MediaQuery.of(context).size.height,
            panelBuilder: () => panel(),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    onChanged: (value) {
                      if (value.length > 1) {
                        hitsSearcher.query(value);
                        dataListener.value = true;
                      } else {
                        dataListener.value = false;
                      }
                    },
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                        hintText: "Search Grounds, Location & Much More.",
                        fillColor: Colors.grey.shade200,
                        filled: true,
                        suffixIcon:
                            const Icon(Icons.search, color: Colors.green),
                        border: const OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius:
                                BorderRadius.all(Radius.circular(50)))),
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable: dataListener,
                  builder: (context, value, child) => value
                      ? StreamBuilder<SearchResponse>(
                          stream: hitsSearcher.responses,
                          builder: (_, snapshot) {
                            if (snapshot.hasData) {
                              final response = snapshot.data;
                              final hits = response?.hits.toList() ?? [];
                              // 3.2 Display your search hits
                              return SingleChildScrollView(
                                child: Column(
                                  children: [
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: hits.length,
                                      itemBuilder: (_, i) => Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: InkWell(
                                          onTap: () async {
                                            panelController.open();
                                            groundID = hits[i]['groundID'];
                                            groundType = hits[i]["groundType"];
                                            groundAddress =
                                                hits[i]["locationName"];
                                            groundName = hits[i]["groundName"];
                                            panelListener.value = true;
                                            destinationLat = hits[i]["geo"]
                                                ['_geoloc']['lat'];
                                            destinationLong = hits[i]["geo"]
                                                ['_geoloc']['lng'];
                                            directionListened.value = false;
                                            await getDistanceMatrix();
                                            panelListener.value = true;

                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                  BorderRadius.circular(10),
                                                  child:
                                                  Image.network(
                                                    hits[i]['groundImages'][0],height: MediaQuery.of(context).size.height/8,
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
                                                          child: Icon(Icons.image,size: MediaQuery.of(context).size.height/10),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                const Row(
                                                  children: [
                                                    Text(
                                                      'Name',
                                                      style: TextStyle(
                                                          fontFamily: "Nunito",
                                                          color:
                                                              Colors.black45),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Text(hits[i]['groundName'],
                                                        softWrap: true,
                                                        style: const TextStyle(
                                                            fontFamily:
                                                                "DMSans",
                                                            fontSize: 22,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                  ],
                                                ),
                                                const Text(
                                                  'Ground Type',
                                                  style: TextStyle(
                                                      fontFamily: "Nunito",
                                                      color: Colors.black45),
                                                ),
                                                Card(
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              50)),
                                                  color: Colors.green.shade900,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                        hits[i]['groundType'],
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontFamily: "DMSans",
                                                        )),
                                                  ),
                                                ),
                                                Text(hits[i]['locationName'],
                                                    style: const TextStyle(
                                                        fontFamily: "DMSans",
                                                        fontSize: 18)),
                                                const Divider()
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              );
                            } else {
                              return Container();
                            }
                          },
                        )
                      : Lottie.asset(
                          'assets/search.json',
                          controller: _controller,
                          onLoaded: (composition) {
                            _controller
                              ..duration = composition.duration
                              ..repeat();
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
  panel() {
    return  StreamBuilder(
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
                                    3,
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
                                const Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: Text("Ground Name",
                                      style: TextStyle(
                                          fontFamily: "DMSans",
                                          color: Colors.black)),
                                ),
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
                          child: const Text(
                              "Book Now")), //Icon
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
        );
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

  Future<void> getDistanceMatrix() async {
    try {
      String url =
          "https://maps.googleapis.com/maps/api/directions/json?origin=${widget.originLat.toString()},${widget.originLong.toString()}&destination=${destinationLat.toString()},${destinationLong.toString()}&key=${MapKey.mapKey}";

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
}
