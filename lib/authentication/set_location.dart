import 'dart:convert';
import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel2/sliding_up_panel2.dart';
import 'package:sportistan/nav/main_page.dart';
import 'package:sportistan/nav/nav_home.dart';
import 'package:sportistan/widgets/page_route.dart';

class SetLocation extends StatefulWidget {
  const SetLocation({super.key});

  @override
  State<SetLocation> createState() => _SetLocationState();
}

class _SetLocationState extends State<SetLocation>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  ValueNotifier<bool> locationListener = ValueNotifier(true);
  ValueNotifier<bool> showCurrentAddress = ValueNotifier(false);
  String? address;
  var pc = PanelController();
  TextEditingController searchController = TextEditingController();

  String? placeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(vsync: this);

    checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();

    super.dispose();
  }

  Future<void> checkPermission() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      checkPermission();
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      if (pc.isPanelOpen) {
        pc.close();
      }
      getLocation();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.unableToDetermine) {
      pc.open();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        onResumed();
        break;
      case AppLifecycleState.inactive:
        onPaused();
        break;
      case AppLifecycleState.paused:
        onInactive();
        break;
      case AppLifecycleState.detached:
        onDetached();
        break;
      case AppLifecycleState.hidden:
        onHidden();
        break;
    }
  }

  void onResumed() {
    checkPermission();
  }

  void onHidden() {}

  void onPaused() {}

  void onInactive() {}

  void onDetached() {}
  List<dynamic> listData = [];

  Future<void> _placeApiRequest(String userKeyboard) async {
    if (userKeyboard.length > 1) {
      String autoComplete =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$userKeyboard&location=$serverLatitude%2C$serverLongitude&radius=100&key=${MapKey.mapKey}";
      var response = await RequestApi.getRequestUrl(autoComplete);
      if (response["status"] == "OK") {
        var prediction = response["predictions"];
        setState(() {
          listData = prediction;
        });
      }
    }
  }

  void clearList() {
    searchController.clear();
    listData = [];
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: ValueListenableBuilder(
        valueListenable: showCurrentAddress,
        builder: (context, value, child) => value
            ? CupertinoButton(
                color: Colors.indigo,
                borderRadius: BorderRadius.zero,
                onPressed: () async {
                  PageRouter.pushRemoveUntil(context, const NavHome());
                },
                child: const Text(
                  "Go Home",
                  style: TextStyle(fontFamily: "DMSans"),
                ))
            : const Text(''),
      ),
      body: SlidingUpPanel(
        minHeight: 0,
        maxHeight: MediaQuery.of(context).size.height,
        panelBuilder: () => panel(),
        controller: pc,
        isDraggable: false,
        disableDraggableOnScrolling: true,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Image.asset('assets/logo.png',
                        height: MediaQuery.of(context).size.height / 8),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Sportistan',
                          style: TextStyle(fontFamily: "DMSans", fontSize: 20)),
                    ),
                    ValueListenableBuilder(
                      valueListenable: locationListener,
                      builder: (context, value, child) => value
                          ? const Column(
                              children: [
                                CircularProgressIndicator(
                                  strokeWidth: 1,
                                  color: Colors.indigo,
                                ),
                                Text(
                                  "Updating Location",
                                  style: TextStyle(
                                    fontFamily: 'DMSans',
                                  ),
                                )
                              ],
                            )
                          : Padding(
                              padding:
                                  const EdgeInsets.only(right: 8.0, left: 8.0),
                              child: TextFormField(
                                style: const TextStyle(color: Colors.black),
                                controller: searchController,
                                onChanged: (value) {
                                  _placeApiRequest(value);
                                },
                                decoration: InputDecoration(
                                    hintText: "Search Location",
                                    fillColor: Colors.grey.shade200,
                                    filled: true,
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        listData.clear();
                                        searchController.clear();

                                        setState(() {
                                          clearList();
                                        });
                                      },
                                      icon: const Icon(Icons.close),
                                    ),
                                    border: const OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(50)))),
                              ),
                            ),
                    ),
                    (listData.isNotEmpty)
                        ? Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: ListView.builder(
                              itemCount: listData.length,
                              itemBuilder: (BuildContext context, int index) {
                                return GestureDetector(
                                  onTap: () async {
                                  locationListener.value = true;
                                  showCurrentAddress.value = false;
                                    placeId = listData[index]["place_id"];
                                    clearList();
                                    getCustomLocation();
                                  },
                                  child: Card(
                                    child: Padding(
                                      padding: EdgeInsets.all(
                                          MediaQuery.of(context).size.height /
                                              60),
                                      child: ListBody(
                                        children: [
                                          Text(
                                            listData[index]
                                                        ["structured_formatting"]
                                                    ["main_text"]
                                                .toString(),
                                            style: const TextStyle(
                                              fontFamily: "Nunito",
                                              fontWeight: FontWeight.bold,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            softWrap: false,
                                            maxLines: 4,
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                30,
                                          ),
                                          Text(
                                            listData[index]
                                                        ["structured_formatting"]
                                                    ["secondary_text"]
                                                .toString(),
                                            softWrap: false,
                                            maxLines: 4,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            listData[0]["description"].toString(),
                                            softWrap: false,
                                            maxLines: 4,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                30,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              shrinkWrap: true,
                              physics: const ClampingScrollPhysics(),
                            ),
                          )
                        : Container(),
                  ],
                ),
                ValueListenableBuilder(
                  valueListenable: locationListener,
                  builder: (context, value, child) {
                    return value
                        ? Center(
                            child: Column(
                              children: [
                                Lottie.asset(
                                  'assets/getLocation.json',
                                  controller: _controller,
                                  onLoaded: (composition) {
                                    _controller
                                      ..duration = composition.duration
                                      ..repeat();
                                  },
                                ),
                              ],
                            ),
                          )
                        : Center(
                            child: ValueListenableBuilder(
                              valueListenable: showCurrentAddress,
                              builder: (context, value, child) => value
                                  ? Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          Lottie.asset(
                                            'assets/getLocation.json',
                                            controller: _controller,
                                            onLoaded: (composition) {
                                              _controller
                                                ..duration = composition.duration
                                                ..repeat();
                                            },
                                          ),
                                          DelayedDisplay(
                                            child: Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      Icons.location_pin,
                                                      color: Colors.green,
                                                    ),
                                                    Text(address.toString(),
                                                        style: const TextStyle(
                                                            color: Colors.black45,
                                                            fontFamily: "Nunito",
                                                            fontSize: 22),
                                                        textAlign:
                                                            TextAlign.center),
                                                  ],
                                                ),
                                                Card(
                                                  color: Colors.green.shade900,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              50)),
                                                  child: const Padding(
                                                    padding: EdgeInsets.all(8.0),
                                                    child: Text(
                                                        "Your Current Location is Updated",
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontFamily: "Nunito",
                                                            fontSize: 18),
                                                        textAlign:
                                                            TextAlign.center),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    )
                                  : const CircularProgressIndicator(
                                      strokeWidth: 1,
                                      color: Colors.orangeAccent,
                                    ),
                            ),
                          );
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  late double serverLatitude;
  late double serverLongitude;

  Future<void> getLocation() async {
    try {
      SharedPreferences preferences = await SharedPreferences.getInstance();

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      serverLatitude = position.latitude;
      serverLongitude = position.longitude;
      preferences.setDouble('latitude', serverLatitude);
      preferences.setDouble('longitude', serverLongitude);
      String url =
          "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=${MapKey.mapKey}";
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> addressComponents =
            json.decode(response.body)['results'][0]['address_components'];
        String locality = addressComponents.firstWhere(
            (entry) => entry['types'].contains('locality'))['long_name'];
        address = locality;
        preferences.setString('address', address.toString());
        preferences.setBool('isLocationSet', true);
        showCurrentAddress.value = true;
        locationListener.value = false;
      }
    } catch (e) {
      return;
    }
  }

        late double  latitude;
        late double longitude;
  Future<void> getCustomLocation() async {
      SharedPreferences preferences = await SharedPreferences.getInstance();
    try {
      String placeIDGetUrl =
          "https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeId&key=${MapKey.mapKey}";
      var placeIDResponse = await RequestApi.getRequestUrl(placeIDGetUrl);
      if (RequestApi.responseState) {
        latitude =
            await placeIDResponse["result"]["geometry"]["location"]["lat"];
        longitude =
            await placeIDResponse["result"]["geometry"]["location"]["lng"];
      }

      String url =
          "https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=${MapKey.mapKey}";
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> addressComponents =
            json.decode(response.body)['results'][0]['address_components'];
        String locality = addressComponents.firstWhere(
            (entry) => entry['types'].contains('locality'))['long_name'];
        address = locality;
        preferences.setString('address', address.toString());
        preferences.setDouble('latitude', latitude);
        preferences.setDouble('longitude', longitude);
        preferences.setBool('isLocationSet', true);
        showCurrentAddress.value = true;
        locationListener.value = false;
      }
    } catch (e) {
      return;
    }
  }

  panel() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        const Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Please Allow Location Permission in App Setting",
                  style: TextStyle(fontFamily: 'DMSans', fontSize: 22)),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                  "We are unable to get your location to provide you best service please allow permission to get your location",
                  style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 16,
                      color: Colors.black38)),
            ),
          ],
        ),
        Card(
          elevation: 10,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          child: Icon(
            Icons.warning,
            size: MediaQuery.of(context).size.height / 10,
            color: Colors.orange,
          ),
        ),
        Icon(
          Icons.location_disabled,
          size: MediaQuery.of(context).size.height / 4,
          color: Colors.red,
        ),
        CupertinoButton(
            color: Colors.indigo,
            onPressed: () {
              Geolocator.openAppSettings();
            },
            child: const Text('Open App Setting'))
      ],
    );
  }
}

class RequestApi {
  static late bool responseState;

  static Future<dynamic> getRequestUrl(String url) async {
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        String jsonData = response.body;
        var decoder = jsonDecode(jsonData);
        responseState = true;
        return decoder;
      } else {
        responseState = false;
      }
    } catch (e) {
      responseState = false;
    }
  }
}
