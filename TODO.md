# Things to do

## Optimization

Include a benchmark mechanism.

AutoHashMap - consider the performance impact of repeated hashing (for example the swap operation hashes keys at each level during the heapify). Look into the hashmap options in the zig std library and consider a custom one.

Consider structure of arrays instead of array of structures for the Entry type. It provides better cache coherence.

Avoid allocator bugs by making sure the same allocator is used for array list and hash map operations. API level fix.

Gemini 3 suggests... Would you like me to show you how to implement the "Dense Integer Optimization" for this queue? If your Keys can be mapped to 0..N integers (common in tokenizer IDs or graph nodes), we can replace the AutoHashMap with a simple ArrayList, making the queue roughly 2-3x faster by eliminating hashing entirely.

Example code from Gemini

```zig
const std = @import("std");

pub fn IndexedPriorityQueue(
    comptime Key: type,
    comptime Value: type,
    comptime Context: type,
    comptime is_higher_priority: fn (context: Context, a: Value, b: Value) bool,
) type {
    return struct {
        const Self = @This();

        // Use MultiArrayList for SoA layout (Cache Friendly)
        // slice[0] is keys, slice[1] is values
        heap: std.MultiArrayList(struct { key: Key, value: Value }),

        map: std.AutoHashMap(Key, usize),
        allocator: std.mem.Allocator, // Store allocator to prevent mismatch
        context: Context,

        pub fn init(allocator: std.mem.Allocator, context: Context) Self {
            return Self{
                .heap = .{},
                .map = std.AutoHashMap(Key, usize).init(allocator),
                .allocator = allocator,
                .context = context,
            };
        }

        pub fn deinit(self: *Self) void {
            self.heap.deinit(self.allocator);
            self.map.deinit();
            self.* = undefined;
        }

        fn swap(self: *Self, i: usize, j: usize) void {
            // Access separate slices (SoA)
            const keys = self.heap.items(.key); 
            
            // Update map (Still incurs hashing cost, unavoidable with HashMap)
            // Note: usage of putAssumeCapacity requires ensureCapacity elsewhere
            // but standard put is safer here.
            self.map.put(keys[i], j) catch unreachable;
            self.map.put(keys[j], i) catch unreachable;

            // MultiArrayList swap handles the data movement efficiently
            self.heap.swap(self.allocator, i, j);
        }
        
        // Updated push ensures consistency using self.allocator
        pub fn push(self: *Self, key: Key, value: Value) Error!void {
            if (self.map.contains(key)) return Error.KeyAlreadyExists;

            try self.heap.append(self.allocator, .{ .key = key, .value = value });
            const new_index = self.heap.len - 1;
            try self.map.put(key, new_index);

            self.siftUp(new_index);
        }
        
        // ... Rest of implementation adapted for MultiArrayList ...
    };
}
```
