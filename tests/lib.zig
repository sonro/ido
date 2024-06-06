const std = @import("std");
const testing = std.testing;
const allocator = testing.allocator;
const ido = @import("ido");

test "create simple task" {
    const task = ido.Task.simple("name");
    try testing.expectEqualStrings("name", task.name);
    try testing.expectEqual(null, task.description);
}
