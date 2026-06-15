import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../domain/connectivity_state.dart';

class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  ConnectivityState _lastState = ConnectivityState.online;

  ConnectivityState get lastState => _lastState;

  Stream<ConnectivityState> get onStateChange {
    return _connectivity.onConnectivityChanged.map((result) {
      _lastState = result.contains(ConnectivityResult.none)
          ? ConnectivityState.offline
          : ConnectivityState.online;
      return _lastState;
    }).asBroadcastStream();
  }

  Future<ConnectivityState> checkNow() async {
    final result = await _connectivity.checkConnectivity();
    _lastState = result.contains(ConnectivityResult.none)
        ? ConnectivityState.offline
        : ConnectivityState.online;
    return _lastState;
  }

  Future<bool> get isOnline async {
    final state = await checkNow();
    return state == ConnectivityState.online;
  }
}
