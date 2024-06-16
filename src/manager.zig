const std = @import("std");
const ido = @import("ido.zig");
const Task = ido.Task;

pub const Manager = struct {
    allocator: std.mem.Allocator,
    store: ido.TaskStore,
    tasks: std.ArrayList(ido.Task),
    persist_all_changes: bool = true,

    pub fn init(allocator: std.mem.Allocator, store: ido.TaskStore) !Manager {
        var task_store = store;
        const tasks = try task_store.load(allocator);
        return Manager{
            .allocator = allocator,
            .store = task_store,
            .tasks = tasks,
        };
    }

    pub fn initManualSave(allocator: std.mem.Allocator, store: ido.TaskStore) !Manager {
        var manager = try Manager.init(allocator, store);
        manager.persist_all_changes = false;
        return manager;
    }

    pub fn deinit(self: *const Manager) void {
        self.tasks.deinit();
    }

    pub fn save(self: *Manager) !void {
        try self.store.save(self.tasks.items);
    }

    pub fn reload(self: *Manager) !void {
        self.tasks.clearRetainingCapacity();
        try self.store.loadInto(&self.tasks);
    }

    pub fn allTasks(self: *const Manager) []const Task {
        return self.tasks.items;
    }

    pub fn getTask(self: *const Manager, index: usize) ?Task {
        if (index >= self.tasks.items.len) return null;
        return self.tasks.items[index];
    }

    pub fn markDone(self: *Manager, index: usize) !Task {
        if (index >= self.tasks.items.len) return error.OutOfRange;
        self.tasks.items[index].done = true;
        if (self.persist_all_changes) try self.store.save(self.tasks.items);
        return self.tasks.items[index];
    }

    pub fn unmarkDone(self: *Manager, index: usize) !Task {
        if (index >= self.tasks.items.len) return error.OutOfRange;
        self.tasks.items[index].done = false;
        if (self.persist_all_changes) try self.store.save(self.tasks.items);
        return self.tasks.items[index];
    }

    pub fn delete(self: *Manager, index: usize) !void {
        if (index >= self.tasks.items.len) return error.OutOfRange;
        _ = self.tasks.orderedRemove(index);
        if (self.persist_all_changes) try self.store.save(self.tasks.items);
    }

    pub fn setFirst(self: *Manager, index: usize) !void {
        if (index >= self.tasks.items.len) return error.OutOfRange;
        if (index == 0) return;
        for (self.tasks.items[0..index]) |*task| {
            std.mem.swap(Task, task, &self.tasks.items[index]);
        }
        if (self.persist_all_changes) try self.store.save(self.tasks.items);
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
            try self.store.save(self.tasks.items);
        }
    }
};
