class PuzzleInfo {
  final Map<String, dynamic> info;

  PuzzleInfo(this.info);

  String get type => info['type'];
  PuzzleInfo? get also =>
      info['also'] != null ? PuzzleInfo(Map<String, dynamic>.from(info['also'])) : null;

  @override
  bool operator ==(Object other) => other is PuzzleInfo && other.type == type && other.also == also;

  @override
  String toString() {
    return "PuzzleInfo($info)";
  }
}
