/// 목표 데이터 모델
class Goal {
  final String id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? deadline; // 목표 마감일
  final String displayPeriod; // "Always", "Once a Day" 등
  final String? motivationalMessage; // 동기부여 메시지
  final String goalType; // 목표 유형 (예: "자격증/학습", "운동", "습관" 등)
  final int importance; // 중요도 (1: 보통, 2: 중요, 3: 매우 중요)
  final bool showOnLockScreen; // 잠금화면 표시 여부
  final List<RoadmapStep>? roadmapSteps; // 로드맵 단계
  final int? currentStep; // 현재 진행 중인 로드맵 단계
  bool isCompleted;

  Goal({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    this.completedAt,
    this.deadline,
    required this.displayPeriod,
    this.motivationalMessage,
    this.goalType = "일반",
    this.importance = 1,
    this.showOnLockScreen = false,
    this.roadmapSteps,
    this.currentStep,
    this.isCompleted = false,
  });

  /// JSON에서 Goal 객체 생성
  factory Goal.fromJson(Map<String, dynamic> json) {
    List<RoadmapStep>? steps;
    if (json['roadmapSteps'] != null) {
      steps =
          (json['roadmapSteps'] as List)
              .map((stepJson) => RoadmapStep.fromJson(stepJson))
              .toList();
    }

    return Goal(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt:
          json['completedAt'] != null
              ? DateTime.parse(json['completedAt'] as String)
              : null,
      deadline:
          json['deadline'] != null
              ? DateTime.parse(json['deadline'] as String)
              : null,
      displayPeriod: json['displayPeriod'] as String,
      motivationalMessage: json['motivationalMessage'] as String?,
      goalType: json['goalType'] as String? ?? "일반",
      importance: json['importance'] as int? ?? 1,
      showOnLockScreen: json['showOnLockScreen'] as bool? ?? false,
      roadmapSteps: steps,
      currentStep: json['currentStep'] as int?,
      isCompleted: json['isCompleted'] as bool,
    );
  }

  /// Goal 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    final roadmapJson = roadmapSteps?.map((step) => step.toJson()).toList();

    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'displayPeriod': displayPeriod,
      'motivationalMessage': motivationalMessage,
      'goalType': goalType,
      'importance': importance,
      'showOnLockScreen': showOnLockScreen,
      'roadmapSteps': roadmapJson,
      'currentStep': currentStep,
      'isCompleted': isCompleted,
    };
  }

  /// 목표 완료 처리
  Goal markAsCompleted() {
    return copyWith(completedAt: DateTime.now(), isCompleted: true);
  }

  /// 목표 복사본 생성 (속성 변경 가능)
  Goal copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? deadline,
    String? displayPeriod,
    String? motivationalMessage,
    String? goalType,
    int? importance,
    bool? showOnLockScreen,
    List<RoadmapStep>? roadmapSteps,
    int? currentStep,
    bool? isCompleted,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      deadline: deadline ?? this.deadline,
      displayPeriod: displayPeriod ?? this.displayPeriod,
      motivationalMessage: motivationalMessage ?? this.motivationalMessage,
      goalType: goalType ?? this.goalType,
      importance: importance ?? this.importance,
      showOnLockScreen: showOnLockScreen ?? this.showOnLockScreen,
      roadmapSteps: roadmapSteps ?? this.roadmapSteps,
      currentStep: currentStep ?? this.currentStep,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// 로드맵 단계 진행률 계산
  double get roadmapProgress {
    if (roadmapSteps == null || roadmapSteps!.isEmpty) return 0.0;

    int completed = roadmapSteps!.where((step) => step.isCompleted).length;
    return completed / roadmapSteps!.length;
  }

  /// 로드맵이 있는지 확인
  bool get hasRoadmap => roadmapSteps != null && roadmapSteps!.isNotEmpty;

  /// 목표까지 남은 일수 계산
  int? get daysRemaining {
    if (deadline == null) return null;

    final now = DateTime.now();
    return deadline!.difference(now).inDays;
  }
}

/// 로드맵 단계 모델
class RoadmapStep {
  final int order; // 단계 순서
  final String title; // 단계 제목
  final String? description; // 단계 설명
  final DateTime? completedAt; // 완료 일자
  final bool isCompleted; // 완료 여부

  RoadmapStep({
    required this.order,
    required this.title,
    this.description,
    this.completedAt,
    this.isCompleted = false,
  });

  factory RoadmapStep.fromJson(Map<String, dynamic> json) {
    return RoadmapStep(
      order: json['order'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      completedAt:
          json['completedAt'] != null
              ? DateTime.parse(json['completedAt'] as String)
              : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'title': title,
      'description': description,
      'completedAt': completedAt?.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  RoadmapStep copyWith({
    int? order,
    String? title,
    String? description,
    DateTime? completedAt,
    bool? isCompleted,
  }) {
    return RoadmapStep(
      order: order ?? this.order,
      title: title ?? this.title,
      description: description ?? this.description,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  RoadmapStep markAsCompleted() {
    return copyWith(completedAt: DateTime.now(), isCompleted: true);
  }
}
