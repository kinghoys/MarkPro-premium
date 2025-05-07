import 'package:flutter/material.dart';
import 'package:markpro_plus/constants/education_constants.dart';
import 'package:markpro_plus/models/student_model.dart';
import 'package:markpro_plus/services/student_service.dart';
import 'package:markpro_plus/services/import_service.dart';
import 'package:markpro_plus/widgets/import_students_dialog.dart';
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
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _fetchData();
  }
  
  void _fetchData() async {
    if (selectedBranch != null && selectedYear != null && selectedSection != null) {
      setState(() {
        isLoading = true;
        _error = null;
      });
      
      try {
        final fetchedStudents = await _studentService.getStudents(
          selectedBranch!,
          selectedYear!,
          selectedSection!,
        );
        
        setState(() {
          students = fetchedStudents;
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          isLoading = false;
          _error = e.toString();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading students: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      setState(() {
        students = [];
        _error = null;
      });
    }
  }

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
                  : _error != null
                      ? Center(
                          child: Text(
                            'Error: $_error',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                        )
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
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            student.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  color: Color(0xFF1E3A8A)),
                                              onPressed: () => _editStudent(student),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () => _deleteStudent(student),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ID: ${student.id} | Roll No: ${student.rollNo}',
                                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      'Branch: ${student.branch} | Year: ${student.year} | Semester: ${student.semester} | Section: ${student.section}',
                                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                  ],
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
                          onPressed: selectedBranch != null &&
                                  selectedYear != null &&
                                  selectedSection != null
                              ? () => _showImportDialog()
                              : null,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Import Students from Excel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
                    const Text('• studentid (Text)'),
                    const Text('• name (Text)'),
                    const Text('• branch (Text)'),
                    const Text('• year (Text)'),
                    const Text('• semester (Text)'),
                    const Text('• section (Text)'),
                    const Text('• academic_year (Text)'),
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
      final loadedStudents = await _studentService.getStudents(
        selectedBranch!,
        selectedYear!,
        selectedSection!,
      );
      
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
        student.rollNo,
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
            // Get values from Excel - directly access the cells by index for more reliability
            Map<String, String> rowData = {};
            // Create a lowercase version of headers for case-insensitive lookup
            final lowercaseHeaders = headers.map((h) => h.toLowerCase()).toList();
            
            // Debug print the row and headers
            print('Excel row data at index $i:');
            print('Headers: $headers');
            print('Lowercase headers: $lowercaseHeaders');
            
            for (int colIndex = 0; colIndex < headers.length; colIndex++) {
              if (colIndex < row.length && row[colIndex]?.value != null) {
                String value = row[colIndex]!.value.toString().trim();
                String header = headers[colIndex].toLowerCase(); // Store with lowercase key
                rowData[header] = value;
                print('  $header: $value');
              }
            }
            
            // Now get values from the map with case-insensitive lookup
            // Try multiple variations of name column headers
            final name = rowData['name'] ?? rowData['student name'] ?? rowData['student_name'] ?? 
                         rowData['studentname'] ?? '';
            final id = rowData['studentid'] ?? rowData['student id'] ?? rowData['student_id'] ?? 
                       rowData['roll no'] ?? rowData['rollno'] ?? rowData['roll_no'] ?? '';
            final branch = rowData['branch'] ?? rowData['dept'] ?? rowData['department'] ?? '';
            final yearStr = rowData['year'] ?? '';
            final semesterStr = rowData['semester'] ?? rowData['sem'] ?? '';
            final section = rowData['section'] ?? rowData['sec'] ?? '';
            final academicYear = rowData['academic_year'] ?? rowData['academicyear'] ?? '';
            
            // Debug the Excel values
            print('Excel values for row $i:');
            print('  name: "$name"');
            print('  studentid: "$id"');
            print('  branch: "$branch"');
            print('  year: "$yearStr"');
            print('  semester: "$semesterStr"');
            print('  section: "$section"');
            print('  academic_year: "$academicYear"');
            
            // Create student with default values if any field is empty
            final student = StudentModel(
              name: name.isNotEmpty ? name : 'Student Name',
              id: id.isNotEmpty ? id : 'ID_${DateTime.now().millisecondsSinceEpoch}',
              rollNo: id.isNotEmpty ? id : 'ID_${DateTime.now().millisecondsSinceEpoch}',
              branch: branch.isNotEmpty ? branch : selectedBranch!,
              year: yearStr.isNotEmpty ? _parseIntSafely(yearStr) : _parseIntSafely(selectedYear!),
              semester: semesterStr.isNotEmpty ? _parseIntSafely(semesterStr) : 1,
              section: section.isNotEmpty ? section : selectedSection!,
              academicYear: academicYear.isNotEmpty ? academicYear : '${DateTime.now().year}-${DateTime.now().year + 1}',
            );
            
            print('Importing student with data: ${student.toMap()}');
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


  
  Future<void> _editStudent(StudentModel student) async {
    // Set default values for possibly empty fields
    final nameController = TextEditingController(text: student.name.isNotEmpty ? student.name : 'Student Name');
    final rollNoController = TextEditingController(text: student.rollNo);
    final branchController = TextEditingController(text: student.branch.isNotEmpty ? student.branch : 'CSE');
    
    // Make copies of the constant lists that we'll use in our dropdowns
    final yearList = List<String>.from(EducationConstants.years);
    final sectionList = List<String>.from(EducationConstants.sections);
    final semesterList = List.generate(8, (index) => (index + 1).toString());

    // Default values for dropdowns
    String selectedYear = yearList.isNotEmpty ? yearList.first : '1';
    String selectedSemester = semesterList.isNotEmpty ? semesterList.first : '1';
    String selectedSection = sectionList.isNotEmpty ? sectionList.first : 'A';
    
    // Try to set values from student if they're valid
    if (student.year > 0) {
      final yearStr = student.year.toString();
      // Check for exact match
      if (yearList.contains(yearStr)) {
        selectedYear = yearStr;
      } else {
        // Check for partial match
        for (var year in yearList) {
          if (year.startsWith(yearStr)) {
            selectedYear = year;
            break;
          }
        }
      }
    }
    
    if (student.semester > 0 && student.semester <= 8) {
      selectedSemester = student.semester.toString();
    }
    
    if (student.section.isNotEmpty && sectionList.contains(student.section)) {
      selectedSection = student.section;
    }
    
    final academicYearController = TextEditingController(
      text: student.academicYear.isNotEmpty ? student.academicYear : '${DateTime.now().year}-${DateTime.now().year + 1}'
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: rollNoController,
                decoration: const InputDecoration(labelText: 'Roll Number'),
                enabled: false, // Don't allow changing roll number as it's the ID
              ),
              const SizedBox(height: 8),
              TextField(
                controller: branchController,
                decoration: const InputDecoration(labelText: 'Branch'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedYear,
                decoration: const InputDecoration(labelText: 'Year'),
                items: yearList
                    .map((year) => DropdownMenuItem<String>(
                          value: year,
                          child: Text(year),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedYear = value;
                  }
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedSemester,
                decoration: const InputDecoration(labelText: 'Semester'),
                items: semesterList
                    .map((sem) => DropdownMenuItem<String>(
                          value: sem,
                          child: Text('Semester $sem'),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedSemester = value;
                  }
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedSection,
                decoration: const InputDecoration(labelText: 'Section'),
                items: sectionList
                    .map((section) => DropdownMenuItem<String>(
                          value: section,
                          child: Text(section),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedSection = value;
                  }
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: academicYearController,
                decoration: const InputDecoration(labelText: 'Academic Year'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Create updated student
              // Create updated student - ensure no empty values
              final updatedStudent = StudentModel(
                id: student.id.isNotEmpty ? student.id : rollNoController.text.trim(),
                name: nameController.text.trim().isNotEmpty ? nameController.text.trim() : 'Student Name',
                rollNo: rollNoController.text.trim(),
                branch: branchController.text.trim().isNotEmpty ? branchController.text.trim() : 'CSE',
                year: _parseIntSafely(selectedYear),
                semester: _parseIntSafely(selectedSemester),
                section: selectedSection.isNotEmpty ? selectedSection : 'A',
                academicYear: academicYearController.text.trim().isNotEmpty ? academicYearController.text.trim() : '${DateTime.now().year}-${DateTime.now().year + 1}',
              );
              
              // Print for debugging
              print('Updating student with data: ${updatedStudent.toMap()}');
              
              Navigator.pop(context);
              
              try {
                await _updateStudent(student, updatedStudent);
                setState(() => isLoading = true);
                try {
                  // We know these values are not null because we've checked earlier
                  final refreshedStudents = await _studentService.getStudents(
                    selectedBranch!,
                    selectedYear!,
                    selectedSection!,
                  );
                  setState(() {
                    students = refreshedStudents;
                    isLoading = false;
                  });
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Student updated successfully'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  setState(() => isLoading = false);
                  print('Error refreshing students: $e');
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error refreshing data: $e'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating student: $e'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _updateStudent(StudentModel oldStudent, StudentModel updatedStudent) async {
    if (selectedBranch == null || selectedYear == null || selectedSection == null) {
      throw Exception('Please select branch, year, and section');
    }
    
    try {
      // If any of these key properties changed, we need to delete and recreate
      if (oldStudent.branch != updatedStudent.branch ||
          oldStudent.year != updatedStudent.year ||
          oldStudent.section != updatedStudent.section) {
        
        // Delete from old location
        await _studentService.deleteStudent(
          oldStudent.rollNo,
          oldStudent.branch,
          oldStudent.year.toString(),
          oldStudent.section,
        );
        
        // Create in new location - use batch to avoid partial operations
        await _studentService.addStudentsFromExcel(
          [updatedStudent],
          updatedStudent.branch,
          updatedStudent.year.toString(),
          updatedStudent.section,
        );
      } else {
        // Just update the document in place
        await _studentService.updateStudent(
          updatedStudent,
          selectedBranch!,
          selectedYear!,
          selectedSection!,
        );
      }
      
      // No need to call _fetchData here as it's called after the update
    } catch (e) {
      print('Error updating student: $e');
      rethrow;
    }
  }
  
  int _parseIntSafely(String value) {
    if (value.isEmpty) return 1;
    // First, try to parse as-is
    int? result = int.tryParse(value);
    if (result != null) return result;
    
    // If that fails, try extracting only numeric characters
    final numericOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericOnly.isNotEmpty) {
      result = int.tryParse(numericOnly);
      if (result != null) return result;
    }
    
    // Default fallback
    return 1;
  }
  
  void _showImportDialog() async {
    if (selectedBranch == null || selectedYear == null || selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select branch, year, and section first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    final result = await showDialog<List<StudentModel>>(
      context: context,
      builder: (context) => ImportStudentsDialog(
        branch: selectedBranch!,
        year: selectedYear!,
        section: selectedSection!,
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      setState(() {
        isLoading = true;
      });
      
      try {
        // Add the imported students
        await _studentService.addStudentsFromExcel(
          result,
          selectedBranch!,
          selectedYear!,
          selectedSection!,
        );
        
        // Refresh the student list
        _fetchData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported ${result.length} students'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing students: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
