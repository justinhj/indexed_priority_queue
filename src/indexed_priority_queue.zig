const std = @import("std");
const Allocator = std.mem.Allocator;

// Ported from https://www.geeksforgeeks.org/cpp/indexed-priority-queue-with-implementation/
// by Gemini 2.5 Pro

/// Errors that can be returned by IndexedPriorityQueue operations.
pub const Error = error{
    Underflow,
    KeyAlreadyExists,
    KeyNotFound,
    OutOfMemory,
};

/// An Indexed Priority Queue (IPQ).
///
/// It's a priority queue that also provides efficient O(log N) lookup and update
/// of elements by a unique key. It's implemented as a binary heap.
///
/// - `Key`: The type used to uniquely identify elements. Must be hashable and equatable.
/// - `Value`: The type that determines the priority.
/// - `Context`: An optional context object passed to the comparator. Use `void` if not needed.
/// - `is_higher_priority`: A comptime function that compares two values.
///   It must return `true` if the first argument has a higher priority than the second.
///   For a max-heap, this would be `a > b`. For a min-heap, `a < b`.
pub fn IndexedPriorityQueue(
    comptime Key: type,
    comptime Value: type,
    comptime Context: type,
    comptime is_higher_priority: fn (context: Context, a: Value, b: Value) bool,
) type {
    return struct {
        const Self = @This();
        pub const Entry = struct { key: Key, value: Value };

        // The binary heap is just a dynamic array
        heap: std.ArrayList(Entry),

        // Maps keys to their index in the `heap` array.
        map: std.AutoHashMap(Key, usize),

        // Allocator for the heap and map.
        allocator: Allocator,

        // User-provided context for the comparator.
        context: Context,

        /// Initializes a new, empty IndexedPriorityQueue.
        pub fn init(allocator: Allocator, context: Context) Self {
            return Self{
                .heap = std.ArrayList(Entry).init(allocator),
                .map = std.AutoHashMap(Key, usize).init(allocator),
                .allocator = allocator,
                .context = context,
            };
        }

        /// Deinitializes the IPQ, freeing all associated memory.
        pub fn deinit(self: *Self) void {
            self.heap.deinit();
            self.map.deinit();
            self.* = undefined;
        }

        pub fn size(self: *const Self) usize {
            return self.heap.items.len;
        }

        pub fn isEmpty(self: *const Self) bool {
            return self.heap.items.len == 0;
        }

        /// Returns true if the queue contains the given key.
        pub fn contains(self: *const Self, key: Key) bool {
            return self.map.contains(key);
        }

        /// Returns a const pointer to the highest-priority element without removing it.
        /// Returns `null` if the queue is empty.
        pub fn top(self: *const Self) ?*const Entry {
            if (self.isEmpty()) {
                return null;
            }
            return &self.heap.items[0];
        }

        /// Adds a new key-value pair to the queue.
        /// Returns `error.KeyAlreadyExists` if the key is already present.
        pub fn push(self: *Self, key: Key, value: Value) Error!void {
            if (self.map.contains(key)) {
                return Error.KeyAlreadyExists;
            }

            const new_entry = Entry{ .key = key, .value = value };
            try self.heap.append(new_entry);
            const new_index = self.heap.items.len - 1;
            try self.map.put(key, new_index);

            self.siftUp(new_index);
        }

        /// Removes and returns the highest-priority element.
        /// Returns `error.Underflow` if the queue is empty.
        pub fn pop(self: *Self) Error!Entry {
            if (self.isEmpty()) {
                return Error.Underflow;
            }

            const top_entry = self.heap.items[0];
            _ = self.map.remove(top_entry.key);

            if (self.heap.items.len > 1) {
                const last_entry = self.heap.pop();
                self.heap.items[0] = last_entry.?;
                // Update the map for the element that was moved to the root.
                _ = self.map.put(last_entry.?.key, 0) catch unreachable;
                self.siftDown(0);
            } else {
                _ = self.heap.pop();
            }

            return top_entry;
        }

        /// Changes the value associated with a given key.
        /// The element's position is adjusted to maintain the heap property.
        /// Returns `error.KeyNotFound` if the key does not exist.
        pub fn changeValue(self: *Self, key: Key, new_value: Value) Error!void {
            const index = self.map.get(key) orelse return Error.KeyNotFound;
            const old_value = self.heap.items[index].value;
            self.heap.items[index].value = new_value;

            // Decide whether to sift up or down based on the new priority.
            if (is_higher_priority(self.context, new_value, old_value)) {
                self.siftUp(index);
            } else {
                self.siftDown(index);
            }
        }

        /// Creates a deep copy of the IPQ.
        pub fn clone(self: *const Self) Error!Self {
            // Clone the heap's ArrayList. If this fails, we exit immediately.
            const new_heap = try self.heap.clone();

            // If heap.clone() succeeds but map.clone() fails, this errdefer
            // ensures the newly allocated heap memory is freed.
            errdefer new_heap.deinit();

            // Clone the map.
            const new_map = try self.map.clone();

            // Both clones were successful, so we can construct the new IPQ.
            return Self{
                .heap = new_heap,
                .map = new_map,
                .allocator = self.allocator,
                .context = self.context,
            };
        }

        // --- Private Helper Methods ---

        fn parent(_: *const Self, i: usize) usize {
            return (i - 1) / 2;
        }

        fn leftChild(_: *const Self, i: usize) usize {
            return 2 * i + 1;
        }

        fn rightChild(_: *const Self, i: usize) usize {
            return 2 * i + 2;
        }

        fn swap(self: *Self, i: usize, j: usize) void {
            // Update the map with the new indices before swapping in the heap.
            _ = self.map.put(self.heap.items[i].key, j) catch unreachable;
            _ = self.map.put(self.heap.items[j].key, i) catch unreachable;

            // Swap the entries in the heap.
            std.mem.swap(Entry, &self.heap.items[i], &self.heap.items[j]);
        }

        fn siftUp(self: *Self, start_index: usize) void {
            var index = start_index;
            while (index > 0) {
                const parent_index = self.parent(index);
                if (is_higher_priority(self.context, self.heap.items[index].value, self.heap.items[parent_index].value)) {
                    self.swap(index, parent_index);
                    index = parent_index;
                } else {
                    return;
                }
            }
        }

        fn siftDown(self: *Self, start_index: usize) void {
            var index = start_index;
            const len = self.heap.items.len;

            while (true) {
                const left = self.leftChild(index);
                const right = self.rightChild(index);
                var suitable_node = index;

                if (left < len and is_higher_priority(self.context, self.heap.items[left].value, self.heap.items[suitable_node].value)) {
                    suitable_node = left;
                }
                if (right < len and is_higher_priority(self.context, self.heap.items[right].value, self.heap.items[suitable_node].value)) {
                    suitable_node = right;
                }

                if (suitable_node != index) {
                    self.swap(index, suitable_node);
                    index = suitable_node;
                } else {
                    return;
                }
            }
        }
    };
}

