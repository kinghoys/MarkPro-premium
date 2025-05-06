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
                          onPressed: _loadStudents,
                          icon: const Icon(Icons.search),
                          label: const Text('Search'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24.0, vertical: 12.0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : students.isEmpty
                      ? const Center(
                          child: Text(
                            'No students found. Try a different filter or import students.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final student = students[index];
                            return Card(
                              elevation: 1,
                              margin: const EdgeInsets.only(bottom: 8.0),
                              child: ListTile(
                                title: Text(
                                  student.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'ID: ${student.id} | Rollno: ${student.rollNo} | Semester: ${student.semester}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteStudent(student),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportSection() {
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
                    const Text('• Name (Text)'),
                    const Text('• ID (Text)'),
                    const Text('• Roll Number (Text)'),
                    const Text('• Branch (Text)'),
                    const Text('• Year (Text)'),
                    const Text('• Semester (Text)'),
                    const Text('• Section (Text)'),
                    const Text('• Academic Year (Text)'),
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
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _deleteStudent(StudentModel student) async {
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
      await _studentService.deleteStudent(
        student,
        selectedBranch!,
        selectedYear!,
        selectedSection!,
      );
      await _loadStudents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting student: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
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

        final students = <StudentModel>[];
        final headers = sheet.rows[0].map((cell) => cell?.value.toString().trim() ?? '').toList();

        for (var i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          if (row.any((cell) => cell?.value != null)) {
            final student = StudentModel(
              name: _getCellValue(row, headers, 'Name'),
              id: _getCellValue(row, headers, 'ID'),
              rollNo: _getCellValue(row, headers, 'Roll Number'),
              branch: selectedBranch!,
              year: selectedYear!,
              semester: _getCellValue(row, headers, 'Semester'),
              section: selectedSection!,
              academicYear: _getCellValue(row, headers, 'Academic Year'),
            );
            students.add(student);
          }
        }

        if (students.isEmpty) {
          throw Exception('No valid student records found in the Excel file');
        }

        await _studentService.addStudentsFromExcel(
          students,
          selectedBranch!,
          selectedYear!,
          selectedSection!,
        );

        await _loadStudents();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${students.length} students imported successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing students: $e'),
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

  String _getCellValue(List<dynamic> row, List<String> headers, String columnName) {
    final index = headers.indexOf(columnName);
    if (index >= 0 && index < row.length && row[index]?.value != null) {
      return row[index]!.value.toString().trim();
    }
    return '';
  }
}
