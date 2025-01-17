const std = @import("std");
const ido = @import("ido.zig");
const Task = ido.Task;
const fs = std.fs;
const io = std.io;

/// Interface for saving and loading tasks
pub const TaskStore = struct {
    /// Type erased pointer to the underlying implmentation
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        save: *const fn (*anyopaque, []const Task) anyerror!void,
        load: *const fn (*anyopaque, std.mem.Allocator) anyerror!std.ArrayList(Task),
        loadInto: *const fn (*anyopaque, *std.ArrayList(Task)) anyerror!void,
    };

    pub fn save(self: TaskStore, tasks: []const Task) !void {
        return self.vtable.save(self.ptr, tasks);
    }

    pub fn load(self: TaskStore, allocator: std.mem.Allocator) !std.ArrayList(Task) {
        return self.vtable.load(self.ptr, allocator);
    }

    pub fn loadInto(self: TaskStore, tasklist: *std.ArrayList(Task)) !void {
        return self.vtable.loadInto(self.ptr, tasklist);
    }

    /// Call from the implmentation to load the interface
    ///
    /// ```zig
    /// pub fn taskStore(self: *MyStore) ido.TaskStore {
    ///     return ido.TaskStore.interface(self);
    /// }
    /// ```
    pub fn interface(ptr: anytype) TaskStore {
        const impl = Implentation(@TypeOf(ptr));

        return .{
            .ptr = ptr,
            .vtable = &.{
                .save = impl.save,
                .load = impl.load,
                .loadInto = impl.loadInto,
            },
        };
    }

    fn Implentation(comptime T: type) type {
        const ptr_info = @typeInfo(T);

        if (ptr_info != .Pointer) @compileError("ptr must be a pointer");
        if (ptr_info.Pointer.size != .One) @compileError("ptr must be a single item pointer");

        return struct {
            pub fn save(ctx: *anyopaque, tasks: []const Task) anyerror!void {
                const self: T = @ptrCast(@alignCast(ctx));
                return ptr_info.Pointer.child.save(self, tasks);
            }
            pub fn load(ctx: *anyopaque, allocator: std.mem.Allocator) anyerror!std.ArrayList(Task) {
                const self: T = @ptrCast(@alignCast(ctx));
                return ptr_info.Pointer.child.load(self, allocator);
            }
            pub fn loadInto(ctx: *anyopaque, tasklist: *std.ArrayList(Task)) anyerror!void {
                const self: T = @ptrCast(@alignCast(ctx));
                return ptr_info.Pointer.child.loadInto(self, tasklist);
            }
        };
    }
};

pub fn FileStore(Format: type) type {
    if (!@hasDecl(Format, "serializeTaskList")) {
        @compileError("Format requires a serializeTaskList function");
    }
    if (!@hasDecl(Format, "parseTaskList")) {
        @compileError("Format requires a parseTaskList function");
    }
    return struct {
        allocator: std.mem.Allocator,
        path: []const u8,
        contents: []const u8,

        const Self = @This();

        /// Allocator used to store file contents
        pub fn init(allocator: std.mem.Allocator, path: []const u8) Self {
            return .{
                .allocator = allocator,
                .path = path,
                .contents = "",
            };
        }

        pub fn deinit(self: Self) void {
            self.allocator.free(self.contents);
        }

        pub fn taskStore(self: *Self) TaskStore {
            return TaskStore.interface(self);
        }

        pub fn save(self: *Self, tasks: []const Task) !void {
            var file = try fs.cwd().createFile(self.path, .{});
            defer file.close();
            var bw = io.bufferedWriter(file.writer());
            try Format.serializeTaskList(tasks, bw.writer());
            try bw.flush();
        }

        /// Allocator used to store `TaskList`
        pub fn load(self: *Self, allocator: std.mem.Allocator) !std.ArrayList(Task) {
            var tasklist = std.ArrayList(Task).init(allocator);
            try self.loadInto(&tasklist);
            return tasklist;
        }

        pub fn loadInto(self: *Self, tasklist: *std.ArrayList(Task)) !void {
            self.contents = try fs.cwd().readFileAlloc(
                self.allocator,
                self.path,
                std.math.maxInt(usize),
            );
            return try Format.parseTaskList(tasklist, self.contents);
        }
    };
}
