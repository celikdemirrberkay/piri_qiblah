import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:location/location.dart';
import 'package:piri_qiblah/src/qibla_calculation/qibla_calculation.dart';
import 'package:piri_qiblah/src/qibla_calculation/qiblah_direction.dart';

/// [PiriQiblah] is a widget package that shows the qibla direction to be used in
/// "Piri Medya" projects.
@immutable
final class PiriQiblah extends StatefulWidget {
  ///
  const PiriQiblah({
    this.defaultWidgetPermissionDeniedMessage,
    this.useDefaultAssets = true,
    this.customNeedle,
    this.customBackgroundCompass,
    this.loadingIndicator,
    this.specialErrorWidget,
    this.waitingForPermissionWidget,
    this.compassSize,
    this.defaultNeedleColor,
    this.defaultWidgetErrorText,
    this.customSpaceBetweenCompassAndAngleText,
    this.angleTextStyle,
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

  /// Custom permission denied message for default permission denied widget.
  /// If location permission is not given by the user,
  /// this text is displayed in the widget that appears.
  /// If you don't pass a value, the default value is 'Konum izni bekleniyor...'.
  final String? defaultWidgetPermissionDeniedMessage;

  /// Custom error message for default error widget.
  /// If there is an error this text is displayed in the widget that appears.
  /// If you don't pass a value, the default value is 'Bir hata oluştu'
  final String? defaultWidgetErrorText;

  /// Custom space between compass and angle text
  final double? customSpaceBetweenCompassAndAngleText;

  /// Custom angle text style
  final TextStyle? angleTextStyle;

  @override
  // ignore: library_private_types_in_public_api
  _PiriQiblahState createState() => _PiriQiblahState();
}

class _PiriQiblahState extends State<PiriQiblah> with TickerProviderStateMixin, WidgetsBindingObserver {
  /// Location permission bool value for qiblah
  /// If the location permission is granted, it is set to true,
  /// otherwise it is set to false.
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

  /// initState
  @override
  void initState() {
    /// Animation properties for needles
    _animationControllerForNeedle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationForNeedle = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(_animationControllerForNeedle!);

    /// Animation properties for background compass
    _animationControllerForBackgroundCompass = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 500),
    );
    _animationForBackgroundCompass = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(_animationControllerForBackgroundCompass!);

    ///
    super.initState();

    /// Control app lifecycle
    WidgetsBinding.instance.addObserver(this); // Start observing the widget
  }

