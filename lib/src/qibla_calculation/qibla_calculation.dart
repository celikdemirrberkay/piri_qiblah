import 'dart:async';
import 'package:flutter_compass_v2/flutter_compass_v2.dart';
import 'package:location/location.dart';
import 'package:piri_qiblah/src/qibla_calculation/utils.dart';
import 'package:piri_qiblah/src/qibla_calculation/qiblah_direction.dart';
import 'package:stream_transform/stream_transform.dart' show CombineLatest;

/// [FlutterQiblah] is a singleton class that provides assess to compass events,
/// Get current  location
/// Get Qiblah direction
class FlutterQiblah {
  static final FlutterQiblah _instance = FlutterQiblah._();

  Stream<QiblahDirection>? _qiblahStream;

  FlutterQiblah._();

  factory FlutterQiblah() => _instance;

  /// Request Location permission, return PermissionStatus object
  static Future<PermissionStatus> requestPermissions() => Location().requestPermission();

  /// Get location status: GPS enabled and the permission status with LocationStatus
  static Future<LocationStatus> checkLocationStatus() async {
    final status = await Location().hasPermission();
    return LocationStatus(status);
  }

  /// Provides a stream of Map with current compass and Qiblah direction
  /// {"qiblah": QIBLAH, "direction": DIRECTION}
  /// Direction varies from 0-360, 0 being north.
  /// Qiblah varies from 0-360, offset from direction(North)
  static Stream<QiblahDirection> get qiblahStream {
    _instance._qiblahStream ??= _merge<CompassEvent, LocationData>(
      FlutterCompass.events!,
      Location.instance.onLocationChanged.transform(
        StreamTransformer<LocationData, LocationData>.fromHandlers(
          handleData: (LocationData position, EventSink<LocationData> sink) {
            sink.add(position);
            sink.close();
          },
        ),
      ),
    );

    return _instance._qiblahStream!;
  }

  /// Merge the compass stream with location updates, and calculate the Qiblah direction
  /// return a Stream<Map<String, dynamic>> containing compass and Qiblah direction
  /// Direction varies from 0-360, 0 being north.
  /// Qiblah varies from 0-360, offset from direction(North)
  static Stream<QiblahDirection> _merge<A, B>(
    Stream<A> streamA,
    Stream<B> streamB,
  ) =>
      streamA.combineLatest<B, QiblahDirection>(
        streamB,
        (dir, pos) {
          final position = pos as LocationData;
          final event = dir as CompassEvent;

          // Calculate the Qiblah offset to North
          final offSet = Utils.getOffsetFromNorth(
            position.latitude ?? 0.0,
            position.longitude ?? 0.0,
          );

          // Adjust Qiblah direction based on North direction
          final qiblah = (event.heading ?? 0.0) + (360 - offSet);

          return QiblahDirection(qiblah, event.heading ?? 0.0, offSet);
        },
      );

  /// Close compass stream, and set Qiblah stream to null
  void dispose() {
    _qiblahStream = null;
  }
}

/// Location Status class, contains the GPS status(Enabled or not) and GeolocationStatus
class LocationStatus {
  final PermissionStatus status;

  const LocationStatus(
    this.status,
  );
}
