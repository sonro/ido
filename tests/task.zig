const std = @import("std");
const testing = std.testing;
const allocator = testing.allocator;
const ido = @import("ido");

test "create new simple task" {
    const task = try ido.Task.newSimple("a");
    try checkTask(task, "a", null);
}

test "create new simple task with empty name" {
    const res = ido.Task.newSimple("");
    try testing.expectError(ido.TaskError.NoTaskName, res);
}

test "create new task with description" {
    const task = try ido.Task.new("a", "b");
    try checkTask(task, "a", "b");
}

test "create new task with empty name" {
    const res = ido.Task.new("", "b");
    try testing.expectError(ido.TaskError.NoTaskName, res);
}

test "create new task with empty description" {
    const task = try ido.Task.new("a", "");
    try checkTask(task, "a", null);
}

test "create new task with empty name and description" {
    const res = ido.Task.new("", "");
    try testing.expectError(ido.TaskError.NoTaskName, res);
}

fn checkTask(task: ido.Task, name: []const u8, description: ?[]const u8) !void {
    try testing.expectEqualStrings(name, task.name);
    if (description) |desc| {
        try testing.expectEqualStrings(desc, task.description.?);
    } else {
        try testing.expectEqual(null, task.description);
    }
}
