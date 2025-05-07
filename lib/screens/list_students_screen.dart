import 'package:flutter/material.dart';
import 'package:markpro_plus/constants/education_constants.dart';
import 'package:markpro_plus/models/student_model.dart';
import 'package:markpro_plus/services/student_service.dart';

class ListStudentsScreen extends StatefulWidget {
  const ListStudentsScreen({super.key});

  @override
  State<ListStudentsScreen> createState() => _ListStudentsScreenState();
}

class _ListStudentsScreenState extends State<ListStudentsScreen> {
  final StudentService _studentService = StudentService();
  String? selectedBranch;
  String? selectedYear;
  String? selectedSection;
  bool isLoading = false;

  Future<List<StudentModel>> _loadStudents() async {
    if (selectedBranch == null || selectedYear == null || selectedSection == null) {
      return [];
    }
    
    try {
      return await _studentService.getStudents(
        selectedBranch!,
        selectedYear!,
        selectedSection!,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e')),
        );
      }
      return [];
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
            const SnackBar(content: Text('Student deleted successfully')),
          );
        }
        // Force refresh
        setState(() {}); 
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting student: $e')),
          );
        }
      }
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteAllStudents() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete All'),
        content: const Text(
            'Are you sure you want to delete all students in this section? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => isLoading = true);
      try {
        await _studentService.deleteAllStudents(
          selectedBranch!,
          selectedYear!,
          selectedSection!,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All students deleted successfully')),
          );
        }
        // Force refresh
        setState(() {});
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting students: $e')),
          );
        }
      }
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student List'),
        actions: [
          if (selectedBranch != null &&
              selectedYear != null &&
              selectedSection != null)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: isLoading ? null : _deleteAllStudents,
              tooltip: 'Delete All Students',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedBranch,
                    decoration: const InputDecoration(labelText: 'Branch'),
                    items: EducationConstants.branches
                        .map((branch) => DropdownMenuItem(
                              value: branch,
                              child: Text(branch),
                            ))
                        .toList(),
                    onChanged: (value) => 
                        setState(() => selectedBranch = value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
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
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedSection,
                    decoration: const InputDecoration(labelText: 'Section'),
                    items: EducationConstants.sections
                        .map((section) => DropdownMenuItem(
                              value: section,
                              child: Text(section),
                            ))
                        .toList(),
                    onChanged: (value) => 
                        setState(() => selectedSection = value),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: selectedBranch == null ||
                    selectedYear == null ||
                    selectedSection == null
                ? const Center(
                    child: Text('Select Branch, Year, and Section to view students'),
                  )
                : FutureBuilder<List<StudentModel>>(
                    future: _loadStudents(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
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
                            title: Text(student.name),
                            subtitle: Text(
                                'ID: ${student.studentId} | Semester: ${student.semester}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: isLoading
                                  ? null
                                  : () => _deleteStudent(student),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
