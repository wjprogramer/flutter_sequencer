
import 'flutter_sequencer_platform_interface.dart';

class FlutterSequencer {
  Future<String?> getPlatformVersion() {
    return FlutterSequencerPlatform.instance.getPlatformVersion();
  }
}
