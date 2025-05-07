import 'package:flutter/material.dart';
import 'package:markpro_plus/constants/education_constants.dart';
import 'package:markpro_plus/models/student_model.dart';
import 'package:markpro_plus/models/subject_model.dart';
import 'package:markpro_plus/services/assignment_service.dart';
import 'package:markpro_plus/services/student_service.dart';
import 'package:markpro_plus/services/subject_service.dart';

class CreateAssignmentSessionScreen extends StatefulWidget {
  const CreateAssignmentSessionScreen({Key? key}) : super(key: key);

  @override
  _CreateAssignmentSessionScreenState createState() => _CreateAssignmentSessionScreenState();
}

class _CreateAssignmentSessionScreenState extends State<CreateAssignmentSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final AssignmentService _assignmentService = AssignmentService();
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
      // No need to convert year format when calling getStudents
      // The StudentService handles this conversion
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

  Future<void> _createAssignmentSession() async {
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
          content: const Text('No students found for this class. Do you want to create the assignment session anyway?'),
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
      // Create new assignment session - use the selectedYear directly
      // The service layer should handle any necessary conversions
      await _assignmentService.createAssignmentSession(
        subjectName: selectedSubject!.name,
        branch: selectedBranch!,
        year: selectedYear!,
        section: selectedSection!,
        students: studentIds,
      );
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment session created successfully'),
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
            content: Text('Error creating assignment session: $e'),
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
        title: const Text('Create Assignment Session'),
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
                              'Select Subject',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Subject dropdown
                            DropdownButtonFormField<SubjectModel>(
                              decoration: const InputDecoration(
                                labelText: 'Subject',
                                hintText: 'Select a subject',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedSubject,
                              items: subjects.map((subject) {
                                return DropdownMenuItem<SubjectModel>(
                                  value: subject,
                                  child: Text(subject.name),
                                );
                              }).toList(),
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
                            
                            // Class details
                            const Text(
                              'Class Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Branch, Year, Section
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                      labelText: 'Branch',
                                      hintText: 'Select branch',
                                      border: OutlineInputBorder(),
                                    ),
                                    value: selectedBranch,
                                    items: EducationConstants.branches.map((branch) {
                                      return DropdownMenuItem<String>(
                                        value: branch,
                                        child: Text(branch),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedBranch = value;
                                        studentIds = [];
                                        studentsError = null;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                      labelText: 'Year',
                                      hintText: 'Select year',
                                      border: OutlineInputBorder(),
                                    ),
                                    value: selectedYear,
                                    items: EducationConstants.years.map((year) {
                                      return DropdownMenuItem<String>(
                                        value: year,
                                        child: Text(year),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedYear = value;
                                        studentIds = [];
                                        studentsError = null;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                      labelText: 'Section',
                                      hintText: 'Select section',
                                      border: OutlineInputBorder(),
                                    ),
                                    value: selectedSection,
                                    items: EducationConstants.sections.map((section) {
                                      return DropdownMenuItem<String>(
                                        value: section,
                                        child: Text(section),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedSection = value;
                                        studentIds = [];
                                        studentsError = null;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: selectedBranch != null && 
                                             selectedYear != null && 
                                             selectedSection != null
                                      ? _loadStudents
                                      : null,
                                  child: const Text('Load Students'),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),
                            
                            // Students Section
                            const Text(
                              'Students',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            if (loadingStudents)
                              const Center(child: CircularProgressIndicator())
                            else if (studentsError != null)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Error: $studentsError',
                                      style: TextStyle(color: Colors.red[800]),
                                    ),
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/student-management')
                                          .then((_) {
                                            if (selectedBranch != null && 
                                                selectedYear != null && 
                                                selectedSection != null) {
                                              _loadStudents();
                                            }
                                          });
                                      },
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add Students'),
                                    ),
                                  ],
                                ),
                              ),
                            
                            const SizedBox(height: 16),
                            
                            if (loadingStudents)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: selectedBranch != null && 
                                           selectedYear != null && 
                                           selectedSection != null
                                    ? _loadStudents
                                    : null,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Load Students'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 45),
                                ),
                              ),
                            
                            if (studentIds.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${studentIds.length} students loaded',
                                      style: TextStyle(color: Colors.green[800]),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Branch: $selectedBranch, Year: $selectedYear, Section: $selectedSection',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            
                            const SizedBox(height: 32),
                            
                            ElevatedButton(
                              onPressed: isLoading ? null : _createAssignmentSession,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Create Assignment Session'),
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