// --- Test Code ---

 const Test = if (@import("builtin").is_test) struct {
    // Comparator for a max-heap of integers. `a` has higher priority if it's greater than `b`.
    fn intMaxHeapComparator(_: void, a: i32, b: i32) bool {
        return a > b;
    }
 } else struct {};

test "IndexedPriorityQueue operations" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // Define the concrete type for our IPQ (i32 key, i32 value, max-heap).
    const IntIntMaxIPQ = IndexedPriorityQueue(i32, i32, void, Test.intMaxHeapComparator);

    // Create an instance of the IPQ.
    var ipq = IntIntMaxIPQ.init(allocator, {});
    defer ipq.deinit();

    // -- Check initial state --
    try testing.expect(ipq.isEmpty());
    try testing.expectEqual(@as(usize, 0), ipq.size());
    try testing.expect(!ipq.contains(1));

    // -- Insert pairs (2, 1), (3, 7), (1, 0) and (4, 5) --
    try ipq.push(2, 1);
    try ipq.push(3, 7);
    try ipq.push(1, 0);
    try ipq.push(4, 5);

    // -- Check contains after insertion --
    try testing.expect(ipq.contains(1));
    try testing.expect(ipq.contains(2));
    try testing.expect(ipq.contains(3));
    try testing.expect(ipq.contains(4));
    try testing.expect(!ipq.contains(5));

    // -- Check state after insertion --
    try testing.expectEqual(@as(usize, 4), ipq.size());
    // The top element should be the one with the highest value (7)
    var top_entry = ipq.top().?;
    try testing.expectEqual(@as(i32, 3), top_entry.key);
    try testing.expectEqual(@as(i32, 7), top_entry.value);

    // -- Change value associated with key 3 to 2 and 1 to 9 --
    try ipq.changeValue(3, 2);
    try ipq.changeValue(1, 9);

    // -- Check state after value change --
    try testing.expectEqual(@as(usize, 4), ipq.size());
    // The new top element should be key 1 with the new highest value (9)
    top_entry = ipq.top().?;
    try testing.expectEqual(@as(i32, 1), top_entry.key);
    try testing.expectEqual(@as(i32, 9), top_entry.value);

    // -- Pop two elements --
    var popped = try ipq.pop();
    try testing.expectEqual(@as(i32, 1), popped.key); // Popped (1, 9)
    try testing.expectEqual(@as(i32, 9), popped.value);
    try testing.expect(!ipq.contains(1));

    popped = try ipq.pop();
    try testing.expectEqual(@as(i32, 4), popped.key); // Popped (4, 5)
    try testing.expectEqual(@as(i32, 5), popped.value);
    try testing.expect(!ipq.contains(4));

    // -- Check final state --
    try testing.expectEqual(@as(usize, 2), ipq.size());
    // The final top element should be key 3 with value 2
    top_entry = ipq.top().?;
    try testing.expectEqual(@as(i32, 3), top_entry.key);
    try testing.expectEqual(@as(i32, 2), top_entry.value);
    try testing.expect(ipq.contains(2));
    try testing.expect(ipq.contains(3));
}