const Task = @import("ido").Task;
pub const tasks = [_]Task{
    .{
        .name = "just a name",
        .description = null,
        .done = false,
    },
    .{
        .name = "name",
        .description = "And a description",
        .done = false,
    },
    .{
        .name = "another name",
        .description = "With a multiline\ndescription",
        .done = false,
    },
    .{
        .name = "short name",
        .description = null,
        .done = false,
    },
    .{
        .name = "another todo",
        .description = null,
        .done = false,
    },
    .{
        .name = "done name",
        .description = null,
        .done = true,
    },
    .{
        .name = "another done name",
        .description = "with a description",
        .done = true,
    },
    .{
        .name = "short done",
        .description = null,
        .done = true,
    },
    .{
        .name = "final done",
        .description = null,
        .done = true,
    },
};
