import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:markpro_plus/models/subject_model.dart';
import 'package:markpro_plus/services/subject_service.dart';

class SubjectManagementScreen extends StatefulWidget {
  const SubjectManagementScreen({Key? key}) : super(key: key);

  @override
  _SubjectManagementScreenState createState() => _SubjectManagementScreenState();
}

class _SubjectManagementScreenState extends State<SubjectManagementScreen> {
  final SubjectService _subjectService = SubjectService();
  bool isLoading = false;
  List<SubjectModel> subjects = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    setState(() {
      isLoading = true;
      _error = null;
    });

    try {
      final fetchedSubjects = await _subjectService.getSubjects();
      setState(() {
        subjects = fetchedSubjects;
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
            content: Text('Error loading subjects: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subjects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import Subjects from Excel',
            onPressed: _pickExcelFile,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Text(
                      'Error: $_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                  )
                : subjects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'No subjects found. Add a subject to get started.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _showAddSubjectDialog,
                              child: const Text('Add Subject'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: subjects.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final subject = subjects[index];
                          return _buildSubjectListItem(subject);
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubjectDialog,
        tooltip: 'Add Subject',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSubjectListItem(SubjectModel subject) {
    return ListTile(
      title: Text(
        subject.name,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.purple.shade100,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.book, color: Colors.purple),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _showEditSubjectDialog(subject),
            color: Colors.blue,
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            onPressed: () => _confirmDeleteSubject(subject),
            color: Colors.red,
          ),
        ],
      ),
      onTap: () => _navigateToSubjectDetails(subject),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
    );
  }

  void _navigateToSubjectDetails(SubjectModel subject) {
    // Navigation to subject details can be implemented later
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected ${subject.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showAddSubjectDialog() async {
    final nameController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Subject'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Subject Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      setState(() => isLoading = true);
      
      try {
        await _subjectService.addSubject(result);
        await _fetchSubjects();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subject added successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        setState(() => isLoading = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding subject: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _showEditSubjectDialog(SubjectModel subject) async {
    final nameController = TextEditingController(text: subject.name);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Subject'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Subject Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty && result != subject.name) {
      setState(() => isLoading = true);
      
      try {
        await _subjectService.updateSubject(subject.id, result);
        await _fetchSubjects();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subject updated successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        setState(() => isLoading = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating subject: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteSubject(SubjectModel subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete "${subject.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() => isLoading = true);
      
      try {
        await _subjectService.deleteSubject(subject.id);
        await _fetchSubjects();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subject deleted successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        setState(() => isLoading = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting subject: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _pickExcelFile() async {
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

        // Process Excel data
        final subjectNames = _processExcelData(sheet);
        
        if (subjectNames.isEmpty) {
          throw Exception('No valid subject names found in the Excel file');
        }

        // Add subjects to Firestore
        final addedSubjects = await _subjectService.addSubjectsFromExcel(subjectNames);
        
        // Refresh the subject list
        await _fetchSubjects();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${addedSubjects.length} subjects imported successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing subjects: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() => isLoading = false);
    }
  }

  List<String> _processExcelData(Sheet sheet) {
    final subjectNames = <String>[];
    final headers = sheet.rows[0].map((cell) => cell?.value.toString().trim().toLowerCase() ?? '').toList();
    
    // Debug output
    print('Excel headers: $headers');
    
    // Find the column index for subject name
    int? nameIndex;
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i];
      if (header == 'subject name' || header == 'subject_name' || 
          header == 'name' || header == 'subjectname' || 
          header == 'subject') {
        nameIndex = i;
        break;
      }
    }
    
    if (nameIndex == null) {
      throw Exception('Could not find a column for Subject Name in the Excel file');
    }
    
    // Process rows
    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.length > nameIndex && row[nameIndex]?.value != null) {
        final name = row[nameIndex]!.value.toString().trim();
        
        if (name.isNotEmpty) {
          subjectNames.add(name);
          print('Found subject: $name');
        }
      }
    }
    
    return subjectNames;
  }
}
