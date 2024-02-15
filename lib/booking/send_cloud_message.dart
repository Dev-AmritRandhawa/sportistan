import 'dart:convert';
import 'package:http/http.dart' as http;


class FirebaseCloudMessaging{
static Future<bool> sendPushMessage(String body, String title, String token) async {

    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer AAAACS6Ujj4:APA91bEMFKhQeAG_XEzFPiLU-uQinZfjdAvFQ8-7GN18qwU2ED9UZ2dLkjE59UAFcBe3pP41Ua27cCwVcTSziM5EX_AzubpV6WZvT4xkzqhWZgl05Xsqig7BMwOVEjksXc-LItDAT-Er',
        },
        body: jsonEncode(
          <String, dynamic>{
              "to": token,
              "notification": {
                "title": title,
                "body": body,
              },
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'id': '1',
              'status': 'done'
            },
              "priority": "high"
          },
        ),
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}