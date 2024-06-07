const std = @import("std");
const testing = std.testing;
const ido = @import("ido");

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
    try testing.expectEqualStrings(name, task.name);
    if (description) |desc| {
        try testing.expectEqualStrings(desc, task.description.?);
    } else {
        try testing.expectEqual(null, task.description);
    }
    try testing.expectEqual(done, task.done);
}
