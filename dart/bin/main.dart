import 'dart:io';

import '../lib/console/console_app.dart';
import '../lib/web/server.dart';

/// Entry point for the Grade Calculator application.
///
/// Presents a mode-selection menu on startup and delegates to either
/// [ConsoleApp] (interactive terminal) or [WebServer] (browser GUI).
Future<void> main() async {
  _printBanner();

  // ── Main menu loop ────────────────────────────────────────────────────────
  // Keeps showing the menu after Console Mode finishes so the user can run
  // again, switch to GUI mode, or exit. The loop breaks when the user chooses
  // GUI Mode (server runs indefinitely) or Exit.
  while (true) {
    _printMenu();

    final input = stdin.readLineSync()?.trim() ?? '';

    switch (input) {
      case '1':
        // ── Console Mode ──────────────────────────────────────────────────
        // Run the full interactive terminal session, then loop back to the
        // menu so the user can process another file or switch modes.
        print('');
        final app = ConsoleApp();
        app.run();
        // Fall through to the top of the loop — menu is shown again.
        break;

      case '2':
        // ── GUI Mode ──────────────────────────────────────────────────────
        // Start the local HTTP server and await it. The server runs until
        // the process is terminated with Ctrl+C, so we never return here.
        print('');
        final server = WebServer();
        await server.start();
        // Unreachable in normal operation (server blocks indefinitely).
        return;

      case '3':
        // ── Exit ──────────────────────────────────────────────────────────
        print('\nGoodbye!\n');
        exit(0);

      default:
        // ── Invalid input ─────────────────────────────────────────────────
        print('\nInvalid choice. Please enter 1, 2, or 3.\n');
    }
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Prints the application startup banner.
void _printBanner() {
  print('');
  print('╔══════════════════════════════════════════╗');
  print('║        GRADE CALCULATOR v1.0             ║');
  print('║        SE 3242 Android App Development   ║');
  print('║        Dart Implementation               ║');
  print('╚══════════════════════════════════════════╝');
  print('');
}

/// Prints the mode-selection menu.
void _printMenu() {
  print('Please select a mode:');
  print('  [1] Console Mode  — interactive terminal interface');
  print('  [2] GUI Mode      — browser-based graphical interface');
  print('  [3] Exit');
  stdout.write('  > Your choice: ');
}
