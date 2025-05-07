import 'package:flutter/material.dart';
import 'package:markpro_plus/models/student_model.dart';
import 'package:markpro_plus/services/import_service.dart';

class ImportStudentsDialog extends StatefulWidget {
  final String branch;
  final String year;
  final String section;

  const ImportStudentsDialog({
    Key? key,
    required this.branch,
    required this.year,
    required this.section,
  }) : super(key: key);

  @override
  State<ImportStudentsDialog> createState() => _ImportStudentsDialogState();
}

class _ImportStudentsDialogState extends State<ImportStudentsDialog> {
  final ImportService _importService = ImportService();
  bool _isImporting = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _importedStudents = [];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: const Offset(0.0, 10.0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Import Students',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            _buildInstructions(),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            const SizedBox(height: 20),
            if (_importedStudents.isNotEmpty) _buildStudentPreview(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _isImporting
                          ? null
                          : () async {
                              setState(() {
                                _isImporting = true;
                                _errorMessage = null;
                              });
                              
                              try {
                                final importedStudents =
                                    await _importService.importStudentsFromExcel(context);
                                
                                setState(() {
                                  _importedStudents = importedStudents;
                                  _isImporting = false;
                                });
                              } catch (e) {
                                setState(() {
                                  _errorMessage = e.toString();
                                  _isImporting = false;
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.upload_file, size: 16),
                          const SizedBox(width: 8),
                          _isImporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Select Excel File'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _importedStudents.isEmpty
                          ? null
                          : () {
                              // Get the current academic year
                              final currentYear = DateTime.now().year;
                              final nextYear = currentYear + 1;
                              final academicYear = '$currentYear-$nextYear';
                              
                              // Create student models with the required parameters
                              final List<StudentModel> studentModels = _importService.createStudentModels(_importedStudents);
                              Navigator.of(context).pop(studentModels);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Confirm Import'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instructions:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          _buildInstructionItem(
            '1. Prepare an Excel file with the following columns:',
            subItems: [
              'studentid (required)',
              'name (required)',
              'branch (required)',
              'year (required)',
              'section (required)',
            ],
          ),
          _buildInstructionItem(
            '2. Click "Select Excel File" to choose your file',
          ),
          _buildInstructionItem(
            '3. Review the imported data',
          ),
          _buildInstructionItem(
            '4. Click "Confirm Import" to add the students',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text, {List<String>? subItems}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text),
          if (subItems != null)
            ...subItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentPreview() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview (${_importedStudents.length} students):',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _importedStudents.length > 10
                    ? 10
                    : _importedStudents.length,
                itemBuilder: (context, index) {
                  final student = _importedStudents[index];
                  return ListTile(
                    title: Text(student['name']),
                    subtitle: Text(
                      'ID: ${student['rollNo']} | ${student['branch']} | Year ${student['year']} | Section ${student['section']}',
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        student['name'].substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_importedStudents.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Showing 10 of ${_importedStudents.length} students...',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
