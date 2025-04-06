const std = @import("std");

pub fn Heap(comptime T: type, comptime size: usize, comptime less: fn (T, T) bool) type {
    return struct {
        const Self = @This();

        storage: [size]T = undefined,
        len: usize = 0,

        pub fn add(self: *Self, item: T) void {
            if (self.len == size) {
                if (!less(self.storage[0], item)) return;

                self.storage[0] = item;
                self.siftDown();
                return;
            }
            self.storage[self.len] = item;
            self.len += 1;
            self.siftUp();
        }

        pub fn items(self: *Self) []T {
            return self.storage[0..self.len];
        }

        pub fn clear(self: *Self) void {
            self.len = 0;
        }

        fn siftUp(self: *Self) void {
            var child_idx = self.len - 1;
            const child = self.storage[child_idx];
            while (child_idx > 0 and less(child, self.storage[(child_idx - 1) / 2])) {
                const parent_idx = (child_idx - 1) / 2;
                self.storage[child_idx] = self.storage[parent_idx];
                child_idx = parent_idx;
            }
            self.storage[child_idx] = child;
        }

        fn siftDown(self: *Self) void {
            var idx: usize = 0;
            const elem = self.storage[idx];
            while (true) {
                var first = idx;
                const left_child_idx = idx * 2 + 1;
                if (left_child_idx < self.len and less(self.storage[left_child_idx], elem)) {
                    first = left_child_idx;
                }
                const right_child_idx = idx * 2 + 2;
                if (right_child_idx < self.len and
                    less(self.storage[right_child_idx], elem) and
                    less(self.storage[right_child_idx], self.storage[left_child_idx]))
                {
                    first = right_child_idx;
                }
                if (idx == first) break;

                self.storage[idx] = self.storage[first];
                idx = first;
            }
            self.storage[idx] = elem;
        }
    };
}

fn testLess(i: usize, j: usize) bool {
    return i < j;
}

test "heapAdd" {
    var heap = Heap(usize, 20, testLess){};

    for (0..100) |i| {
        const v: usize = i * 17 % 100;
        heap.add(v);
    }

    const items = heap.items();
    for (1..20) |i| {
        const parent = items[(i - 1) / 2];
        const child = items[i];
        std.debug.print("t: i: {} p: {}, c: {}\n", .{ i, parent, child });
        try std.testing.expect(parent < child);
    }
}

// Benchmark
pub fn main() !void {
    var heap = Heap(usize, 20, testLess){};

    var minDur: u64 = std.math.maxInt(u64);
    var timer = try std.time.Timer.start();
    for (0..10) |_| {
        for (0..1_000_000) |_| {
            heap.clear();
            for (0..100) |i| {
                heap.add(i * 17 % 100);
            }
            std.mem.doNotOptimizeAway(heap);
        }
        const dur = timer.lap();
        if (minDur > dur) {
            minDur = dur;
        }
    }
    std.debug.print("heap:       {d} sec\n", .{@as(f64, @floatFromInt(minDur)) / 1_000_000_000});
}
