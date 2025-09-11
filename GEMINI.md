# Gemini Project Context: Indexed Priority Queue

## Project Overview

This project is a single-file Zig library that implements an "Indexed Priority Queue" (IPQ). An IPQ is a priority queue data structure that also allows for efficient O(log N) lookup and value updates for elements using a unique key.

The implementation is a generic data structure that uses a binary heap (`std.ArrayList`) internally, paired with a hash map (`std.AutoHashMap`) to track the indices of keys. The file `indexed_priority_queue.zig` contains the core data structure, and it also includes comprehensive tests within a `test` block to verify its functionality.

*   **Language:** Zig
*   **Core Technology:** Generic data structures, compile-time polymorphism.
*   **Architecture:** A single file containing a generic `IndexedPriorityQueue` function that returns a struct type. This is a common Zig pattern for creating generic data structures.

## Building and Running

The project uses the standard Zig build system.

*   **Build the project:**
    ```sh
    zig build
    ```
    This will create an executable in `zig-out/bin/`.

*   **Run the executable (if it has a `main` function):**
    ```sh
    zig build run
    ```

*   **Run the tests:**
    ```sh
    zig test indexed_priority_queue.zig
    ```

## Development Conventions

*   **Testing:** Tests are included directly in the source file (`indexed_priority_queue.zig`) inside a `test "description" { ... }` block. Test-specific helper functions are defined within a `const Test = if (@import("builtin").is_test) struct { ... }` block to ensure they are not included in release builds. `std.testing.allocator` is used for memory management in tests.
*   **Generics:** The main data structure is a function that returns a type, a common Zig pattern for generics. It is parameterized using `comptime` arguments for the key type, value type, and a custom comparator function.
*   **Memory Management:** The data structure requires an `Allocator` to be passed in on initialization. The caller is responsible for managing the allocator's lifecycle.
