import 'package:cloud_firestore/cloud_firestore.dart';

class Certificate {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String courseName;
  final String certificateNumber;
  final DateTime issueDate;
  final String issuedBy; // Teacher/Admin email or name
  final double percentageScore;
  final String certificateUrl; // URL to PDF/image of certificate
  final String status; // 'issued', 'revoked'

  Certificate({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.courseName,
    required this.certificateNumber,
    required this.issueDate,
    required this.issuedBy,
    required this.percentageScore,
    required this.certificateUrl,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'courseName': courseName,
      'certificateNumber': certificateNumber,
      'issueDate': issueDate.millisecondsSinceEpoch,
      'issuedBy': issuedBy,
      'percentageScore': percentageScore,
      'certificateUrl': certificateUrl,
      'status': status,
    };
  }

  factory Certificate.fromMap(Map<String, dynamic> map) {
    return Certificate(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      courseName: map['courseName'] ?? '',
      certificateNumber: map['certificateNumber'] ?? '',
      issueDate: map['issueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['issueDate'])
          : DateTime.now(),
      issuedBy: map['issuedBy'] ?? '',
      percentageScore: (map['percentageScore'] ?? 0.0).toDouble(),
      certificateUrl: map['certificateUrl'] ?? '',
      status: map['status'] ?? 'issued',
    );
  }

  factory Certificate.fromDocSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Certificate.fromMap({
      'id': doc.id,
      ...data,
    });
  }
}

class CourseCompletion {
  final String userId;
  final String courseName;
  final bool isCompleted;
  final DateTime completedDate;
  final String completedBy; // Teacher/Admin who marked it complete
  final List<String> passedTestIds;
  final double testPassPercentage;
  final bool certificateIssued;
  final String? certificateId;

  CourseCompletion({
    required this.userId,
    required this.courseName,
    required this.isCompleted,
    required this.completedDate,
    required this.completedBy,
    required this.passedTestIds,
    required this.testPassPercentage,
    required this.certificateIssued,
    this.certificateId,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'courseName': courseName,
      'isCompleted': isCompleted,
      'completedDate': completedDate.millisecondsSinceEpoch,
      'completedBy': completedBy,
      'passedTestIds': passedTestIds,
      'testPassPercentage': testPassPercentage,
      'certificateIssued': certificateIssued,
      'certificateId': certificateId,
    };
  }

  factory CourseCompletion.fromMap(Map<String, dynamic> map) {
    return CourseCompletion(
      userId: map['userId'] ?? '',
      courseName: map['courseName'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      completedDate: map['completedDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedDate'])
          : DateTime.now(),
      completedBy: map['completedBy'] ?? '',
      passedTestIds: List<String>.from(map['passedTestIds'] ?? []),
      testPassPercentage: (map['testPassPercentage'] ?? 0.0).toDouble(),
      certificateIssued: map['certificateIssued'] ?? false,
      certificateId: map['certificateId'],
    );
  }
}
