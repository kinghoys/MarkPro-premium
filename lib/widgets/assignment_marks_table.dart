import 'dart:async'; // For Completer
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter and LogicalKeyboardKey
import 'package:markpro_plus/models/assignment_session.dart';
import 'package:markpro_plus/models/student_model.dart';
import 'package:markpro_plus/services/assignment_service.dart';

class AssignmentMarksTable extends StatefulWidget {
  final AssignmentSession assignmentSession;
  final List<StudentModel> students;
  final String assignmentNumber; // '1' or '2'
  final Function onMarksSaved;

  const AssignmentMarksTable({
    Key? key,
    required this.assignmentSession,
    required this.students,
    required this.assignmentNumber,
    required this.onMarksSaved,
  }) : super(key: key);

  @override
  _AssignmentMarksTableState createState() => _AssignmentMarksTableState();
}

class _AssignmentMarksTableState extends State<AssignmentMarksTable> {
  final AssignmentService _assignmentService = AssignmentService();
  
  // Controllers for the text fields
  final Map<String, TextEditingController> _marksControllers = {};
  
  // Focus nodes for keyboard navigation
  final Map<String, FocusNode> _marksFocusNodes = {};
  
  // Status trackers
  final Map<String, bool> _isSaving = {};
  final Map<String, String?> _errors = {};
  
  // Student data (initialized as empty to prevent late initialization error)
  List<StudentModel> _sortedStudents = [];
  
  // Navigation matrix for keyboard traversal
  List<FocusNode> _fieldMatrix = [];
  
