import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class InternetService {
  InternetService._();

  static final Connectivity _connectivity =
      Connectivity();

  static StreamSubscription<List<ConnectivityResult>>?
      _subscription;

  static final StreamController<bool>
      _internetStatusController =
      StreamController<bool>.broadcast();

  static bool _isConnected = true;

  static bool get isConnected => _isConnected;

  static Stream<bool> get internetStatusStream =>
      _internetStatusController.stream;

  static Future<bool> checkConnection() async {
    final List<ConnectivityResult> results =
        await _connectivity.checkConnectivity();

    _updateConnectionStatus(results);

    return _isConnected;
  }

  static Future<void> startMonitoring() async {
    await checkConnection();

    await _subscription?.cancel();

    _subscription =
        _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _updateConnectionStatus(results);
      },
    );
  }

  static void _updateConnectionStatus(
    List<ConnectivityResult> results,
  ) {
    final bool connected =
        results.isNotEmpty &&
        !results.contains(
          ConnectivityResult.none,
        );

    if (_isConnected == connected) {
      return;
    }

    _isConnected = connected;

    _internetStatusController.add(
      _isConnected,
    );
  }

  static Future<void> stopMonitoring() async {
    await _subscription?.cancel();

    _subscription = null;
  }

  static Future<void> dispose() async {
    await stopMonitoring();

    await _internetStatusController.close();
  }
}