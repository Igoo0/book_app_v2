import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/foundation.dart';

class SensorService {
  static final SensorService instance = SensorService._internal();
  factory SensorService() => instance;
  SensorService._internal();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<UserAccelerometerEvent>? _userAccelerometerSubscription;

  // Shake detection variables - Made more sensitive
  static const double _shakeThreshold = 8.0; // Reduced from 12.0 to 8.0
  static const int _shakeDuration = 800; // Reduced from 1000ms to 800ms
  DateTime? _lastShakeTime;
  
  // Callbacks
  Function()? _onShakeDetected;
  Function(AccelerometerEvent)? _onAccelerometerEvent;
  Function(GyroscopeEvent)? _onGyroscopeEvent;

  // Current sensor values
  AccelerometerEvent? _currentAccelerometer;
  GyroscopeEvent? _currentGyroscope;
  UserAccelerometerEvent? _currentUserAccelerometer;

  // Shake detection state
  bool _isShakeDetectionActive = false;

  // Getters for current values
  AccelerometerEvent? get currentAccelerometer => _currentAccelerometer;
  GyroscopeEvent? get currentGyroscope => _currentGyroscope;
  UserAccelerometerEvent? get currentUserAccelerometer => _currentUserAccelerometer;

  // Check if sensors are available
  Future<bool> areSensorsAvailable() async {
    try {
      debugPrint('Checking sensor availability...');
      
      // Try to listen to accelerometer for a brief moment
      final completer = Completer<bool>();
      late StreamSubscription subscription;
      
      subscription = accelerometerEvents.listen(
        (event) {
          debugPrint('Accelerometer test event received: x=${event.x}, y=${event.y}, z=${event.z}');
          subscription.cancel();
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
        onError: (error) {
          debugPrint('Accelerometer test error: $error');
          subscription.cancel();
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );

      // Timeout after 3 seconds
      Timer(const Duration(seconds: 3), () {
        if (!completer.isCompleted) {
          debugPrint('Sensor availability check timed out');
          subscription.cancel();
          completer.complete(false);
        }
      });

      final result = await completer.future;
      debugPrint('Sensor availability result: $result');
      return result;
    } catch (e) {
      debugPrint('Error checking sensor availability: $e');
      return false;
    }
  }

  // Start listening to accelerometer
  void startAccelerometerListening() {
    try {
      debugPrint('Starting accelerometer listening...');
      
      _accelerometerSubscription?.cancel();
      _isShakeDetectionActive = true;
      
      _accelerometerSubscription = accelerometerEvents.listen(
        (AccelerometerEvent event) {
          _currentAccelerometer = event;
          _onAccelerometerEvent?.call(event);
          
          if (_isShakeDetectionActive) {
            _checkForShake(event);
          }
        },
        onError: (error) {
          debugPrint('Accelerometer error: $error');
        },
      );
      
      debugPrint('Accelerometer listening started successfully');
    } catch (e) {
      debugPrint('Error starting accelerometer listening: $e');
    }
  }

  // Start listening to gyroscope
  void startGyroscopeListening() {
    try {
      _gyroscopeSubscription?.cancel();
      _gyroscopeSubscription = gyroscopeEvents.listen(
        (GyroscopeEvent event) {
          _currentGyroscope = event;
          _onGyroscopeEvent?.call(event);
        },
        onError: (error) {
          debugPrint('Gyroscope error: $error');
        },
      );
    } catch (e) {
      debugPrint('Error starting gyroscope listening: $e');
    }
  }

  // Start listening to user accelerometer (without gravity)
  void startUserAccelerometerListening() {
    try {
      _userAccelerometerSubscription?.cancel();
      _userAccelerometerSubscription = userAccelerometerEvents.listen(
        (UserAccelerometerEvent event) {
          _currentUserAccelerometer = event;
        },
        onError: (error) {
          debugPrint('User accelerometer error: $error');
        },
      );
    } catch (e) {
      debugPrint('Error starting user accelerometer listening: $e');
    }
  }

  // Start all sensors
  void startAllSensors() {
    debugPrint('Starting all sensors...');
    startAccelerometerListening();
    startGyroscopeListening();
    startUserAccelerometerListening();
  }

  // Stop all sensors
  void stopAllSensors() {
    debugPrint('Stopping all sensors...');
    
    _isShakeDetectionActive = false;
    
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _userAccelerometerSubscription?.cancel();
    
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _userAccelerometerSubscription = null;
  }

  // Set shake detection callback
  void setShakeCallback(Function() callback) {
    _onShakeDetected = callback;
    debugPrint('Shake callback set');
  }

  // Set accelerometer callback
  void setAccelerometerCallback(Function(AccelerometerEvent) callback) {
    _onAccelerometerEvent = callback;
  }

  // Set gyroscope callback
  void setGyroscopeCallback(Function(GyroscopeEvent) callback) {
    _onGyroscopeEvent = callback;
  }

  // Check for shake gesture - Improved algorithm
  void _checkForShake(AccelerometerEvent event) {
    try {
      final now = DateTime.now();
      
      // Check if enough time has passed since last shake
      if (_lastShakeTime != null) {
        final timeDifference = now.difference(_lastShakeTime!).inMilliseconds;
        if (timeDifference < _shakeDuration) {
          return; // Too soon for another shake
        }
      }

      // Calculate the magnitude of acceleration
      final magnitude = sqrt(
        event.x * event.x + 
        event.y * event.y + 
        event.z * event.z
      );

      // Log for debugging (remove in production)
      if (kDebugMode && magnitude > 5.0) {
        debugPrint('Acceleration magnitude: ${magnitude.toStringAsFixed(2)} (threshold: $_shakeThreshold)');
      }

      // Check if magnitude exceeds threshold
      if (magnitude > _shakeThreshold) {
        _lastShakeTime = now;
        debugPrint('🎉 SHAKE DETECTED! Magnitude: ${magnitude.toStringAsFixed(2)}');
        
        // Call the callback
        _onShakeDetected?.call();
      }
    } catch (e) {
      debugPrint('Error in shake detection: $e');
    }
  }

  // Manual shake trigger for testing
  void triggerManualShake() {
    debugPrint('Manual shake triggered');
    _onShakeDetected?.call();
  }

  // Get device orientation based on accelerometer
  DeviceOrientation getDeviceOrientation() {
    if (_currentAccelerometer == null) return DeviceOrientation.unknown;

    final x = _currentAccelerometer!.x;
    final y = _currentAccelerometer!.y;

    if (y.abs() > x.abs()) {
      return y > 0 ? DeviceOrientation.portraitDown : DeviceOrientation.portraitUp;
    } else {
      return x > 0 ? DeviceOrientation.landscapeRight : DeviceOrientation.landscapeLeft;
    }
  }

  // Check if device is flat (face up or face down)
  bool isDeviceFlat() {
    if (_currentAccelerometer == null) return false;
    
    final z = _currentAccelerometer!.z.abs();
    return z > 8.0; // Device is relatively flat
  }

  // Check if device is being moved
  bool isDeviceMoving({double threshold = 1.0}) {
    if (_currentUserAccelerometer == null) return false;

    final magnitude = sqrt(
      _currentUserAccelerometer!.x * _currentUserAccelerometer!.x +
      _currentUserAccelerometer!.y * _currentUserAccelerometer!.y +
      _currentUserAccelerometer!.z * _currentUserAccelerometer!.z
    );

    return magnitude > threshold;
  }

  // Get tilt angle in degrees
  double getTiltAngle() {
    if (_currentAccelerometer == null) return 0.0;

    final x = _currentAccelerometer!.x;
    final y = _currentAccelerometer!.y;
    final z = _currentAccelerometer!.z;

    // Calculate tilt angle from vertical
    final angle = atan2(sqrt(x * x + y * y), z) * 180 / pi;
    return angle;
  }

  // Get rotation rate (from gyroscope)
  double getRotationRate() {
    if (_currentGyroscope == null) return 0.0;

    final magnitude = sqrt(
      _currentGyroscope!.x * _currentGyroscope!.x +
      _currentGyroscope!.y * _currentGyroscope!.y +
      _currentGyroscope!.z * _currentGyroscope!.z
    );

    return magnitude;
  }

  // Get sensor data summary
  Map<String, dynamic> getSensorData() {
    return {
      'accelerometer': _currentAccelerometer != null ? {
        'x': _currentAccelerometer!.x,
        'y': _currentAccelerometer!.y,
        'z': _currentAccelerometer!.z,
      } : null,
      'gyroscope': _currentGyroscope != null ? {
        'x': _currentGyroscope!.x,
        'y': _currentGyroscope!.y,
        'z': _currentGyroscope!.z,
      } : null,
      'userAccelerometer': _currentUserAccelerometer != null ? {
        'x': _currentUserAccelerometer!.x,
        'y': _currentUserAccelerometer!.y,
        'z': _currentUserAccelerometer!.z,
      } : null,
      'orientation': getDeviceOrientation().name,
      'isFlat': isDeviceFlat(),
      'isMoving': isDeviceMoving(),
      'tiltAngle': getTiltAngle(),
      'rotationRate': getRotationRate(),
      'shakeThreshold': _shakeThreshold,
      'isShakeDetectionActive': _isShakeDetectionActive,
    };
  }

  // Get current acceleration magnitude for debugging
  double getCurrentAccelerationMagnitude() {
    if (_currentAccelerometer == null) return 0.0;
    
    return sqrt(
      _currentAccelerometer!.x * _currentAccelerometer!.x + 
      _currentAccelerometer!.y * _currentAccelerometer!.y + 
      _currentAccelerometer!.z * _currentAccelerometer!.z
    );
  }

  // Adjust shake sensitivity
  void setShakeThreshold(double threshold) {
    debugPrint('Shake threshold changed to: $threshold');
    // Note: _shakeThreshold is const, so this would need to be implemented differently
    // For now, this is just for future extensibility
  }

  // Dispose of all resources
  void dispose() {
    stopAllSensors();
    _onShakeDetected = null;
    _onAccelerometerEvent = null;
    _onGyroscopeEvent = null;
  }
}

enum DeviceOrientation {
  portraitUp,
  portraitDown,
  landscapeLeft,
  landscapeRight,
  unknown,
}