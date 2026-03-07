// ============================================================
// SE 3242: Android Application Development
// Grade Calculator — Kotlin Implementation
// File: Main.kt
// Branch: Precious
// Description: Application entry point with startup menu
//              to choose Console or GUI mode.
// ============================================================

package com.gradecalculator

import com.gradecalculator.console.ConsoleApp
import com.gradecalculator.web.WebServer
import kotlin.system.exitProcess

/**
 * Application entry point for the Grade Calculator.
 *
 * Displays a startup banner and a mode-selection menu that lets the operator
 * choose between:
 * - **Console Mode** — guided interactive terminal session ([ConsoleApp])
 * - **GUI Mode**     — browser-based interface served by a local Ktor server ([WebServer])
 * - **Exit**         — terminates the process cleanly
 *
 * The menu loops after Console Mode completes so the operator can run another
 * session or switch to GUI Mode without restarting the application.
 */
fun main() {
	printBanner()

	while (true) {
		printMenu()
		val choice = readLine()?.trim() ?: ""
		println()
		when (choice) {
			"1" -> {
				ConsoleApp().run()
				println()
			}
			"2" -> {
				WebServer().start()   // blocks until Ctrl+C
				return
			}
			"3" -> {
				println("Goodbye!")
				exitProcess(0)
			}
			else -> {
				println("  Invalid choice. Please enter 1, 2, or 3.")
				println()
			}
		}
	}
}