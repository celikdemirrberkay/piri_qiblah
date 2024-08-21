import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';

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
      home: const PiriQiblah(),
    );
  }
}

@immutable
final class PiriQiblah extends StatefulWidget {
  ///
  const PiriQiblah({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PiriQiblahState createState() => _PiriQiblahState();
}

class _PiriQiblahState extends State<PiriQiblah> with TickerProviderStateMixin {
  /// Animation properties for needles
  late Animation<double>? animationForNeedle;
  late AnimationController? _animationControllerForNeedle;

  /// Animation properties for background compass view
  late Animation<double>? animationForBackgroundCompass;
  late AnimationController? _animationControllerForBackgroundCompass;

  double beginForNeedle = 0;
  double beginForCompass = 0;

  @override
  void initState() {
    /// Check and Request location permission for qiblah
    requestLocationPermissionForQiblah();

    /// Animation for needles
    _animationControllerForNeedle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    animationForNeedle = Tween<double>(
      begin: 0.0,
      end: 360.0,
    ).animate(_animationControllerForNeedle!);

    /// Animation for background  compass view
    _animationControllerForBackgroundCompass = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 500),
    );
    animationForBackgroundCompass = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(_animationControllerForBackgroundCompass!);
    super.initState();
  }

  @override
  void dispose() {
    _animationControllerForNeedle!.dispose();
    _animationControllerForBackgroundCompass!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Piri Qiblah')),
      body: SafeArea(
        child: SizedBox.expand(
          child: Column(
            children: [
              const Spacer(flex: 30),
              const Icon(
                Icons.navigation,
              ),
              Expanded(
                flex: 40,
                child: StreamBuilder(
                  stream: FlutterQiblah.qiblahStream,
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.none:
                        return _exceptionMessage();
                      case ConnectionState.waiting:
                        return _loadingIndicator();
                      case ConnectionState.active:
                        if (snapshot.hasError) {
                          return _exceptionMessage();
                        } else {
                          /// Animation properties for needle view
                          animationForNeedle = Tween(
                            begin: beginForNeedle,
                            end: (snapshot.data!.qiblah).toRadians() * -1,
                          ).animate(_animationControllerForNeedle!);
                          beginForNeedle = snapshot.data!.qiblah.toRadians() * -1;
                          _animationControllerForNeedle!.forward(from: 0);

                          /// Animation properties for background compass view
                          animationForBackgroundCompass = Tween(
                            begin: (snapshot.data!.direction).toRadians() * -1,
                            end: 360.0,
                          ).animate(_animationControllerForBackgroundCompass!);
                          beginForCompass = snapshot.data!.direction.toRadians() * -1;
                          _animationControllerForBackgroundCompass!.forward(from: 0);

                          /// Return the compass view
                          return Stack(
                            children: [
                              AnimatedBuilder(
                                animation: animationForBackgroundCompass!,
                                builder: (context, child) => Transform.rotate(
                                  angle: animationForBackgroundCompass!.value,
                                  child: Center(
                                    child: SizedBox(
                                      height: 300,
                                      width: 300,
                                      child: SvgPicture.asset('assets/compass.svg'),
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: animationForNeedle!,
                                builder: (context, child) => Transform.rotate(
                                  angle: animationForNeedle!.value,
                                  child: const Center(
                                    child: Icon(
                                      Icons.navigation,
                                      size: 100,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      case ConnectionState.done:
                        return _exceptionMessage();
                    }
                  },
                ),
              ),
              const Spacer(flex: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loadingIndicator() => const Center(child: CircularProgressIndicator());

  Widget _exceptionMessage() => const Text(
        'Something went wrong',
      );

  /// Request location permission for qiblah
  Future<void> requestLocationPermissionForQiblah() async {
    final permission = await checkLocationPermissionForQiblah();
    if (!permission) {
      await FlutterQiblah.requestPermissions();
    }
  }

  /// Check location permission for qiblah
  Future<bool> checkLocationPermissionForQiblah() async {
    final permission = await Geolocator.checkPermission();
    switch (permission) {
      case LocationPermission.denied:
        return false;
      case LocationPermission.deniedForever:
        return false;
      case LocationPermission.whileInUse:
        return true;
      case LocationPermission.always:
        return true;
      case LocationPermission.unableToDetermine:
        return false;
    }
  }
}

extension AngleConversion on double {
  double toRadians() => this * pi / 180;
  double toDegrees() => this * 180 / pi;
}
