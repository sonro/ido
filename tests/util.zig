const std = @import("std");
const testing = std.testing;
const ido = @import("ido");
const Task = ido.Task;
pub const TestStore = @import("util/store.zig").TestStore;
pub const TestFile = @import("util/file.zig").TestFile;
pub const TestFormat = @import("util/format.zig");

pub const FOUR_TODOS = &.{
    .{ .name = "foo", .description = null, .done = false },
    .{ .name = "bar", .description = null, .done = false },
    .{ .name = "baz", .description = null, .done = false },
    .{ .name = "qux", .description = null, .done = false },
};
pub const FOUR_DONES = &.{
    .{ .name = "foo", .description = null, .done = true },
    .{ .name = "bar", .description = null, .done = true },
    .{ .name = "baz", .description = null, .done = true },
    .{ .name = "qux", .description = null, .done = true },
};
pub const FOUR_MIXED = &.{
    .{ .name = "foo", .description = null, .done = false },
    .{ .name = "bar", .description = null, .done = true },
    .{ .name = "baz", .description = null, .done = false },
    .{ .name = "qux", .description = null, .done = true },
};
pub const ONE_TODO = &.{FOUR_TODOS[0]};
pub const ONE_DONE = &.{FOUR_DONES[0]};
pub const EMPTY_TASKS: []const Task = &.{};

pub fn expectTaskSliceEqual(
    expected: []const Task,
    actual: []const Task,
) !void {
    try testing.expectEqual(expected.len, actual.len);
    for (expected, actual) |exp, act| {
        try expectTaskEqual(exp, act);
    }
}

pub fn expectTaskEqual(expected: Task, actual: Task) !void {
    try testing.expectEqualStrings(expected.name, actual.name);
    if (expected.description) |desc| {
        try testing.expectEqualStrings(desc, actual.description.?);
    } else {
        try testing.expectEqual(null, actual.description);
    }
    try testing.expectEqual(expected.done, actual.done);
}

pub fn checkTaskNotDone(task: Task, name: []const u8, desc: ?[]const u8) !void {
    return checkTask(task, name, desc, false);
}

pub fn checkTaskDone(task: Task, name: []const u8, desc: ?[]const u8) !void {
    return checkTask(task, name, desc, true);
}

fn checkTask(
    task: Task,
    name: []const u8,
    description: ?[]const u8,
    done: bool,
) !void {
    try expectTaskEqual(.{
        .name = name,
        .description = description,
        .done = done,
    }, task);
}
