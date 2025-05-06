class SubjectModel {
  final String id;
  final String name;
  final String code;
  final String professorId;
  final String branch;
  final int year;
  final String? section;
  final int semester;
  final String academicYear;

  SubjectModel({
    required this.id,
    required this.name,
    required this.code,
    required this.professorId,
    required this.branch,
    required this.year,
    this.section,
    required this.semester,
    required this.academicYear,
  });

  // Create from Firestore document
  factory SubjectModel.fromMap(Map<String, dynamic> data, String id) {
    return SubjectModel(
      id: id,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      professorId: data['professorId'] ?? '',
      branch: data['branch'] ?? '',
      year: data['year'] ?? 1,
      section: data['section'],
      semester: data['semester'] ?? 1,
      academicYear: data['academicYear'] ?? '',
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'professorId': professorId,
      'branch': branch,
      'year': year,
      'section': section,
      'semester': semester,
      'academicYear': academicYear,
    };
  }
}
