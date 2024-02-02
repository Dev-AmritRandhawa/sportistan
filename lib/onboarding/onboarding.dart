import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:SportistanPro/authentication/authentication.dart';
import 'package:SportistanPro/widgets/page_route.dart';

class OnBoard extends StatefulWidget {
  const OnBoard({super.key});

  @override
  State<OnBoard> createState() => _OnBoardState();
}

class _OnBoardState extends State<OnBoard> {
  int currentPage = 0;
  final PageController _pageController = PageController(initialPage: 0);
  ValueNotifier<bool> loading = ValueNotifier<bool>(false);

  _onPageChanged(int index) {
    setState(() {
      currentPage = index;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return Scaffold(
      bottomNavigationBar: ValueListenableBuilder(
        valueListenable: loading,
        builder: (context, value, child) => CupertinoButton(
            color: Colors.green,
            borderRadius: BorderRadius.zero,
            onPressed: () async {
              loading.value = true;
              userStateOnBoardSave();
            },
            child: const Text(
              "Start Booking",
              style: TextStyle(fontFamily: "DMSans"),
            )),
      ),
      body: PageView.builder(
        physics: const BouncingScrollPhysics(),
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: slideList.length,
        itemBuilder: (ctx, i) => SlideItem(i),
      ),
    );
  }

  void userStateOnBoardSave() async {
    final data = await SharedPreferences.getInstance();
    data.setBool("onBoarding", true).then((value) => {
          loading.value = false,
          PageRouter.pushRemoveUntil(context, const PhoneAuthentication())
        });
  }
}

class SlideItem extends StatefulWidget {
  final int index;

  const SlideItem(this.index, {super.key});

  @override
  State<SlideItem> createState() => _SlideItemState();
}

class _SlideItemState extends State<SlideItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height / 6,
            child: Lottie.asset(
              'assets/loading.json',
              controller: _controller,
              onLoaded: (composition) {
                _controller
                  ..duration = composition.duration
                  ..repeat();
              },
            ),
          ),
          DelayedDisplay(
            child: Text(
              "Sportistan",
              style: TextStyle(
                  fontFamily: "DMSans",
                  fontSize: MediaQuery.of(context).size.height / 35,
                  color: const Color(0XFF3c2deb),
                  fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height / 3,
            child: Image.asset(
              slideList[widget.index].image,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.height / 55),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      slideList[widget.index].title,
                      style: TextStyle(
                          fontFamily: "DMSans",
                          fontSize: MediaQuery.of(context).size.height / 40,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        slideList[widget.index].description,
                        style: TextStyle(
                          fontFamily: "DMSans",
                          fontSize: MediaQuery.of(context).size.height / 50,
                          color: Colors.black45,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Slide {
  String title;
  String description;
  String image;

  Slide({required this.title, required this.description, required this.image});
}

final slideList = [
  Slide(
      title: "Sport Grounds",
      description: "Show your sportsman spirit and book grounds to play.",
      image: "assets/onBoard.png"),
];
