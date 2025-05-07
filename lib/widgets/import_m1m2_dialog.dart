import 'package:flutter/material.dart';
import 'package:markpro_plus/models/lab_session.dart';
import 'package:markpro_plus/services/m1m2_import_service.dart';

class ImportM1M2Dialog extends StatefulWidget {
  final LabSession labSession;
  final Function onImportComplete;

  const ImportM1M2Dialog({
    Key? key,
    required this.labSession,
    required this.onImportComplete,
  }) : super(key: key);

  @override
  State<ImportM1M2Dialog> createState() => _ImportM1M2DialogState();
}

class _ImportM1M2DialogState extends State<ImportM1M2Dialog> {
  final M1M2ImportService _importService = M1M2ImportService();
  bool _isImporting = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _importedMarks = [];

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
            Text(
              'Import M1/M2 Marks',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
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
            if (_importedMarks.isNotEmpty) _buildMarksPreview(),
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
                                final importedMarks =
                                    await _importService.importM1M2FromExcel(context);
                                
                                setState(() {
                                  _importedMarks = importedMarks;
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
                          Text(_importedMarks.isEmpty ? 'Select Excel File' : 'Change File'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _importedMarks.isEmpty || _isImporting
                          ? null
                          : () async {
                              // Show a loading overlay during the import process
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return Dialog(
                                    backgroundColor: Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircularProgressIndicator(),
                                          const SizedBox(height: 20),
                                          Text('Importing ${_importedMarks.length} M1/M2 marks...')
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                              
                              setState(() {
                                _isImporting = true;
                              });
                              
                              try {
                                await _importService.saveImportedM1M2Marks(
                                  labSessionId: widget.labSession.id,
                                  marks: _importedMarks,
                                );
                                
                                if (mounted) {
                                  // Close loading dialog
                                  Navigator.of(context).pop();
                                  // Close the import dialog
                                  Navigator.of(context).pop();
                                  
                                  // Notify parent to refresh data
                                  widget.onImportComplete();
                                  
                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: Colors.white),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Successfully imported ${_importedMarks.length} M1/M2 marks',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      duration: const Duration(seconds: 4),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.green,
                                      action: SnackBarAction(
                                        label: 'OK',
                                        textColor: Colors.white,
                                        onPressed: () {},
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                // Close loading dialog if open
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                }
                                
                                setState(() {
                                  _errorMessage = e.toString();
                                  _isImporting = false;
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check, size: 16),
                          const SizedBox(width: 8),
                          const Text('Import Marks'),
                        ],
                      ),
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
              'Student ID (required)',
              'Name (required)',
              'M1 Marks (required, 0-15)',
              'M2 Marks (required, 0-15)',
            ],
          ),
          _buildInstructionItem(
            '2. Click "Select Excel File" to choose your file',
          ),
          _buildInstructionItem(
            '3. Review the imported data',
          ),
          _buildInstructionItem(
            '4. Click "Import Marks" to update the lab session',
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade800,
                fontStyle: FontStyle.italic,
              ),
              children: [
                const TextSpan(
                  text: 'Note: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                  text: 'Existing M1/M2 marks will be overwritten for the imported students.',
                ),
              ],
            ),
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

  Widget _buildMarksPreview() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview (${_importedMarks.length} entries):',
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
                itemCount: _importedMarks.length > 10
                    ? 10
                    : _importedMarks.length,
                itemBuilder: (context, index) {
                  final mark = _importedMarks[index];
                  return ListTile(
                    title: Text('${mark['name']} (${mark['studentId']})'),
                    subtitle: Text(
                      'M1: ${mark['m1Mark']} | M2: ${mark['m2Mark']}',
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.shade100,
                      child: Text(
                        ((mark['m1Mark'] + mark['m2Mark']) / 2).toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.purple.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_importedMarks.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Showing 10 of ${_importedMarks.length} entries...',
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
