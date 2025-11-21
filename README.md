# Indexed Priority Queue for Zig

An efficient, generic, and easy-to-use Indexed Priority Queue (IPQ) implementation in Zig.

## Overview

This library provides an `IndexedPriorityQueue` data structure. An IPQ is a variation of a standard priority queue that allows for efficient `O(log N)` updates and lookups of elements using a unique key.

This is particularly useful in algorithms where the priority of an item that is already in the queue needs to be changed, such as Dijkstra's algorithm or A* search.

## Features

- **Generic:** Works with any key and value type.
- **Customizable Priority:** Use a comptime-provided function to define either a min-heap or a max-heap.
- **Efficient Performance:** All major operations are logarithmic or constant time on average.

## Performance vs. Standard Heap

| Operation     | Indexed Priority Queue | Standard Binary Heap |
|---------------|------------------------|----------------------|
| `push`        | `O(log N)`             | `O(log N)`           |
| `pop`         | `O(log N)`             | `O(log N)`           |
| `contains`    | `O(1)` (average)       | `O(N)`               |
| `get`         | `O(1)` (average)       | `O(N)`               |
| `changeValue` | `O(log N)`             | `O(N)`               |

The key advantage of an IPQ is the efficient `changeValue` and `contains` operations, which are made possible by an internal hash map that tracks the position of each key in the heap.

## Building & Testing

To build and run the tests, you can use the standard Zig build system.

### Running Tests

To run the test suite:

```sh
zig test src/indexed_priority_queue.zig
```

### Building

To build the project (if a `main` function is present):

```sh
zig build
```

## Installation

You can add this library to your own Zig project using the Zig Package Manager.

1.  **Add to `build.zig.zon`:**

    Add the `indexed_priority_queue` as a dependency in your `build.zig.zon` file. You will need to replace `<commit_hash>` with the actual commit hash you wish to use.

    ```zon
    .{
        .name = "my-project",
        .version = "0.1.0",
        .dependencies = .{
            .indexed_priority_queue = .{
                .url = "https://github.com/justinhj/indexed_priority_queue/archive/<commit_hash>.tar.gz",
                .hash = "<tarball_hash>",
            },
        },
    }
    ```

2.  **Add to `build.zig`:**

    In your `build.zig` file, add the dependency to your executable or library.

    ```zig
    const exe = b.addExecutable(.{
        .name = "my-project",
        .root_source_file = "src/main.zig",
        .target = target,
        .optimize = optimize,
    });

    // Add the package
    const ipq_dep = b.dependency("indexed_priority_queue", .{});
    exe.addModule("indexed_priority_queue", ipq_dep.module("indexed_priority_queue"));
    ```

3.  **Use in your code:**

    Now you can import and use the `IndexedPriorityQueue` in your project.

    ```zig
    const ipq = @import("indexed_priority_queue");

    pub fn main() !void {
        const MyIPQ = ipq.IndexedPriorityQueue(u32, i32, void, myComparator);
        // ...
    }
    ```
