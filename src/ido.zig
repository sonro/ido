const std = @import("std");
const task = @import("task.zig");
const parser = @import("parser.zig");

pub const Task = task.Task;
pub const TaskError = task.TaskError;
pub const parseTask = parser.parseTask;
pub const ParseError = parser.ParseError;
pub const TODO_PATTERN = "TODO:";
pub const DONE_PATTERN = "DONE:";
