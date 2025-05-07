import 'package:flutter/material.dart';
import 'package:markpro_plus/constants/education_constants.dart';
import 'package:markpro_plus/models/seminar_session.dart';
import 'package:markpro_plus/models/subject_model.dart';
import 'package:markpro_plus/services/seminar_service.dart';
import 'package:markpro_plus/services/student_service.dart';
import 'package:markpro_plus/services/subject_service.dart';

class CreateSeminarSessionScreen extends StatefulWidget {
  const CreateSeminarSessionScreen({Key? key}) : super(key: key);

  @override
  _CreateSeminarSessionScreenState createState() => _CreateSeminarSessionScreenState();
}

class _CreateSeminarSessionScreenState extends State<CreateSeminarSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final SeminarService _seminarService = SeminarService();
  final SubjectService _subjectService = SubjectService();
  final StudentService _studentService = StudentService();

  bool isLoading = false;
  String? _error;
  
  // Form fields
  SubjectModel? selectedSubject;
  List<SubjectModel> subjects = [];
  String? selectedBranch;
  String? selectedYear;
  String? selectedSection;
  
  // Students
  List<String> studentIds = [];
  bool loadingStudents = false;
  String? studentsError;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() {
      isLoading = true;
      _error = null;
    });

    try {
      final loadedSubjects = await _subjectService.getSubjects();
      setState(() {
        subjects = loadedSubjects;
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

  Future<void> _loadStudents() async {
    if (selectedBranch == null || selectedYear == null || selectedSection == null) {
      setState(() {
        studentsError = 'Please select branch, year, and section';
      });
      return;
    }

    setState(() {
      loadingStudents = true;
      studentsError = null;
    });

    try {
      final students = await _studentService.getStudents(
        selectedBranch!,
        selectedYear!,
        selectedSection!,
      );
      
      setState(() {
        studentIds = students.map((s) => s.rollNo).toList();
        loadingStudents = false;
      });
      
      if (studentIds.isEmpty) {
        setState(() {
          studentsError = 'No students found for the selected class. Please add students first.';
        });
      }
    } catch (e) {
      setState(() {
        loadingStudents = false;
        studentsError = e.toString();
      });
    }
  }

  Future<void> _createSeminarSession() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a subject'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    if (selectedBranch == null || selectedYear == null || selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select branch, year, and section'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    if (studentIds.isEmpty) {
      final confirmNoStudents = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Students'),
          content: const Text('No students found for this class. Do you want to create the seminar session anyway?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Create Anyway'),
            ),
          ],
        ),
      );
      
      if (confirmNoStudents != true) {
        return;
      }
    }
    
    setState(() {
      isLoading = true;
      _error = null;
    });
    
    try {
      // Create new seminar session
      final seminarSession = SeminarSession.create(
        subjectId: selectedSubject!.id,
        subjectName: selectedSubject!.name,
        branch: selectedBranch!,
        year: selectedYear!,
        section: selectedSection!,
        students: studentIds,
      );
      
      // Save to database
      await _seminarService.createSeminarSession(seminarSession);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seminar session created successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Navigate back
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating seminar session: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Seminar Session'),
      ),
      body: isLoading && subjects.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && subjects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSubjects,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Subject selection
                            const Text(
                              'Subject Information',
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<SubjectModel>(
                              decoration: const InputDecoration(
                                labelText: 'Select Subject',
                                prefixIcon: Icon(Icons.book),
                              ),
                              value: selectedSubject,
                              items: subjects
                                  .map((subject) => DropdownMenuItem(
                                        value: subject,
                                        child: Text(subject.name),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedSubject = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a subject';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            
                            // Class information
                            const Text(
                              'Class Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Branch dropdown
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Branch',
                                prefixIcon: Icon(Icons.business),
                              ),
                              value: selectedBranch,
                              items: EducationConstants.branches
                                  .map((branch) => DropdownMenuItem(
                                        value: branch,
                                        child: Text(branch),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedBranch = value;
                                  studentIds = [];
                                  studentsError = null;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a branch';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Year dropdown
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Year',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              value: selectedYear,
                              items: EducationConstants.years
                                  .map((year) => DropdownMenuItem(
                                        value: year,
                                        child: Text(year),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedYear = value;
                                  studentIds = [];
                                  studentsError = null;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a year';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Section dropdown
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Section',
                                prefixIcon: Icon(Icons.group),
                              ),
                              value: selectedSection,
                              items: EducationConstants.sections
                                  .map((section) => DropdownMenuItem(
                                        value: section,
                                        child: Text(section),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedSection = value;
                                  studentIds = [];
                                  studentsError = null;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a section';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            
                            // Load students button
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: selectedBranch != null &&
                                        selectedYear != null &&
                                        selectedSection != null
                                    ? !loadingStudents 
                                        ? _loadStudents
                                        : null
                                    : null,
                                icon: loadingStudents
                                    ? Container(
                                        width: 24,
                                        height: 24,
                                        padding: const EdgeInsets.all(2.0),
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : const Icon(Icons.people),
                                label: Text(loadingStudents
                                    ? 'Loading Students...'
                                    : 'Load Students'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Students info
                            if (studentsError != null)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error, color: Colors.red.shade700),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        studentsError!,
                                        style: TextStyle(color: Colors.red.shade700),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (studentIds.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green.shade700),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${studentIds.length} students loaded successfully',
                                      style: TextStyle(color: Colors.green.shade700),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 24),
                            
                            // Create button
                            if (_error != null)
                              Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error, color: Colors.red.shade700),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Error: $_error',
                                        style: TextStyle(color: Colors.red.shade700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Center(
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: isLoading
                                      ? Container(
                                          width: 24,
                                          height: 24,
                                          padding: const EdgeInsets.all(2.0),
                                          child: const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        )
                                      : const Icon(Icons.add),
                                  label: Text(
                                    isLoading ? 'Creating...' : 'Create Seminar Session',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  onPressed: isLoading ? null : _createSeminarSession,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E3A8A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    textStyle: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
