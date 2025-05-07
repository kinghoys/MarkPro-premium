import 'package:flutter/material.dart';
import 'package:markpro_plus/models/assignment_session.dart';
import 'package:markpro_plus/services/assignment_import_service.dart';

class ImportAllAssignmentsDialog extends StatefulWidget {
  final AssignmentSession assignmentSession;
  final Function onImportComplete;

  const ImportAllAssignmentsDialog({
    Key? key,
    required this.assignmentSession,
    required this.onImportComplete,
  }) : super(key: key);

  @override
  State<ImportAllAssignmentsDialog> createState() => _ImportAllAssignmentsDialogState();
}

class _ImportAllAssignmentsDialogState extends State<ImportAllAssignmentsDialog> {
  final AssignmentImportService _importService = AssignmentImportService();
  AllAssignmentMarksImportResult? _importResult;
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
              'Import All Assignment Marks',
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold,
                color: Color(0xFF6200EE),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Import all assignment marks from an Excel file. The file should have two sheets:\n\n'
              '• Sheet 1: Assignment 1 marks with "Student ID" and "Marks" columns\n'
              '• Sheet 2: Assignment 2 marks with "Student ID" and "Marks" columns\n\n'
              'Note: Only Student ID and Marks columns are required. Other columns will be ignored.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            if (_hasImported && _importResult != null)
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
    final assignment1Count = _importResult!.assignment1Marks.length;
    final assignment2Count = _importResult!.assignment2Marks.length;
    final totalCount = assignment1Count + assignment2Count;
    
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
                'Successfully imported $totalCount student marks',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Assignment 1: $assignment1Count records\n'
                'Assignment 2: $assignment2Count records',
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
              await _importService.saveAllImportedAssignmentMarks(
                assignmentSessionId: widget.assignmentSession.id,
                assignment1Marks: _importResult!.assignment1Marks,
                assignment2Marks: _importResult!.assignment2Marks,
              );
              widget.onImportComplete();
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All assignment marks imported successfully')),
                );
              }
            } catch (e) {
              setState(() {
                _errorMessage = 'Error saving marks: $e';
              });
            }
          },
          child: const Text(
            'Save All Marks',
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
              final result = await _importService.importAllAssignmentMarksFromExcel(context);
              setState(() {
                _importResult = result;
                _hasImported = result.hasAssignment1Data || result.hasAssignment2Data;
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
