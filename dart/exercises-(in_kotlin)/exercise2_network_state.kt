// ============================================================
// SE 3242: Android Application Development
// Week 2 - Kotlin Exercises
// Exercise 2: Network Request State with Sealed Classes
// Student: Precious [Last Name]
// Date: March 2026
// Description: Demonstrates sealed classes and exhaustive
//              when expressions in Kotlin, modelling the
//              possible states of a network request.
// ============================================================

/**
 * Sealed class representing all possible states of a network request.
 *
 * Because the class is sealed, the compiler knows every possible subclass,
 * which allows `when` expressions to be exhaustive without an `else` branch.
 */
sealed class NetworkState {

    /**
     * Indicates that the network request is currently in progress.
     * Declared as an `object` because there is only ever one "loading" state —
     * no extra data is needed.
     */
    object Loading : NetworkState()

    /**
     * Indicates that the network request completed successfully.
     *
     * @property data The payload returned by the request.
     */
    data class Success(val data: String) : NetworkState()

    /**
     * Indicates that the network request failed.
     *
     * @property message A human-readable description of what went wrong.
     */
    data class NetworkError(val message: String) : NetworkState()
}

/**
 * Handles a [NetworkState] by printing a human-readable message to the console.
 *
 * The `when` expression is exhaustive: because [NetworkState] is sealed the
 * compiler guarantees that every subclass is covered, so no `else` branch is
 * required.
 *
 * @param state The current state of the network request to handle.
 */
fun handleState(state: NetworkState) {
    when (state) {
        is NetworkState.Loading      -> println("⏳ Loading... please wait.")
        is NetworkState.Success      -> println("✅ Success! Data: ${state.data}")
        is NetworkState.NetworkError -> println("❌ Error: ${state.message}")
    }
}

/**
 * Simulates a network fetch by returning a [NetworkState] based on a numeric scenario.
 *
 * | scenario | returned state                              |
 * |----------|---------------------------------------------|
 * | 1        | [NetworkState.Loading]                      |
 * | 2        | [NetworkState.Success] with a sample payload |
 * | 3        | [NetworkState.NetworkError] — timeout        |
 * | other    | [NetworkState.NetworkError] — unknown error  |
 *
 * @param scenario An integer code selecting which state to simulate.
 * @return The [NetworkState] that corresponds to the given scenario.
 */
fun simulateFetch(scenario: Int): NetworkState = when (scenario) {
    1    -> NetworkState.Loading
    2    -> NetworkState.Success("User profile loaded")
    3    -> NetworkState.NetworkError("Connection timed out")
    else -> NetworkState.NetworkError("Unknown error")
}

/**
 * Entry point for Exercise 2.
 *
 * Demonstrates:
 * - Creating a list of mixed [NetworkState] instances
 * - Using `forEach` with [handleState] to process each state
 * - Using [simulateFetch] inside a `for` loop to simulate scenarios 1-3
 * - Using `filterIsInstance<NetworkState.Success>()` to extract only successful states
 */
fun main() {
    // ── Part 1: Predefined list of states ────────────────────────────────────
    println("=== Part 1: Handling a list of network states ===\n")

    val states: List<NetworkState> = listOf(
        NetworkState.Loading,
        NetworkState.Success("User profile loaded"),
        NetworkState.NetworkError("Connection timed out"),
        NetworkState.Success("Settings retrieved"),
        NetworkState.NetworkError("404 Not Found"),
        NetworkState.Loading,
        NetworkState.Success("Notifications fetched")
    )

    states.forEach { state -> handleState(state) }

    // ── Separator ─────────────────────────────────────────────────────────────
    println()
    println("------------------------------------------------------------")
    println()

    // ── Part 2: simulateFetch loop for scenarios 1–3 ─────────────────────────
    println("=== Part 2: Simulated fetch scenarios ===\n")

    for (scenario in 1..3) {
        val result = simulateFetch(scenario)
        print("Scenario $scenario → ")
        handleState(result)
    }

    println()
    println("------------------------------------------------------------")
    println()

    // ── Part 3: Filter only successful states ────────────────────────────────
    println("=== Part 3: Successful states only ===\n")

    val successfulStates = states.filterIsInstance<NetworkState.Success>()

    if (successfulStates.isEmpty()) {
        println("No successful states found.")
    } else {
        println("Found ${successfulStates.size} successful state(s):")
        successfulStates.forEach { success ->
            println("  → ${success.data}")
        }
    }

    println()
    println("Exercise 2 complete.")
}
