import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markpro_plus/models/lab_session.dart';
import 'package:markpro_plus/models/student_model.dart';
import 'package:markpro_plus/services/lab_service.dart';

class FinalLabMarksTable extends StatefulWidget {
  final LabSession labSession;
  final List<StudentModel> students;
  final VoidCallback onMarksSaved;

  const FinalLabMarksTable({
    Key? key,
    required this.labSession,
    required this.students,
    required this.onMarksSaved,
  }) : super(key: key);

  @override
  State<FinalLabMarksTable> createState() => _FinalLabMarksTableState();
}

class _FinalLabMarksTableState extends State<FinalLabMarksTable> {
  final LabService _labService = LabService();
  
  // Controllers and focus nodes for viva marks
  final Map<String, TextEditingController> _vivaMarkControllers = {};
  final Map<String, FocusNode> _vivaMarkFocusNodes = {};
  
  // Student with active focus
  String? _activeStudentId;
  
  // Loading states
  final Map<String, bool> _isLoading = {};
  bool _isBatchSaving = false;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }
  
  @override
  void didUpdateWidget(FinalLabMarksTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.labSession.id != widget.labSession.id) {
      _disposeControllers();
      _initializeControllers();
    }
  }
  
  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }
  
  void _initializeControllers() {
    for (final student in widget.students) {
      final studentId = student.rollNo;
      
      // Get current viva mark if available
      final vivaMark = widget.labSession.getVivaMark(studentId);
      
      // Create controller with initial value
      _vivaMarkControllers[studentId] = TextEditingController(
        text: vivaMark != null ? vivaMark.toString() : '',
      );
      
      // Create focus node with listener
      _vivaMarkFocusNodes[studentId] = FocusNode()
        ..addListener(() {
          if (_vivaMarkFocusNodes[studentId]!.hasFocus) {
            setState(() {
              _activeStudentId = studentId;
            });
          }
        });
    }
  }
  
  void _disposeControllers() {
    for (final controller in _vivaMarkControllers.values) {
      controller.dispose();
    }
    
    for (final focusNode in _vivaMarkFocusNodes.values) {
      focusNode.dispose();
    }
    
    _vivaMarkControllers.clear();
    _vivaMarkFocusNodes.clear();
  }
  
  Future<void> _saveVivaMark(String studentId) async {
    if (_isLoading[studentId] == true) return;
    
    setState(() {
      _isLoading[studentId] = true;
    });
    
    try {
      // Get value from controller
      final markText = _vivaMarkControllers[studentId]!.text.trim();
      
      // Check if mark is provided
      if (markText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a viva mark'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      // Parse and validate mark
      final mark = int.tryParse(markText) ?? 0;
      
      if (mark < 0 || mark > 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid mark. Viva mark should be between 0-10'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      // Check if M1 and M2 marks are available
      final m1Mark = widget.labSession.m1Marks[studentId];
      final m2Mark = widget.labSession.m2Marks[studentId];
      
      if (m1Mark == null || m2Mark == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('M1 and M2 marks must be calculated before saving viva mark'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      // Save mark and calculate final grade
      await _labService.saveVivaMarkAndCalculateFinal(
        labSessionId: widget.labSession.id,
        studentId: studentId,
        vivaMark: mark,
      );
      
      // Call the callback to refresh data
      widget.onMarksSaved();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Viva mark saved for ${_getStudentName(studentId)}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving viva mark: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading[studentId] = false;
        });
      }
    }
  }

  Future<void> _calculateAllFinalGrades() async {
    // Check if batch process is already running
    if (_isBatchSaving) return;
    
    // Confirm with user
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calculate All Final Grades'),
        content: const Text(
          'This will calculate final lab grades for all students who have M1, M2, '
          'and viva marks entered. Students with missing marks will be skipped.\n\n'
          'Do you want to proceed?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
            child: const Text('Calculate All'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isBatchSaving = true;
    });
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Calculating final grades...'),
          ],
        ),
      ),
    );
    
    try {
      // Calculate final grades for all students
      final errors = await _labService.calculateAllFinalLabGrades(
        labSessionId: widget.labSession.id,
      );
      
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Show results
      if (mounted) {
        // Call the callback to refresh data
        widget.onMarksSaved();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Final grades calculated for ${widget.labSession.finalLabMarks.length} students'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // If there were errors, show them
        if (errors.isNotEmpty) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Students Skipped'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: errors.entries.map((entry) {
                    // Find student name by roll number
                    final student = widget.students.firstWhere(
                      (s) => s.rollNo == entry.key,
                      orElse: () => StudentModel(
                        id: '', 
                        name: 'Unknown', 
                        rollNo: entry.key,
                        branch: '',
                        year: 1,
                        semester: 1,
                        section: '',
                        academicYear: '',
                      ),
                    );
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('• ${student.name}: ${entry.value}'),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calculating final grades: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBatchSaving = false;
        });
      }
    }
  }
  
  Future<void> _saveAllVivaMarks() async {
    if (_isBatchSaving) return;
    
    setState(() {
      _isBatchSaving = true;
    });
    
    final studentsToUpdate = <String>[];
    final errors = <String>[];
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Saving all viva marks...'),
          ],
        ),
      ),
    );
    
    try {
      // Loop through all students with viva mark controllers
      for (final entry in _vivaMarkControllers.entries) {
        final studentId = entry.key;
        final controller = entry.value;
        
        // Skip if empty
        if (controller.text.trim().isEmpty) {
          continue;
        }
        
        // Parse and validate mark
        final mark = int.tryParse(controller.text.trim());
        if (mark == null || mark < 0 || mark > 10) {
          errors.add('${_getStudentName(studentId)}: Invalid mark (should be 0-10)');
          continue;
        }
        
        // Check if M1 and M2 marks are available
        final m1Mark = widget.labSession.m1Marks[studentId];
        final m2Mark = widget.labSession.m2Marks[studentId];
        
        if (m1Mark == null || m2Mark == null) {
          errors.add('${_getStudentName(studentId)}: Missing M1/M2 marks');
          continue;
        }
        
        // Add to list of students to update
        studentsToUpdate.add(studentId);
      }
      
      // Update all students in the list
      for (final studentId in studentsToUpdate) {
        final mark = int.parse(_vivaMarkControllers[studentId]!.text.trim());
        
        try {
          await _labService.saveVivaMarkAndCalculateFinal(
            labSessionId: widget.labSession.id,
            studentId: studentId,
            vivaMark: mark,
          );
        } catch (e) {
          errors.add('${_getStudentName(studentId)}: $e');
        }
      }
      
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Show results
      if (mounted) {
        // Call the callback to refresh data
        widget.onMarksSaved();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved viva marks for ${studentsToUpdate.length} students'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // If there were errors, show them
        if (errors.isNotEmpty) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Errors'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: errors.map((error) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('• $error'),
                  )).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving viva marks: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBatchSaving = false;
        });
      }
    }
  }
  
  String _getStudentName(String studentId) {
    final student = widget.students.firstWhere(
      (s) => s.rollNo == studentId,
      orElse: () => StudentModel(
        id: '', 
        name: 'Unknown', 
        rollNo: studentId, 
        branch: '',
        year: 1,
        semester: 1,
        section: '',
        academicYear: '',
      ),
    );
    return student.name;
  }
  
  @override
  Widget build(BuildContext context) {
    final m1Calculated = widget.labSession.m1Marks.isNotEmpty;
    final m2Calculated = widget.labSession.m2Marks.isNotEmpty;
    
    return Column(
      children: [
        // Information panel for final grade calculation
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple[200] ?? Colors.purple),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.purple, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Final Assessment Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '• Viva marks should be entered on a scale of 0-10',
                style: TextStyle(color: Colors.purple[800]),
              ),
              Text(
                '• Final grade = 75% of better model exam (M1 or M2) + Viva marks',
                style: TextStyle(color: Colors.purple[800]),
              ),
              Text(
                '• Maximum final grade: 40 (30 from model exam + 10 from viva)',
                style: TextStyle(color: Colors.purple[800]),
              ),
            ],
          ),
        ),
        
        // Buttons row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: _calculateAllFinalGrades,
                icon: const Icon(Icons.calculate, size: 18),
                label: const Text('Calculate All Final Grades'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _saveAllVivaMarks,
                icon: const Icon(Icons.save_alt, size: 18),
                label: const Text('Save All Viva Marks'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        
        // Table header
        _buildHeader(m1Calculated, m2Calculated),
        
        // Student list
        if (widget.students.isEmpty)
          const Expanded(
            child: Center(
              child: Text('No students found'),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: widget.students.length,
              itemBuilder: (context, index) {
                final student = widget.students[index];
                return _buildStudentRow(student);
              },
            ),
          ),
      ],
    );
  }
  
  Widget _buildHeader(bool m1Calculated, bool m2Calculated) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(color: Colors.blue[100] ?? Colors.blue),
        ),
      ),
      child: Row(
        children: [
          // Student column
          const Expanded(
            flex: 3,
            child: Text(
              'Student',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Marks columns
          Expanded(
            flex: 7,
            child: Row(
              children: [
                // M1 column
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'M1',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (m1Calculated)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 14,
                          )
                        else
                          const Icon(
                            Icons.pending,
                            color: Colors.grey,
                            size: 14,
                          ),
                      ],
                    ),
                  ),
                ),
                
                // M2 column
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'M2',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (m2Calculated)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 14,
                          )
                        else
                          const Icon(
                            Icons.pending,
                            color: Colors.grey,
                            size: 14,
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Viva column
                const Expanded(
                  child: Center(
                    child: Text(
                      'Viva (0-10)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Final grade column
                const Expanded(
                  child: Center(
                    child: Text(
                      'Final Grade',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Actions column
                const Expanded(
                  child: Center(
                    child: Text(
                      'Actions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStudentRow(StudentModel student) {
    final studentId = student.rollNo;
    final m1Mark = widget.labSession.m1Marks[studentId];
    final m2Mark = widget.labSession.m2Marks[studentId];
    final vivaMark = widget.labSession.getVivaMark(studentId);
    final finalGrade = widget.labSession.finalLabMarks[studentId];
    
    final isLoading = _isLoading[studentId] == true;
    final canEnterViva = m1Mark != null && m2Mark != null;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300] ?? Colors.grey),
        ),
        color: _activeStudentId == studentId ? Colors.blue.withOpacity(0.05) : null,
      ),
      child: Row(
        children: [
          // Student name and roll number
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  studentId,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Marks columns
          Expanded(
            flex: 7,
            child: Row(
              children: [
                // M1 mark
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: m1Mark != null ? Colors.green[50] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        m1Mark != null ? m1Mark.toStringAsFixed(1) : '-',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: m1Mark != null ? Colors.green[800] : Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // M2 mark
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: m2Mark != null ? Colors.green[50] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        m2Mark != null ? m2Mark.toStringAsFixed(1) : '-',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: m2Mark != null ? Colors.green[800] : Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Viva mark input
                Expanded(
                  child: Center(
                    child: TextFormField(
                      controller: _vivaMarkControllers[studentId],
                      focusNode: _vivaMarkFocusNodes[studentId],
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: '0-10',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      enabled: canEnterViva,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                
                // Final grade
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: finalGrade != null ? Colors.purple[50] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                        border: finalGrade != null 
                            ? Border.all(color: Colors.purple[200] ?? Colors.purple) 
                            : null,
                      ),
                      child: Text(
                        finalGrade != null ? finalGrade.toStringAsFixed(1) : '-',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: finalGrade != null ? Colors.purple[800] : Colors.grey[500],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Actions
                Expanded(
                  child: Center(
                    child: ElevatedButton(
                      onPressed: canEnterViva && !isLoading ? () => _saveVivaMark(studentId) : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: const Size(80, 30),
                        backgroundColor: Colors.green,
                      ),
                      child: isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              vivaMark != null ? 'Update' : 'Save',
                              style: const TextStyle(fontSize: 12),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
