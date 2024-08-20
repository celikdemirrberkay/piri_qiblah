import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),

      /// 39.75649757032112, 37.05508957748691
      home: const PiriQiblah(
        userLatitude: 39.7602078065278,
        userLongitude: 37.05381501948753,
      ),
    );
  }
}

@immutable
final class PiriQiblah extends StatefulWidget {
  ///
  const PiriQiblah({
    super.key,
    required this.userLatitude,
    required this.userLongitude,
  });

  final double userLatitude;
  final double userLongitude;

  @override
  _PiriQiblahState createState() => _PiriQiblahState();
}

class _PiriQiblahState extends State<PiriQiblah> {
  double? qiblaDirection;
  double initialDirection = 0;
  final _sensors = Sensors();

  @override
  void initState() {
    super.initState();
    qiblaDirection = calculateQiblaDirection(widget.userLatitude, widget.userLongitude);
    _sensors.magnetometerEventStream().listen((event) {
      setState(() {
        initialDirection = calculateDeviceDirection(event);
      });
    });
  }

  /// Calculate device direction
  double calculateDeviceDirection(MagnetometerEvent event) {
    // Manyetik alan verilerini kullanarak cihazın yönünü hesaplayın
    double angle = atan2(event.y, event.x) * (180 / pi);
    return (angle + 360) % 360; // Negatif açıları düzelt
  }

  /// Calculate Qibla direction
  double calculateQiblaDirection(double latitude, double longitude) {
    const double makkahLatitude = 21.4225;
    const double makkahLongitude = 39.8262;

    double latDifference = (makkahLatitude - latitude).toRadians();
    double lonDifference = (makkahLongitude - longitude).toRadians();

    double y = sin(lonDifference) * cos(makkahLatitude.toRadians());
    double x = cos(latitude.toRadians()) * sin(makkahLatitude.toRadians()) - sin(latitude.toRadians()) * cos(makkahLatitude.toRadians()) * cos(lonDifference);

    /// Kıble yönü hesaplamasında, kullanıcının bulunduğu konum ile Mekke arasındaki coğrafi
    /// farktan bir açı elde etmek için atan2 fonksiyonu kullanılır.
    /// Bu açı, cihazın hangi yöne bakması gerektiğini belirler.
    double qiblaDirection = atan2(y, x).toDegrees();

    return (qiblaDirection + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Piri Qiblah')),
      body: SafeArea(
        child: qiblaDirection == null
            ? const CircularProgressIndicator()
            : Transform.rotate(
                angle: (initialDirection - qiblaDirection!) * pi / 180,
                child: Stack(
                  children: [
                    Center(
                      child: SvgPicture.asset(
                        'assets/compass.svg',
                        width: 300,
                        height: 300,
                      ),
                    ),
                    Center(
                      child: Transform.rotate(
                        angle: qiblaDirection! * pi / 180 * -1,
                        child: const Icon(
                          Icons.navigation,
                          size: 100,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

extension AngleConversion on double {
  double toRadians() => this * pi / 180;
  double toDegrees() => this * 180 / pi;
}
