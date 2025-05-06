import 'package:flutter/material.dart';
import 'package:markpro_plus/models/seminar_session.dart';
import 'package:markpro_plus/services/seminar_service.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

class ImportSeminarMarksDialog extends StatefulWidget {
  final SeminarSession seminarSession;
  final Function onImportComplete;

  const ImportSeminarMarksDialog({
    Key? key,
    required this.seminarSession,
    required this.onImportComplete,
  }) : super(key: key);

  @override
  State<ImportSeminarMarksDialog> createState() => _ImportSeminarMarksDialogState();
}

class _ImportSeminarMarksDialogState extends State<ImportSeminarMarksDialog> {
  bool _isLoading = false;
  bool _isPreviewReady = false;
  String? _error;
  List<Map<String, dynamic>> _previewData = [];
  final SeminarService _seminarService = SeminarService();

  Future<void> _pickExcelFile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _isPreviewReady = false;
        _previewData = [];
      });
      
      // Pick Excel file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );
      
      if (result == null || result.files.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Get file bytes
      final fileBytes = result.files.first.bytes;
      if (fileBytes == null) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to read file';
        });
        return;
      }
      
      // Parse Excel file
      final excel = Excel.decodeBytes(fileBytes);
      if (excel.tables.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'No sheets found in the Excel file';
        });
        return;
      }
      
      final sheet = excel.tables.keys.first;
      
      // Process data
      final table = excel.tables[sheet];
      if (table == null) {
        setState(() {
          _isLoading = false;
          _error = 'Error reading Excel sheet';
        });
        return;
      }
      
      final rows = table.rows;
      if (rows.isEmpty || rows.length < 2) {
        setState(() {
          _isLoading = false;
          _error = 'No data found in the Excel file';
        });
        return;
      }
      
      // Extract column indices for student ID and marks
      int? idColumnIndex;
      int? marksColumnIndex;
      
      final headerRow = rows[0];
      for (int i = 0; i < headerRow.length; i++) {
        final cellValue = headerRow[i]?.value.toString().toLowerCase();
        if (cellValue == null) continue;
        
        if (cellValue.contains('id') || cellValue.contains('roll')) {
          idColumnIndex = i;
        } else if (cellValue.contains('mark') || cellValue.contains('score')) {
          marksColumnIndex = i;
        }
      }
      
      if (idColumnIndex == null || marksColumnIndex == null) {
        setState(() {
          _isLoading = false;
          _error = 'Could not find Student ID or Marks columns';
        });
        return;
      }
      
      // Create preview data
      final previewData = <Map<String, dynamic>>[];
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.length <= idColumnIndex || row.length <= marksColumnIndex) {
          continue;
        }
        
        String studentId = '';
        if (row[idColumnIndex]?.value != null) {
          studentId = row[idColumnIndex]!.value.toString();
        }
        final marksValue = row[marksColumnIndex]?.value;
        
        if (studentId.isEmpty) continue;
        
        double marks = 0.0;
        if (marksValue != null) {
          // Convert CellValue to appropriate type
          final valueStr = marksValue.toString();
          
          try {
            // Try to parse as double
            marks = double.tryParse(valueStr) ?? 0.0;
          } catch (_) {
            marks = 0.0;
          }
        }
        
        // Validate marks range (0-5)
        if (marks < 0) marks = 0;
        if (marks > 5) marks = 5;
        
        previewData.add({
          'studentId': studentId,
          'marks': marks,
        });
      }
      
      setState(() {
        _isLoading = false;
        _isPreviewReady = true;
        _previewData = previewData;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error parsing Excel file: $e';
      });
    }
  }
  
  Future<void> _importMarks() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // Import marks for each student
      for (final item in _previewData) {
        final studentId = item['studentId'] as String;
        final marks = item['marks'] as double;
        
        await _seminarService.updatePresentationMarks(
          sessionId: widget.seminarSession.id,
          studentId: studentId,
          seminarMark: marks,
        );
      }
      
      // Call the onImportComplete callback
      widget.onImportComplete();
      
      if (mounted) {
        Navigator.of(context).pop(); // Close the dialog
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported marks for ${_previewData.length} students'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error importing marks: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Import Seminar Marks',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text(
              'Upload an Excel file containing student IDs and seminar marks (0-5). '
              'The file should have headers and at least columns for Student ID and Marks.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickExcelFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Select Excel File'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade800),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (_isLoading) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Processing...'),
            ],
            if (_isPreviewReady && _previewData.isNotEmpty) ...[
              const SizedBox(height: 24),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Preview (${_previewData.length} students)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _previewData.length,
                        itemBuilder: (context, index) {
                          final item = _previewData[index];
                          return ListTile(
                            dense: true,
                            title: Text('ID: ${item['studentId']}'),
                            trailing: Text(
                              'Mark: ${item['marks']}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _importMarks,
                          icon: const Icon(Icons.save),
                          label: const Text('Import Marks'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (!_isPreviewReady && !_isLoading) ...[
              const SizedBox(height: 16),
              const Expanded(
                child: Center(
                  child: Text(
                    'Select an Excel file to import marks',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
