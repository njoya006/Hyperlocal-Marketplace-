import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../models/student.dart';
import '../services/excel_export.dart';
import '../services/file_parser.dart';
import '../services/grade_service.dart';

/// Runs a local HTTP server on `localhost:8080` that serves a browser-based
/// GUI for the Grade Calculator.
///
/// The server exposes three routes:
/// - `GET  /`         — the main single-page application.
/// - `POST /upload`   — accepts a JSON body (file as Base64 + course info),
///                      processes grades, and returns a JSON response.
/// - `GET  /download` — serves the last generated Excel report as a download.
class WebServer {
  final _parser = FileParser();
  final _grader = GradeService();
  final _exporter = ExcelExporter();

  /// Path of the most recently exported Excel file.
  /// Populated by the `/upload` handler and consumed by `/download`.
  String? _lastExcelPath;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Starts the HTTP server on `localhost:8080`, prints the URL to the
  /// console, and launches the default browser on Windows.
  ///
  /// The server runs until the process is terminated.
  Future<void> start() async {
    final router = Router();

    router.get('/', _serveHomePage);
    router.post('/upload', _handleUpload);
    router.get('/download', _handleDownload);

    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router.call);

    final server = await shelf_io.serve(handler, 'localhost', 8080);
    server.autoCompress = true;

    print('');
    print('╔══════════════════════════════════════════════╗');
    print('║   Grade Calculator — Web GUI                 ║');
    print('║   http://localhost:${server.port}                    ║');
    print('╚══════════════════════════════════════════════╝');
    print('Press Ctrl+C to stop the server.\n');

