const std = @import("std");
const ido = @import("ido.zig");
const Task = ido.Task;
const fs = std.fs;

/// Interface for saving and loading tasks
pub const TaskStore = struct {
    /// Type erased pointer to the underlying implmentation
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        save: *const fn (*anyopaque, []const Task) anyerror!void,
        load: *const fn (*anyopaque, std.mem.Allocator) anyerror!std.ArrayList(Task),
    };

    pub fn save(self: TaskStore, tasks: []const Task) !void {
        return self.vtable.save(self.ptr, tasks);
    }

    pub fn load(self: TaskStore, allocator: std.mem.Allocator) !std.ArrayList(Task) {
        return self.vtable.load(self.ptr, allocator);
    }

    /// Call from the implmentation to load the interface
    ///
    /// ```zig
    /// pub fn taskStore(self: *MyStore) ido.TaskStore {
    ///     return ido.TaskStore.init(self);
    /// }
    /// ```
    pub fn init(ptr: anytype) TaskStore {
        const T = @TypeOf(ptr);
        const ptr_info = @typeInfo(T);

        if (ptr_info != .Pointer) @compileError("ptr must be a pointer");
        if (ptr_info.Pointer.size != .One) @compileError("ptr must be a single item pointer");

        const gen = comptime struct {
            pub fn save(ctx: *anyopaque, tasks: []const Task) anyerror!void {
                const self: T = @ptrCast(@alignCast(ctx));
                return ptr_info.Pointer.child.save(self, tasks);
            }
            pub fn load(
                ctx: *anyopaque,
                allocator: std.mem.Allocator,
            ) anyerror!std.ArrayList(Task) {
                const self: T = @ptrCast(@alignCast(ctx));
                return ptr_info.Pointer.child.load(self, allocator);
            }
        };

        return .{
            .ptr = ptr,
            .vtable = &.{
                .save = gen.save,
                .load = gen.load,
            },
        };
    }
};

pub const FileStore = struct {
    allocator: std.mem.Allocator,
    path: []const u8,
    contents: []const u8,

    pub fn init(allocator: std.mem.Allocator, path: []const u8) !FileStore {
        const contents = try std.fs.cwd().readFileAlloc(
            allocator,
            path,
            std.math.maxInt(usize),
        );
        return .{
            .allocator = allocator,
            .path = path,
            .contents = contents,
        };
    }

    pub fn deinit(self: FileStore) void {
        self.allocator.free(self.contents);
    }
};
