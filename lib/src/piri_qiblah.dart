import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';

/// PiriQiblah is a widget that shows the direction of the Qiblah.
@immutable
final class PiriQiblah extends StatefulWidget {
  const PiriQiblah({super.key});

  @override
  State<PiriQiblah> createState() => _PiriQiblahState();
}

class _PiriQiblahState extends State<PiriQiblah> with TickerProviderStateMixin {
  /// --------------------------------------------------------------------------
  /// Animation properties for needles
  late Animation<double>? _animationForNeedle;
  late AnimationController? _animationControllerForNeedle;

  /// --------------------------------------------------------------------------
  /// Animation properties for background compass view
  late Animation<double>? _animationForBackgroundCompass;
  late AnimationController? _animationControllerForBackgroundCompass;

  /// --------------------------------------------------------------------------
  /// Initial tween begin values
  double beginForNeedle = 0;
  double beginForCompass = 0;

  @override
  void initState() {
    super.initState();

    /// --------------------------------------------------------------------------
    /// Animation controller for needles
    _animationControllerForNeedle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    /// --------------------------------------------------------------------------
    /// Tween for needle view
    _animationForNeedle = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(_animationControllerForNeedle!);

    /// --------------------------------------------------------------------------
    /// Animation controller for background  compass view
    _animationControllerForBackgroundCompass = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 500),
    );

    /// --------------------------------------------------------------------------
    /// Tween for background compass view
    _animationForBackgroundCompass = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(_animationControllerForBackgroundCompass!);
  }

  @override
  void dispose() {
    _animationControllerForNeedle!.dispose();
    _animationControllerForBackgroundCompass!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FlutterQiblah.qiblahStream,
      builder: (context, snapshot) {
        /// Animation properties for needle view
        _animationForNeedle = Tween(
          begin: beginForNeedle,
          end: (snapshot.data!.qiblah).toRadians() * -1,
        ).animate(_animationControllerForNeedle!);
        beginForNeedle = snapshot.data!.qiblah * (pi / 180) * -1;
        _animationControllerForNeedle!.forward(from: 0);

        /// Animation properties for background compass view
        _animationForBackgroundCompass = Tween(
          begin: (snapshot.data!.direction).toRadians() * -1,
          end: 360.0,
        ).animate(_animationControllerForBackgroundCompass!);
        beginForCompass = snapshot.data!.direction * (pi / 180) * -1;
        _animationControllerForBackgroundCompass!.forward(from: 0);

        /// Return the compass view
        return Stack(
          children: [
            _backgroundCompassView(),
            _needleView(),
          ],
        );
      },
    );
  }

  Widget _needleView() {
    return AnimatedBuilder(
      animation: _animationForNeedle!,
      builder: (context, child) => Transform.rotate(
        angle: _animationForNeedle!.value,
        child: const Center(
          child: Icon(
            Icons.navigation,
            size: 100,
            color: Colors.green,
          ),
        ),
      ),
    );
  }

  Widget _backgroundCompassView() {
    return AnimatedBuilder(
      animation: _animationForBackgroundCompass!,
      builder: (context, child) => Transform.rotate(
        angle: _animationForBackgroundCompass!.value,
        child: const Center(
          child: SizedBox(
            height: 300,
            width: 300,
            child: Icon(Icons.compass_calibration),
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
