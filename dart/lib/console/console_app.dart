import 'dart:io';

import '../models/student.dart';
import '../services/excel_export.dart';
import '../services/file_parser.dart';
import '../services/grade_service.dart';

/// Drives the interactive console/terminal mode of the Grade Calculator.
///
/// Call [run] once from `main()` to start the step-by-step guided flow:
/// banner → course info → file input → scale detection → grading → export.
class ConsoleApp {
  final _parser = FileParser();
  final _grader = GradeService();
  final _exporter = ExcelExporter();

  // ---------------------------------------------------------------------------
  // Public entry point
  // ---------------------------------------------------------------------------

  /// Runs the full interactive console session.
  ///
  /// Steps executed in order:
  /// 1. Display a welcome banner.
  /// 2. Collect course information from the user.
  /// 3. Load and parse the student file.
  /// 4. Detect (and optionally override) the mark scale, then convert marks.
  /// 5. Assign grades, display the student table and summary.
  /// 6. Export the graded data to an Excel file.
  void run() {
    _printBanner();

    final courseInfo = _collectCourseInfo();

    final students = _loadStudentFile();
    if (students.isEmpty) {
      print('\nNo valid student records were found. Exiting.');
      return;
    }

    final scaled = _detectAndConvertMarks(students);

    final graded = _processAndDisplay(scaled);

    _exportReport(graded, courseInfo);

    print('\nDone. Thank you for using Grade Calculator v1.0.\n');
  }

  // ---------------------------------------------------------------------------
  // Step 1 — Banner
  // ---------------------------------------------------------------------------

  void _printBanner() {
    print('');
    print('╔══════════════════════════════════════╗');
    print('║     GRADE CALCULATOR v1.0            ║');
    print('║     SE 3242 Android App Development  ║');
    print('╚══════════════════════════════════════╝');
    print('');
  }

  // ---------------------------------------------------------------------------
  // Step 2 — Course info
  // ---------------------------------------------------------------------------

  /// Prompts the user to enter all course-related metadata and returns the
  /// collected values as a [Map] with the keys expected by [ExcelExporter].
  Map<String, String> _collectCourseInfo() {
    print('─' * 42);
    print('  STEP 1 — Course Information');
    print('─' * 42);

    return {
      'lecturerName': _prompt('Lecturer Name'),
      'courseName': _prompt('Course Name'),
      'semester': _prompt('Semester (e.g. Semester 1)'),
      'academicYear': _prompt('Academic Year (e.g. 2025/2026)'),
      'department': _prompt('Department / Faculty'),
    };
  }

  // ---------------------------------------------------------------------------
  // Step 3 — File input
  // ---------------------------------------------------------------------------

