const manager = @import("manager.zig");
const store = @import("store.zig");

pub const Task = @import("Task.zig");
pub const Format = @import("Format.zig");
pub const Manager = manager.Manager;
pub const TaskStore = store.TaskStore;
pub const FileStore = store.FileStore;

pub const TODO_PATTERN = "TODO:";
pub const DONE_PATTERN = "DONE:";

pub const Error = error{
    NoTaskName,
};
