// ============================================================
// SE 3242: Android Application Development
// Grade Calculator — Kotlin Implementation
// File: Server.kt
// Branch: Precious
// Description: Local HTTP server using Ktor that serves a
//              browser-based GUI for the Grade Calculator.
// ============================================================

package com.gradecalculator.web

import com.gradecalculator.models.Student
import com.gradecalculator.services.ExcelExporter
import com.gradecalculator.services.FileParser
import com.gradecalculator.services.GradeService
import io.ktor.http.ContentDisposition
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.server.application.call
import io.ktor.server.engine.embeddedServer
import io.ktor.server.netty.Netty
import io.ktor.server.request.receiveText
import io.ktor.server.response.header
import io.ktor.server.response.respond
import io.ktor.server.response.respondBytes
import io.ktor.server.response.respondText
import io.ktor.server.routing.get
import io.ktor.server.routing.post
import io.ktor.server.routing.routing
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.double
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonPrimitive
import java.io.File
import java.nio.file.Files
import java.util.Base64

/**
 * Encapsulates the Ktor/Netty HTTP server that provides a browser-based GUI
 * for the Grade Calculator.
 *
 * Call [start] to launch the server. The server binds to `http://localhost:8080`
 * and automatically opens the default browser on Windows.
 *
 * ### Routes
 * | Method | Path        | Description                                      |