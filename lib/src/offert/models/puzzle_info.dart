class PuzzleInfo {
  final Map<String, dynamic> info;

  PuzzleInfo(this.info);

  String get type => info['type'];
  PuzzleInfo? get also => info['also'] ? PuzzleInfo(Map<String, dynamic>.from(info['also'])) : null;
}
