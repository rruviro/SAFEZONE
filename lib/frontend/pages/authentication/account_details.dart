// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:safezone/frontend/widgets/account_display.dart';

import '../../../resources/schema/colors.dart';
import '../../../resources/schema/texts.dart';

class AccountDetails extends StatefulWidget {
  const AccountDetails({super.key});

  @override
  State<AccountDetails> createState() => _AccountDetailsState();
}

class _AccountDetailsState extends State<AccountDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: CategoryText(
          text: "Account Details"
        ),
      ),
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 15),
        child: ListView(
          children: [
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 240, 240, 240),
                borderRadius: BorderRadius.circular(5),
                // boxShadow: const [
                //   BoxShadow(
                //     color: Colors.grey,
                //     blurRadius: 2,
                //     offset: Offset(1, 1),
                //   ),
                // ],
              ),
              child: Center(
                child: Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle
                        ),
                      ),
                      SizedBox(height: 5),
                      CategoryText(
                        text: "Jaira Solis"
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 13,
                            height: 13,
                            child: SvgPicture.asset(
                              'lib/resources/svg/verified.svg',
                              color: widgetPricolor,
                            ),
                          ),
                          SizedBox(width: 5),
                          CategoryDescripText(
                            text: "Verified at Safezone"
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Container(
                width: double.infinity,
                child: Stack(
                  children: [
                    Text(
                      "Credentials",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        child: SvgPicture.asset(
                          'lib/resources/svg/edit.svg'
                        ),
                      )
                    )
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 240, 240, 240),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Container(
                margin: EdgeInsets.only(
                  left: 10,
                  right: 10
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AccountDisplay(
                      title: "Password", 
                      svgIcon: "lib/resources/svg/password.svg", 
                      data: "Squk1*****"
                    ),
                    AccountDisplay(
                      title: "Phone", 
                      svgIcon: "lib/resources/svg/phone.svg", 
                      data: "(+63) 970 815 2371"
                    ),
                    AccountDisplay(
                      title: "Email", 
                      svgIcon: "lib/resources/svg/mail.svg", 
                      data: "j1loui***@gmail.com"
                    ),
                    AccountDisplay(
                      title: "Location", 
                      svgIcon: "lib/resources/svg/location.svg", 
                      data: "Pangasinan, Dagupan City, Pantal"
                    )
                  ],
                )
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Text(
                "Privacy & Security",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black
                ),
              ),
            ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 240, 240, 240),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Container(
                margin: EdgeInsets.only(
                  left: 10,
                  right: 10
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AccountDisplay(
                      title: "Two-step Authentication", 
                      svgIcon: "lib/resources/svg/two-step.svg", 
                      data: "Enable"
                    ),
                    AccountDisplay(
                      title: "Alerts for Suspicious Activity", 
                      svgIcon: "lib/resources/svg/two-step.svg", 
                      data: "Enable"
                    )
                  ]
                )
              )
            )
          ]
        )
      )
    );
  }
}