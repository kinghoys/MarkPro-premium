import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:universal_html/html.dart' as html;
import 'package:markpro_plus/models/lab_session.dart';
import 'package:markpro_plus/models/mid_session.dart';
import 'package:markpro_plus/models/assignment_session.dart';
import 'package:markpro_plus/models/seminar_session.dart';
import 'package:markpro_plus/models/student_model.dart';

class ExportService {
  // Helper method to create Excel workbook and get the default sheet name
  Excel createExcel() {
    // Create a brand new workbook
    return Excel.createExcel();
  }
  
  // Get the default sheet name (typically 'Sheet1')
  String getDefaultSheetName(Excel excel) {
    return excel.getDefaultSheet() ?? 'Sheet1';
  }
  
  // Export experiment marks for a specific experiment
  Future<void> exportExperimentMarks({
    required LabSession labSession,
    required String experimentNumber,
    required List<StudentModel> students,
  }) async {
    try {
      // Create a new Excel workbook
      final excel = createExcel();
      
      // Get the default sheet and rename it to match our content
      final defaultSheet = getDefaultSheetName(excel);
      final sheetName = 'Experiment $experimentNumber Marks';
      excel.rename(defaultSheet, sheetName);
      final sheet = excel[sheetName];
      
      // Add headers
      final headers = [
        'Student ID',
        'Name',
        'Component A',
        'Component B', 
        'Component C',
        'Total Marks'
      ];
      
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
      }
      
      // Add data
      var rowIndex = 1;
      for (final student in students) {
        final studentId = student.rollNo; // Use rollNo instead of id as the key
        final experimentMarks = labSession.experimentMarks[studentId]?[experimentNumber];
        
        final markA = experimentMarks?['A'] ?? 0;
        final markB = experimentMarks?['B'] ?? 0;
        final markC = experimentMarks?['C'] ?? 0;
        final total = experimentMarks?['total'] ?? 0;
        
        // Add student data
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          ..value = TextCellValue(student.rollNo);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          ..value = TextCellValue(student.name);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          ..value = IntCellValue(markA is int ? markA : 0);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          ..value = IntCellValue(markB is int ? markB : 0);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          ..value = IntCellValue(markC is int ? markC : 0);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          ..value = IntCellValue(total is int ? total : 0);
        
        rowIndex++;
      }
      
      // Auto-fit columns
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 15);
      }
      
      // Generate the Excel file as bytes
      final bytes = excel.encode();
      
      // Download the file
      if (bytes != null) {
        final uint8list = Uint8List.fromList(bytes);
        // Create a more descriptive filename with subject, branch, year and section
        final filename = '${labSession.subjectName}_${labSession.branch}_${labSession.year}_${labSession.section}_Experiment${experimentNumber}.xlsx';
        _downloadExcelFile(uint8list, filename);
      }
    } catch (e) {
      throw Exception('Failed to export experiment marks: $e');
    }
  }
  
  // Export all experiment marks
  Future<void> exportAllExperimentMarks({
    required LabSession labSession,
    required List<StudentModel> students,
  }) async {
    try {
      // Create a new Excel workbook
      final excel = createExcel();
      
      // Get the default sheet and rename it for the first experiment
      final defaultSheet = getDefaultSheetName(excel);
      final firstSheetName = 'Experiment 1';
      excel.rename(defaultSheet, firstSheetName);
      
      // Create a sheet for each experiment
      for (var i = 1; i <= labSession.numberOfExperiments; i++) {
        final experimentNumber = i.toString();
        final sheetName = 'Experiment $experimentNumber';
        final sheet = excel[sheetName];
        
        // Add headers
        final headers = [
          'Student ID',
          'Name',
          'Component A',
          'Component B', 
          'Component C',
          'Total Marks'
        ];
        
        for (var j = 0; j < headers.length; j++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: 0))
            ..value = TextCellValue(headers[j])
            ..cellStyle = CellStyle(
              bold: true,
              horizontalAlign: HorizontalAlign.Center,
            );
        }
        
        // Add data
        var rowIndex = 1;
        for (final student in students) {
          final studentId = student.rollNo; // IMPORTANT: Must use rollNo (not id) as key
          final experimentMarks = labSession.experimentMarks[studentId]?[experimentNumber];
          
          final markA = experimentMarks?['A'] ?? 0;
          final markB = experimentMarks?['B'] ?? 0;
          final markC = experimentMarks?['C'] ?? 0;
          final total = experimentMarks?['total'] ?? 0;
          
          // Add student data
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            ..value = TextCellValue(student.rollNo);
          
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            ..value = TextCellValue(student.name);
          
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
            ..value = IntCellValue(markA is int ? markA : 0);
          
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
            ..value = IntCellValue(markB is int ? markB : 0);
          
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
            ..value = IntCellValue(markC is int ? markC : 0);
          
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
            ..value = IntCellValue(total is int ? total : 0);
          
          rowIndex++;
        }
        
        // Auto-fit columns
        for (var j = 0; j < headers.length; j++) {
          sheet.setColumnWidth(j, 15);
        }
      }
      
      // Add Internal Marks sheet
      final internalSheet = excel['Internal Marks'];
      
      // Add headers
      final internalHeaders = [
        'Student ID',
        'Name',
        'Internal 1',
        'Internal 2',
      ];
      
      for (var i = 0; i < internalHeaders.length; i++) {
        internalSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(internalHeaders[i])
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
      }
      
      // Add Internal marks data
      var internalRowIndex = 1;
      for (final student in students) {
        final studentId = student.rollNo; // Use rollNo instead of id as the key
        final internal1Mark = labSession.internalMarks['1']?[studentId] ?? 0;
        final internal2Mark = labSession.internalMarks['2']?[studentId] ?? 0;
        
        // Add student data
        internalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: internalRowIndex))
          ..value = TextCellValue(student.rollNo);
        
        internalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: internalRowIndex))
          ..value = TextCellValue(student.name);
        
        internalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: internalRowIndex))
          ..value = IntCellValue(internal1Mark);
        
        internalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: internalRowIndex))
          ..value = IntCellValue(internal2Mark);
        
        internalRowIndex++;
      }
      
      // Auto-fit columns
      for (var i = 0; i < internalHeaders.length; i++) {
        internalSheet.setColumnWidth(i, 15);
      }
      
      // Add M1/M2 sheet
      final m1m2Sheet = excel['M1 M2 Marks'];
      
      // Add headers
      final m1m2Headers = [
        'Student ID',
        'Name',
        'M1 Marks',
        'M2 Marks',
      ];
      
      for (var i = 0; i < m1m2Headers.length; i++) {
        m1m2Sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(m1m2Headers[i])
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
      }
      
      // Add M1/M2 data
      var m1m2RowIndex = 1;
      for (final student in students) {
        final studentId = student.rollNo; // Use rollNo instead of id as the key
        final m1Mark = labSession.m1Marks[studentId] ?? 0.0;
        final m2Mark = labSession.m2Marks[studentId] ?? 0.0;
        
        // Add student data
        m1m2Sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: m1m2RowIndex))
          ..value = TextCellValue(student.rollNo);
        
        m1m2Sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: m1m2RowIndex))
          ..value = TextCellValue(student.name);
        
        m1m2Sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: m1m2RowIndex))
          ..value = DoubleCellValue(m1Mark);
        
        m1m2Sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: m1m2RowIndex))
          ..value = DoubleCellValue(m2Mark);
        
        m1m2RowIndex++;
      }
      
      // Auto-fit columns
      for (var i = 0; i < m1m2Headers.length; i++) {
        m1m2Sheet.setColumnWidth(i, 15);
      }
      
      // Add Viva & Final Grade sheet
      final finalSheet = excel['Final Assessment'];
      
      // Add headers
      final finalHeaders = [
        'Student ID',
        'Name',
        'Viva Marks',
        'Final Lab Grade',
      ];
      
      for (var i = 0; i < finalHeaders.length; i++) {
        finalSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(finalHeaders[i])
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
      }
      
      // Add Final data
      var finalRowIndex = 1;
      for (final student in students) {
        final studentId = student.rollNo; // Use rollNo instead of id as the key
        final vivaMarks = labSession.vivaMarks[studentId] ?? 0;
        final finalGrade = labSession.finalLabMarks[studentId] ?? 0.0;
        
        // Add student data
        finalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: finalRowIndex))
          ..value = TextCellValue(student.rollNo);
        
        finalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: finalRowIndex))
          ..value = TextCellValue(student.name);
        
        finalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: finalRowIndex))
          ..value = IntCellValue(vivaMarks);
        
        finalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: finalRowIndex))
          ..value = DoubleCellValue(finalGrade);
        
        finalRowIndex++;
      }
      
      // Auto-fit columns
      for (var i = 0; i < finalHeaders.length; i++) {
        finalSheet.setColumnWidth(i, 15);
      }
      
      // Generate the Excel file as bytes
      final bytes = excel.encode();
      
      // Download the file
      if (bytes != null) {
        final uint8list = Uint8List.fromList(bytes);
        // Create a more descriptive filename with subject, branch, year and section
        final filename = '${labSession.subjectName}_${labSession.branch}_${labSession.year}_${labSession.section}_Complete_Marks_Data.xlsx';
        _downloadExcelFile(uint8list, filename);
      }
    } catch (e) {
      throw Exception('Failed to export all experiment marks: $e');
    }
  }
  
  // Export internal marks
  Future<void> exportInternalMarks({
    required LabSession labSession,
    required List<StudentModel> students,
  }) async {
    try {
      // Create a new Excel workbook
      final excel = createExcel();
      
      // Get the default sheet and rename it for internal marks
      final defaultSheet = getDefaultSheetName(excel);
      final sheetName = 'Internal Marks';
      excel.rename(defaultSheet, sheetName);
      final sheet = excel[sheetName];
      
      // Add headers
      final headers = [
        'Student ID',
        'Name',
        'Internal 1',
        'Internal 2',
      ];
      
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
      }
      
      // Add data
      var rowIndex = 1;
      for (final student in students) {
        final studentId = student.rollNo; // Use rollNo instead of id as the key
        final internal1Mark = labSession.internalMarks['1']?[studentId] ?? 0;
        final internal2Mark = labSession.internalMarks['2']?[studentId] ?? 0;
        
        // Add student data
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          ..value = TextCellValue(student.rollNo);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          ..value = TextCellValue(student.name);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          ..value = IntCellValue(internal1Mark);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          ..value = IntCellValue(internal2Mark);
        
        rowIndex++;
      }
      
      // Auto-fit columns
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 15);
      }
      
      // Generate the Excel file as bytes
      final bytes = excel.encode();
      
      // Download the file
      if (bytes != null) {
        final uint8list = Uint8List.fromList(bytes);
        // Create a more descriptive filename with subject, branch, year and section
        final filename = '${labSession.subjectName}_${labSession.branch}_${labSession.year}_${labSession.section}_Internal_Marks.xlsx';
        _downloadExcelFile(uint8list, filename);
      }
    } catch (e) {
      throw Exception('Failed to export internal marks: $e');
    }
  }
  
  // Export M1/M2 marks only
  Future<void> exportM1M2Marks({
    required LabSession labSession,
    required List<StudentModel> students,
  }) async {
    try {
      // Create a new Excel workbook
      final excel = createExcel();
      
      // Get the default sheet and rename it for M1 M2 marks
      final defaultSheet = getDefaultSheetName(excel);
      final sheetName = 'M1 M2 Marks';
      excel.rename(defaultSheet, sheetName);
      final sheet = excel[sheetName];
      
      // Add headers
      final headers = [
        'Student ID',
        'Name',
        'M1 Marks',
        'M2 Marks',
      ];
      
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
      }
      
      // Add data
      var rowIndex = 1;
      for (final student in students) {
        final studentId = student.rollNo; // Use rollNo instead of id as the key
        final m1Mark = labSession.m1Marks[studentId] ?? 0.0;
        final m2Mark = labSession.m2Marks[studentId] ?? 0.0;
        
        // Add student data
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          ..value = TextCellValue(student.rollNo);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          ..value = TextCellValue(student.name);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          ..value = DoubleCellValue(m1Mark);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          ..value = DoubleCellValue(m2Mark);
        
        rowIndex++;
      }
      
      // Auto-fit columns
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 15);
      }
      
      // Generate the Excel file as bytes
      final bytes = excel.encode();
      
      // Download the file
      if (bytes != null) {
        final uint8list = Uint8List.fromList(bytes);
        // Create a more descriptive filename with subject, branch, year and section
        final filename = '${labSession.subjectName}_${labSession.branch}_${labSession.year}_${labSession.section}_M1_M2_Marks.xlsx';
        _downloadExcelFile(uint8list, filename);
      }
    } catch (e) {
      throw Exception('Failed to export M1/M2 marks: $e');
    }
  }

  // Export final lab assessment (viva and final grade)
  Future<void> exportFinalLabMarks({
    required LabSession labSession,
    required List<StudentModel> students,
  }) async {
    try {
      // Create a new Excel workbook
      final excel = createExcel();
      
      // Get the default sheet and rename it for final assessment
      final defaultSheet = getDefaultSheetName(excel);
      final sheetName = 'Final Lab Assessment';
      excel.rename(defaultSheet, sheetName);
      final sheet = excel[sheetName];
      
      // Add headers
      final headers = [
        'Student ID',
        'Name',
        'Viva Marks',
        'Final Lab Grade',
      ];
      
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
      }
      
      // Add data
      var rowIndex = 1;
      for (final student in students) {
        final studentId = student.rollNo; // Use rollNo instead of id as the key
        final vivaMarks = labSession.vivaMarks[studentId] ?? 0;
        final finalGrade = labSession.finalLabMarks[studentId] ?? 0.0;
        
        // Add student data
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          ..value = TextCellValue(student.rollNo);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          ..value = TextCellValue(student.name);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          ..value = IntCellValue(vivaMarks);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          ..value = DoubleCellValue(finalGrade);
        
        rowIndex++;
      }
      
      // Auto-fit columns
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 15);
      }
      
      // Generate the Excel file as bytes
      final bytes = excel.encode();
      
      // Download the file
      if (bytes != null) {
        final uint8list = Uint8List.fromList(bytes);
        // Create a more descriptive filename with subject, branch, year and section
        final filename = '${labSession.subjectName}_${labSession.branch}_${labSession.year}_${labSession.section}_Final_Assessment.xlsx';
        _downloadExcelFile(uint8list, filename);
      }
    } catch (e) {
      throw Exception('Failed to export final lab marks: $e');
    }
  }
  
  // Export seminar marks
  Future<void> exportSeminarMarks({
    required SeminarSession seminarSession,
    required List<StudentModel> students,
  }) async {
    try {
      // Create a new Excel workbook
      final excel = createExcel();
      
      // Get the default sheet and rename it to 'Seminar Marks'
      final defaultSheet = getDefaultSheetName(excel);
      final sheetName = 'Seminar Marks';
      excel.rename(defaultSheet, sheetName);
      final sheet = excel[sheetName];
      
      // Add headers
      final headers = [
        'Student ID',
        'Name',
        'Seminar Marks (0-5)',
      ];
      
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
      }
      
      // Add data
      var rowIndex = 1;
      for (final student in students) {
        final studentId = student.rollNo;
        final presentationMarks = seminarSession.presentationMarks[studentId];
        final seminarMark = presentationMarks?['total'] as double? ?? 0.0;
        
        // Add student data
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          ..value = TextCellValue(student.rollNo);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          ..value = TextCellValue(student.name);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          ..value = DoubleCellValue(seminarMark);
        
        rowIndex++;
      }
      
      // Auto-fit columns
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20); // Make columns a bit wider for better readability
      }
      
      // Generate the Excel file as bytes
      final bytes = excel.encode();
      
      // Download the file
      if (bytes != null) {
        final uint8list = Uint8List.fromList(bytes);
        final filename = '${seminarSession.subjectName}_${seminarSession.branch}_${seminarSession.year}_${seminarSession.section}_Seminar_Marks.xlsx';
        _downloadExcelFile(uint8list, filename);
      }
    } catch (e) {
      throw Exception('Failed to export seminar marks: $e');
    }
  }
  
  // Private method to handle the download
  void _downloadExcelFile(Uint8List bytes, String filename) {
    // Create a Blob
    final blob = html.Blob([bytes]);
    
    // Create a URL for the blob
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // Create a download anchor element
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    
    // Add to the DOM and trigger the download
    html.document.body?.children.add(anchor);
    anchor.click();
    
    // Clean up
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
  
  // Export Mid 1 marks
  Future<void> exportMid1Marks({
    required MidSession midSession,
    required List<StudentModel> students,
  }) async {
    try {
      // Create a new Excel workbook
      final excel = createExcel();
      
      // Get the default sheet and rename it
      final defaultSheet = getDefaultSheetName(excel);
      final sheetName = 'Mid 1 Marks';
      excel.rename(defaultSheet, sheetName);
      final sheet = excel[sheetName];
      
      // Add headers
      final headers = [
        'Student ID',
        'Name',
        'Descriptive',
        'Objective', 
        'Total'
      ];
      
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
      }
      
      // Add data
      var rowIndex = 1;
      for (final student in students) {
        final studentId = student.rollNo;
        final marks = midSession.getMid1Marks(studentId);
        
        final descriptive = marks?['descriptive'] as double? ?? 0.0;
        final objective = marks?['objective'] as double? ?? 0.0;
        final total = marks?['total'] as double? ?? 0.0;
        
        // Add student data
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          ..value = TextCellValue(student.rollNo);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          ..value = TextCellValue(student.name);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          ..value = DoubleCellValue(descriptive);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          ..value = DoubleCellValue(objective);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          ..value = DoubleCellValue(total);
        
        rowIndex++;
      }
      
      // Auto-fit columns
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 15);
      }
      
      // Generate the Excel file as bytes
      final bytes = excel.encode();
      
      // Download the file
      if (bytes != null) {
        final uint8list = Uint8List.fromList(bytes);
        final filename = '${midSession.subjectName}_${midSession.branch}_${midSession.year}_${midSession.section}_Mid1_Marks.xlsx';
        _downloadExcelFile(uint8list, filename);
      }
    } catch (e) {
      throw Exception('Failed to export Mid 1 marks: $e');
    }
  }
  
  // Export Mid 2 marks
  Future<void> exportMid2Marks({
    required MidSession midSession,
    required List<StudentModel> students,
  }) async {
    try {
      // Create a new Excel workbook
      final excel = createExcel();
      
      // Get the default sheet and rename it
      final defaultSheet = getDefaultSheetName(excel);
      final sheetName = 'Mid 2 Marks';
      excel.rename(defaultSheet, sheetName);
      final sheet = excel[sheetName];
      
      // Add headers
      final headers = [
        'Student ID',
        'Name',
        'Descriptive',
        'Objective', 
        'Total'
      ];
      
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
      }
      
      // Add data
      var rowIndex = 1;
      for (final student in students) {
        final studentId = student.rollNo;
        final marks = midSession.getMid2Marks(studentId);
        
        final descriptive = marks?['descriptive'] as double? ?? 0.0;
        final objective = marks?['objective'] as double? ?? 0.0;
        final total = marks?['total'] as double? ?? 0.0;
        
        // Add student data
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          ..value = TextCellValue(student.rollNo);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          ..value = TextCellValue(student.name);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          ..value = DoubleCellValue(descriptive);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          ..value = DoubleCellValue(objective);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          ..value = DoubleCellValue(total);
        
        rowIndex++;
      }
      
      // Auto-fit columns
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 15);
      }
      
      // Generate the Excel file as bytes
      final bytes = excel.encode();
      
      // Download the file
      if (bytes != null) {
        final uint8list = Uint8List.fromList(bytes);
        final filename = '${midSession.subjectName}_${midSession.branch}_${midSession.year}_${midSession.section}_Mid2_Marks.xlsx';
        _downloadExcelFile(uint8list, filename);
      }
    } catch (e) {
      throw Exception('Failed to export Mid 2 marks: $e');
    }
  }
  
  // Export Final Mid marks
  Future<void> exportFinalMidMarks({
    required MidSession midSession,
    required List<StudentModel> students,
  }) async {
    try {
      // Create a new Excel workbook
      final excel = createExcel();
      
      // Get the default sheet and rename it
      final defaultSheet = getDefaultSheetName(excel);
      final sheetName = 'Final Mid Marks';
      excel.rename(defaultSheet, sheetName);
      final sheet = excel[sheetName];
      
      // Add headers
      final headers = [
        'Student ID',
        'Name',
        'Mid 1 Total',
        'Mid 2 Total', 
        'Final Mid Mark'
      ];
      
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
      }
      
      // Add data
      var rowIndex = 1;
      for (final student in students) {
        final studentId = student.rollNo;
        final mid1Marks = midSession.getMid1Marks(studentId);
        final mid2Marks = midSession.getMid2Marks(studentId);
        final finalMark = midSession.getFinalMidMark(studentId) ?? 0.0;
        
        final mid1Total = mid1Marks?['total'] as double? ?? 0.0;
        final mid2Total = mid2Marks?['total'] as double? ?? 0.0;
        
        // Add student data
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          ..value = TextCellValue(student.rollNo);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          ..value = TextCellValue(student.name);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          ..value = DoubleCellValue(mid1Total);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          ..value = DoubleCellValue(mid2Total);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          ..value = DoubleCellValue(finalMark);
        
        rowIndex++;
      }
      
      // Auto-fit columns
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 15);
      }
      
      // Generate the Excel file as bytes
      final bytes = excel.encode();
      
      // Download the file
      if (bytes != null) {
        final uint8list = Uint8List.fromList(bytes);
        final filename = '${midSession.subjectName}_${midSession.branch}_${midSession.year}_${midSession.section}_Final_Mid_Marks.xlsx';
        _downloadExcelFile(uint8list, filename);
      }
    } catch (e) {
      throw Exception('Failed to export Final Mid marks: $e');
    }
  }
  
  // Export All Mid marks (combined)
  Future<void> exportAllMidMarks({
    required MidSession midSession,
    required List<StudentModel> students,
  }) async {
    try {
      // Create a new Excel workbook
      final excel = createExcel();
      
      // Create sheets for different mark types
      final defaultSheet = getDefaultSheetName(excel);
      excel.rename(defaultSheet, 'Mid 1 Marks');
      final mid1Sheet = excel['Mid 1 Marks'];
      
      // Create a new sheet for Mid 2 marks
      excel.copy(defaultSheet, 'Mid 2 Marks');
      final mid2Sheet = excel['Mid 2 Marks'];
      
      // Create a new sheet for Final Mid marks
      excel.copy(defaultSheet, 'Final Mid Marks');
      final finalSheet = excel['Final Mid Marks'];
      
      // Add headers for Mid 1 sheet
      final mid1Headers = [
        'Student ID',
        'Name',
        'Descriptive',
        'Objective', 
        'Total'
      ];
      
      for (var i = 0; i < mid1Headers.length; i++) {
        mid1Sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(mid1Headers[i])
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
      }
      
      // Add headers for Mid 2 sheet
      final mid2Headers = [
        'Student ID',
        'Name',
        'Descriptive',
        'Objective', 
        'Total'
      ];
      
      for (var i = 0; i < mid2Headers.length; i++) {
        mid2Sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(mid2Headers[i])
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
      }
      
      // Add headers for Final Mid sheet
      final finalHeaders = [
        'Student ID',
        'Name',
        'Mid 1 Total',
        'Mid 2 Total', 
        'Final Mid Mark'
      ];
      
      for (var i = 0; i < finalHeaders.length; i++) {
        finalSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(finalHeaders[i])
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
      }
      
      // Add data to all sheets
      var rowIndex = 1;
      for (final student in students) {
        final studentId = student.rollNo;
        final mid1Marks = midSession.getMid1Marks(studentId);
        final mid2Marks = midSession.getMid2Marks(studentId);
        final finalMark = midSession.getFinalMidMark(studentId) ?? 0.0;
        
        final mid1Descriptive = mid1Marks?['descriptive'] as double? ?? 0.0;
        final mid1Objective = mid1Marks?['objective'] as double? ?? 0.0;
        final mid1Total = mid1Marks?['total'] as double? ?? 0.0;
        
        final mid2Descriptive = mid2Marks?['descriptive'] as double? ?? 0.0;
        final mid2Objective = mid2Marks?['objective'] as double? ?? 0.0;
        final mid2Total = mid2Marks?['total'] as double? ?? 0.0;
        
        // Add data to Mid 1 sheet
        mid1Sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          ..value = TextCellValue(student.rollNo);
        
        mid1Sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          ..value = TextCellValue(student.name);
        
        mid1Sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          ..value = DoubleCellValue(mid1Descriptive);
        
        mid1Sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          ..value = DoubleCellValue(mid1Objective);
        
        mid1Sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          ..value = DoubleCellValue(mid1Total);
        
        // Add data to Mid 2 sheet
        mid2Sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          ..value = TextCellValue(student.rollNo);
        
        mid2Sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          ..value = TextCellValue(student.name);
        
        mid2Sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          ..value = DoubleCellValue(mid2Descriptive);
        
        mid2Sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          ..value = DoubleCellValue(mid2Objective);
        
        mid2Sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          ..value = DoubleCellValue(mid2Total);
        
        // Add data to Final Mid sheet
        finalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          ..value = TextCellValue(student.rollNo);
        
        finalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          ..value = TextCellValue(student.name);
        
        finalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          ..value = DoubleCellValue(mid1Total);
        
        finalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          ..value = DoubleCellValue(mid2Total);
        
        finalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          ..value = DoubleCellValue(finalMark);
        
        rowIndex++;
      }
      
      // Auto-fit columns for all sheets
      for (var i = 0; i < mid1Headers.length; i++) {
        mid1Sheet.setColumnWidth(i, 15);
        mid2Sheet.setColumnWidth(i, 15);
      }
      
      for (var i = 0; i < finalHeaders.length; i++) {
        finalSheet.setColumnWidth(i, 15);
      }
      
      // Generate the Excel file as bytes
      final bytes = excel.encode();
      
      // Download the file
      if (bytes != null) {
        final uint8list = Uint8List.fromList(bytes);
        final filename = '${midSession.subjectName}_${midSession.branch}_${midSession.year}_${midSession.section}_All_Mid_Marks.xlsx';
        _downloadExcelFile(uint8list, filename);
      }
    } catch (e) {
      throw Exception('Failed to export all Mid marks: $e');
    }
  }
}
