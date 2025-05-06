class StudentModel {
  final String id;
  final String name;
  final String rollNo;
  final String branch;
  final int year;
  final int semester;
  final String section;
  final String academicYear;

  String get studentId => rollNo; // Alias for rollNo to maintain compatibility

  StudentModel({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.branch,
    required this.year,
    required this.semester,
    required this.section,
    required this.academicYear,
  });

  // Create from Firestore document
  factory StudentModel.fromMap(Map<String, dynamic> data, String id) {
    return StudentModel(
      id: id,
      name: data['name'] ?? '',
      rollNo: data['rollNo'] ?? '',
      branch: data['branch'] ?? '',
      year: data['year'] ?? 1,
      semester: data['semester'] ?? 1,
      section: data['section'] ?? 'A',
      academicYear: data['academicYear'] ?? '',
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'rollNo': rollNo,
      'branch': branch,
      'year': year,
      'semester': semester,
      'section': section,
      'academicYear': academicYear,
    };
  }
}
