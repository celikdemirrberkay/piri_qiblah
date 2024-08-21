import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';

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
    super.key,
  });

  /// If you pass true, default assets will be used
  /// If you have a custom needle or background compass view, you can pass them false
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
    isAccessGranted = await checkLocationPermissionForQiblah();
    if (isAccessGranted == false) {
      await requestLocationPermissionForQiblah();
      isAccessGranted = await checkLocationPermissionForQiblah();
    }
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
                  return _specialErrorMessage('Something went wrong');
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
                  return _specialErrorMessage('Something went wrong');
              }
            },
          )
        : _specialErrorMessage('Waiting for permission ...');
  }

  Widget _stack() {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: animationForBackgroundCompass!,
          builder: (context, child) => Transform.rotate(
            angle: animationForBackgroundCompass!.value,
            child: widget.useDefaultAssets
                ? Center(
                    child: SizedBox(
                      height: 300,
                      width: 300,
                      child: SvgPicture.asset('assets/compass.svg'),
                    ),
                  )
                : widget.customBackgroundCompass,
          ),
        ),
        AnimatedBuilder(
          animation: animationForNeedle!,
          builder: (context, child) => Transform.rotate(
            angle: animationForNeedle!.value,
            child: Center(
              child: widget.useDefaultAssets
                  ? const Icon(
                      Icons.navigation,
                      size: 100,
                      color: Colors.green,
                    )
                  : widget.customNeedle,
            ),
          ),
        ),
      ],
    );
  }

  /// Loading indicator
  Widget _loadingIndicator() => widget.loadingIndicator ?? const Center(child: CircularProgressIndicator());

  /// Exception message
  Widget _specialErrorMessage(String message) => widget.specialErrorWidget ?? Text(message);

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
