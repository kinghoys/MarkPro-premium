import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markpro_plus/models/seminar_session.dart';
import 'package:markpro_plus/models/student_model.dart';
import 'package:markpro_plus/services/seminar_service.dart';

class SeminarMarksTable extends StatefulWidget {
  final SeminarSession seminarSession;
  final List<StudentModel> students;
  final VoidCallback onMarksSaved;

  const SeminarMarksTable({
    Key? key,
    required this.seminarSession,
    required this.students,
    required this.onMarksSaved,
  }) : super(key: key);

  @override
  State<SeminarMarksTable> createState() => _SeminarMarksTableState();
}

class _SeminarMarksTableState extends State<SeminarMarksTable> {
  final SeminarService _seminarService = SeminarService();
  
  // Controllers for text fields
  final Map<String, TextEditingController> _marksControllers = {};
  final Map<String, FocusNode> _marksFocusNodes = {};
  
  // Student with active focus
  String? _activeStudentId;
  
  // Field navigation matrix
  List<List<FocusNode>> _fieldMatrix = [];
  
  // Track current position for navigation
  int _currentRow = 0;
  int _currentColumn = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }
  
  @override
  void didUpdateWidget(SeminarMarksTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seminarSession.id != widget.seminarSession.id) {
      _disposeControllers();
      _initializeControllers();
    }
  }
  
  void _initializeControllers() {
    // Initialize controllers and focus nodes for each student
    for (int i = 0; i < widget.students.length; i++) {
      final student = widget.students[i];
      
      // Create controller with existing mark or empty
      final mark = widget.seminarSession.presentationMarks[student.rollNo]?['total'] ?? 0.0;
      _marksControllers[student.rollNo] = TextEditingController(
        text: mark > 0 ? mark.toString() : '',
      );
      
      // Create focus node with listeners
      _marksFocusNodes[student.rollNo] = FocusNode()
        ..addListener(() {
          if (_marksFocusNodes[student.rollNo]!.hasFocus) {
            setState(() {
              _activeStudentId = student.rollNo;
              _currentRow = i;
              _currentColumn = 0;
            });
          }
        });
    }
    
    // Create field matrix for navigation
    _fieldMatrix = widget.students.map((student) {
      return [_marksFocusNodes[student.rollNo]!];
    }).toList();
  }
  
  void _disposeControllers() {
    for (final controller in _marksControllers.values) {
      controller.dispose();
    }
    for (final focusNode in _marksFocusNodes.values) {
      focusNode.dispose();
    }
    _marksControllers.clear();
    _marksFocusNodes.clear();
  }
  
  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }
  
  // Save marks for a student
  Future<bool> _saveMarks(String studentId) async {
    final text = _marksControllers[studentId]?.text.trim() ?? '';
    
    // Skip if empty
    if (text.isEmpty) return false;
    
    try {
      // Parse the mark
      final mark = double.parse(text);
      
      // Validate mark (0-5)
      if (mark < 0 || mark > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seminar mark must be between 0 and 5'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return false;
      }
      
      // Save to database
      await _seminarService.updatePresentationMarks(
        sessionId: widget.seminarSession.id,
        studentId: studentId,
        content: 0,  // Not used in simplified model
        delivery: 0, // Not used in simplified model
        qa: 0,       // Not used in simplified model
        seminarMark: mark,
      );
      
      // Call onMarksSaved callback
      widget.onMarksSaved();
      
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving mark: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }
  
  // Handle enter key press
  void _handleEnterKey(String studentId) {
    // First move to the next field immediately
    _moveToNextField();
    
    // Then save the mark in the background without waiting
    _saveMarks(studentId).then((saved) {
      // No need to show success messages for every field
      // Only show error if there's an issue
      if (!saved) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error saving mark'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    });
  }
  
  // Move to the next field
  void _moveToNextField() {
    // Calculate next position
    int nextRow = _currentRow + 1;
    int nextColumn = _currentColumn;
    
    // If we reached the end of rows, go to the next column or wrap around
    if (nextRow >= _fieldMatrix.length) {
      nextRow = 0;
      nextColumn = (nextColumn + 1) % 1; // Only one column
    }
    
    // Request focus on the next field
    if (nextRow < _fieldMatrix.length && nextColumn < _fieldMatrix[nextRow].length) {
      _fieldMatrix[nextRow][nextColumn].requestFocus();
    }
  }
  
  // Move to the previous field
  void _moveToPrevField() {
    // Calculate previous position
    int prevRow = _currentRow - 1;
    int prevColumn = _currentColumn;
    
    // If we reached the beginning of rows, go to the previous column or wrap around
    if (prevRow < 0) {
      prevRow = _fieldMatrix.length - 1;
      prevColumn = (prevColumn - 1 + 1) % 1; // Only one column
      if (prevColumn < 0) prevColumn = 0;
    }
    
    // Request focus on the previous field
    if (prevRow >= 0 && prevColumn >= 0 && prevColumn < _fieldMatrix[prevRow].length) {
      _fieldMatrix[prevRow][prevColumn].requestFocus();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seminar Marks (Out of 5)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter seminar marks for each student (0-5).',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Table(
              border: TableBorder.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
              columnWidths: const {
                0: FlexColumnWidth(1.5), // Roll No
                1: FlexColumnWidth(3),    // Name
                2: FlexColumnWidth(1.5),  // Seminar Marks
              },
              children: [
                // Header row
                TableRow(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Roll No',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Student Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Marks (0-5)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                // Data rows
                ...widget.students.map((student) {
                  return TableRow(
                    decoration: BoxDecoration(
                      color: _activeStudentId == student.rollNo
                          ? Colors.blue.withOpacity(0.05)
                          : null,
                    ),
                    children: [
                      // Roll No
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          student.rollNo,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Name
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          student.name,
                        ),
                      ),
                      // Seminar Marks
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Focus(
                          onKeyEvent: (FocusNode node, KeyEvent event) {
                            if (event is KeyDownEvent) {
                              if (event.logicalKey == LogicalKeyboardKey.tab) {
                                _moveToNextField();
                                return KeyEventResult.handled;
                              } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                                _handleEnterKey(student.rollNo);
                                return KeyEventResult.handled;
                              } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                                _moveToNextField();
                                return KeyEventResult.handled;
                              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                                _moveToPrevField();
                                return KeyEventResult.handled;
                              }
                            }
                            return KeyEventResult.ignored;
                          },
                          child: TextField(
                            controller: _marksControllers[student.rollNo],
                            focusNode: _marksFocusNodes[student.rollNo],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: '0-5',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            onSubmitted: (_) {
                              _handleEnterKey(student.rollNo);
                            },
                            onTap: () {
                              setState(() {
                                _activeStudentId = student.rollNo;
                              });
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                // Save all marks
                bool allSaved = true;
                for (final studentId in _marksControllers.keys) {
                  if (_marksControllers[studentId]!.text.trim().isNotEmpty) {
                    final saved = await _saveMarks(studentId);
                    allSaved = allSaved && saved;
                  }
                }
                
                if (allSaved) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All marks saved successfully'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Save All Marks'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