  @override
  void dispose() {
    /// Disposing animation controllers and removing the observer
    _animationControllerForNeedle!.dispose();
    _animationControllerForBackgroundCompass!.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    /// If the app is resumed, check the location permission for qiblah
    /// User may have changed the location permission settings
    if (state == AppLifecycleState.resumed) {
      /// Checking again the location permission for qiblah
      isAccessGranted = await checkLocationPermissionForQiblah();
      setState(() {});
    }
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
                    /// Animation properties set for needle view
                    _animationForNeedle = Tween(
                      begin: beginForNeedle,
                      end: (snapshot.data!.qiblah).toRadians() * -1,
                    ).animate(_animationControllerForNeedle!);
                    beginForNeedle = snapshot.data!.qiblah.toRadians() * -1;
                    _animationControllerForNeedle!.forward(from: 0);

                    /// Animation properties set for background compass view
                    _animationForBackgroundCompass = Tween(
                      begin: (snapshot.data!.direction).toRadians() * -1,
                      end: 360.0,
                    ).animate(_animationControllerForBackgroundCompass!);
                    beginForCompass = snapshot.data!.direction.toRadians() * -1;
                    _animationControllerForBackgroundCompass!.forward(from: 0);

                    /// Return the compass view
                    return _qiblahStack(snapshot.data!);
                  }
              }
            },
          )

        /// If the location permission is not granted, the waiting for permission widget is displayed.
        : _waitingForPermissionWidget();
  }

  /// Stack view for needle and background compass
  /// If you want to use custom assets, you can pass them as a parameter.
  Widget _qiblahStack(QiblahDirection qiblahDirection) {
    return Column(
      children: [
        _qiblahAngleText(qiblahDirection),
        SizedBox(height: widget.customSpaceBetweenCompassAndAngleText ?? 5),
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

  /// Qiblah angle text widget
  Widget _qiblahAngleText(QiblahDirection qiblahDirection) {
    return Text(
      /// Qiblah Angle Text
      ((qiblahDirection.direction.toInt() - 180) * -1).isNegative
          ? ((qiblahDirection.direction.toInt() - 180)).toString()
          : ((qiblahDirection.direction.toInt() - 180) * -1).toString(),

      /// Qiblah Angle Text Style
      style: widget.angleTextStyle?.copyWith(
        color: qiblahDirection.direction.toInt() - 180 == 0 ? Colors.green : Colors.red,
        fontSize: 20,
      ),
    );
  }

  /// Needle view
  ///  Both default and custom assets can be used.
  Widget _qiblahNeedleWidget() {
    return AnimatedBuilder(
      animation: _animationForNeedle!,
      builder: (context, child) => Transform.rotate(
        angle: _animationForNeedle!.value,
        child: widget.useDefaultAssets == true
            ? Center(
                child: Icon(
                  Icons.navigation,
                  size: (widget.compassSize ?? 300) / 3,
                  color: widget.defaultNeedleColor,
                ),
              )
            : widget.useDefaultAssets
                ? Center(
                    child: Icon(
                      Icons.navigation,
                      color: widget.defaultNeedleColor,
                    ),
                  )
                : Center(
                    child: SizedBox.expand(
                      child: Column(
                        children: [
                          Expanded(flex: 51, child: FittedBox(child: widget.customNeedle!)),
                          Spacer(flex: 49),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  /// Background compass view
  ///  Both default and custom assets can be used.
  Widget _backgroundCompassWidget() {
    return AnimatedBuilder(
      animation: _animationForBackgroundCompass!,
      builder: (context, child) => Transform.rotate(
        angle: _animationForBackgroundCompass!.value,
        child: SizedBox(
          height: widget.compassSize ?? 300,
          width: widget.compassSize ?? 300,
          child: widget.useDefaultAssets
              ? SvgPicture.asset(
                  _DefaultAssetPaths.defaultCompassSvgPath.path,
                )
              : widget.customBackgroundCompass!,
        ),
      ),
    );
  }

  /// Loading indicator
  /// If you want to use a custom loading indicator, you can pass it as a parameter.
  Widget _loadingIndicator() =>

      /// Special loading indicator
      SizedBox(
        height: (widget.compassSize ?? 300),
        width: (widget.compassSize ?? 300),
        child: widget.loadingIndicator ??

            /// Default loading indicator
            const Center(child: CircularProgressIndicator()),
      );

  /// Error Widget
  /// If there is an error this widget will be shown.
  /// If you want to use a custom error widget, you can pass it as a parameter.
  Widget _errorWidget() => SizedBox(
        height: (widget.compassSize ?? 300) / 2,
        width: (widget.compassSize ?? 300) / 2,
        child: widget.specialErrorWidget ??

            /// Default error widget
            Column(
              children: [
                SvgPicture.asset(_DefaultAssetPaths.defaultErrorSvgPath.path),
                Text(widget.defaultWidgetErrorText ?? 'Bir hata oluştu'),
              ],
            ),
      );

  /// Waiting for permission widget
  /// If the user does not grant location permission, this widget is displayed.
  Widget _waitingForPermissionWidget() => SizedBox(
        height: (widget.compassSize ?? 300) / 2,
        width: (widget.compassSize ?? 300) / 2,
        child: widget.waitingForPermissionWidget ??

            /// Default waiting for permission widget
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(_DefaultAssetPaths.defaultWaitingForLocationSvgPath.path),
                  FittedBox(
                    child: Text(
                      widget.defaultWidgetPermissionDeniedMessage ?? 'Konum izni bekleniyor...',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
      );

  /// Request location permission for qiblah
  Future<void> requestLocationPermissionForQiblah() async {
    await FlutterQiblah.requestPermissions();
  }

  /// Check location permission for qiblah
  Future<bool> checkLocationPermissionForQiblah() async {
    final permission = await Location.instance.hasPermission();
    switch (permission) {
      case PermissionStatus.denied:
        return false;
      case PermissionStatus.deniedForever:
        return false;
      case PermissionStatus.granted:
        return true;
      case PermissionStatus.grantedLimited:
        return true;
    }
  }
}

/// Extension for angle conversion
extension AngleConversion on double {
  double toRadians() => this * pi / 180;
  double toDegrees() => this * 180 / pi;
}

/// Packages default asset paths
enum _DefaultAssetPaths {
  /// Default compass svg asset paths
  defaultCompassSvgPath('packages/piri_qiblah/lib/assets/compass.svg'),

  /// Default error svg asset paths
  defaultErrorSvgPath('packages/piri_qiblah/lib/assets/error.svg'),

  /// Default waiting for location svg asset paths
  defaultWaitingForLocationSvgPath('packages/piri_qiblah/lib/assets/waiting_for_location.svg');

  /// Path parameter
  final String path;

  const _DefaultAssetPaths(this.path);
}
