const std = @import("std");
const testing = std.testing;
const allocator = testing.allocator;
const ido = @import("ido");
const util = @import("test-util");

test "create empty" {
    const list = ido.TaskList.empty;
    try testing.expectEqual(0, list.len());
}

test "init from owned slice empty" {
    const slice: []ido.Task = &.{};
    const list = ido.TaskList.fromOwnedSlice(@constCast(slice));
    try testing.expectEqual(0, list.len());
}

test "init from owned slice 1 member" {
    const slice = util.ONE_TODO;
    const list = ido.TaskList.fromOwnedSlice(@constCast(slice));
    try testing.expectEqual(1, list.len());
    try util.expectTaskSliceEqual(util.ONE_TODO, list.asSlice());
}

test "init from owned slice multi members" {
    const slice = util.FOUR_MIXED;
    const list = ido.TaskList.fromOwnedSlice(@constCast(slice));
    try testing.expectEqual(util.FOUR_MIXED.len, list.len());
    try util.expectTaskSliceEqual(util.FOUR_MIXED, list.asSlice());
}
