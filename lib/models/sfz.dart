/// Learn more about the SFZ format here: <https://sfzformat.com/headers/>
library;

String opcodeMapToString(Map<String, String>? opcodeMap) {
  if (opcodeMap == null) {
    return '';
  } else {
    return opcodeMap.entries
        .map((entry) => '${entry.key}=${entry.value}\n')
        .join('');
  }
}

class SfzRegion {
  SfzRegion({
    this.sample,
    this.key,
    this.loKey,
    this.hiKey,
    this.loVel,
    this.hiVel,
    this.loopStart,
    this.loopEnd,
    this.otherOpcodes,
  });

  String? sample;
  int? key;
  int? loKey, hiKey;
  int? loVel, hiVel;
  double? loopStart, loopEnd;
  Map<String, String>? otherOpcodes;

  String buildString() {
    // cSpell:disable
    return '<region>\n'
        '${sample != null ? 'sample=$sample\n' : ''}'
        '${key != null ? 'key=$key\n' : ''}'
        '${loKey != null ? 'lokey=$loKey\n' : ''}'
        '${hiKey != null ? 'hikey=$hiKey\n' : ''}'
        '${loVel != null ? 'lovel=$loVel\n' : ''}'
        '${hiVel != null ? 'hivel=$hiVel\n' : ''}'
        '${loopStart != null ? 'loop_start=$loopStart\n' : ''}'
        '${loopEnd != null ? 'loop_end=$loopEnd\n' : ''}'
        '${opcodeMapToString(otherOpcodes)}';
    // cSpell:enable
  }
}

class SfzGroup {
  SfzGroup({this.opcodes, required this.regions});

  Map<String, String>? opcodes;
  List<SfzRegion> regions;

  String buildString() {
    return '<group>\n'
        '${opcodeMapToString(opcodes)}'
        '${regions.map((r) => r.buildString()).join('')}';
  }
}

class SfzControl {
  SfzControl({this.opcodes});

  Map<String, String>? opcodes;

  String buildString() {
    return '<control>\n'
        '${opcodeMapToString(opcodes)}'
        '';
  }
}

class SfzGlobal {
  SfzGlobal({this.opcodes});

  Map<String, String>? opcodes;

  String buildString() {
    return '<global>\n'
        '${opcodeMapToString(opcodes)}';
  }
}

class SfzEffect {
  SfzEffect({this.opcodes});

  Map<String, String>? opcodes;

  String buildString() {
    return '<effect>\n'
        '${opcodeMapToString(opcodes)}';
  }
}

class SfzCurve {
  SfzCurve({this.opcodes});

  Map<String, String>? opcodes;

  String buildString() {
    return '<curve>\n'
        '${opcodeMapToString(opcodes)}';
  }
}

/// Used to build an SFZ. Note that if loKey or hiKey are not set on a given
/// region, they will be set automatically.
class Sfz {
  final List<SfzGroup> groups;
  final List<SfzControl> controls;
  final List<SfzEffect> effects;
  final List<SfzCurve> curves;
  final SfzGlobal? global;

  Sfz({
    required this.groups,
    this.controls = const [],
    this.effects = const [],
    this.curves = const [],
    this.global,
  });

  void _setNoteRanges() {
    final allRegions = <SfzRegion>[];

    for (var g in groups) {
      allRegions.addAll(g.regions);
    }

    allRegions.sort((a, b) => (a.key! - b.key!).toInt());
    allRegions.asMap().forEach((index, sd) {
      final prevSd = index > 0 ? allRegions[index - 1] : null;
      final nextSd = index < allRegions.length - 1
          ? allRegions[index + 1]
          : null;

      if (sd.loKey == null) {
        if (prevSd == null) {
          sd.loKey = 0;
        } else {
          sd.loKey = ((sd.key! + prevSd.key!) / 2).floor() + 1;
        }
      }

      if (sd.hiKey == null) {
        if (nextSd == null) {
          sd.hiKey = 127;
        } else {
          sd.hiKey = ((nextSd.key! + sd.key!) / 2).floor();
        }
      }
    });
  }

  String buildString() {
    _setNoteRanges();

    return (global?.buildString() ?? '') +
        controls.map((c) => c.buildString()).join('') +
        effects.map((e) => e.buildString()).join('') +
        curves.map((c) => c.buildString()).join('') +
        groups.map((g) => g.buildString()).join('');
  }
}
