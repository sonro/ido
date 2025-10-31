const std = @import("std");
const testing = std.testing;
const allocator = testing.allocator;
const ido = @import("ido");
const util = @import("test-util");

test "create empty" {
    const list = ido.TaskList.empty;
    try testing.expectEqual(0, list.len());
    try util.expectTaskSliceEqual(&.{}, list.asSlice());
}

test "from owned slice empty" {
    const slice: []ido.Task = &.{};
    const list = ido.TaskList.fromOwnedSlice(@constCast(slice));
    try testing.expectEqual(0, list.len());
}

test "from owned slice 1 member" {
    const slice = util.ONE_TODO;
    const list = ido.TaskList.fromOwnedSlice(@constCast(slice));
    try testing.expectEqual(1, list.len());
    try util.expectTaskSliceEqual(util.ONE_TODO, list.asSlice());
}

test "from owned slice multi members" {
    const slice = util.FOUR_MIXED;
    const list = ido.TaskList.fromOwnedSlice(@constCast(slice));
    try testing.expectEqual(util.FOUR_MIXED.len, list.len());
    try util.expectTaskSliceEqual(util.FOUR_MIXED, list.asSlice());
}

test "append task" {
    const task = util.ONE_TODO[0];
    var list = ido.TaskList.empty;
    defer list.deinit(allocator);
    const id = try list.append(allocator, task);
    try testing.expectEqual(1, id);
    try testing.expectEqual(1, list.len());
    try util.expectTaskSliceEqual(util.ONE_TODO, list.asSlice());
}

test "append multiple tasks" {
    var list = ido.TaskList.empty;
    defer list.deinit(allocator);
    for (util.FOUR_MIXED, 1..) |task, i| {
        const id = try list.append(allocator, task);
        try testing.expectEqual(i, id);
        try testing.expectEqual(i, list.len());
    }
    try util.expectTaskSliceEqual(util.FOUR_MIXED, list.asSlice());
}

test "append task slice" {
    var list = ido.TaskList.empty;
    defer list.deinit(allocator);
    try list.appendSlice(allocator, util.FOUR_MIXED);
    try testing.expectEqual(util.FOUR_MIXED.len, list.len());
    try util.expectTaskSliceEqual(util.FOUR_MIXED, list.asSlice());
}

test "get from empty list" {
    const list = ido.TaskList.empty;
    const err = list.get(1);
    try testing.expectError(error.OutOfBounds, err);
}

test "get zero indexed" {
    const list = ido.TaskList.fromOwnedSlice(@constCast(util.FOUR_MIXED));
    const err = list.get(0);
    try testing.expectError(error.OutOfBounds, err);
}

test "get success" {
    const list = ido.TaskList.fromOwnedSlice(@constCast(util.FOUR_MIXED));
    for (util.FOUR_MIXED, 1..) |expected, id| {
        const actual = try list.get(id);
        try util.expectTaskEqual(expected, actual);
    }
}

test "remove empty list" {
    var list = ido.TaskList.empty;
    const err = list.remove(1);
    try testing.expectError(error.OutOfBounds, err);
}

test "remove zero indexed" {
    var list = ido.TaskList.fromOwnedSlice(@constCast(util.FOUR_MIXED));
    const err = list.remove(0);
    try testing.expectError(error.OutOfBounds, err);
}

test "remove success" {
    const len = util.FOUR_MIXED.len;
    var arr: [4]ido.Task = undefined;
    @memcpy(&arr, util.FOUR_MIXED);
    var list = ido.TaskList.fromOwnedSlice(&arr);
    const removed = try list.remove(2);
    try util.expectTaskEqual(util.FOUR_MIXED[1], removed);
    try testing.expectEqual(len - 1, list.len());
}
