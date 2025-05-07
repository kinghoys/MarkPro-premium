import 'package:flutter/material.dart';
import 'package:markpro_plus/constants/education_constants.dart';
import 'package:markpro_plus/models/lab_session.dart';
import 'package:markpro_plus/models/subject_model.dart';
import 'package:markpro_plus/services/lab_service.dart';
import 'package:markpro_plus/services/student_service.dart';
import 'package:markpro_plus/services/subject_service.dart';

class CreateLabSessionScreen extends StatefulWidget {
  const CreateLabSessionScreen({Key? key}) : super(key: key);

  @override
  _CreateLabSessionScreenState createState() => _CreateLabSessionScreenState();
}

class _CreateLabSessionScreenState extends State<CreateLabSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final LabService _labService = LabService();
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
  int numberOfExperiments = 10;
  
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

  Future<void> _createLabSession() async {
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
          content: const Text('No students found for this class. Do you want to create the lab session anyway?'),
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
      
      if (confirmNoStudents != true) return;
    }
    
    setState(() {
      isLoading = true;
    });
    
    try {
      final newLabSession = LabSession.create(
        subjectId: selectedSubject!.id,
        subjectName: selectedSubject!.name,
        branch: selectedBranch!,
        year: selectedYear!,
        section: selectedSection!,
        numberOfExperiments: numberOfExperiments,
        students: studentIds,
      );
      
      await _labService.createLabSession(newLabSession);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lab session created successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        _error = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating lab session: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Lab Session'),
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
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSubjects,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          const SizedBox(height: 16),
                          
                          // Number of experiments
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Number of Experiments',
                              hintText: 'Enter number of experiments',
                              border: OutlineInputBorder(),
                            ),
                            initialValue: numberOfExperiments.toString(),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                numberOfExperiments = int.tryParse(value) ?? 10;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter number of experiments';
                              }
                              final number = int.tryParse(value);
                              if (number == null || number < 1) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          const Text(
                            'Class Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
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
                          const SizedBox(height: 16),
                          
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
                            )
                          else if (studentIds.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: const Text(
                                'No students loaded. Please select branch, year, and section, then click "Load Students".',
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
                              onPressed: isLoading ? null : _createLabSession,
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
                              label: const Text('Create Lab Session'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
