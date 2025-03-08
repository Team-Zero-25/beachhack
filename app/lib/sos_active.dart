import 'dart:async';

class SosActive {
  static final SosActive _instance = SosActive._internal();
  factory SosActive() => _instance;

  SosActive._internal();

  final _sosStreamController = StreamController<bool>.broadcast();
  bool _isSosActive = false; // Keep track of current SOS state

  Stream<bool> get sosStream => _sosStreamController.stream;

  bool get isSosActive => _isSosActive; // Getter to check current state

  void updateSos(bool status) {
    _isSosActive = status;
    _sosStreamController.add(status); // Always notify listeners
  }


  void dispose() {
    _sosStreamController.close();
  }
}
