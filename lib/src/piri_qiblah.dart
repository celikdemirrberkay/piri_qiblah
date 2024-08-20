import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// PiriQiblah is a widget that shows the direction of the Qiblah.
@immutable
final class PiriQiblah extends StatefulWidget {
  ///
  const PiriQiblah({
    super.key,
    required this.langitude,
    required this.longitude,
  });

  /// The langitude and longitude
  final double langitude;
  final double longitude;

  @override
  State<PiriQiblah> createState() => _PiriQiblahState();
}

class _PiriQiblahState extends State<PiriQiblah> {
  double _direction = 0;

  @override
  void initState() {
    super.initState();
    Sensors().magnetometerEventStream().listen((MagnetometerEvent event) {
      setState(() {
        _direction = event.x;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Transform.rotate(
          angle: _direction * pi / 180 * -1,
          child: Icon(
            Icons.navigation,
            size: 100,
          ),
        ),
      ),
    );
  }
}

double calculateQiblaDirection(double latitude, double longitude) {
  const double makkahLatitude = 21.4225;
  const double makkahLongitude = 39.8262;

  double lonDifference = (makkahLongitude - longitude).toRadians();

  double y = sin(lonDifference) * cos(makkahLatitude.toRadians());
  double x = cos(latitude.toRadians()) * sin(makkahLatitude.toRadians()) - sin(latitude.toRadians()) * cos(makkahLatitude.toRadians()) * cos(lonDifference);

  double qiblaDirection = atan2(y, x).toDegrees();

  return (qiblaDirection + 360) % 360;
}

extension AngleConversion on double {
  double toRadians() => this * pi / 180;
  double toDegrees() => this * 180 / pi;
}
