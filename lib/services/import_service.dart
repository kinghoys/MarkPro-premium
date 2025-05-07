import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:markpro_plus/models/student_model.dart';

class ImportService {
  // Import students from Excel file
  Future<List<Map<String, dynamic>>> importStudentsFromExcel(BuildContext context) async {
    try {
      // Open file picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.single.bytes == null) {
        return [];
      }

      // Get the file as bytes
      final bytes = result.files.single.bytes!;
      
      // Parse the Excel file
      return await _parseStudentExcelFile(bytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing students: $e')),
      );
      return [];
    }
  }

  // Parse Excel file and convert to list of student maps
  Future<List<Map<String, dynamic>>> _parseStudentExcelFile(Uint8List bytes) async {
    final students = <Map<String, dynamic>>[];
    final validationErrors = <String>[];
    
    try {
      // Decode the Excel file
      final excel = Excel.decodeBytes(bytes);
      
      // Get the first sheet
      final sheet = excel.tables.keys.first;
      final table = excel.tables[sheet];
      
      if (table == null || table.rows.isEmpty) {
        throw Exception('No data found in the Excel file');
      }
      
      // Get headers from the first row
      final headers = _extractHeaderRow(table.rows[0]);
      
      // Validate required headers
      _validateRequiredHeaders(headers);
      
      // Process each row
      for (var rowIndex = 1; rowIndex < table.rows.length; rowIndex++) {
        final row = table.rows[rowIndex];
        
        // Skip empty rows
        if (row.isEmpty || row.every((cell) => cell?.value == null)) {
          continue;
        }
        
        try {
          // Create student map from row
          final student = _createStudentMapFromRow(headers, row, rowIndex);
          students.add(student);
        } catch (e) {
          validationErrors.add('Error in row ${rowIndex + 1}: $e');
        }
      }
      
      // If there are validation errors, throw an exception
      if (validationErrors.isNotEmpty) {
        throw Exception(
          'Validation errors in Excel file:\n${validationErrors.join('\n')}'
        );
      }
      
      return students;
    } catch (e) {
      throw Exception('Failed to parse Excel file: $e');
    }
  }

  // Extract header row from Excel
  List<String> _extractHeaderRow(List<dynamic> headerRow) {
    return headerRow
        .where((cell) => cell?.value != null)
        .map((cell) => cell!.value.toString().toLowerCase().trim())
        .toList();
  }

  // Validate that required headers are present
  void _validateRequiredHeaders(List<String> headers) {
    const requiredHeaders = [
      'studentid', 
      'name', 
      'branch', 
      'year', 
      'section'
    ];
    
    final missingHeaders = requiredHeaders
        .where((header) => !headers.contains(header))
        .toList();
    
    if (missingHeaders.isNotEmpty) {
      throw Exception(
        'Missing required headers: ${missingHeaders.join(', ')}'
      );
    }
  }

  // Create student map from Excel row
  Map<String, dynamic> _createStudentMapFromRow(
    List<String> headers, 
    List<dynamic> row,
    int rowIndex
  ) {
    final studentMap = <String, dynamic>{};
    
    // Map each cell to the corresponding header
    for (var i = 0; i < headers.length && i < row.length; i++) {
      final header = headers[i];
      final cell = row[i];
      
      if (cell?.value != null) {
        studentMap[header] = cell!.value.toString().trim();
      }
    }
    
    // Validate required fields
    _validateStudentData(studentMap, rowIndex);
    
    // Create standardized student map
    return {
      'id': studentMap['studentid'],
      'name': studentMap['name'],
      'rollNo': studentMap['studentid'],
      'branch': studentMap['branch'],
      'year': int.parse(studentMap['year'].toString()),
      'section': studentMap['section'],
    };
  }

  // Validate student data
  void _validateStudentData(Map<String, dynamic> student, int rowIndex) {
    // Check for required fields
    final requiredFields = ['studentid', 'name', 'branch', 'year', 'section'];
    
    for (final field in requiredFields) {
      if (!student.containsKey(field) || student[field] == null || student[field].toString().isEmpty) {
        throw Exception('Missing required field: $field in row ${rowIndex + 1}');
      }
    }
    
    // Validate student ID format
    final studentId = student['studentid'].toString();
    if (studentId.length < 5) {
      throw Exception('Invalid student ID format in row ${rowIndex + 1}');
    }
    
    // Validate year as number
    try {
      final year = int.parse(student['year'].toString());
      if (year < 1 || year > 5) {
        throw Exception('Year must be between 1 and 5 in row ${rowIndex + 1}');
      }
    } catch (e) {
      throw Exception('Year must be a number in row ${rowIndex + 1}');
    }
  }

  // Create StudentModel objects from the parsed data
  List<StudentModel> createStudentModels(List<Map<String, dynamic>> studentMaps) {
    final currentYear = DateTime.now().year;
    final nextYear = currentYear + 1;
    final academicYear = '$currentYear-$nextYear';
    
    return studentMaps.map((map) => StudentModel(
      id: map['id'],
      name: map['name'],
      rollNo: map['rollNo'],
      branch: map['branch'],
      year: map['year'],
      section: map['section'],
      semester: 1, // Default to semester 1
      academicYear: academicYear,
    )).toList();
  }
}
