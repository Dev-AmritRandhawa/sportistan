import 'dart:convert';
import 'package:http/http.dart' as http;


class FirebaseCloudMessaging{
static Future<bool> sendPushMessage(String body, String title, String token) async {

    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer AAAAc9YPq2A:APA91bElqwfJnL_35X9BB3iiBYYmYZzdfMc5QJv6uPtvUsKJxihtpL7WXpeFnvmC3wAGKWrKn_1r1rPFsYx-b49t7MHsbymg9oXzuh-41UmwbEpnNy4ThpoMX6tHkDRnpNy8i0E3WRKQ',
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