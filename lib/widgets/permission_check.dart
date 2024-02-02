import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:SportistanPro/nav/main_page.dart';
import 'package:SportistanPro/widgets/page_route.dart';

class PermissionCheck extends StatefulWidget {
  final bool result;

  const PermissionCheck({super.key, required this.result});

  @override
  State<PermissionCheck> createState() => _PermissionCheckState();
}

class _PermissionCheckState extends State<PermissionCheck> with WidgetsBindingObserver {
   bool check = false ;
@override
  void initState() {
  WidgetsBinding.instance.addObserver(this);
    check = widget.result;
    super.initState();
  }
   @override
   void didChangeAppLifecycleState(AppLifecycleState state) {
     switch (state) {
       case AppLifecycleState.inactive:
         break;
       case AppLifecycleState.paused:
         break;
       case AppLifecycleState.resumed:
         getLocationPermission();
         break;
       case AppLifecycleState.detached:
         break;
       case AppLifecycleState.hidden:
     }
   }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Location Permission Disabled",
              style: TextStyle(color: Colors.red, fontFamily: "DMSans"),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Not able to provide nearby sport grounds until permission will not allowed",
              style: TextStyle(color: Colors.black54, fontFamily: "DMSans"),
            ),
          ),
          Image.asset(
            "assets/noPermission.png",
            height: MediaQuery.of(context).size.height / 4,
          ),
         check
              ? Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child:
                Text("Open App Settings to Allow Permission"),
              ),
              CupertinoButton(
                  color: Colors.red,
                  onPressed: () async {
                    await openAppSettings();
                  },
                  child: const Text("Open Settings")),
            ],
          )
              : Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Allow Permission to use Sportistan"),
              ),
              CupertinoButton(
                  color: Colors.green,
                  onPressed: () async {
                    await getLocationPermission();
                  },
                  child: const Text("Allow Permission")),
            ],

          )
        ],
      ),
    ));
  }

  Future<void> getLocationPermission() async {
    PermissionStatus permissionStatus;
    try {
      permissionStatus = await Permission.location.request();
      if (permissionStatus == PermissionStatus.denied) {
        setState(() {
        check = false;
        });
      } else if (permissionStatus == PermissionStatus.granted ||
          permissionStatus == PermissionStatus.limited) {
        if (mounted) {
          PageRouter.pushRemoveUntil(context, const MainPage());
        }
      } else if (permissionStatus == PermissionStatus.permanentlyDenied) {
        setState(() {

          check = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
