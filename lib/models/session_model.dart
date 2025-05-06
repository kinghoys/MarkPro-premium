import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String title;
  final String subjectId;
  final String professorId;
  final String sessionType; // 'lab', 'mid', 'assignment', 'objective', 'seminar'
  final DateTime createdAt;
  final DateTime date;
  final DateTime? dueDate;
  final int totalMarks;
  final Map<String, dynamic>? markingScheme;
  final List<StudentMark>? marks;
  final bool isActive;

  SessionModel({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.professorId,
    required this.sessionType,
    required this.createdAt,
    required this.date,
    this.dueDate,
    required this.totalMarks,
    this.markingScheme,
    this.marks,
    required this.isActive,
  });

  // Create from Firestore document
  factory SessionModel.fromMap(Map<String, dynamic> data, String id) {
    List<StudentMark>? marksList;
    
    if (data['marks'] != null) {
      marksList = (data['marks'] as List).map((markData) {
        return StudentMark.fromMap(markData);
      }).toList();
    }

    return SessionModel(
      id: id,
      title: data['title'] ?? '',
      subjectId: data['subjectId'] ?? '',
      professorId: data['professorId'] ?? '',
      sessionType: data['sessionType'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      date: (data['date'] as Timestamp).toDate(),
      dueDate: data['dueDate'] != null 
          ? (data['dueDate'] as Timestamp).toDate() 
          : null,
      totalMarks: data['totalMarks'] ?? 0,
      markingScheme: data['markingScheme'],
      marks: marksList,
      isActive: data['isActive'] ?? true,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    Map<String, dynamic> sessionMap = {
      'title': title,
      'subjectId': subjectId,
      'professorId': professorId,
      'sessionType': sessionType,
      'createdAt': createdAt,
      'date': date,
      'totalMarks': totalMarks,
      'isActive': isActive,
    };

    if (dueDate != null) {
      sessionMap['dueDate'] = dueDate;
    }

    if (markingScheme != null) {
      sessionMap['markingScheme'] = markingScheme;
    }

    if (marks != null) {
      sessionMap['marks'] = marks!.map((mark) => mark.toMap()).toList();
    }

    return sessionMap;
  }
}

class StudentMark {
  final String studentId;
  final String studentName;
  final String rollNo;
  final double obtainedMarks;
  final Map<String, dynamic>? breakup;
  final String? remarks;
  final DateTime submittedAt;

  StudentMark({
    required this.studentId,
    required this.studentName,
    required this.rollNo,
    required this.obtainedMarks,
    this.breakup,
    this.remarks,
    required this.submittedAt,
  });

  // Create from Map
  factory StudentMark.fromMap(Map<String, dynamic> data) {
    return StudentMark(
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      rollNo: data['rollNo'] ?? '',
      obtainedMarks: (data['obtainedMarks'] ?? 0).toDouble(),
      breakup: data['breakup'],
      remarks: data['remarks'],
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    Map<String, dynamic> markMap = {
      'studentId': studentId,
      'studentName': studentName,
      'rollNo': rollNo,
      'obtainedMarks': obtainedMarks,
      'submittedAt': submittedAt,
    };

    if (breakup != null) {
      markMap['breakup'] = breakup;
    }

    if (remarks != null) {
      markMap['remarks'] = remarks;
    }

    return markMap;
  }
}
