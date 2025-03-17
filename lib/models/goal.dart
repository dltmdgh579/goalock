/// 목표 데이터 모델
class Goal {
  final String id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String displayPeriod; // "Always", "Once a Day" 등
  bool isCompleted;

  Goal({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    this.completedAt,
    required this.displayPeriod,
    this.isCompleted = false,
  });

  /// JSON에서 Goal 객체 생성
  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt:
          json['completedAt'] != null
              ? DateTime.parse(json['completedAt'] as String)
              : null,
      displayPeriod: json['displayPeriod'] as String,
      isCompleted: json['isCompleted'] as bool,
    );
  }

  /// Goal 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'displayPeriod': displayPeriod,
      'isCompleted': isCompleted,
    };
  }

  /// 목표 완료 처리
  Goal markAsCompleted() {
    return Goal(
      id: id,
      title: title,
      description: description,
      createdAt: createdAt,
      completedAt: DateTime.now(),
      displayPeriod: displayPeriod,
      isCompleted: true,
    );
  }

  /// 목표 복사본 생성 (속성 변경 가능)
  Goal copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? completedAt,
    String? displayPeriod,
    bool? isCompleted,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      displayPeriod: displayPeriod ?? this.displayPeriod,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