  // Track current position in the matrix
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _sortStudents();
  }
  
  @override
  void didUpdateWidget(AssignmentMarksTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Refresh controllers when the session data changes
    if (oldWidget.assignmentSession != widget.assignmentSession) {
      _initializeControllers();
    }
  }
  
  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }
  
  void _sortStudents() {
    _sortedStudents = List.from(widget.students);
    _sortedStudents.sort((a, b) => a.rollNo.compareTo(b.rollNo));
  }
  
  void _initializeControllers() {
    // Clear previous controllers and focus nodes
    _disposeControllers();
    
    // Make sure students are sorted first
    _sortStudents();
    
    // Clear tracking collections
    _marksControllers.clear();
    _marksFocusNodes.clear();
    _errors.clear();
    _isSaving.clear();
    _fieldMatrix.clear();
    
    for (final student in _sortedStudents) {
      final studentId = student.rollNo;
      final marks = widget.assignmentSession.assignmentMarks[studentId];
      
      // Get marks based on assignment number and handle different data formats
      dynamic assignmentData;
      
      if (widget.assignmentNumber == '1') {
        assignmentData = marks?['assignment1'];
      } else {
        assignmentData = marks?['assignment2'];
      }
      
      int assignmentMarks = 0;
      
      // Handle different data formats
      if (assignmentData is int) {
        // Legacy format: direct integer
        assignmentMarks = assignmentData;
      } else if (assignmentData is Map) {
        // New format: map with marks, outOf, and convertedMarks
        try {
          final marks = assignmentData['marks'];
          if (marks is int) {
            assignmentMarks = marks;
          } else if (marks is double) {
            assignmentMarks = marks.round();
          } else if (marks is String) {
            assignmentMarks = int.tryParse(marks) ?? 0;
          }
        } catch (e) {
          print('Error extracting marks: $e');
        }
      } else if (assignmentData != null) {
        print('Unexpected data type for marks: ${assignmentData.runtimeType}');
      }
      
      // Create controller with initial value
      _marksControllers[studentId] = TextEditingController(
        text: assignmentMarks > 0 ? assignmentMarks.toString() : '',
      );
      
      // Create focus node with listener
      _marksFocusNodes[studentId] = FocusNode()
        ..addListener(() {
          if (_marksFocusNodes[studentId]!.hasFocus) {
            // Update current index when this field gets focus
            _updateCurrentIndex(studentId);
          }
        });
      
      // Initialize error and saving state
      _errors[studentId] = null;
      _isSaving[studentId] = false;
    }
    
    // Build navigation matrix
    _buildNavigationMatrix();
  }
  
  // Build a linear navigation matrix for keyboard traversal
  void _buildNavigationMatrix() {
    _fieldMatrix = [];
    
    // Create a list of focus nodes in the order they should be navigated
    for (final student in _sortedStudents) {
      final studentId = student.rollNo;
      if (_marksFocusNodes.containsKey(studentId)) {
        _fieldMatrix.add(_marksFocusNodes[studentId]!);
      }
    }
  }
  
  // Dispose controllers and focus nodes to prevent memory leaks
  void _disposeControllers() {
    for (final controller in _marksControllers.values) {
      controller.dispose();
    }
    
    for (final focusNode in _marksFocusNodes.values) {
      focusNode.dispose();
    }
  }
  
  // Update the current index when a field gets focus
  void _updateCurrentIndex(String studentId) {
    for (int i = 0; i < _fieldMatrix.length; i++) {
      if (_fieldMatrix[i] == _marksFocusNodes[studentId]) {
        _currentIndex = i;
        return;
      }
    }
  }
  
  // Navigate to the next field when Enter or Down arrow is pressed
  void _navigateToNextField(String studentId) {
    if (_fieldMatrix.isEmpty) return;
    
    // Move to the next field in the matrix
    int nextIndex = _currentIndex + 1;
    
    // Wrap around to the beginning if at the end
    if (nextIndex >= _fieldMatrix.length) {
      nextIndex = 0;
    }
    
    print('Moving focus from index $_currentIndex to $nextIndex');
    
    // Force any active text selection to end
    if (_currentIndex < _fieldMatrix.length) {
      FocusScope.of(_marksFocusNodes[studentId]!.context!).unfocus();
    }
    
    // Request focus on the next field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_fieldMatrix.isNotEmpty && nextIndex < _fieldMatrix.length) {
        _fieldMatrix[nextIndex].requestFocus();
        _currentIndex = nextIndex;
        
        // Get the studentId for the next field to show feedback
        String? nextStudentId;
        for (final entry in _marksFocusNodes.entries) {
          if (entry.value == _fieldMatrix[nextIndex]) {
            nextStudentId = entry.key;
            break;
          }
        }
        
        if (nextStudentId != null) {
          print('Focus moved to student: $nextStudentId');
        }
      }
    });
  }
  
  // Navigate to the previous field when Up arrow is pressed
  void _navigateToPreviousField(String studentId) {
    if (_fieldMatrix.isEmpty) return;
    
    // Move to the previous field in the matrix
    int prevIndex = _currentIndex - 1;
    
    // Wrap around to the end if at the beginning
    if (prevIndex < 0) {
      prevIndex = _fieldMatrix.length - 1;
    }
    
    print('Moving focus from index $_currentIndex to previous index $prevIndex');
    
    // Force any active text selection to end
    if (_currentIndex < _fieldMatrix.length) {
      FocusScope.of(_marksFocusNodes[studentId]!.context!).unfocus();
    }
    
    // Request focus on the previous field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_fieldMatrix.isNotEmpty && prevIndex < _fieldMatrix.length) {
        _fieldMatrix[prevIndex].requestFocus();
        _currentIndex = prevIndex;
        
        // Get the studentId for the previous field to show feedback
        String? prevStudentId;
        for (final entry in _marksFocusNodes.entries) {
          if (entry.value == _fieldMatrix[prevIndex]) {
            prevStudentId = entry.key;
            break;
          }
        }
        
        if (prevStudentId != null) {
          print('Focus moved to student: $prevStudentId');
        }
      }
    });
  }
  
  Future<bool> _saveMarks(String studentId) async {
    final text = _marksControllers[studentId]?.text.trim() ?? '';
    
    // Clear previous error
    setState(() {
      _errors[studentId] = null;
    });
    
    // Validate input
    if (text.isEmpty) {
      return true; // Empty input is valid (no marks)
    }
    
    // Try to parse input as integer
    int? marks;
    try {
      marks = int.parse(text);
    } catch (e) {
      setState(() {
        _errors[studentId] = 'Invalid number';
      });
      return false;
    }
    
    // Validate marks range
    if (marks < 0 || marks > 60) {
      setState(() {
        _errors[studentId] = 'Marks must be 0-60';
      });
      return false;
    }
    
    // Default outOf value (can be made configurable later)
    const int outOf = 60;
    
    // Save marks
    setState(() {
      _isSaving[studentId] = true;
    });
    
    try {
      print('Saving marks for student: $studentId, Assignment: ${widget.assignmentNumber}, Marks: $marks');
      print('Session ID: ${widget.assignmentSession.id}');
      
      // Create a completer to ensure the save completes
      Completer<void> saveCompleter = Completer<void>();
      
      // Execute the appropriate save method based on assignment number
      if (widget.assignmentNumber == '1') {
        await _assignmentService.updateAssignment1Marks(
          sessionId: widget.assignmentSession.id,
          studentId: studentId,
          marks: marks,
          outOf: outOf,
        ).then((_) {
          saveCompleter.complete();
        }).catchError((error) {
          saveCompleter.completeError(error);
        });
      } else {
        await _assignmentService.updateAssignment2Marks(
          sessionId: widget.assignmentSession.id,
          studentId: studentId,
          marks: marks,
          outOf: outOf,
        ).then((_) {
          saveCompleter.complete();
        }).catchError((error) {
          saveCompleter.completeError(error);
        });
      }
      
      // Wait for the save operation to complete
      await saveCompleter.future;
      
      // Add a slight delay to ensure the Firestore update is completed
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Call the callback to refresh session data in the background
      widget.onMarksSaved();
      
      // Show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marks saved for Roll No: $studentId'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }
      
      return true; // Return success
    } catch (e) {
      print('Error saving marks: $e');
      setState(() {
        _errors[studentId] = 'Error: $e';
      });
      return false; // Return failure
    } finally {
      if (mounted) {
        setState(() {
          _isSaving[studentId] = false;
        });
      }
    }
  }
  
  // Save all marks at once
  Future<void> _saveAllMarks() async {
    int savedCount = 0;
    int errorCount = 0;
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      print('Starting bulk save for ${_sortedStudents.length} students');
      print('Session ID: ${widget.assignmentSession.id}');
      
      for (final student in _sortedStudents) {
        final studentId = student.rollNo;
        final text = _marksControllers[studentId]?.text.trim() ?? '';
        
        // Skip empty entries
        if (text.isEmpty) continue;
        
        // Parse marks
        int? marks;
        try {
          marks = int.parse(text);
        } catch (e) {
          print('Error parsing marks for student $studentId: $e');
          errorCount++;
          continue;
        }
        
        // Validate range
        if (marks < 0 || marks > 60) {
          print('Invalid marks range for student $studentId: $marks');
          errorCount++;
          continue;
        }
        
        // Default outOf value (can be made configurable later)
        const int outOf = 60;
        
        // Save to database
        try {
          if (widget.assignmentNumber == '1') {
            await _assignmentService.updateAssignment1Marks(
              sessionId: widget.assignmentSession.id,
              studentId: studentId,
              marks: marks,
              outOf: outOf,
            );
          } else {
            await _assignmentService.updateAssignment2Marks(
              sessionId: widget.assignmentSession.id,
              studentId: studentId,
              marks: marks,
              outOf: outOf,
            );
          }
          savedCount++;
          print('Successfully saved marks for student $studentId');
        } catch (e) {
          print('Error saving marks for student $studentId: $e');
          errorCount++;
        }
      }
      
      // Add a slight delay to ensure all Firestore updates are completed
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved $savedCount marks. Errors: $errorCount'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
      // Update parent with partial refresh
      if (savedCount > 0) {
        print('Calling onMarksSaved callback after successful save');
        widget.onMarksSaved();
      }
    } catch (e) {
      print('Global error during save all operation: $e');
      // Close loading dialog on error
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving marks: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Add Save All button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _saveAllMarks,
                  icon: const Icon(Icons.save),
                  label: const Text('Save All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Table(
              border: TableBorder.all(
                color: Colors.grey[300] ?? Colors.grey,
                width: 1,
              ),
              columnWidths: const {
                0: FlexColumnWidth(1), // Roll No
                1: FlexColumnWidth(3), // Name
                2: FlexColumnWidth(2), // Marks
                3: FlexColumnWidth(2), // Converted
                4: FlexColumnWidth(2), // Actions
              },
              children: [
                // Header Row
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                  ),
                  children: [
                    _buildTableHeader('Roll No'),
                    _buildTableHeader('Name'),
                    _buildTableHeader('Marks (0-60)'),
                    _buildTableHeader('Converted (0-5)'),
                    _buildTableHeader('Actions'),
                  ],
                ),
                // Data Rows
                ..._sortedStudents.map((student) {
                  final studentId = student.rollNo;
                  final assignmentMarks = widget.assignmentSession.assignmentMarks[studentId];
                  
                  // Get converted marks
                  int convertedMarks = 0;
                  int marksValue = 0;
                  
                  // Get assignment data based on assignment number
                  dynamic assignmentData;
                  
                  if (widget.assignmentNumber == '1') {
                    assignmentData = assignmentMarks?['assignment1'];
                  } else {
                    assignmentData = assignmentMarks?['assignment2'];
                  }
                  
                  // Handle different data formats
                  if (assignmentData is int) {
                    // Legacy format: direct integer
                    marksValue = assignmentData;
                  } else if (assignmentData is Map) {
                    // New format: map with marks, outOf, and convertedMarks
                    try {
                      dynamic marks = assignmentData['marks'];
                      if (marks is int) {
                        marksValue = marks;
                      } else if (marks is double) {
                        marksValue = marks.round();
                      } else if (marks is String) {
                        marksValue = int.tryParse(marks) ?? 0;
                      }
                    } catch (e) {
                      print('Error extracting marks: $e');
                    }
                  }
                  
                  // Calculate converted marks
                  convertedMarks = _assignmentService.convertTo5PointScale(marksValue);
                  
                  return TableRow(
                    decoration: BoxDecoration(
                      color: _errors[studentId] != null ? Colors.red[50] : null,
                    ),
                    children: [
                      // Roll No
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          studentId,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Name
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(student.name),
                      ),
                      // Marks Input
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: RawKeyboardListener(
                          focusNode: FocusNode(),
                          onKey: (event) {
                            if (event is RawKeyDownEvent) {
                              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                                // Prevent default to avoid unexpected text cursor movement
                                event.character;
                                _navigateToNextField(studentId);
                                return;
                              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                                // Prevent default to avoid unexpected text cursor movement
                                event.character;
                                _navigateToPreviousField(studentId);
                                return;
                              } else if (event.logicalKey == LogicalKeyboardKey.tab) {
                                // Tab navigation is handled by default, but we can add custom behavior if needed
                                if (event.isShiftPressed) {
                                  _navigateToPreviousField(studentId);
                                } else {
                                  _navigateToNextField(studentId);
                                }
                                return;
                              }
                            }
                          },
                          child: TextField(
                            controller: _marksControllers[studentId],
                            focusNode: _marksFocusNodes[studentId],
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              border: const OutlineInputBorder(),
                              errorText: _errors[studentId],
                              isDense: true,
                              hintText: 'Enter marks',
                            ),
                            onSubmitted: (_) {
                              // First navigate to the next field immediately
                              _navigateToNextField(studentId);
                              
                              // Then save the marks in the background
                              Future(() async {
                                await _saveMarks(studentId);
                              }).catchError((e) {
                                print('Error saving marks in background: $e');
                              });
                            },
                          ),
                        ),
                      ),
                      // Converted Marks
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        alignment: Alignment.center,
                        child: Text(
                          convertedMarks.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: convertedMarks >= 4 ? Colors.green[700] :
                                  convertedMarks >= 3 ? Colors.blue[700] :
                                  convertedMarks >= 2 ? Colors.orange[700] :
                                  Colors.red[700],
                          ),
                        ),
                      ),
                      // Save Button
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _isSaving[studentId] ?? false
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: () {
                                  // First navigate to the next field immediately
                                  _navigateToNextField(studentId);
                                  
                                  // Then save the marks in the background
                                  Future(() async {
                                    await _saveMarks(studentId);
                                  }).catchError((e) {
                                    print('Error saving marks in background: $e');
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: const Size(30, 30),
                                ),
                                child: const Text('Save'),
                              ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
          // Conversion Scale Explanation
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300] ?? Colors.grey),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Conversion Scale:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildScaleRow('36-60 marks', '→ 5 points'),
                  _buildScaleRow('26-35 marks', '→ 4 points'),
                  _buildScaleRow('16-25 marks', '→ 3 points'),
                  _buildScaleRow('6-15 marks', '→ 2 points'),
                  _buildScaleRow('1-5 marks', '→ 1 point'),
                  _buildScaleRow('0 marks', '→ 0 points'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTableHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
  
  Widget _buildScaleRow(String range, String points) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              range,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(points),
        ],
      ),
    );
  }
}
