import 'package:flutter/material.dart';
import 'package:safezone/frontend/widgets/buttons/identifiedZone.dart';

import '../../widgets/buttons/userinfomartion.dart';

class AdminSafezones extends StatefulWidget {
  const AdminSafezones({super.key});

  @override
  State<AdminSafezones> createState() => _AdminSafezonesState();
}

class _AdminSafezonesState extends State<AdminSafezones> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        child: ListView(
          children: [
            IdentifiedZone(
                name: "Miro Abnormal",
                profileImage: '',
                location: 'Pantal, Dagupan City, Pangasinan'),
            IdentifiedZone(
                name: "Miro Abnormal",
                profileImage: '',
                location: 'Pantal, Dagupan City, Pangasinan'),
            IdentifiedZone(
                name: "Miro Abnormal",
                profileImage: '',
                location: 'Pantal, Dagupan City, Pangasinan'),
            IdentifiedZone(
                name: "Miro Abnormal",
                profileImage: '',
                location: 'Pantal, Dagupan City, Pangasinan'),
            IdentifiedZone(
                name: "Miro Abnormal",
                profileImage: '',
                location: 'Pantal, Dagupan City, Pangasinan'),
            IdentifiedZone(
                name: "Miro Abnormal",
                profileImage: '',
                location: 'Pantal, Dagupan City, Pangasinan'),
          ],
        ),
      ),
    );
  }
}
