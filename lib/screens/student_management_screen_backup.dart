import 'package:flutter/material.dart';
import 'package:markpro_plus/constants/education_constants.dart';
import 'package:markpro_plus/models/student_model.dart';
import 'package:markpro_plus/services/student_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final StudentService _studentService = StudentService();
  String? selectedBranch;
  String? selectedYear;
  String? selectedSection;
  bool isLoading = false;
  List<StudentModel> students = [];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Student Management',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF1E3A8A),
          bottom: TabBar(
            tabs: const [
              Tab(
                icon: Icon(Icons.people, color: Colors.white),
                text: 'Student List',
              ),
              Tab(
                icon: Icon(Icons.upload_file, color: Colors.white),
                text: 'Import Students',
              ),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            _buildStudentList(),
            _buildImportSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1E3A8A).withOpacity(0.05),
            Colors.white,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2, 
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter Students',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedBranch,
                            decoration: const InputDecoration(
                              labelText: 'Branch',
                              border: OutlineInputBorder(),
                            ),
                            items: EducationConstants.branches
                                .map((branch) => DropdownMenuItem(
                                      value: branch,
                                      child: Text(branch),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedBranch = value;
                              });
                              _loadStudents();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedYear,
                            decoration: const InputDecoration(
                              labelText: 'Year',
                              border: OutlineInputBorder(),
                            ),
                            items: EducationConstants.years
                                .map((year) => DropdownMenuItem(
                                      value: year,
                                      child: Text(year),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedYear = value;
                              });
                              _loadStudents();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedSection,
                            decoration: const InputDecoration(
                              labelText: 'Section',
                              border: OutlineInputBorder(),
                            ),
                            items: EducationConstants.sections
                                .map((section) => DropdownMenuItem(
                                      value: section,
                                      child: Text(section),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedSection = value;
                              });
                              _loadStudents();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: StreamBuilder<List<StudentModel>>(
                  stream: _studentService.getStudents(
                    selectedBranch ?? '',
                    selectedYear ?? '',
                    selectedSection ?? '',
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final students = snapshot.data ?? [];

                    if (students.isEmpty) {
                      return const Center(
                        child: Text('No students found'),
                      );
                    }

                    return ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          title: Text(
                            student.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          subtitle: Text(
                            'Roll No: ${student.rollNo}\nBranch: ${student.branch} | Year: ${student.year}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red.shade400,
                            ),
                            onPressed: () => _deleteStudent(student),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportSection() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1E3A8A).withOpacity(0.05),
            Colors.white,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Import Students from Excel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedBranch,
                            decoration: const InputDecoration(
                              labelText: 'Branch',
                            ),
                            items: EducationConstants.branches
                                .map((branch) => DropdownMenuItem<String>(
                                      value: branch,
                                      child: Text(branch),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => selectedBranch = value);
                            },
                          ),
                        ),
                      ],
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedYear,
                          decoration: const InputDecoration(
                            labelText: 'Year',
                          ),
                          items: EducationConstants.years
                              .map((year) => DropdownMenuItem<String>(
                                    value: year,
                                    child: Text(year),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() => selectedYear = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedSection,
                          decoration: const InputDecoration(
                            labelText: 'Section',
                          ),
                          items: EducationConstants.sections
                              .map((section) => DropdownMenuItem<String>(
                                    value: section,
                                    child: Text(section),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() => selectedSection = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _pickExcelFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Select Excel File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            Card(
              elevation: 2, 
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Excel File Format',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'The Excel file should have the following columns:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8.0),
                    const Text('â€¢ Name (Text)'),
                    const Text('â€¢ Roll No (Text)'),
                    const Text('â€¢ Branch (Text)'),
                    const Text('â€¢ Year (Text)'),
                    const Text('â€¢ Semester (Text)'),
                    const Text('â€¢ Section (Text)'),
                    const Text('â€¢ Academic Year (Text)'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadStudents() async {
    if (selectedBranch == null || selectedYear == null || selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select all filters'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final studentsStream = _studentService.getStudents(
        selectedBranch!,
        selectedYear!,
        selectedSection!,
      );
      final loadedStudents = await studentsStream.first;
      setState(() {
        students = loadedStudents;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteStudent(StudentModel student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete student ${student.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => isLoading = true);
      try {
        await _studentService.deleteStudent(
          student.studentId,
          selectedBranch!,
          selectedYear!,
          selectedSection!,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student deleted successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _loadStudents();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _pickExcelFile() async {
    if (selectedBranch == null || selectedYear == null || selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select branch, year, and section'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        setState(() => isLoading = true);

        final bytes = result.files.first.bytes!;
        final excel = Excel.decodeBytes(bytes);
        final sheet = excel.tables[excel.tables.keys.first]!;

        if (sheet.rows.isEmpty) {
          throw Exception('Excel file is empty');
        }

        // Skip header row
        final rows = sheet.rows.skip(1);
        final students = <StudentModel>[];

        for (var row in rows) {
          if (row.isEmpty || row[0]?.value == null) continue;

          final id = '${row[1]?.value.toString()}_${DateTime.now().millisecondsSinceEpoch}';
          students.add(StudentModel(
            id: id,
            name: row[0]?.value.toString() ?? '',
            rollNo: row[1]?.value.toString() ?? '',
            branch: row[2]?.value.toString() ?? '',
            year: int.tryParse(row[3]?.value.toString() ?? '') ?? 1,
            semester: int.tryParse(row[4]?.value.toString() ?? '') ?? 1,
            section: row[5]?.value.toString() ?? '',
            academicYear: row[6]?.value.toString() ?? '',
          ));
        }

        if (students.isEmpty) {
          throw Exception('No valid student records found');
        }

        await _studentService.addStudentsFromExcel(
          students,
          selectedBranch!,
          selectedYear!,
          selectedSection!,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Students imported successfully'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}
