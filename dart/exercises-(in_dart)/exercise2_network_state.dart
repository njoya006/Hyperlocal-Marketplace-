// ============================================================
// SE 3242: Android Application Development
// Week 2 - Dart Exercises
// Exercise 2: Network Request State with Sealed Classes
// Student: [Your Name]
// Date: March 2026
// Description: Demonstrates sealed classes and exhaustive
//              pattern matching in Dart, modelling the three
//              possible states of a network request.
// ============================================================

// ─────────────────────────────────────────────────────────────
// Sealed class hierarchy
// ─────────────────────────────────────────────────────────────

/// Sealed base class representing all possible states of a
/// network request.
///
/// Because this class is `sealed`, the Dart compiler knows every
/// subclass at compile time and can enforce exhaustive pattern
/// matching in switch expressions — no `default` branch needed.
sealed class NetworkState {}

/// Represents a network request that is currently in progress.
///
/// No data is available yet while in this state.
class Loading extends NetworkState {}

/// Represents a successfully completed network request.
///
/// [data] contains the payload returned by the server.
class Success extends NetworkState {
  /// The data payload returned by the successful request.
  final String data;

  /// Creates a [Success] state with the given [data].
  Success(this.data);
}

/// Represents a network request that has failed.
///
/// [message] describes the reason for the failure.
class NetworkError extends NetworkState {
  /// A human-readable description of the error.
  final String message;

  /// Creates a [NetworkError] state with the given [message].
  NetworkError(this.message);
}

// ─────────────────────────────────────────────────────────────
// State handler
// ─────────────────────────────────────────────────────────────

/// Handles [state] by printing a descriptive message for each
/// possible [NetworkState] subtype.
///
/// Uses an exhaustive `switch` expression — because [NetworkState]
/// is `sealed`, the compiler guarantees every case is covered
/// without a `default` branch.
void handleState(NetworkState state) {
  final message = switch (state) {
    Loading()       => '⏳ Loading... please wait.',
    Success(:final data)          => '✅ Success! Data: $data',
    NetworkError(:final message)  => '❌ Error: $message',
  };
  print(message);
}

// ─────────────────────────────────────────────────────────────
// Simulated fetch
// ─────────────────────────────────────────────────────────────

/// Simulates a network fetch by returning a [NetworkState] based
/// on the given [scenario] number.
///
/// | scenario | returned state                          |
/// |----------|-----------------------------------------|
/// | 1        | [Loading]                               |
/// | 2        | [Success] with `"User profile loaded"`  |
/// | 3        | [NetworkError] with `"Connection timed out"` |
/// | other    | [NetworkError] with `"Unknown error"`   |
NetworkState simulateFetch(int scenario) {
  return switch (scenario) {
    1 => Loading(),
    2 => Success('User profile loaded'),
    3 => NetworkError('Connection timed out'),
    _ => NetworkError('Unknown error'),
  };
}

// ─────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────

/// Demonstrates sealed classes and exhaustive pattern matching
/// through a series of simulated network state operations.
void main() {
  final separator = '─' * 50;

  // ── Section 1: forEach over a mixed list of states ────────
  print(separator);
  print('Section 1 — Handle a list of states (forEach)');
  print(separator);

  final List<NetworkState> states = [
    Loading(),
    Success('Dashboard data loaded'),
    NetworkError('404 Not Found'),
    Success('Settings saved'),
    NetworkError('No internet connection'),
  ];

  states.forEach(handleState);

  print('');

  // ── Section 2: simulateFetch for scenarios 1–3 ────────────
  print(separator);
  print('Section 2 — Simulate fetch for scenarios 1 – 3');
  print(separator);

  for (var scenario = 1; scenario <= 3; scenario++) {
    final state = simulateFetch(scenario);
    print('Scenario $scenario → ', );
    handleState(state);
  }

  print('');

  // ── Section 3: whereType<Success>() ───────────────────────
  print(separator);
  print('Section 3 — Successful states only (whereType<Success>)');
  print(separator);

  states
      .whereType<Success>()
      .forEach((s) => print('✅ Received: ${s.data}'));

  print(separator);
}
