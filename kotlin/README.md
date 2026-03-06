# Kotlin Implementation — Grade Calculator

This folder contains the Kotlin implementation of the Grade Calculator project, developed as part of **SE 3242: Android Application Development**. It mirrors the functionality of the Dart implementation and is maintained by the assigned partner.

---

## Expected Structure

```
kotlin/
├── src/
│   ├── main/
│   │   └── kotlin/
│   │       ├── models/
│   │       │   └── Student.kt
│   │       ├── services/
│   │       │   ├── GradeService.kt
│   │       │   ├── FileParser.kt
│   │       │   └── ExcelExport.kt
│   │       ├── console/
│   │       │   └── ConsoleApp.kt
│   │       └── web/
│   │           └── Server.kt
│   └── main.kt
├── exercises/
│   ├── exercise1_zoo.kt
│   ├── exercise2_network_state.kt
│   └── exercise3_drawable_shapes.kt
└── build.gradle
```

---

## Branch

This Kotlin implementation lives on the **[PartnerName]** branch of the shared repository.  
Replace `[PartnerName]` with your actual branch name before pushing.

---

## How to Run

1. Make sure you have the [Kotlin compiler](https://kotlinlang.org/docs/command-line.html) or [IntelliJ IDEA](https://www.jetbrains.com/idea/) installed.
2. Navigate to the `kotlin/` directory:
   ```bash
   cd kotlin
   ```
3. Build the project using Gradle:
   ```bash
   ./gradlew build
   ```
4. Run the console application:
   ```bash
   ./gradlew run
   ```

> On Windows, use `gradlew.bat` instead of `./gradlew`.

---

## Dependencies

The following libraries are required for the Kotlin implementation:

| Dependency | Purpose |
|---|---|
| [Apache POI](https://poi.apache.org/) | Excel file export (`.xlsx`) |
| [OpenCSV](http://opencsv.sourceforge.net/) or `kotlin-csv` | Reading and parsing CSV input files |
| [Ktor](https://ktor.io/) | Embedded HTTP server for the web interface |
| Kotlin Standard Library | Core language features |

Add these to your `build.gradle` under the `dependencies` block.
