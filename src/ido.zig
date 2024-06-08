const std = @import("std");

const serialize = @import("serialize.zig");
const parse = @import("parse.zig");
const task = @import("task.zig");

pub const Task = task.Task;
pub const TaskError = task.TaskError;

pub const parseTask = parse.parseTask;
pub const ParseError = parse.ParseError;

pub const TODO_PATTERN = "TODO:";
pub const DONE_PATTERN = "DONE:";

pub const serializeTask = serialize.serializeTask;
