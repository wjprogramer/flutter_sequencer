import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_sequencer_method_channel.dart';

abstract class FlutterSequencerPlatform extends PlatformInterface {
  /// Constructs a FlutterSequencerPlatform.
  FlutterSequencerPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterSequencerPlatform _instance = MethodChannelFlutterSequencer();

  /// The default instance of [FlutterSequencerPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterSequencer].
  static FlutterSequencerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterSequencerPlatform] when
  /// they register themselves.
  static set instance(FlutterSequencerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
