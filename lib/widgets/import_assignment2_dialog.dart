import 'package:flutter/material.dart';
import 'package:markpro_plus/models/assignment_session.dart';
import 'package:markpro_plus/services/assignment_import_service.dart';

class ImportAssignment2Dialog extends StatefulWidget {
  final AssignmentSession assignmentSession;
  final Function onImportComplete;

  const ImportAssignment2Dialog({
    Key? key,
    required this.assignmentSession,
    required this.onImportComplete,
  }) : super(key: key);

  @override
  State<ImportAssignment2Dialog> createState() => _ImportAssignment2DialogState();
}

class _ImportAssignment2DialogState extends State<ImportAssignment2Dialog> {
  final AssignmentImportService _importService = AssignmentImportService();
  List<Map<String, dynamic>> _importedMarks = [];
  bool _hasImported = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Import Assignment 2 Marks',
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold,
                color: Color(0xFF6200EE),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Import Assignment 2 marks from an Excel file. The file should have the following columns:\n'
              '• Student ID\n'
              '• Marks\n\n'
              'Note: Only Student ID and Marks columns are required. Other columns will be ignored.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            if (_hasImported && _importedMarks.isNotEmpty)
              _buildImportSummary()
            else if (_errorMessage.isNotEmpty)
              _buildErrorMessage()
            else
              _buildImportButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildImportSummary() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 48),
              const SizedBox(height: 10),
              Text(
                'Successfully imported ${_importedMarks.length} student marks',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: () async {
            try {
              await _importService.saveImportedAssignment2Marks(
                assignmentSessionId: widget.assignmentSession.id,
                marks: _importedMarks,
              );
              widget.onImportComplete();
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Assignment 2 marks imported successfully')),
                );
              }
            } catch (e) {
              setState(() {
                _errorMessage = 'Error saving marks: $e';
              });
            }
          },
          child: const Text(
            'Save Marks',
            style: TextStyle(fontSize: 16),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade600, size: 48),
              const SizedBox(height: 10),
              Text(
                'Error: $_errorMessage',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: () {
            setState(() {
              _errorMessage = '';
            });
          },
          child: const Text('Try Again'),
        ),
      ],
    );
  }

  Widget _buildImportButtons() {
    return Column(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6200EE),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: () async {
            try {
              final marks = await _importService.importAssignment2MarksFromExcel(context);
              setState(() {
                _importedMarks = marks;
                _hasImported = marks.isNotEmpty;
                _errorMessage = '';
              });
            } catch (e) {
              setState(() {
                _errorMessage = e.toString();
              });
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.file_upload),
              SizedBox(width: 10),
              Text('Select Excel File', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
