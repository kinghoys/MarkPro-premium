import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:markpro_plus/constants/education_constants.dart';
import 'package:markpro_plus/models/student_model.dart';
import 'package:markpro_plus/services/student_service.dart';

class LoadStudentsScreen extends StatefulWidget {
  const LoadStudentsScreen({super.key});

  @override
  State<LoadStudentsScreen> createState() => _LoadStudentsScreenState();
}

class _LoadStudentsScreenState extends State<LoadStudentsScreen> {
  final StudentService _studentService = StudentService();
  String? selectedBranch;
  String? selectedYear;
  String? selectedSection;
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  Future<void> _pickAndProcessExcel() async {
    if (selectedBranch == null || selectedYear == null || selectedSection == null) {
      setState(() {
        errorMessage = 'Please select Branch, Year, and Section first';
      });
      return;
    }

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
        successMessage = null;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'No file selected';
        });
        return;
      }

      final bytes = result.files.first.bytes;
      if (bytes == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Could not read file';
        });
        return;
      }

      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables[excel.tables.keys.first];
      
      if (sheet == null) {
        setState(() {
          errorMessage = 'Excel file has no sheets';
          isLoading = false;
        });
        return;
      }

      final students = <StudentModel>[];
      bool isFirstRow = true;

      for (var row in sheet.rows) {
        if (isFirstRow) {
          isFirstRow = false;
          continue;
        }

        if (row.length < 7) continue;

        try {
          final student = StudentModel(
            id: '', // Will be set by Firestore
            rollNo: row[0]?.value.toString() ?? '',
            name: row[1]?.value.toString() ?? '',
            branch: row[2]?.value.toString() ?? '',
            year: int.tryParse(row[3]?.value.toString() ?? '') ?? 1,
            semester: int.tryParse(row[4]?.value.toString() ?? '') ?? 1,
            section: row[5]?.value.toString() ?? 'A',
            academicYear: row[6]?.value.toString() ?? '',
          );

          // Validate that data matches selected filters
          if (student.branch != selectedBranch ||
              student.year != selectedYear ||
              student.section != selectedSection) {
            throw Exception(
                'Row data does not match selected Branch/Year/Section');
          }

          students.add(student);
        } catch (e) {
          setState(() {
            errorMessage = 'Error processing row: ${e.toString()}';
            isLoading = false;
          });
          return;
        }
      }

      if (students.isEmpty) {
        setState(() {
          errorMessage = 'No valid student data found in Excel';
          isLoading = false;
        });
        return;
      }

      await _studentService.addStudentsFromExcel(
        students,
        selectedBranch!,
        selectedYear!,
        selectedSection!,
      );

      setState(() {
        successMessage = '${students.length} students imported successfully';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Load Students'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Excel File Format:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Required columns (in order):\nstudentId, name, branch, year, semester, section, academicYear',
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: selectedBranch,
              decoration: const InputDecoration(labelText: 'Branch'),
              items: EducationConstants.branches
                  .map((branch) => DropdownMenuItem(
                        value: branch,
                        child: Text(branch),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => selectedBranch = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedYear,
              decoration: const InputDecoration(labelText: 'Year'),
              items: EducationConstants.years
                  .map((year) => DropdownMenuItem(
                        value: year,
                        child: Text(year),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => selectedYear = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedSection,
              decoration: const InputDecoration(labelText: 'Section'),
              items: EducationConstants.sections
                  .map((section) => DropdownMenuItem(
                        value: section,
                        child: Text(section),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => selectedSection = value),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : _pickAndProcessExcel,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Upload Excel File'),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            if (successMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                successMessage!,
                style: const TextStyle(color: Colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
