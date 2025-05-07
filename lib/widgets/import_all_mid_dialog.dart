import 'package:flutter/material.dart';
import 'package:markpro_plus/models/mid_session.dart';
import 'package:markpro_plus/services/mid_import_service.dart';

class ImportAllMidDialog extends StatefulWidget {
  final MidSession midSession;
  final VoidCallback onImportComplete;

  const ImportAllMidDialog({
    Key? key,
    required this.midSession,
    required this.onImportComplete,
  }) : super(key: key);

  @override
  State<ImportAllMidDialog> createState() => _ImportAllMidDialogState();
}

class _ImportAllMidDialogState extends State<ImportAllMidDialog> {
  final MidImportService _importService = MidImportService();
  AllMidMarksImportResult? _importedData;
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
              'Import All Mid Marks',
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold,
                color: Color(0xFF6200EE),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Import both Mid 1 and Mid 2 marks from an Excel file with multiple sheets. '
              'The file should have two sheets:\n\n'
              '• A sheet for Mid 1 Marks with columns: Student ID, Name, Descriptive, Objective\n'
              '• A sheet for Mid 2 Marks with the same columns\n\n'
              'Note: Sheet names should contain "Mid 1" and "Mid 2" for automatic detection. '
              'Otherwise, the first sheet will be treated as Mid 1 and the second as Mid 2.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            if (_hasImported && _importedData != null)
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
    int mid1Count = _importedData?.mid1Marks.length ?? 0;
    int mid2Count = _importedData?.mid2Marks.length ?? 0;
    bool hasMid1 = _importedData?.hasMid1Data ?? false;
    bool hasMid2 = _importedData?.hasMid2Data ?? false;
    
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
                'Successfully imported:',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (hasMid1)
                Text(
                  'Mid 1: $mid1Count student marks',
                  style: const TextStyle(fontSize: 16),
                ),
              if (hasMid2)
                Text(
                  'Mid 2: $mid2Count student marks',
                  style: const TextStyle(fontSize: 16),
                ),
              if (!hasMid1 && !hasMid2)
                const Text(
                  'No valid marks found in Excel file',
                  style: TextStyle(fontSize: 16, color: Colors.red),
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
          onPressed: (hasMid1 || hasMid2) 
            ? () async {
                try {
                  await _importService.saveAllImportedMidMarks(
                    midSessionId: widget.midSession.id,
                    mid1Marks: _importedData?.mid1Marks ?? [],
                    mid2Marks: _importedData?.mid2Marks ?? [],
                  );
                  widget.onImportComplete();
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mid marks imported successfully')),
                    );
                  }
                } catch (e) {
                  setState(() {
                    _errorMessage = 'Error saving marks: $e';
                  });
                }
              }
            : null,
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
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: () async {
            try {
              final result = await _importService.importAllMidMarksFromExcel(context);
              setState(() {
                _importedData = result;
                _hasImported = true;
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
