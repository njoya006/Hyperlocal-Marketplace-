// ============================================================
// SE 3242: Android Application Development
// Week 2 - Kotlin Exercises
// Exercise 3: Drawable Shapes with Interfaces
// Student: Precious [Last Name]
// Date: March 2026
// Description: Demonstrates interfaces, multiple interface
//              implementation, and polymorphism in Kotlin
//              using geometric shapes.
// ============================================================

import kotlin.math.PI

/**
 * Represents any object that can be drawn to the console.
 *
 * Classes that implement [Drawable] must supply a visual representation
 * via [draw] and identify themselves via [shapeType].
 */
interface Drawable {

    /**
     * Renders an ASCII-art representation of the shape to standard output.
     */
    fun draw()

    /**
     * Returns the name of this shape (e.g. "Circle", "Square", "Triangle").
     *
     * @return A human-readable string identifying the shape type.
     */
    fun shapeType(): String
}

/**
 * Represents any object whose geometric measurements can be computed.
 *
 * Classes that implement [Measurable] must provide an [area] and a [perimeter].
 */
interface Measurable {

    /**
     * Calculates and returns the area of the shape.
     *
     * @return The area expressed in square units.
     */
    fun area(): Double

    /**
     * Calculates and returns the perimeter (or circumference) of the shape.
     *
     * @return The perimeter expressed in linear units.
     */
    fun perimeter(): Double
}

// ── Concrete shape classes ────────────────────────────────────────────────────

/**
 * A geometric circle implementing both [Drawable] and [Measurable].
 *
 * @property radius The radius of the circle in abstract units.
 */
class Circle(val radius: Double) : Drawable, Measurable {

    /** Prints a simple ASCII circle to the console. */
    override fun draw() {
        println("  Shape: Circle (radius = $radius)")
        println("     *  *  *  ")
        println("  *           *")
        println(" *             *")
        println("  *           *")
        println("     *  *  *  ")
    }

    /**
     * Returns the area of the circle: $A = \pi r^2$.
     *
     * @return Area in square units.
     */
    override fun area(): Double = PI * radius * radius

    /**
     * Returns the circumference of the circle: $C = 2\pi r$.
     *
     * @return Circumference in linear units.
     */
    override fun perimeter(): Double = 2 * PI * radius

    /** @return The string `"Circle"`. */
    override fun shapeType(): String = "Circle"
}

/**
 * A geometric square implementing both [Drawable] and [Measurable].
 *
 * @property side The length of one side in abstract units.
 */
class Square(val side: Double) : Drawable, Measurable {

    /** Prints a simple ASCII square to the console. */
    override fun draw() {
        println("  Shape: Square (side = $side)")
        println("  +-------+")
        println("  |       |")
        println("  |       |")
        println("  |       |")
        println("  +-------+")
    }

    /**
     * Returns the area of the square: $A = s^2$.
     *
     * @return Area in square units.
     */
    override fun area(): Double = side * side

    /**
     * Returns the perimeter of the square: $P = 4s$.
     *
     * @return Perimeter in linear units.
     */
    override fun perimeter(): Double = 4 * side

    /** @return The string `"Square"`. */
    override fun shapeType(): String = "Square"
}

/**
 * A geometric triangle implementing both [Drawable] and [Measurable].
 *
 * The area formula uses the classic base-height formula, while the perimeter
 * assumes an equilateral-style model where all sides equal [side].
 *
 * @property base   The length of the base in abstract units.
 * @property height The perpendicular height from the base in abstract units.
 * @property side   The length of one side used for the perimeter calculation.
 */
class Triangle(val base: Double, val height: Double, val side: Double) : Drawable, Measurable {

    /** Prints a simple ASCII triangle to the console. */
    override fun draw() {
        println("  Shape: Triangle (base = $base, height = $height, side = $side)")
        println("       *       ")
        println("      * *      ")
        println("     *   *     ")
        println("    *     *    ")
        println("   *       *   ")
        println("  ***********  ")
    }

    /**
     * Returns the area of the triangle: $A = \frac{1}{2} \times base \times height$.
     *
     * @return Area in square units.
     */
    override fun area(): Double = 0.5 * base * height

    /**
     * Returns the perimeter of the triangle: $P = 3 \times side$.
     *
     * @return Perimeter in linear units.
     */
    override fun perimeter(): Double = 3 * side

    /** @return The string `"Triangle"`. */
    override fun shapeType(): String = "Triangle"
}

// ── Higher-order utility ──────────────────────────────────────────────────────

/**
 * Applies a given [action] to every [Drawable] in [shapes].
 *
 * This higher-order function abstracts iteration so callers can supply any
 * lambda without knowing the internal list mechanics.
 *
 * @param shapes A list of [Drawable] objects to operate on.
 * @param action A lambda that receives each [Drawable] and performs some work.
 */
fun applyToShapes(shapes: List<Drawable>, action: (Drawable) -> Unit) {
    shapes.forEach { shape -> action(shape) }
}

// ── Entry point ───────────────────────────────────────────────────────────────

/**
 * Entry point for Exercise 3.
 *
 * Demonstrates:
 * - Creating a `List<Drawable>` with [Circle], [Square], and [Triangle]
 * - Iterating with `forEach` to call [draw] on each shape
 * - Casting to `List<Measurable>` and printing [area] and [perimeter]
 * - Using `filterIsInstance<Circle>()` to extract only circles
 * - Calling [applyToShapes] with a lambda that prints each shape's type
 */
fun main() {
    // ── Part 1: Draw all shapes ───────────────────────────────────────────────
    println("=== Part 1: Drawing all shapes ===\n")

    val shapes: List<Drawable> = listOf(
        Circle(radius = 5.0),
        Square(side = 4.0),
        Triangle(base = 6.0, height = 4.0, side = 5.0)
    )

    shapes.forEach { shape ->
        shape.draw()
        println()
    }

    // ── Separator ─────────────────────────────────────────────────────────────
    println("------------------------------------------------------------")
    println()

    // ── Part 2: Print area and perimeter for each shape ───────────────────────
    println("=== Part 2: Measurements (area & perimeter) ===\n")

    @Suppress("UNCHECKED_CAST")
    val measurables = shapes as List<Measurable>   // safe: all shapes implement Measurable

    measurables.forEach { m ->
        // Re-cast to Drawable just to get the name for the label
        val name = (m as Drawable).shapeType()
        println("  $name")
        println("    Area      : ${"%.4f".format(m.area())} sq units")
        println("    Perimeter : ${"%.4f".format(m.perimeter())} units")
        println()
    }

    // ── Separator ─────────────────────────────────────────────────────────────
    println("------------------------------------------------------------")
    println()

    // ── Part 3: Filter only circles ───────────────────────────────────────────
    println("=== Part 3: Circles only (filterIsInstance) ===\n")

    val circles = shapes.filterIsInstance<Circle>()

    if (circles.isEmpty()) {
        println("  No circles found.")
    } else {
        println("  Found ${circles.size} circle(s):")
        circles.forEach { c ->
            println("    → Circle with radius ${c.radius}, area = ${"%.4f".format(c.area())}")
        }
    }

    println()
    println("------------------------------------------------------------")
    println()

    // ── Part 4: applyToShapes with a lambda ───────────────────────────────────
    println("=== Part 4: Shape types via applyToShapes() ===\n")

    applyToShapes(shapes) { shape ->
        println("  Shape type: ${shape.shapeType()}")
    }

    println()
    println("Exercise 3 complete.")
}
