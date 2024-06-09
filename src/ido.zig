const std = @import("std");

const serialize = @import("serialize.zig");
const parse = @import("parse.zig");
const task = @import("task.zig");
const manager = @import("manager.zig");
pub const store = @import("store.zig");

pub const Manager = manager.Manager;

pub const Task = task.Task;
pub const TaskError = task.TaskError;

pub const parseTask = parse.parseTask;
pub const parseTaskList = parse.parseTaskList;
pub const ParseError = parse.ParseError;

pub const TODO_PATTERN = "TODO:";
pub const DONE_PATTERN = "DONE:";

pub const serializeTask = serialize.serializeTask;

pub const TaskStore = store.TaskStore;
