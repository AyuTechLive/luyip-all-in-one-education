class TestQuestion {
  final String id;
  final String questionText;
  final String type; // 'mcq' or 'subjective'
  final List<String>? options; // Only for MCQ
  final String? correctAnswer; // For MCQ or pre-defined subjective answers
  final int marks;
  final String? explanation; // Optional explanation for correct answer

  TestQuestion({
    required this.id,
    required this.questionText,
    required this.type,
    this.options,
    this.correctAnswer,
    required this.marks,
    this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionText': questionText,
      'type': type,
      'options': options,
      'correctAnswer': correctAnswer,
      'marks': marks,
      'explanation': explanation,
    };
  }

  factory TestQuestion.fromMap(Map<String, dynamic> map) {
    // Handle nullable fields with defaults
    return TestQuestion(
      id: map['id'] ?? '',
      questionText: map['questionText'] ?? 'Question text unavailable',
      type: map['type'] ?? 'mcq', // Default to mcq if not specified
      options: _getOptionsList(map['options']),
      correctAnswer: map['correctAnswer'],
      marks: map['marks'] is int
          ? map['marks']
          : (int.tryParse(map['marks']?.toString() ?? '0') ?? 0),
      explanation: map['explanation'],
    );
  }

  // Helper function to safely convert options to List<String>
  static List<String>? _getOptionsList(dynamic options) {
    if (options == null) {
      return null;
    }

    if (options is List) {
      return options.map((e) => e?.toString() ?? '').toList();
    }

    return null;
  }
}

class Test {
  final String id;
  final String title;
  final String description;
  final int totalMarks;
  final int durationMinutes;
  final bool isActive;
  final String courseName;
  final String subjectName;
  final DateTime createdAt;
  final List<TestQuestion> questions;

  Test({
    required this.id,
    required this.title,
    required this.description,
    required this.totalMarks,
    required this.durationMinutes,
    required this.isActive,
    required this.courseName,
    required this.subjectName,
    required this.createdAt,
    required this.questions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'totalMarks': totalMarks,
      'durationMinutes': durationMinutes,
      'isActive': isActive,
      'courseName': courseName,
      'subjectName': subjectName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      // Questions are stored separately with test ID as parent
    };
  }

  factory Test.fromMap(Map<String, dynamic> map, List<TestQuestion> questions) {
    return Test(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Untitled Test',
      description: map['description'] ?? '',
      totalMarks: map['totalMarks'] is int
          ? map['totalMarks']
          : (int.tryParse(map['totalMarks']?.toString() ?? '0') ?? 0),
      durationMinutes: map['durationMinutes'] is int
          ? map['durationMinutes']
          : (int.tryParse(map['durationMinutes']?.toString() ?? '60') ?? 60),
      isActive: map['isActive'] ?? false,
      courseName: map['courseName'] ?? '',
      subjectName: map['subjectName'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map['createdAt'] is int ? map['createdAt'] : 0)
          : DateTime.now(),
      questions: questions,
    );
  }
}

class UserTestResponse {
  final String questionId;
  final String userAnswer;
  final int? autoMarks; // For MCQ auto evaluation
  final int? manualMarks; // For teacher evaluation
  final String? feedback; // Teacher feedback

  UserTestResponse({
    required this.questionId,
    required this.userAnswer,
    this.autoMarks,
    this.manualMarks,
    this.feedback,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'userAnswer': userAnswer,
      'autoMarks': autoMarks,
      'manualMarks': manualMarks,
      'feedback': feedback,
    };
  }

  factory UserTestResponse.fromMap(Map<String, dynamic> map) {
    return UserTestResponse(
      questionId: map['questionId'] ?? '',
      userAnswer: map['userAnswer'] ?? '',
      autoMarks: map['autoMarks'],
      manualMarks: map['manualMarks'],
      feedback: map['feedback'],
    );
  }
}

class TestSubmission {
  final String id;
  final String testId;
  final String userId;
  final String userEmail;
  final String userName;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final int totalAutoMarks;
  final int? totalManualMarks;
  final bool isEvaluated;
  final Map<String, UserTestResponse> responses;

  TestSubmission({
    required this.id,
    required this.testId,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.startedAt,
    this.submittedAt,
    required this.totalAutoMarks,
    this.totalManualMarks,
    required this.isEvaluated,
    required this.responses,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'testId': testId,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'startedAt': startedAt.millisecondsSinceEpoch,
      'submittedAt': submittedAt?.millisecondsSinceEpoch,
      'totalAutoMarks': totalAutoMarks,
      'totalManualMarks': totalManualMarks,
      'isEvaluated': isEvaluated,
      'responses': responses.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  factory TestSubmission.fromMap(Map<String, dynamic> map) {
    final responsesMap = map['responses'] is Map
        ? (map['responses'] as Map<dynamic, dynamic>).cast<String, dynamic>()
        : <String, dynamic>{};

    final parsedResponses = <String, UserTestResponse>{};

    responsesMap.forEach((key, value) {
      if (value is Map) {
        parsedResponses[key] =
            UserTestResponse.fromMap(Map<String, dynamic>.from(value));
      }
    });

    return TestSubmission(
      id: map['id'] ?? '',
      testId: map['testId'] ?? '',
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userName: map['userName'] ?? '',
      startedAt: map['startedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map['startedAt'] is int ? map['startedAt'] : 0)
          : DateTime.now(),
      submittedAt: map['submittedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map['submittedAt'] is int ? map['submittedAt'] : 0)
          : null,
      totalAutoMarks: map['totalAutoMarks'] is int ? map['totalAutoMarks'] : 0,
      totalManualMarks:
          map['totalManualMarks'] is int ? map['totalManualMarks'] : null,
      isEvaluated: map['isEvaluated'] ?? false,
      responses: parsedResponses,
    );
  }
}
