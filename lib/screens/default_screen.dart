import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:oss_surveys_customer/database/database.dart";
import "package:oss_surveys_customer/main.dart";

/// Default Screen
class DefaultScreen extends StatefulWidget {
  const DefaultScreen({ super.key });

  @override
  State<DefaultScreen> createState() => _DefaultScreenState();
}

/// Default Screen state
class _DefaultScreenState extends State<DefaultScreen> {
  bool _isApprovedDevice = false;

  @override
  void initState() {
    super.initState();
    database.isDeviceApproved().then((value) {
      if (!value) {
        Timer.periodic(const Duration(seconds: 10), (timer) async {
          logger.info("Checking if device is approved...");
          if (await database.isDeviceApproved()) {
            logger.info("Device was approved, canceling timer.");
            timer.cancel();
            _isApprovedDevice = true;
          }
        });
      }
      
      _isApprovedDevice = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          children: [
            if (!_isApprovedDevice) const Text("Laitetta ei ole vielä otettu käyttöön.", style: TextStyle(fontFamily: "S-Bonus-Regular", color: Color(0xffffffff), fontSize: 20),),
            SvgPicture.asset(
                  "assets/logo.svg",
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: MediaQuery.of(context).size.height * 0.7
                ),
          ]
        )
      )
    );
  }
}