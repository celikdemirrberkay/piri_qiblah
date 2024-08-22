import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';

/// ----------------------------------------------------------------------------

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const MyApp());
}

/// ----------------------------------------------------------------------------

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
      home: Scaffold(
        appBar: AppBar(title: const Text('Piri Qiblah')),
        body: SafeArea(
          child: SizedBox.expand(
            child: Column(
              children: [
                PiriQiblah(
                  useDefaultAssets: false,
                  customBackgroundCompass: SvgPicture.asset('assets/error.svg'),
                  customNeedle: const Icon(Icons.abc),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ----------------------------------------------------------------------------
@immutable
final class PiriQiblah extends StatefulWidget {
  ///
  const PiriQiblah({
    this.useDefaultAssets = true,
    this.customNeedle,
    this.customBackgroundCompass,
    this.loadingIndicator,
    this.specialErrorWidget,
    this.waitingForPermissionWidget,
    this.compassSize,
    super.key,
  });

  /// If you pass true, default assets will be used
  /// If you have a custom needle or background compass view, you can pass false
  final bool useDefaultAssets;

  /// Custom needle view
  final Widget? customNeedle;

  /// Custom background compass view
  final Widget? customBackgroundCompass;

  /// Loading indicator view
  /// While the stream is loading, the value you give appears on the screen.
  /// If null is returned, default loading indicator is used.
  final Widget? loadingIndicator;

  /// Error  widget
  /// While the stream is on error, the value you give appears on the screen.
  /// If null is returned, default text is used.
  final Widget? specialErrorWidget;

  /// Widget to be displayed while waiting for permission.
  /// You can customize with this parameter
  final Widget? waitingForPermissionWidget;

  /// The height of the widget, whether custom or default
  final double? compassSize;

  @override
  // ignore: library_private_types_in_public_api
  _PiriQiblahState createState() => _PiriQiblahState();
}

class _PiriQiblahState extends State<PiriQiblah> with TickerProviderStateMixin {
  bool isAccessGranted = false;

  /// Animation properties for needles
  late Animation<double>? animationForNeedle;
  late AnimationController? _animationControllerForNeedle;

  /// Animation properties for background compass view
  late Animation<double>? animationForBackgroundCompass;
  late AnimationController? _animationControllerForBackgroundCompass;

  /// Begin tween values
  double beginForNeedle = 0;
  double beginForCompass = 0;

  @override
  void initState() {
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
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();

    /// Check location permission for qiblah if it is granted
    /// isAccessGranted is set to true, otherwise it is set to false.
    isAccessGranted = await checkLocationPermissionForQiblah();
    if (isAccessGranted == false) {
      /// If isAccessGranted is false, request location permission for qiblah
      await requestLocationPermissionForQiblah();
      isAccessGranted = await checkLocationPermissionForQiblah();
    }

    /// Then update the screen
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return isAccessGranted
        ? StreamBuilder(
            stream: FlutterQiblah.qiblahStream,
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  return _errorWidget();
                case ConnectionState.waiting:
                  return _loadingIndicator();
                case ConnectionState.active:
                  if (snapshot.hasError) {
                    return Text(snapshot.error.toString());
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
                    return _stack();
                  }
                case ConnectionState.done:
                  return _errorWidget();
              }
            },
          )

        /// If the location permission is not granted, the waiting for permission widget is displayed.
        : _waitingForPermissionWidget();
  }

  /// Stack view for needle and background compass
  /// If you want to use custom assets, you can pass them as a parameter.
  Widget _stack() {
    return SizedBox(
      height: widget.compassSize ?? 300,
      width: widget.compassSize ?? 300,
      child: Stack(
        children: [
          _backgroundCompassWidget(),
          _qiblahNeedleWidget(),
        ],
      ),
    );
  }

  /// Needle view
  Widget _qiblahNeedleWidget() {
    return AnimatedBuilder(
      animation: animationForNeedle!,
      builder: (context, child) => Transform.rotate(
        angle: animationForNeedle!.value,
        child: Center(
          child: widget.useDefaultAssets
              ? Icon(
                  Icons.navigation,
                  size: (widget.compassSize ?? 300) / 3,
                  color: Colors.green,
                )
              : widget.customNeedle,
        ),
      ),
    );
  }

  /// Background compass view
  Widget _backgroundCompassWidget() {
    return AnimatedBuilder(
      animation: animationForBackgroundCompass!,
      builder: (context, child) => Transform.rotate(
          angle: animationForBackgroundCompass!.value,
          child: SizedBox.expand(
            child: widget.useDefaultAssets
                ? SvgPicture.asset(
                    _PiriQiblahAssetPath.defaultCompassSvgPath.path,
                  )
                : widget.customBackgroundCompass,
          )),
    );
  }

  /// Loading indicator
  Widget _loadingIndicator() =>

      /// Special loading indicator
      widget.loadingIndicator ??

      /// Default loading indicator
      const Center(
        child: CircularProgressIndicator(),
      );

  /// Exception message
  Widget _errorWidget() =>

      /// Special error widget
      widget.specialErrorWidget ??

      /// Default error widget
      Column(
        children: [
          SvgPicture.asset(_PiriQiblahAssetPath.defaultErrorSvgPath.path),
          const Text('Something went wrong!'),
        ],
      );

  /// Waiting for permission widget
  Widget _waitingForPermissionWidget() =>

      /// Special waiting for permission widget
      widget.waitingForPermissionWidget ??

      /// Default waiting for permission widget
      Column(
        children: [
          SvgPicture.asset(_PiriQiblahAssetPath.defaultWaitingForLocationSvgPath.path),
          const Text('Waiting for permission ...'),
        ],
      );

  /// Request location permission for qiblah
  Future<void> requestLocationPermissionForQiblah() async {
    await FlutterQiblah.requestPermissions();
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

/// Extension for angle conversion
extension AngleConversion on double {
  double toRadians() => this * pi / 180;
  double toDegrees() => this * 180 / pi;
}

/// Packages default asset paths
enum _PiriQiblahAssetPath {
  /// Default compass svg asset paths
  defaultCompassSvgPath('assets/compass.svg'),

  /// Default error svg asset paths
  defaultErrorSvgPath('assets/error.svg'),

  /// Default waiting for location svg asset paths
  defaultWaitingForLocationSvgPath('assets/waiting_for_location.svg');

  /// Path parameter
  final String path;

  const _PiriQiblahAssetPath(this.path);
}
