import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:universal_html/html.dart' as html;
import 'package:markpro_plus/models/lab_session.dart';
import 'package:markpro_plus/models/student_model.dart';

class ExportService {
  // Create a completely fresh Excel workbook without Sheet1
  Excel _createExcelWithoutSheet1() {
    // Create a brand new workbook
    final excel = Excel.createExcel();
    
    // Create a custom sheet first so we're not working with Sheet1 only
    excel['CustomSheet'];
    
    // Now it's safe to remove Sheet1
    excel.delete('Sheet1');
    
    return excel;
  }
  // Export experiment marks for a specific experiment
  Future<void> exportExperimentMarks({
    required LabSession labSession,
    required String experimentNumber,
    required List<StudentModel> students,
  }) async {
    try {
      // Create a new Excel workbook without Sheet1
      final excel = _createExcelWithoutSheet1();
      
      // Create the experiment marks sheet
      final sheetName = 'Experiment $experimentNumber Marks';
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
        final studentId = student.rollNo; // Critical: Must use rollNo as the key for lookups
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
        _downloadExcelFile(uint8list, 'experiment_${experimentNumber}_marks.xlsx');
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
      // Create a new Excel workbook without Sheet1
      final excel = _createExcelWithoutSheet1();
      
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
          final studentId = student.rollNo; // Critical: Must use rollNo as the key for lookups
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
      var rowIndex = 1;
      for (final student in students) {
        final studentId = student.id;
        final m1Mark = labSession.m1Marks[studentId] ?? 0.0;
        final m2Mark = labSession.m2Marks[studentId] ?? 0.0;
        
        // Add student data
        m1m2Sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          ..value = TextCellValue(student.rollNo);
        
        m1m2Sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          ..value = TextCellValue(student.name);
        
        m1m2Sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          ..value = DoubleCellValue(m1Mark is double ? m1Mark : 0.0);
        
        m1m2Sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          ..value = DoubleCellValue(m2Mark is double ? m2Mark : 0.0);
        
        rowIndex++;
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
      rowIndex = 1;
      for (final student in students) {
        final studentId = student.id;
        final vivaMarks = labSession.vivaMarks[studentId] ?? 0;
        final finalGrade = labSession.finalLabMarks[studentId] ?? 0.0;
        
        // Add student data
        finalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          ..value = TextCellValue(student.rollNo);
        
        finalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          ..value = TextCellValue(student.name);
        
        finalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          ..value = IntCellValue(vivaMarks is int ? vivaMarks : 0);
        
        finalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          ..value = DoubleCellValue(finalGrade is double ? finalGrade : 0.0);
        
        rowIndex++;
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
        _downloadExcelFile(uint8list, '${labSession.subjectName}_complete_marks.xlsx');
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
      // Create a new Excel workbook without Sheet1
      final excel = _createExcelWithoutSheet1();
      
      // Create the internal marks sheet
      final sheet = excel['Internal Marks'];
      
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
        // Critical: Must use rollNo as the key for all lookups in labSession maps
        final studentId = student.rollNo;
        // Get internal marks using the studentId (rollNo)
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
      
      final bytes = excel.encode();
      
      // Download the file
      if (bytes != null) {
        final uint8list = Uint8List.fromList(bytes);
        _downloadExcelFile(uint8list, 'internal_marks.xlsx');
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
      // Create a new Excel workbook without Sheet1
      final excel = _createExcelWithoutSheet1();
      
      // Create the M1 M2 marks sheet
      final sheetName = 'M1 M2 Marks';
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
        final studentId = student.rollNo; // Critical: Must use rollNo as the key for all lookups
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
        _downloadExcelFile(uint8list, '${labSession.subjectName}_m1_m2_marks.xlsx');
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
      // Create a new Excel workbook without Sheet1
      final excel = _createExcelWithoutSheet1();
      
      // Create the final lab assessment sheet
      final sheetName = 'Final Lab Assessment';
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
        final studentId = student.rollNo; // Critical: Must use rollNo as the key for all lookups
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
        _downloadExcelFile(uint8list, '${labSession.subjectName}_final_assessment.xlsx');
      }
    } catch (e) {
      throw Exception('Failed to export final lab marks: $e');
    }
  }
  
  // Private method to handle the download
  void _downloadExcelFile(Uint8List bytes, String fileName) {
    // Create a Blob
    final blob = html.Blob([bytes]);
    
    // Create a URL for the blob
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // Create a download anchor element
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
    
    // Add to the DOM and trigger the download
    html.document.body?.children.add(anchor);
    anchor.click();
    
    // Clean up
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
}