  /// Asks the user for a file path, parses it with [FileParser], and returns
  /// the list of [Student] objects loaded from the file.
  ///
  /// Retries indefinitely until a file is successfully parsed or the user
  /// presses Ctrl+C to abort.
  List<Student> _loadStudentFile() {
    print('');
    print('─' * 42);
    print('  STEP 2 — Load Student File');
    print('─' * 42);
    print('Supported formats: .csv  .xlsx  .xls  .txt');

    while (true) {
      final filePath = _prompt('Enter the full path to the student file');

      try {
        final students = _parser.parseFile(filePath.trim());
        print('✓ Successfully loaded ${students.length} student(s) '
            'from "${filePath.trim()}".');
        return students;
      } catch (e) {
        print('ERROR: Could not parse file — $e');
        print('Please try again.');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Step 4 — Scale detection and conversion
  // ---------------------------------------------------------------------------

  /// Auto-detects the mark scale from the loaded [students], lets the user
  /// confirm or override it, then converts all marks to out-of-100.
  List<Student> _detectAndConvertMarks(List<Student> students) {
    print('');
    print('─' * 42);
    print('  STEP 3 — Mark Scale Detection');
    print('─' * 42);

    final detected = _grader.detectMarkScale(students);
    print('Detected mark scale: out of $detected.');

    int scale = detected;

    while (true) {
      final input = _prompt(
        'Press Enter to accept, or type 20 / 40 / 100 to override',
      ).trim();

      if (input.isEmpty) {
        // User accepted the detected scale.
        break;
      }

      final parsed = int.tryParse(input);
      if (parsed != null && [20, 40, 100].contains(parsed)) {
        scale = parsed;
        print('Scale overridden to: out of $scale.');
        break;
      }

      print('Invalid input. Please enter 20, 40, or 100 (or press Enter to accept).');
    }

    final converted = _grader.convertMarks(students, scale);
    print('✓ Marks converted to out of 100 (scale used: $scale).');
    return converted;
  }

  // ---------------------------------------------------------------------------
  // Step 5 — Process and display
  // ---------------------------------------------------------------------------

  /// Assigns grades and statuses to all students, prints the student table,
  /// and prints the class summary. Returns the fully graded list.
  List<Student> _processAndDisplay(List<Student> students) {
    print('');
    print('─' * 42);
    print('  STEP 4 — Grades & Summary');
    print('─' * 42);

    final graded = _grader.processStudents(students);

    print('');
    print('Student Results:');
    print('─' * 80);
    _grader.printAllStudents(graded);
    print('─' * 80);

    final summary = _grader.generateSummary(graded);
    final avg = (summary['average'] as double).toStringAsFixed(2);
    final high = (summary['highest'] as double).toStringAsFixed(2);
    final low = (summary['lowest'] as double).toStringAsFixed(2);

    print('');
    print('Class Summary');
    print('  Total Students : ${summary['totalStudents']}');
    print('  Pass           : ${summary['passCount']}');
    print('  Fail           : ${summary['failCount']}');
    print('  Average        : $avg');
    print('  Highest Mark   : $high');
    print('  Lowest Mark    : $low');

    return graded;
  }

  // ---------------------------------------------------------------------------
  // Step 6 — Export
  // ---------------------------------------------------------------------------

  /// Asks the user for an output file path (defaulting to
  /// `output/grade_report.xlsx`), then exports the graded data to Excel.
  void _exportReport(
    List<Student> graded,
    Map<String, String> courseInfo,
  ) {
    print('');
    print('─' * 42);
    print('  STEP 5 — Export to Excel');
    print('─' * 42);
    print('Default output path: output/grade_report.xlsx');

    final rawPath = _prompt(
      'Enter output file path or folder (press Enter for default)',
    ).trim();

    // Resolve the output path:
    // • Empty input       → use the default.
    // • Existing directory or path ending with \ or / → append filename.
    // • Otherwise        → use as-is (must include .xlsx extension).
    String outputPath;
    if (rawPath.isEmpty) {
      outputPath = 'output/grade_report.xlsx';
    } else {
      final isDir = FileSystemEntity.isDirectorySync(rawPath) ||
          rawPath.endsWith('/') ||
          rawPath.endsWith('\\');
      if (isDir) {
        final sep = rawPath.endsWith('/') || rawPath.endsWith('\\')
            ? ''
            : Platform.pathSeparator;
        outputPath = '$rawPath${sep}grade_report.xlsx';
      } else {
        outputPath = rawPath;
      }
    }

    final summary = _grader.generateSummary(graded);

    try {
      _exporter.exportToExcel(
        students: graded,
        outputPath: outputPath,
        courseInfo: courseInfo,
        summary: summary,
      );

      final absolute = File(outputPath).absolute.path;
      print('✓ Excel report saved to: $absolute');
    } catch (e) {
      print('ERROR: Failed to export Excel file — $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Private helper
  // ---------------------------------------------------------------------------

  /// Prints [question] to the console, reads and returns the user's input line.
  ///
  /// Returns an empty string if the user enters nothing or if stdin is closed.
  String _prompt(String question) {
    stdout.write('  > $question: ');
    return stdin.readLineSync() ?? '';
  }
}
