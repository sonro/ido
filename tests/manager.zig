const std = @import("std");
const testing = std.testing;
const allocator = testing.allocator;
const ido = @import("ido");
const util = @import("util.zig");

test "create task manager with no tasks" {
    var store = util.TestStore.init(&.{});
    const manager = try ido.Manager.init(allocator, store.taskStore());
    defer manager.deinit();
    try util.expectTaskSliceEqual(&.{}, manager.allTasks());
}

test "create task manager with tasks" {
    const task1 = .{ .name = "foo", .description = null, .done = false };
    const task2 = .{ .name = "bar", .description = null, .done = true };
    var store = util.TestStore.init(&.{ task1, task2 });
    const manager = try ido.Manager.init(allocator, store.taskStore());
    defer manager.deinit();
    try util.expectTaskSliceEqual(&.{ task1, task2 }, manager.allTasks());
}
