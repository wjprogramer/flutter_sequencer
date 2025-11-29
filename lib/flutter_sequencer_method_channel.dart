import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_sequencer_platform_interface.dart';

/// An implementation of [FlutterSequencerPlatform] that uses method channels.
class MethodChannelFlutterSequencer extends FlutterSequencerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_sequencer');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
