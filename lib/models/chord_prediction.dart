class ChordPrediction {
  final String status;
  final String? chord;
  final double confidence;
  final String? message;

  const ChordPrediction({
    required this.status,
    this.chord,
    this.confidence = 0.0,
    this.message,
  });

  factory ChordPrediction.fromJson(Map<String, dynamic> json) {
    return ChordPrediction(
      status: json['status'] as String? ?? 'error',
      chord: json['chord'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] as String?,
    );
  }

  factory ChordPrediction.error(String message) {
    return ChordPrediction(status: 'error', message: message);
  }
}
