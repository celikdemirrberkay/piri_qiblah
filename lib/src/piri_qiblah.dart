import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';

/// [PiriQiblah] is a widget package that shows the qibla direction to be used in
/// "Piri Medya" projects.
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
    this.defaultNeedleColor,
    super.key,
  });

  /// If you pass true, default assets will be used.
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

  /// The height of the widget, whether custom or default.
  /// If you don't pass a value, the default value is 300.
  final double? compassSize;

  /// Default needle color
  final Color? defaultNeedleColor;

  @override
  // ignore: library_private_types_in_public_api
  _PiriQiblahState createState() => _PiriQiblahState();
}

class _PiriQiblahState extends State<PiriQiblah> with TickerProviderStateMixin {
  bool isAccessGranted = false;

  /// Animation properties for needles
  late Animation<double>? _animationForNeedle;
  late AnimationController? _animationControllerForNeedle;

  /// Animation properties for background compass view
  late Animation<double>? _animationForBackgroundCompass;
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
    _animationForNeedle = Tween<double>(
      begin: 0.0,
      end: 360.0,
    ).animate(_animationControllerForNeedle!);

    /// Animation for background  compass view
    _animationControllerForBackgroundCompass = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 500),
    );
    _animationForBackgroundCompass = Tween<double>(
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
                case ConnectionState.done:
                  return _errorWidget();
                case ConnectionState.waiting:
                  return _loadingIndicator();
                case ConnectionState.active:
                  // If there is an error, the error widget is displayed.
                  if (snapshot.hasError) {
                    return _errorWidget();
                  }
                  // If there is no error, the compass view is displayed.
                  else {
                    /// Animation properties for needle view
                    _animationForNeedle = Tween(
                      begin: beginForNeedle,
                      end: (snapshot.data!.qiblah).toRadians() * -1,
                    ).animate(_animationControllerForNeedle!);
                    beginForNeedle = snapshot.data!.qiblah.toRadians() * -1;
                    _animationControllerForNeedle!.forward(from: 0);

                    /// Animation properties for background compass view
                    _animationForBackgroundCompass = Tween(
                      begin: (snapshot.data!.direction).toRadians() * -1,
                      end: 360.0,
                    ).animate(_animationControllerForBackgroundCompass!);
                    beginForCompass = snapshot.data!.direction.toRadians() * -1;
                    _animationControllerForBackgroundCompass!.forward(from: 0);

                    /// Return the compass view
                    return _stack();
                  }
              }
            },
          )

        /// If the location permission is not granted, the waiting for permission widget is displayed.
        : _waitingForPermissionWidget();
  }

  /// Stack view for needle and background compass
  /// If you want to use custom assets, you can pass them as a parameter.
  Widget _stack() {
    return Column(
      children: [
        Icon(
          Icons.navigation,
          size: (widget.compassSize ?? 300) / 15,
        ),
        SizedBox(
          height: widget.compassSize ?? 300,
          width: widget.compassSize ?? 300,
          child: Stack(
            children: [
              _backgroundCompassWidget(),
              _qiblahNeedleWidget(),
            ],
          ),
        ),
      ],
    );
  }

  /// Needle view
  Widget _qiblahNeedleWidget() {
    return AnimatedBuilder(
      animation: _animationForNeedle!,
      builder: (context, child) => Transform.rotate(
        angle: _animationForNeedle!.value,
        child: Center(
          child: widget.useDefaultAssets
              ? Icon(
                  Icons.navigation,
                  size: (widget.compassSize ?? 300) / 3,
                  color: widget.defaultNeedleColor,
                )
              : widget.customNeedle,
        ),
      ),
    );
  }

  /// Background compass view
  Widget _backgroundCompassWidget() {
    return AnimatedBuilder(
      animation: _animationForBackgroundCompass!,
      builder: (context, child) => Transform.rotate(
        angle: _animationForBackgroundCompass!.value,
        child: SizedBox.expand(
          child: widget.useDefaultAssets
              ? SvgPicture.asset(
                  _PiriQiblahAssetPath.defaultCompassSvgPath.path,
                )
              : widget.customBackgroundCompass,
        ),
      ),
    );
  }

  /// Loading indicator
  Widget _loadingIndicator() =>

      /// Special loading indicator
      SizedBox(
        height: (widget.compassSize ?? 300) / 5,
        width: (widget.compassSize ?? 300) / 5,
        child: widget.loadingIndicator ??

            /// Default loading indicator
            const Center(
              child: CircularProgressIndicator(),
            ),
      );

  /// Exception message
  Widget _errorWidget() => SizedBox(
        height: (widget.compassSize ?? 300) / 2,
        width: (widget.compassSize ?? 300) / 2,
        child: widget.specialErrorWidget ??

            /// Default error widget
            Column(
              children: [
                SvgPicture.asset(_PiriQiblahAssetPath.defaultErrorSvgPath.path),
                const Text('Something went wrong!'),
              ],
            ),
      );

  /// Waiting for permission widget
  Widget _waitingForPermissionWidget() => SizedBox(
        height: (widget.compassSize ?? 300) / 2,
        width: (widget.compassSize ?? 300) / 2,
        child: widget.waitingForPermissionWidget ??

            /// Default waiting for permission widget
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(_PiriQiblahAssetPath.defaultWaitingForLocationSvgPath.path),
                FittedBox(child: const Text('Waiting for permission ...')),
              ],
            ),
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
  defaultCompassSvgPath('packages/piri_qiblah/lib/assets/compass.svg'),

  /// Default error svg asset paths
  defaultErrorSvgPath('packages/piri_qiblah/lib/assets/error.svg'),

  /// Default waiting for location svg asset paths
  defaultWaitingForLocationSvgPath('packages/piri_qiblah/lib/assets/waiting_for_location.svg');

  /// Path parameter
  final String path;

  const _PiriQiblahAssetPath(this.path);
}
