import 'package:hive/hive.dart';
import '../../domain/services/fsrs_algorithm.dart';

part 'fsrs_parameters_model.g.dart';

/// Hive model for FSRS parameters
/// 
/// Stores user-specific or optimized FSRS parameters
@HiveType(typeId: 43)
class FSRSParametersModel extends HiveObject {
  /// User ID
  @HiveField(0)
  final String userId;

  /// Weight parameters (w[0] to w[18])
  @HiveField(1)
  final List<double> weights;

  /// Target retention rate (0.0 to 1.0)
  @HiveField(2)
  final double requestRetention;

  /// Maximum interval in days
  @HiveField(3)
  final int maximumInterval;

  /// Minutes to wait after "Again" rating
  @HiveField(4)
  final int againMinutes;

  /// Minutes to wait after "Hard" rating
  @HiveField(5)
  final int hardMinutes;

  /// Minutes to wait after "Good" rating
  @HiveField(6)
  final int goodMinutes;

  /// When these parameters were created/updated
  @HiveField(7)
  final DateTime updatedAt;

  /// Whether these are optimized parameters (vs default)
  @HiveField(8)
  final bool isOptimized;

  FSRSParametersModel({
    required this.userId,
    required this.weights,
    required this.requestRetention,
    required this.maximumInterval,
    required this.againMinutes,
    required this.hardMinutes,
    required this.goodMinutes,
    required this.updatedAt,
    this.isOptimized = false,
  });

  /// Create from FSRSParameters
  factory FSRSParametersModel.fromFSRSParameters({
    required String userId,
    required FSRSParameters params,
    bool isOptimized = false,
  }) {
    return FSRSParametersModel(
      userId: userId,
      weights: List<double>.from(params.w),
      requestRetention: params.requestRetention,
      maximumInterval: params.maximumInterval,
      againMinutes: params.againMinutes,
      hardMinutes: params.hardMinutes,
      goodMinutes: params.goodMinutes,
      updatedAt: DateTime.now(),
      isOptimized: isOptimized,
    );
  }

  /// Convert to FSRSParameters
  FSRSParameters toFSRSParameters() {
    return FSRSParameters(
      w: List<double>.from(weights),
      requestRetention: requestRetention,
      maximumInterval: maximumInterval,
      againMinutes: againMinutes,
      hardMinutes: hardMinutes,
      goodMinutes: goodMinutes,
    );
  }

  /// Create default parameters
  factory FSRSParametersModel.defaults(String userId) {
    final defaultParams = FSRSParameters.defaults();
    return FSRSParametersModel.fromFSRSParameters(
      userId: userId,
      params: defaultParams,
      isOptimized: false,
    );
  }

  FSRSParametersModel copyWith({
    String? userId,
    List<double>? weights,
    double? requestRetention,
    int? maximumInterval,
    int? againMinutes,
    int? hardMinutes,
    int? goodMinutes,
    DateTime? updatedAt,
    bool? isOptimized,
  }) {
    return FSRSParametersModel(
      userId: userId ?? this.userId,
      weights: weights ?? this.weights,
      requestRetention: requestRetention ?? this.requestRetention,
      maximumInterval: maximumInterval ?? this.maximumInterval,
      againMinutes: againMinutes ?? this.againMinutes,
      hardMinutes: hardMinutes ?? this.hardMinutes,
      goodMinutes: goodMinutes ?? this.goodMinutes,
      updatedAt: updatedAt ?? this.updatedAt,
      isOptimized: isOptimized ?? this.isOptimized,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'weights': weights,
      'requestRetention': requestRetention,
      'maximumInterval': maximumInterval,
      'againMinutes': againMinutes,
      'hardMinutes': hardMinutes,
      'goodMinutes': goodMinutes,
      'updatedAt': updatedAt.toIso8601String(),
      'isOptimized': isOptimized,
    };
  }

  factory FSRSParametersModel.fromJson(Map<String, dynamic> json) {
    return FSRSParametersModel(
      userId: json['userId'] as String,
      weights: (json['weights'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
      requestRetention: (json['requestRetention'] as num).toDouble(),
      maximumInterval: json['maximumInterval'] as int,
      againMinutes: json['againMinutes'] as int,
      hardMinutes: json['hardMinutes'] as int,
      goodMinutes: json['goodMinutes'] as int,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isOptimized: json['isOptimized'] as bool? ?? false,
    );
  }
}
