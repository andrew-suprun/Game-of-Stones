const std = @import("std");
const ArrayList = std.ArrayList;

pub fn heapAdd(comptime T: type, comptime max_items: isize, comptime less: fn (T, T) bool, item: T, items: *ArrayList(T)) void {
    if (items.items.len == max_items) {
        if (!less(items.items[0], item)) return;

        items.items[0] = item;
        siftDown(T, less, items);
        return;
    }
    items.append(item) catch {};
    siftUp(T, less, items);
}

fn siftUp(comptime T: type, less: fn (T, T) bool, items: *ArrayList(T)) void {
    var child_idx = items.items.len - 1;
    const child = items.items[child_idx];
    while (child_idx > 0 and less(child, items.items[(child_idx - 1) / 2])) {
        const parent_idx = (child_idx - 1) / 2;
        items.items[child_idx] = items.items[parent_idx];
        child_idx = parent_idx;
    }
    items.items[child_idx] = child;
}

fn siftDown(comptime T: type, less: fn (T, T) bool, items: *ArrayList(T)) void {
    var idx: usize = 0;
    const elem = items.items[idx];
    while (true) {
        var first = idx;
        const left_child_idx = idx * 2 + 1;
        if (left_child_idx < items.items.len and less(items.items[left_child_idx], elem)) {
            first = left_child_idx;
        }
        const right_child_idx = idx * 2 + 2;
        if (right_child_idx < items.items.len and
            less(items.items[right_child_idx], elem) and
            less(items.items[right_child_idx], items.items[left_child_idx]))
        {
            first = right_child_idx;
        }
        if (idx == first) break;

        items.items[idx] = items.items[first];
        idx = first;
    }
    items.items[idx] = elem;
}

fn testLess(i: isize, j: isize) bool {
    return i < j;
}

test "heapAdd" {
    var items = ArrayList(isize).init(std.testing.allocator);

    for (0..100) |i| {
        heapAdd(isize, 20, testLess, @intCast(i * 17 % 100), &items);
    }

    for (1..20) |i| {
        const parent = items.items[(i - 1) / 2];
        const child = items.items[i];
        try std.testing.expect(parent < child);
    }
    items.deinit();
}

// Benchmark
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var items = ArrayList(isize).init(allocator);

    var timer = try std.time.Timer.start();
    for (0..5) |_| {
        for (0..1_000_000) |_| {
            items.clearRetainingCapacity();
            for (0..100) |i| {
                heapAdd(isize, 20, testLess, @intCast(i * 17 % 100), &items);
            }

            for (1..20) |i| {
                const parent = items.items[(i - 1) / 2];
                const child = items.items[i];
                try std.testing.expect(parent < child);
            }
        }
        const dur = timer.lap();
        std.debug.print("{d} sec\n", .{@as(f64, @floatFromInt(dur)) / 1_000_000_000});
    }

    items.deinit();
}
