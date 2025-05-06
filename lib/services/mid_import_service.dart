import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:markpro_plus/services/mid_service.dart';

// Result model for storing import results
class AllMidMarksImportResult {
  final List<Map<String, dynamic>> mid1Marks;
  final List<Map<String, dynamic>> mid2Marks;
  final bool hasMid1Data;
  final bool hasMid2Data;
  
  AllMidMarksImportResult({
    required this.mid1Marks,
    required this.mid2Marks,
    required this.hasMid1Data,
    required this.hasMid2Data,
  });
}

class MidImportService {
  final MidService _midService = MidService();
  
  // Import Mid 1 marks from Excel file
  Future<List<Map<String, dynamic>>> importMid1MarksFromExcel(BuildContext context) async {
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
      return await _parseMid1ExcelFile(bytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing Mid 1 marks: $e')),
      );
      return [];
    }
  }

  // Import Mid 2 marks from Excel file
  Future<List<Map<String, dynamic>>> importMid2MarksFromExcel(BuildContext context) async {
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
      return await _parseMid2ExcelFile(bytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing Mid 2 marks: $e')),
      );
      return [];
    }
  }
  
  // Import both Mid 1 and Mid 2 marks from a single Excel file with multiple sheets
  Future<AllMidMarksImportResult> importAllMidMarksFromExcel(BuildContext context) async {
    try {
      // Open file picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.single.bytes == null) {
        return AllMidMarksImportResult(
          mid1Marks: [],
          mid2Marks: [],
          hasMid1Data: false,
          hasMid2Data: false,
        );
      }

      // Get the file as bytes
      final bytes = result.files.single.bytes!;
      
      // Parse the Excel file for both Mid 1 and Mid 2 marks
      return await _parseAllMidMarksExcelFile(bytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing all Mid marks: $e')),
      );
      return AllMidMarksImportResult(
        mid1Marks: [],
        mid2Marks: [],
        hasMid1Data: false,
        hasMid2Data: false,
      );
    }
  }

  // Parse Excel file for Mid 1 marks
  Future<List<Map<String, dynamic>>> _parseMid1ExcelFile(Uint8List bytes) async {
    final marks = <Map<String, dynamic>>[];
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
      _validateRequiredHeadersForMid1(headers);
      
      // Process each row
      for (var rowIndex = 1; rowIndex < table.rows.length; rowIndex++) {
        final row = table.rows[rowIndex];
        
        // Skip empty rows
        if (row.isEmpty || row.every((cell) => cell?.value == null)) {
          continue;
        }
        
        try {
          // Create mark map from row
          final mark = _createMid1MarkMapFromRow(headers, row, rowIndex);
          marks.add(mark);
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
      
      return marks;
    } catch (e) {
      throw Exception('Failed to parse Excel file: $e');
    }
  }
  
  // Parse Excel file for Mid 2 marks
  Future<List<Map<String, dynamic>>> _parseMid2ExcelFile(Uint8List bytes) async {
    final marks = <Map<String, dynamic>>[];
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
      _validateRequiredHeadersForMid2(headers);
      
      // Process each row
      for (var rowIndex = 1; rowIndex < table.rows.length; rowIndex++) {
        final row = table.rows[rowIndex];
        
        // Skip empty rows
        if (row.isEmpty || row.every((cell) => cell?.value == null)) {
          continue;
        }
        
        try {
          // Create mark map from row
          final mark = _createMid2MarkMapFromRow(headers, row, rowIndex);
          marks.add(mark);
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
      
      return marks;
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

  // Validate required headers for Mid 1
  void _validateRequiredHeadersForMid1(List<String> headers) {
    // Define standard headers used in export (case insensitive)
    final requiredHeaders = [
      'student id',
      'name',
      'descriptive',
      'objective'
    ];
    
    // Also accept alternate forms of headers
    final alternateHeaders = {
      'student id': ['studentid', 'student_id', 'roll no', 'id', 'roll number'],
      'descriptive': ['descriptive marks', 'desc', 'theory', 'written'],
      'objective': ['objective marks', 'obj', 'practical', 'mcq']
    };
    
    // Normalize headers to lowercase for comparison
    final normalizedHeaders = headers.map((h) => h.toLowerCase()).toList();
    
    // Check for missing headers
    final missingHeaders = <String>[];
    
    for (final required in requiredHeaders) {
      final alternates = alternateHeaders[required] ?? [];
      if (!normalizedHeaders.contains(required.toLowerCase()) && 
          !alternates.any((alt) => normalizedHeaders.contains(alt.toLowerCase()))) {
        missingHeaders.add(required);
      }
    }
    
    if (missingHeaders.isNotEmpty) {
      throw Exception('Missing required headers: ${missingHeaders.join(', ')}');
    }
  }
  
  // Validate required headers for Mid 2
  void _validateRequiredHeadersForMid2(List<String> headers) {
    // Define standard headers used in export (case insensitive)
    final requiredHeaders = [
      'student id',
      'name',
      'descriptive', 
      'objective'
    ];
    
    // Also accept alternate forms of headers
    final alternateHeaders = {
      'student id': ['studentid', 'student_id', 'roll no', 'id', 'roll number'],
      'descriptive': ['descriptive marks', 'desc', 'theory', 'written'],
      'objective': ['objective marks', 'obj', 'practical', 'mcq']
    };
    
    // Normalize headers to lowercase for comparison
    final normalizedHeaders = headers.map((h) => h.toLowerCase()).toList();
    
    // Check for missing headers
    final missingHeaders = <String>[];
    
    for (final required in requiredHeaders) {
      final alternates = alternateHeaders[required] ?? [];
      if (!normalizedHeaders.contains(required.toLowerCase()) && 
          !alternates.any((alt) => normalizedHeaders.contains(alt.toLowerCase()))) {
        missingHeaders.add(required);
      }
    }
    
    if (missingHeaders.isNotEmpty) {
      throw Exception('Missing required headers: ${missingHeaders.join(', ')}');
    }
  }

  // Create mark map from row for Mid 1
  Map<String, dynamic> _createMid1MarkMapFromRow(
    List<String> headers, 
    List<dynamic> row,
    int rowIndex
  ) {
    // Create initial map from headers and row values
    final rowData = <String, dynamic>{};
    for (var i = 0; i < headers.length && i < row.length; i++) {
      if (row[i]?.value != null) {
        rowData[headers[i]] = row[i]!.value.toString().trim();
      }
    }
    
    // Validate required data
    _validateMid1MarkData(rowData, rowIndex);
    
    // Extract student ID
    String studentId = '';
    for (final key in ['student id', 'studentid', 'student_id', 'roll no', 'id', 'roll number']) {
      if (rowData.containsKey(key) && rowData[key] != null) {
        studentId = rowData[key].toString();
        break;
      }
    }
    
    // Extract descriptive marks
    double descriptiveMarks = 0.0;
    for (final key in ['descriptive', 'descriptive marks', 'desc', 'theory', 'written']) {
      if (rowData.containsKey(key) && rowData[key] != null) {
        descriptiveMarks = _parseDoubleSafely(rowData[key].toString());
        break;
      }
    }
    
    // Extract objective marks
    double objectiveMarks = 0.0;
    for (final key in ['objective', 'objective marks', 'obj', 'practical', 'mcq']) {
      if (rowData.containsKey(key) && rowData[key] != null) {
        objectiveMarks = _parseDoubleSafely(rowData[key].toString());
        break;
      }
    }
    
    // Total should be ignored from import - we calculate it
    double total = descriptiveMarks + objectiveMarks;
    
    // Get name
    final name = rowData['name']?.toString() ?? 'Unknown';
    
    // Create standardized mark map
    return {
      'studentId': studentId,
      'name': name,
      'descriptive': descriptiveMarks,
      'objective': objectiveMarks,
      'total': total  // Calculated total
    };
  }
  
  // Create mark map from row for Mid 2
  Map<String, dynamic> _createMid2MarkMapFromRow(
    List<String> headers, 
    List<dynamic> row,
    int rowIndex
  ) {
    // Create initial map from headers and row values
    final rowData = <String, dynamic>{};
    for (var i = 0; i < headers.length && i < row.length; i++) {
      if (row[i]?.value != null) {
        rowData[headers[i]] = row[i]!.value.toString().trim();
      }
    }
    
    // Validate required data
    _validateMid2MarkData(rowData, rowIndex);
    
    // Extract student ID
    String studentId = '';
    for (final key in ['student id', 'studentid', 'student_id', 'roll no', 'id', 'roll number']) {
      if (rowData.containsKey(key) && rowData[key] != null) {
        studentId = rowData[key].toString();
        break;
      }
    }
    
    // Extract descriptive marks
    double descriptiveMarks = 0.0;
    for (final key in ['descriptive', 'descriptive marks', 'desc', 'theory', 'written']) {
      if (rowData.containsKey(key) && rowData[key] != null) {
        descriptiveMarks = _parseDoubleSafely(rowData[key].toString());
        break;
      }
    }
    
    // Extract objective marks
    double objectiveMarks = 0.0;
    for (final key in ['objective', 'objective marks', 'obj', 'practical', 'mcq']) {
      if (rowData.containsKey(key) && rowData[key] != null) {
        objectiveMarks = _parseDoubleSafely(rowData[key].toString());
        break;
      }
    }
    
    // Total should be ignored from import - we calculate it
    double total = descriptiveMarks + objectiveMarks;
    
    // Get name
    final name = rowData['name']?.toString() ?? 'Unknown';
    
    // Create standardized mark map
    return {
      'studentId': studentId,
      'name': name,
      'descriptive': descriptiveMarks,
      'objective': objectiveMarks,
      'total': total  // Calculated total
    };
  }

  // Validate Mid 1 mark data
  void _validateMid1MarkData(Map<String, dynamic> mark, int rowIndex) {
    // Check for student ID using different possible headers
    bool hasStudentId = false;
    for (final key in ['student id', 'studentid', 'student_id', 'roll no', 'id', 'roll number']) {
      if (mark.containsKey(key) && mark[key] != null && mark[key].toString().isNotEmpty) {
        hasStudentId = true;
        // Validate student ID format (should be at least 5 characters)
        if (mark[key].toString().length < 5) {
          throw Exception('Student ID should be at least 5 characters long in row ${rowIndex + 1}');
        }
        break;
      }
    }
    
    if (!hasStudentId) {
      throw Exception('Missing Student ID in row ${rowIndex + 1}');
    }
    
    // Check for name
    if (!mark.containsKey('name') || mark['name'] == null || mark['name'].toString().isEmpty) {
      throw Exception('Missing student name in row ${rowIndex + 1}');
    }
    
    // Check for descriptive marks
    bool hasDescriptiveMarks = false;
    for (final key in ['descriptive', 'descriptive marks', 'desc', 'theory', 'written']) {
      if (mark.containsKey(key) && mark[key] != null) {
        hasDescriptiveMarks = true;
        try {
          final value = double.parse(mark[key].toString());
          if (value < 0 || value > 20) {  // Descriptive marks are typically 0-20
            throw Exception('Descriptive marks must be between 0 and 20 in row ${rowIndex + 1}');
          }
        } catch (e) {
          throw Exception('Descriptive marks must be a number in row ${rowIndex + 1}');
        }
        break;
      }
    }
    
    if (!hasDescriptiveMarks) {
      throw Exception('Missing descriptive marks in row ${rowIndex + 1}');
    }
    
    // Check for objective marks
    bool hasObjectiveMarks = false;
    for (final key in ['objective', 'objective marks', 'obj', 'practical', 'mcq']) {
      if (mark.containsKey(key) && mark[key] != null) {
        hasObjectiveMarks = true;
        try {
          final value = double.parse(mark[key].toString());
          if (value < 0 || value > 10) {  // Objective marks are typically 0-10
            throw Exception('Objective marks must be between 0 and 10 in row ${rowIndex + 1}');
          }
        } catch (e) {
          throw Exception('Objective marks must be a number in row ${rowIndex + 1}');
        }
        break;
      }
    }
    
    if (!hasObjectiveMarks) {
      throw Exception('Missing objective marks in row ${rowIndex + 1}');
    }
  }
  
  // Validate Mid 2 mark data
  void _validateMid2MarkData(Map<String, dynamic> mark, int rowIndex) {
    // Check for student ID using different possible headers
    bool hasStudentId = false;
    for (final key in ['student id', 'studentid', 'student_id', 'roll no', 'id', 'roll number']) {
      if (mark.containsKey(key) && mark[key] != null && mark[key].toString().isNotEmpty) {
        hasStudentId = true;
        // Validate student ID format (should be at least 5 characters)
        if (mark[key].toString().length < 5) {
          throw Exception('Student ID should be at least 5 characters long in row ${rowIndex + 1}');
        }
        break;
      }
    }
    
    if (!hasStudentId) {
      throw Exception('Missing Student ID in row ${rowIndex + 1}');
    }
    
    // Check for name
    if (!mark.containsKey('name') || mark['name'] == null || mark['name'].toString().isEmpty) {
      throw Exception('Missing student name in row ${rowIndex + 1}');
    }
    
    // Check for descriptive marks
    bool hasDescriptiveMarks = false;
    for (final key in ['descriptive', 'descriptive marks', 'desc', 'theory', 'written']) {
      if (mark.containsKey(key) && mark[key] != null) {
        hasDescriptiveMarks = true;
        try {
          final value = double.parse(mark[key].toString());
          if (value < 0 || value > 20) {  // Descriptive marks are typically 0-20
            throw Exception('Descriptive marks must be between 0 and 20 in row ${rowIndex + 1}');
          }
        } catch (e) {
          throw Exception('Descriptive marks must be a number in row ${rowIndex + 1}');
        }
        break;
      }
    }
    
    if (!hasDescriptiveMarks) {
      throw Exception('Missing descriptive marks in row ${rowIndex + 1}');
    }
    
    // Check for objective marks
    bool hasObjectiveMarks = false;
    for (final key in ['objective', 'objective marks', 'obj', 'practical', 'mcq']) {
      if (mark.containsKey(key) && mark[key] != null) {
        hasObjectiveMarks = true;
        try {
          final value = double.parse(mark[key].toString());
          if (value < 0 || value > 10) {  // Objective marks are typically 0-10
            throw Exception('Objective marks must be between 0 and 10 in row ${rowIndex + 1}');
          }
        } catch (e) {
          throw Exception('Objective marks must be a number in row ${rowIndex + 1}');
        }
        break;
      }
    }
    
    if (!hasObjectiveMarks) {
      throw Exception('Missing objective marks in row ${rowIndex + 1}');
    }
  }
  
  // Save imported Mid 1 marks
  Future<void> saveImportedMid1Marks({
    required String midSessionId,
    required List<Map<String, dynamic>> marks,
  }) async {
    for (final mark in marks) {
      try {
        await _midService.updateMid1Marks(
          midSessionId: midSessionId,
          studentId: mark['studentId'],
          descriptive: mark['descriptive'],
          objective: mark['objective'],
        );
      } catch (e) {
        print('Error saving Mid 1 marks for student ${mark['studentId']}: $e');
        // Continue with other students even if one fails
      }
    }
  }
  
  // Save imported Mid 2 marks
  Future<void> saveImportedMid2Marks({
    required String midSessionId,
    required List<Map<String, dynamic>> marks,
  }) async {
    for (final mark in marks) {
      try {
        await _midService.updateMid2Marks(
          midSessionId: midSessionId,
          studentId: mark['studentId'],
          descriptive: mark['descriptive'],
          objective: mark['objective'],
        );
      } catch (e) {
        print('Error saving Mid 2 marks for student ${mark['studentId']}: $e');
        // Continue with other students even if one fails
      }
    }
  }
  
  // Save both imported Mid 1 and Mid 2 marks
  Future<void> saveAllImportedMidMarks({
    required String midSessionId,
    required List<Map<String, dynamic>> mid1Marks,
    required List<Map<String, dynamic>> mid2Marks,
  }) async {
    // Save Mid 1 marks first
    if (mid1Marks.isNotEmpty) {
      await saveImportedMid1Marks(
        midSessionId: midSessionId,
        marks: mid1Marks,
      );
    }
    
    // Then save Mid 2 marks
    if (mid2Marks.isNotEmpty) {
      await saveImportedMid2Marks(
        midSessionId: midSessionId,
        marks: mid2Marks,
      );
    }
  }
  
  // Parse Excel file for both Mid 1 and Mid 2 marks from multiple sheets
  Future<AllMidMarksImportResult> _parseAllMidMarksExcelFile(Uint8List bytes) async {
    final mid1Marks = <Map<String, dynamic>>[];
    final mid2Marks = <Map<String, dynamic>>[];
    final validationErrors = <String>[];
    bool hasMid1Data = false;
    bool hasMid2Data = false;
    
    try {
      // Decode the Excel file
      final excel = Excel.decodeBytes(bytes);
      
      // Check if the file has any sheets
      if (excel.tables.isEmpty) {
        throw Exception('No sheets found in the Excel file');
      }
      
      // Look for Mid 1, Mid 2 or similarly named sheets
      final sheetNames = excel.tables.keys.toList();
      
      // First, look for sheets with exact names
      String? mid1SheetName;
      String? mid2SheetName;
      
      for (final name in sheetNames) {
        final lowerName = name.toLowerCase();
        if (lowerName.contains('mid 1') || lowerName.contains('mid1')) {
          mid1SheetName = name;
        } else if (lowerName.contains('mid 2') || lowerName.contains('mid2')) {
          mid2SheetName = name;
        }
      }
      
      // If not found, try to use the first two sheets
      if (mid1SheetName == null && sheetNames.length >= 1) {
        mid1SheetName = sheetNames[0];
      }
      
      if (mid2SheetName == null && sheetNames.length >= 2) {
        mid2SheetName = sheetNames[1];
      }
      
      // Process Mid 1 sheet if available
      if (mid1SheetName != null) {
        final table = excel.tables[mid1SheetName];
        
        if (table != null && table.rows.isNotEmpty) {
          try {
            // Get headers from the first row
            final headers = _extractHeaderRow(table.rows[0]);
            
            // Try to validate the headers for Mid 1
            try {
              _validateRequiredHeadersForMid1(headers);
              
              // Process each row in the Mid 1 sheet
              for (var rowIndex = 1; rowIndex < table.rows.length; rowIndex++) {
                final row = table.rows[rowIndex];
                
                // Skip empty rows
                if (row.isEmpty || row.every((cell) => cell?.value == null)) {
                  continue;
                }
                
                try {
                  // Create mark map from row
                  final mark = _createMid1MarkMapFromRow(headers, row, rowIndex);
                  mid1Marks.add(mark);
                } catch (e) {
                  validationErrors.add('Error in Mid 1 sheet, row ${rowIndex + 1}: $e');
                }
              }
              
              hasMid1Data = mid1Marks.isNotEmpty;
            } catch (e) {
              validationErrors.add('Mid 1 sheet validation error: $e');
            }
          } catch (e) {
            validationErrors.add('Error processing Mid 1 sheet: $e');
          }
        }
      }
      
      // Process Mid 2 sheet if available
      if (mid2SheetName != null) {
        final table = excel.tables[mid2SheetName];
        
        if (table != null && table.rows.isNotEmpty) {
          try {
            // Get headers from the first row
            final headers = _extractHeaderRow(table.rows[0]);
            
            // Try to validate the headers for Mid 2
            try {
              _validateRequiredHeadersForMid2(headers);
              
              // Process each row in the Mid 2 sheet
              for (var rowIndex = 1; rowIndex < table.rows.length; rowIndex++) {
                final row = table.rows[rowIndex];
                
                // Skip empty rows
                if (row.isEmpty || row.every((cell) => cell?.value == null)) {
                  continue;
                }
                
                try {
                  // Create mark map from row
                  final mark = _createMid2MarkMapFromRow(headers, row, rowIndex);
                  mid2Marks.add(mark);
                } catch (e) {
                  validationErrors.add('Error in Mid 2 sheet, row ${rowIndex + 1}: $e');
                }
              }
              
              hasMid2Data = mid2Marks.isNotEmpty;
            } catch (e) {
              validationErrors.add('Mid 2 sheet validation error: $e');
            }
          } catch (e) {
            validationErrors.add('Error processing Mid 2 sheet: $e');
          }
        }
      }
      
      // If there are validation errors and no valid data was found, throw an exception
      if (validationErrors.isNotEmpty && !hasMid1Data && !hasMid2Data) {
        throw Exception(
          'Validation errors in Excel file:\n${validationErrors.join('\n')}'
        );
      }
      
      return AllMidMarksImportResult(
        mid1Marks: mid1Marks,
        mid2Marks: mid2Marks,
        hasMid1Data: hasMid1Data,
        hasMid2Data: hasMid2Data,
      );
    } catch (e) {
      throw Exception('Failed to parse Excel file: $e');
    }
  }
  
  // Helper to safely parse doubles
  double _parseDoubleSafely(String value) {
    if (value.isEmpty) return 0.0;
    // First, try to parse as-is
    double? result = double.tryParse(value);
    if (result != null) return result;
    
    // If that fails, try extracting only numeric characters with a decimal point
    final numericOnly = value.replaceAll(RegExp(r'[^0-9.]'), '');
    if (numericOnly.isNotEmpty) {
      result = double.tryParse(numericOnly);
      if (result != null) return result;
    }
    
    // Default fallback
    return 0.0;
  }
}
