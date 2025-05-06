import 'package:cloud_firestore/cloud_firestore.dart';

class SeminarSession {
  final String id;
  final String subjectId;
  final String subjectName;
  final String branch;
  final String year;
  final String section;
  final List<String> students;
  Map<String, Map<String, dynamic>> presentationMarks; // studentId -> {content, delivery, qa, total}
  Map<String, Map<String, dynamic>> reportMarks; // studentId -> {content, format, references, total}
  Map<String, double> finalSeminarMarks; // studentId -> total (weighted average)
  final DateTime createdAt;
  final DateTime updatedAt;

  SeminarSession({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.branch,
    required this.year,
    required this.section,
    required this.students,
    Map<String, Map<String, dynamic>>? presentationMarks,
    Map<String, Map<String, dynamic>>? reportMarks,
    Map<String, double>? finalSeminarMarks,
    required this.createdAt,
    required this.updatedAt,
  }) : 
    this.presentationMarks = presentationMarks ?? {},
    this.reportMarks = reportMarks ?? {},
    this.finalSeminarMarks = finalSeminarMarks ?? {};

  factory SeminarSession.create({
    required String subjectId,
    required String subjectName,
    required String branch,
    required String year,
    required String section,
    required List<String> students,
  }) {
    return SeminarSession(
      id: '',
      subjectId: subjectId,
      subjectName: subjectName,
      branch: branch,
      year: year,
      section: section,
      students: students,
      presentationMarks: {},
      reportMarks: {},
      finalSeminarMarks: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory SeminarSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Convert the Firestore maps to the expected format
    Map<String, Map<String, dynamic>> presentationMarks = {};
    if (data['presentationMarks'] != null) {
      final marksData = data['presentationMarks'] as Map<String, dynamic>;
      marksData.forEach((studentId, marks) {
        presentationMarks[studentId] = Map<String, dynamic>.from(marks as Map);
      });
    }
    
    Map<String, Map<String, dynamic>> reportMarks = {};
    if (data['reportMarks'] != null) {
      final marksData = data['reportMarks'] as Map<String, dynamic>;
      marksData.forEach((studentId, marks) {
        reportMarks[studentId] = Map<String, dynamic>.from(marks as Map);
      });
    }
    
    Map<String, double> finalSeminarMarks = {};
    if (data['finalSeminarMarks'] != null) {
      final marksData = data['finalSeminarMarks'] as Map<String, dynamic>;
      marksData.forEach((studentId, marks) {
        finalSeminarMarks[studentId] = (marks as num).toDouble();
      });
    }
    
    return SeminarSession(
      id: doc.id,
      subjectId: data['subjectId'],
      subjectName: data['subjectName'],
      branch: data['branch'],
      year: data['year'],
      section: data['section'],
      students: List<String>.from(data['students']),
      presentationMarks: presentationMarks,
      reportMarks: reportMarks,
      finalSeminarMarks: finalSeminarMarks,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'subjectId': subjectId,
      'subjectName': subjectName,
      'branch': branch,
      'year': year,
      'section': section,
      'students': students,
      'presentationMarks': presentationMarks,
      'reportMarks': reportMarks,
      'finalSeminarMarks': finalSeminarMarks,
      'createdAt': createdAt,
      'updatedAt': DateTime.now(),
    };
  }

  Map<String, dynamic> getPresentationMarks(String studentId) {
    return presentationMarks[studentId] ?? {
      'content': 0.0,
      'delivery': 0.0,
      'qa': 0.0,
      'total': 0.0
    };
  }

  Map<String, dynamic> getReportMarks(String studentId) {
    return reportMarks[studentId] ?? {
      'content': 0.0,
      'format': 0.0,
      'references': 0.0,
      'total': 0.0
    };
  }

  double getFinalSeminarMark(String studentId) {
    return finalSeminarMarks[studentId] ?? 0.0;
  }
  
  // Calculate weighted average of presentation (60%) and report (40%)
  void calculateFinalMarks() {
    for (final studentId in students) {
      final presentation = getPresentationMarks(studentId);
      final report = getReportMarks(studentId);
      
      final presentationTotal = presentation['total'] as double? ?? 0.0;
      final reportTotal = report['total'] as double? ?? 0.0;
      
      final weightedAverage = (presentationTotal * 0.6) + (reportTotal * 0.4);
      finalSeminarMarks[studentId] = weightedAverage;
    }
  }

  SeminarSession copyWith({
    String? id,
    String? subjectId,
    String? subjectName,
    String? branch,
    String? year,
    String? section,
    List<String>? students,
    Map<String, Map<String, dynamic>>? presentationMarks,
    Map<String, Map<String, dynamic>>? reportMarks,
    Map<String, double>? finalSeminarMarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SeminarSession(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      branch: branch ?? this.branch,
      year: year ?? this.year,
      section: section ?? this.section,
      students: students ?? this.students,
      presentationMarks: presentationMarks ?? this.presentationMarks,
      reportMarks: reportMarks ?? this.reportMarks,
      finalSeminarMarks: finalSeminarMarks ?? this.finalSeminarMarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
