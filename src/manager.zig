const std = @import("std");
const ido = @import("ido.zig");
const Task = ido.Task;

pub const Manager = struct {
    store: ido.TaskStore,
    tasks: std.ArrayList(ido.Task) = .empty,
    allocator: std.mem.Allocator,
    persist_all_changes: bool = true,

    pub fn init(allocator: std.mem.Allocator, store: ido.TaskStore) !Manager {
        return Manager{
            .store = store,
            .allocator = allocator,
        };
    }

    pub fn initManualSave(allocator: std.mem.Allocator, store: ido.TaskStore) !Manager {
        var manager = try Manager.init(allocator, store);
        manager.persist_all_changes = false;
        return manager;
    }

    pub fn deinit(self: *Manager) void {
        self.tasks.deinit(self.allocator);
    }

    pub fn save(self: *Manager) !void {
        try self.store.save(self.tasks.items);
    }

    pub fn load(self: *Manager) !void {
        self.tasks.clearRetainingCapacity();
        try self.store.loadInto(self.allocator, &self.tasks);
    }

    pub fn allTasks(self: *const Manager) []const Task {
        return self.tasks.items;
    }

    pub fn getTask(self: *const Manager, index: usize) ?Task {
        if (index >= self.tasks.items.len) return null;
        return self.tasks.items[index];
    }

    pub fn addTask(self: *Manager, task: Task) !usize {
        try self.tasks.append(self.allocator, task);
        if (self.persist_all_changes) try self.save();
        return self.tasks.items.len - 1;
    }

    pub fn markDone(self: *Manager, index: usize) !Task {
        if (index >= self.tasks.items.len) return error.OutOfRange;
        const task = &self.tasks.items[index];
        if (!task.done) {
            task.done = true;
            if (self.persist_all_changes) try self.save();
        }
        return task.*;
    }

    pub fn unmarkDone(self: *Manager, index: usize) !Task {
        if (index >= self.tasks.items.len) return error.OutOfRange;
        const task = &self.tasks.items[index];
        if (task.done) {
            task.done = false;
            if (self.persist_all_changes) try self.save();
        }
        return task.*;
    }

    pub fn delete(self: *Manager, index: usize) !void {
        if (index >= self.tasks.items.len) return error.OutOfRange;
        _ = self.tasks.orderedRemove(index);
        if (self.persist_all_changes) try self.save();
    }

    pub fn setFirst(self: *Manager, index: usize) !void {
        if (index >= self.tasks.items.len) return error.OutOfRange;
        if (index == 0) return;
        for (self.tasks.items[0..index]) |*task| {
            std.mem.swap(Task, task, &self.tasks.items[index]);
        }
        if (self.persist_all_changes) try self.save();
    }

    pub fn deleteAllDone(self: *Manager) !void {
        var deleted: usize = 0;
        // reverse iterate to preserve order
        var i = self.tasks.items.len;
        while (i > 0) {
            i -= 1;
            if (self.tasks.items[i].done) {
                _ = self.tasks.orderedRemove(i);
                deleted += 1;
            }
        }
        if (self.persist_all_changes and deleted > 0) {
            try self.save();
        }
    }
};
