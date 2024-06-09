const std = @import("std");
const testing = std.testing;
const ido = @import("ido");

pub fn expectTaskEqual(expected: ido.Task, actual: ido.Task) !void {
    try testing.expectEqualStrings(expected.name, actual.name);
    if (expected.description) |desc| {
        try testing.expectEqualStrings(desc, actual.description.?);
    } else {
        try testing.expectEqual(null, actual.description);
    }
    try testing.expectEqual(expected.done, actual.done);
}

pub fn checkTaskNotDone(task: ido.Task, name: []const u8, desc: ?[]const u8) !void {
    return checkTask(task, name, desc, false);
}

pub fn checkTaskDone(task: ido.Task, name: []const u8, desc: ?[]const u8) !void {
    return checkTask(task, name, desc, true);
}

fn checkTask(
    task: ido.Task,
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
