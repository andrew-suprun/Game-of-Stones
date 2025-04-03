const std = @import("std");

pub fn Heap(comptime T: type, comptime size: usize, comptime less: fn (T, T) bool) type {
    return struct {
        const Self = @This();

        _items: [size]T,
        len: usize,

        pub fn init() Self {
            return Self{
                ._items = undefined,
                .len = 0,
            };
        }

        pub fn add(self: *Self, item: T) void {
            if (self.len == size) {
                if (!less(self._items[0], item)) return;

                self._items[0] = item;
                self.siftDown();
                return;
            }
            self._items[self.len] = item;
            self.len += 1;
            self.siftUp();
        }

        pub fn items(self: *Self) []T {
            return self._items[0..self.len];
        }

        pub fn clear(self: *Self) void {
            self.len = 0;
        }

        fn siftUp(self: *Self) void {
            var child_idx = self.len - 1;
            const child = self._items[child_idx];
            while (child_idx > 0 and less(child, self._items[(child_idx - 1) / 2])) {
                const parent_idx = (child_idx - 1) / 2;
                self._items[child_idx] = self._items[parent_idx];
                child_idx = parent_idx;
            }
            self._items[child_idx] = child;
        }

        fn siftDown(self: *Self) void {
            var idx: usize = 0;
            const elem = self._items[idx];
            while (true) {
                var first = idx;
                const left_child_idx = idx * 2 + 1;
                if (left_child_idx < self.len and less(self._items[left_child_idx], elem)) {
                    first = left_child_idx;
                }
                const right_child_idx = idx * 2 + 2;
                if (right_child_idx < self.len and
                    less(self._items[right_child_idx], elem) and
                    less(self._items[right_child_idx], self._items[left_child_idx]))
                {
                    first = right_child_idx;
                }
                if (idx == first) break;

                self._items[idx] = self._items[first];
                idx = first;
            }
            self._items[idx] = elem;
        }
    };
}

fn testLess(i: isize, j: isize) bool {
    return i < j;
}

test "heapAdd" {
    var heap = Heap(isize, 20, testLess).init();

    for (0..100) |i| {
        const v: isize = @intCast(i * 17 % 100);
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
    var heap = Heap(isize, 20, testLess).init();
    var timer = try std.time.Timer.start();

    for (0..5) |_| {
        for (0..1_000_000) |_| {
            heap.clear();
            for (0..100) |i| {
                heap.add(@intCast(i * 17 % 100));
            }
        }
        const dur = timer.lap();
        std.debug.print("{d} sec\n", .{@as(f64, @floatFromInt(dur)) / 1_000_000_000});
    }
}