    // Open browser automatically on Windows.
    try {
      await Process.run('cmd', ['/c', 'start', 'http://localhost:8080']);
    } catch (_) {
      // Non-fatal: browser launch is best-effort.
    }
  }

  // ---------------------------------------------------------------------------
  // Route handlers
  // ---------------------------------------------------------------------------

  /// Serves the main HTML single-page application.
  Response _serveHomePage(Request request) {
    return Response.ok(
      _buildHtml(),
      headers: {'Content-Type': 'text/html; charset=utf-8'},
    );
  }

  /// Accepts a JSON body with the following shape and processes the students:
  ///
  /// ```json
  /// {
  ///   "fileName"    : "students.csv",
  ///   "fileContent" : "<base64-encoded file bytes>",
  ///   "lecturerName": "Dr. Smith",
  ///   "courseName"  : "Android Development",
  ///   "semester"    : "Semester 1",
  ///   "academicYear": "2025/2026",
  ///   "department"  : "Computing",
  ///   "scaleOverride": 0
  /// }
  /// ```
  ///
  /// Returns a JSON response:
  /// ```json
  /// {
  ///   "success" : true,
  ///   "students": [ { ... } ],
  ///   "summary" : { ... }
  /// }
  /// ```
  Future<Response> _handleUpload(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      // ── Decode the uploaded file from Base64 and write to a temp file ──
      final fileName = (data['fileName'] as String?) ?? 'upload.csv';
      final fileContent = data['fileContent'] as String?;
      if (fileContent == null || fileContent.isEmpty) {
        return _jsonError('No file content received.');
      }

      final bytes = base64Decode(fileContent);
      final ext = fileName.contains('.') ? '.${fileName.split('.').last}' : '';
      final tempFile = File(
        '${Directory.systemTemp.path}/gc_upload_${DateTime.now().millisecondsSinceEpoch}$ext',
      );
      await tempFile.writeAsBytes(bytes);

      // ── Parse ──
      List<Student> students;
      try {
        students = _parser.parseFile(tempFile.path);
      } finally {
        // Clean up temp file regardless of parse success.
        if (await tempFile.exists()) await tempFile.delete();
      }

      if (students.isEmpty) {
        return _jsonError('No valid student records found in the file.');
      }

      // ── Scale detection / override ──
      final scaleOverride = (data['scaleOverride'] as num?)?.toInt() ?? 0;
      final scale = [20, 40, 100].contains(scaleOverride)
          ? scaleOverride
          : _grader.detectMarkScale(students);

      final converted = _grader.convertMarks(students, scale);

      // ── Grade ──
      final graded = _grader.processStudents(converted);
      final summary = _grader.generateSummary(graded);

      // ── Course info ──
      final courseInfo = <String, String>{
        'lecturerName': (data['lecturerName'] as String?) ?? '',
        'courseName': (data['courseName'] as String?) ?? '',
        'semester': (data['semester'] as String?) ?? '',
        'academicYear': (data['academicYear'] as String?) ?? '',
        'department': (data['department'] as String?) ?? '',
      };

      // ── Export Excel ──
      _lastExcelPath = 'output/grade_report_'
          '${DateTime.now().millisecondsSinceEpoch}.xlsx';

      _exporter.exportToExcel(
        students: graded,
        outputPath: _lastExcelPath!,
        courseInfo: courseInfo,
        summary: summary,
      );

      // ── Build JSON response ──
      final studentRows = graded.map((s) => {
            'firstName': s.firstName,
            'lastName': s.lastName,
            'registrationNumber': s.registrationNumber,
            'rawMark': s.rawMark,
            'markOutOf100': s.markOutOf100,
            'grade': s.grade ?? 'N/A',
            'status': s.status ?? 'N/A',
          }).toList();

      return Response.ok(
        jsonEncode({
          'success': true,
          'detectedScale': scale,
          'students': studentRows,
          'summary': {
            'totalStudents': summary['totalStudents'],
            'passCount': summary['passCount'],
            'failCount': summary['failCount'],
            'average': (summary['average'] as double).toStringAsFixed(2),
            'highest': (summary['highest'] as double).toStringAsFixed(2),
            'lowest': (summary['lowest'] as double).toStringAsFixed(2),
          },
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      stderr.writeln('Upload error: $e\n$st');
      return _jsonError('Server error: $e');
    }
  }

  /// Serves the last generated Excel file as an attachment download.
  ///
  /// Returns HTTP 404 if no report has been generated yet in this session.
  Response _handleDownload(Request request) {
    if (_lastExcelPath == null || !File(_lastExcelPath!).existsSync()) {
      return Response.notFound(
        jsonEncode({'success': false, 'error': 'No report available yet.'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final bytes = File(_lastExcelPath!).readAsBytesSync();
    return Response.ok(
      bytes,
      headers: {
        'Content-Type':
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'Content-Disposition': 'attachment; filename="grade_report.xlsx"',
      },
    );
  }

  // ---------------------------------------------------------------------------
  // HTML builder
  // ---------------------------------------------------------------------------

  /// Builds and returns the complete self-contained HTML page as a [String].
  String _buildHtml() => '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>Grade Calculator</title>
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

  body {
    font-family: 'Segoe UI', Arial, sans-serif;
    background: #f0f2f5;
    color: #222;
    min-height: 100vh;
  }

  /* ── Header ── */
  header {
    background: #0d1b2a;
    color: #fff;
    padding: 1.4rem 2rem;
    display: flex;
    align-items: center;
    gap: 1rem;
  }
  header h1 { font-size: 1.5rem; font-weight: 700; letter-spacing: .5px; }
  header span { font-size: .9rem; opacity: .7; }

  /* ── Layout ── */
  main {
    max-width: 960px;
    margin: 2rem auto;
    padding: 0 1rem;
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }

  /* ── Cards ── */
  .card {
    background: #fff;
    border-radius: 8px;
    box-shadow: 0 2px 8px rgba(0,0,0,.08);
    padding: 1.6rem 2rem;
  }
  .card h2 {
    font-size: 1.1rem;
    font-weight: 600;
    color: #0d1b2a;
    margin-bottom: 1.2rem;
    padding-bottom: .6rem;
    border-bottom: 2px solid #e8eaf0;
  }

  /* ── Form ── */
  .form-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: .9rem 1.4rem;
  }
  @media(max-width:600px){ .form-grid { grid-template-columns: 1fr; } }

  .form-group { display: flex; flex-direction: column; gap: .3rem; }
  .form-group.full { grid-column: 1 / -1; }

  label { font-size: .82rem; font-weight: 600; color: #555; text-transform: uppercase; letter-spacing: .4px; }

  input[type=text], input[type=file] {
    border: 1.5px solid #d0d5dd;
    border-radius: 6px;
    padding: .55rem .75rem;
    font-size: .95rem;
    transition: border-color .2s;
    background: #fafafa;
    width: 100%;
  }
  input[type=text]:focus { outline: none; border-color: #1a73e8; background: #fff; }

  select {
    border: 1.5px solid #d0d5dd;
    border-radius: 6px;
    padding: .55rem .75rem;
    font-size: .95rem;
    background: #fafafa;
    width: 100%;
  }

  /* ── Buttons ── */
  .btn {
    display: inline-flex; align-items: center; gap: .5rem;
    padding: .65rem 1.5rem;
    border: none; border-radius: 6px;
    font-size: .95rem; font-weight: 600; cursor: pointer;
    transition: background .2s, transform .1s;
  }
  .btn:active { transform: scale(.97); }
  .btn-primary { background: #0d1b2a; color: #fff; }
  .btn-primary:hover { background: #1a3550; }
  .btn-success { background: #1e7e34; color: #fff; }
  .btn-success:hover { background: #155724; }
  .btn-row { display: flex; gap: .8rem; flex-wrap: wrap; margin-top: 1rem; }

  /* ── Spinner ── */
  .spinner {
    display: none;
    width: 20px; height: 20px;
    border: 3px solid rgba(255,255,255,.4);
    border-top-color: #fff;
    border-radius: 50%;
    animation: spin .7s linear infinite;
  }
  @keyframes spin { to { transform: rotate(360deg); } }

  /* ── Alert ── */
  .alert {
    padding: .75rem 1rem;
    border-radius: 6px;
    font-size: .9rem;
    display: none;
  }
  .alert-error { background: #fde8e8; color: #b91c1c; border-left: 4px solid #b91c1c; }
  .alert-info  { background: #e8f0fe; color: #1a56db; border-left: 4px solid #1a56db; }

  /* ── Summary chips ── */
  .summary-grid {
    display: flex; flex-wrap: wrap; gap: .8rem;
    margin-bottom: 1rem;
  }
  .chip {
    background: #f0f2f5; border-radius: 20px;
    padding: .45rem 1rem; font-size: .88rem; font-weight: 600;
  }
  .chip .label { color: #555; font-weight: 400; margin-right: .3rem; }
  .chip.pass { background: #d4edda; color: #155724; }
  .chip.fail { background: #f8d7da; color: #721c24; }

  /* ── Results table ── */
  #results { display: none; }

  .table-wrap { overflow-x: auto; border-radius: 6px; border: 1px solid #e8eaf0; }
  table { border-collapse: collapse; width: 100%; font-size: .9rem; }
  th {
    background: #0d1b2a; color: #fff;
    padding: .65rem .9rem; text-align: left;
    font-weight: 600; white-space: nowrap;
  }
  td { padding: .55rem .9rem; border-bottom: 1px solid #f0f2f5; }
  tr:last-child td { border-bottom: none; }
  tr:hover td { background: #f8fafc; }

  .badge {
    display: inline-block;
    padding: .2rem .65rem;
    border-radius: 12px;
    font-size: .8rem;
    font-weight: 700;
  }
  .badge-pass { background: #d4edda; color: #155724; }
  .badge-fail { background: #f8d7da; color: #721c24; }

  .scale-note { font-size: .83rem; color: #666; margin-bottom: .8rem; }
</style>
</head>
<body>

<header>
  <div>
    <h1>&#127891; Grade Calculator</h1>
    <span>SE 3242 &mdash; Android App Development</span>
  </div>
</header>

<main>

  <!-- ── Input form ── -->
  <div class="card">
    <h2>Course Information &amp; File Upload</h2>

    <div id="errAlert" class="alert alert-error"></div>

    <form id="uploadForm">
      <div class="form-grid">
        <div class="form-group">
          <label for="lecturerName">Lecturer Name</label>
          <input type="text" id="lecturerName" placeholder="e.g. Dr. Alice Smith" required/>
        </div>
        <div class="form-group">
          <label for="courseName">Course Name</label>
          <input type="text" id="courseName" placeholder="e.g. Android App Development" required/>
        </div>
        <div class="form-group">
          <label for="semester">Semester</label>
          <input type="text" id="semester" placeholder="e.g. Semester 1" required/>
        </div>
        <div class="form-group">
          <label for="academicYear">Academic Year</label>
          <input type="text" id="academicYear" placeholder="e.g. 2025/2026" required/>
        </div>
        <div class="form-group full">
          <label for="department">Department / Faculty</label>
          <input type="text" id="department" placeholder="e.g. Faculty of Computing" required/>
        </div>
        <div class="form-group">
          <label for="scaleOverride">Mark Scale Override</label>
          <select id="scaleOverride">
            <option value="0">Auto-detect</option>
            <option value="20">Out of 20</option>
            <option value="40">Out of 40</option>
            <option value="100">Out of 100</option>
          </select>
        </div>
        <div class="form-group">
          <label for="studentFile">Student File (.csv / .xlsx / .xls / .txt)</label>
          <input type="file" id="studentFile" accept=".csv,.xlsx,.xls,.txt" required/>
        </div>
      </div>

      <div class="btn-row">
        <button type="submit" class="btn btn-primary" id="submitBtn">
          <span>Generate Report</span>
          <div class="spinner" id="spinner"></div>
        </button>
      </div>
    </form>
  </div>

  <!-- ── Results ── -->
  <div class="card" id="results">
    <h2>Results</h2>
    <p class="scale-note" id="scaleNote"></p>
    <div class="summary-grid" id="summaryChips"></div>

    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th>#</th>
            <th>First Name</th>
            <th>Last Name</th>
            <th>Reg. Number</th>
            <th>Raw Mark</th>
            <th>Mark /100</th>
            <th>Grade</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody id="tableBody"></tbody>
      </table>
    </div>

    <div class="btn-row">
      <button class="btn btn-success" id="downloadBtn" onclick="downloadReport()">
        &#11123; Download Excel Report
      </button>
    </div>
  </div>

</main>

<script>
  const form = document.getElementById('uploadForm');
  const spinner = document.getElementById('spinner');
  const submitBtn = document.getElementById('submitBtn');
  const errAlert = document.getElementById('errAlert');
  const results = document.getElementById('results');

  function showError(msg) {
    errAlert.textContent = msg;
    errAlert.style.display = 'block';
  }

  function hideError() {
    errAlert.style.display = 'none';
  }

  function setLoading(on) {
    spinner.style.display = on ? 'inline-block' : 'none';
    submitBtn.disabled = on;
  }

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    hideError();
    results.style.display = 'none';
    setLoading(true);

    try {
      const file = document.getElementById('studentFile').files[0];
      if (!file) { showError('Please select a student file.'); return; }

      // Encode file as Base64
      const fileContent = await new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => {
          // result is "data:<mime>;base64,<data>" — strip the prefix
          const base64 = reader.result.split(',')[1];
          resolve(base64);
        };
        reader.onerror = reject;
        reader.readAsDataURL(file);
      });

      const payload = {
        fileName:     file.name,
        fileContent:  fileContent,
        lecturerName: document.getElementById('lecturerName').value.trim(),
        courseName:   document.getElementById('courseName').value.trim(),
        semester:     document.getElementById('semester').value.trim(),
        academicYear: document.getElementById('academicYear').value.trim(),
        department:   document.getElementById('department').value.trim(),
        scaleOverride: parseInt(document.getElementById('scaleOverride').value),
      };

      const res = await fetch('/upload', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      const data = await res.json();

      if (!data.success) {
        showError(data.error || 'An unknown error occurred.');
        return;
      }

      renderResults(data);
    } catch (err) {
      showError('Network or server error: ' + err.message);
    } finally {
      setLoading(false);
    }
  });

  function renderResults(data) {
    // Scale note
    document.getElementById('scaleNote').textContent =
      'Marks were processed on a scale of out of ' + data.detectedScale + '.';

    // Summary chips
    const s = data.summary;
    document.getElementById('summaryChips').innerHTML = \`
      <div class="chip"><span class="label">Total</span>\${s.totalStudents}</div>
      <div class="chip pass"><span class="label">Pass</span>\${s.passCount}</div>
      <div class="chip fail"><span class="label">Fail</span>\${s.failCount}</div>
      <div class="chip"><span class="label">Average</span>\${s.average}</div>
      <div class="chip"><span class="label">Highest</span>\${s.highest}</div>
      <div class="chip"><span class="label">Lowest</span>\${s.lowest}</div>
    \`;

    // Student table
    const tbody = document.getElementById('tableBody');
    tbody.innerHTML = data.students.map((s, i) => \`
      <tr>
        <td>\${i + 1}</td>
        <td>\${esc(s.firstName)}</td>
        <td>\${esc(s.lastName)}</td>
        <td>\${esc(s.registrationNumber)}</td>
        <td>\${parseFloat(s.rawMark).toFixed(2)}</td>
        <td>\${parseFloat(s.markOutOf100).toFixed(2)}</td>
        <td><strong>\${esc(s.grade)}</strong></td>
        <td><span class="badge \${s.status === 'Pass' ? 'badge-pass' : 'badge-fail'}">\${esc(s.status)}</span></td>
      </tr>
    \`).join('');

    results.style.display = 'block';
    results.scrollIntoView({ behavior: 'smooth' });
  }

  function downloadReport() {
    window.location.href = '/download';
  }

  function esc(str) {
    return String(str)
      .replace(/&/g,'&amp;').replace(/</g,'&lt;')
      .replace(/>/g,'&gt;').replace(/"/g,'&quot;');
  }
</script>
</body>
</html>''';

  // ---------------------------------------------------------------------------
  // Private helper
  // ---------------------------------------------------------------------------

  /// Returns a JSON 400 error response with a human-readable [message].
  Response _jsonError(String message) => Response(
        400,
        body: jsonEncode({'success': false, 'error': message}),
        headers: {'Content-Type': 'application/json'},
      );
}
