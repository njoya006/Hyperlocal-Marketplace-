// ============================================================
// SE 3242: Android Application Development
// Week 2 - Kotlin Exercises
// Exercise 1: Model a Zoo
// Student: Precious [Last Name]
// Date: March 2026
// Description: Demonstrates abstract classes, inheritance,
//              and polymorphism in Kotlin using a Zoo example.
// ============================================================

// ── Abstract base class ──────────────────────────────────────

/**
 * Abstract representation of an animal in the zoo.
 *
 * Concrete subclasses must supply the number of [legs] and implement
 * [makeSound] to return the animal's characteristic sound.
 *
 * @property name The animal's name (e.g. "Rex", "Tweety").
 */
abstract class Animal(val name: String) {

    /**
     * The number of legs this animal has.
     * Implemented by each concrete subclass.
     */
    abstract val legs: Int

    /**
     * Returns the sound this animal makes (e.g. `"Woof!"`, `"Meow!"`).
     */
    abstract fun makeSound(): String

    /**
     * Returns a human-readable description of the animal combining its
     * name, leg count and characteristic sound.
     *
     * Example: `"Rex has 4 legs and says Woof!"`
     *
     * @return Formatted description string.
     */
    fun describe(): String = "$name has $legs legs and says ${makeSound()}"

    /**
     * Returns a concise string representation of this animal, useful
     * for printing inside collections (e.g. `"Dog(Rex)"`).
     */
    override fun toString(): String = "${this::class.simpleName}($name)"
}

// ── Concrete subclasses ──────────────────────────────────────

/**
 * A domestic dog with four legs that barks.
 *
 * @param name The dog's name.
 */
class Dog(name: String) : Animal(name) {
    /** Dogs have 4 legs. */
    override val legs: Int = 4

    /** Returns `"Woof!"`. */
    override fun makeSound(): String = "Woof!"
}

/**
 * A domestic cat with four legs that meows.
 *
 * @param name The cat's name.
 */
class Cat(name: String) : Animal(name) {
    /** Cats have 4 legs. */
    override val legs: Int = 4

    /** Returns `"Meow!"`. */
    override fun makeSound(): String = "Meow!"
}

/**
 * A bird with two legs that chirps.
 *
 * @param name The bird's name.
 */
class Bird(name: String) : Animal(name) {
    /** Birds have 2 legs. */
    override val legs: Int = 2

    /** Returns `"Tweet!"`. */
    override fun makeSound(): String = "Tweet!"
}

// ── Entry point ──────────────────────────────────────────────

/**
 * Demonstrates abstract classes, inheritance and polymorphism by
 * creating a mixed list of [Animal] instances and iterating over
 * them in several different ways.
 */
fun main() {
    val separator = "─".repeat(50)

    // Create a mixed list of animals
    val zoo: List<Animal> = listOf(
        Dog("Rex"),
        Cat("Whiskers"),
        Bird("Tweety"),
        Dog("Buddy"),
        Cat("Luna"),
        Bird("Polly"),
        Dog("Max")
    )

    // ── Section 1: for loop — print each animal's sound ──────
    println("Section 1: Animal Sounds (for loop)")
    println(separator)
    for (animal in zoo) {
        println("${animal.name} says: ${animal.makeSound()}")
    }

    println()
    println(separator)
    println()

    // ── Section 2: forEach — print full describe() ───────────
    println("Section 2: Full Descriptions (forEach)")
    println(separator)
    zoo.forEach { animal ->
        println(animal.describe())
    }

    println()
    println(separator)
    println()

    // ── Section 3: filterIsInstance — dogs only ───────────────
    println("Section 3: Dogs Only (filterIsInstance<Dog>)")
    println(separator)
    val dogs: List<Dog> = zoo.filterIsInstance<Dog>()
    dogs.forEach { dog ->
        println(dog)
    }

    println()
    println(separator)
    println("Total animals : ${zoo.size}")
    println("Dogs          : ${dogs.size}")
    println("Cats          : ${zoo.filterIsInstance<Cat>().size}")
    println("Birds         : ${zoo.filterIsInstance<Bird>().size}")
    println(separator)
}
