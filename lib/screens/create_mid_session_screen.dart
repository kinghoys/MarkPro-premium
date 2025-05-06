import 'package:flutter/material.dart';
import 'package:markpro_plus/constants/education_constants.dart';
import 'package:markpro_plus/models/mid_session.dart';
import 'package:markpro_plus/models/subject_model.dart';
import 'package:markpro_plus/services/mid_service.dart';
import 'package:markpro_plus/services/student_service.dart';
import 'package:markpro_plus/services/subject_service.dart';

class CreateMidSessionScreen extends StatefulWidget {
  const CreateMidSessionScreen({Key? key}) : super(key: key);

  @override
  _CreateMidSessionScreenState createState() => _CreateMidSessionScreenState();
}

class _CreateMidSessionScreenState extends State<CreateMidSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final MidService _midService = MidService();
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

  Future<void> _createMidSession() async {
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
          content: const Text('No students found for this class. Do you want to create the mid session anyway?'),
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
      // Create new mid session
      final midSession = MidSession.create(
        subjectId: selectedSubject!.id,
        subjectName: selectedSubject!.name,
        branch: selectedBranch!,
        year: selectedYear!,
        section: selectedSection!,
        students: studentIds,
      );
      
      // Save to database
      await _midService.createMidSession(midSession);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mid session created successfully'),
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
            content: Text('Error creating mid session: $e'),
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
        title: const Text('Create Mid Session'),
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
                            
                            // Students
                            const Text(
                              'Students',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            if (studentsError != null)
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
                              )
                            else if (loadingStudents)
                              const Center(
                                child: CircularProgressIndicator(),
                              )
                            else if (studentIds.isEmpty)
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    if (selectedBranch != null && 
                                        selectedYear != null && 
                                        selectedSection != null) {
                                      _loadStudents();
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please select branch, year, and section first'),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.people),
                                  label: const Text('Load Students'),
                                ),
                              )
                            else
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
                          
                            const SizedBox(height: 24),
                          
                            // Create Button
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: isLoading ? null : _createMidSession,
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
                                  : const Icon(Icons.save),
                                label: const Text('Create Mid Session'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  backgroundColor: const Color(0xFF8B5CF6), // Purple color
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
