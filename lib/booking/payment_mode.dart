import 'package:flutter/material.dart';

class PaymentMode{
  static String type = "Cash";
  static List<String> paymentOptions = ["Cash","UPI", "Debit Card & Credit Cards", "Wallet", "NetBanking"];
}
class Payments extends StatefulWidget {
  const Payments({super.key});

  @override
  State<Payments> createState() => _PaymentsState();
}

class _PaymentsState extends State<Payments> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
