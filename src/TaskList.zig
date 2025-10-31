const std = @import("std");
const Allocator = std.mem.Allocator;
const ido = @import("ido.zig");

const ListImpl = std.ArrayList(ido.Task);
const empty_list_impl = ListImpl.empty;

pub const TaskList = @This();
const Self = @This();

impl: ListImpl = empty_list_impl,

pub const empty: Self = .{
    .impl = empty_list_impl,
};

pub fn deinit(self: *Self, allo: Allocator) void {
    self.impl.deinit(allo);
}

/// Takes ownership of the passed in slice.
/// Deinitialize with `deinit` or use `toOwnedSlice`.
pub fn fromOwnedSlice(slice: []ido.Task) Self {
    return .{
        .impl = ListImpl.fromOwnedSlice(slice),
    };
}

pub fn len(self: Self) usize {
    return self.impl.items.len;
}

pub fn asSlice(self: Self) []const ido.Task {
    return self.impl.items;
}

pub fn append(self: *Self, allo: Allocator, task: ido.Task) !usize {
    try self.impl.append(allo, task);
    // id is array idx + 1
    return self.impl.items.len;
}

pub fn appendSlice(self: *Self, allo: Allocator, slice: []const ido.Task) !void {
    try self.impl.appendSlice(allo, slice);
}

/// 1 indexed ids
pub fn get(self: Self, id: usize) ido.Error!ido.Task {
    if (self.isIdValid(id)) return error.OutOfBounds;
    return self.impl.items[id - 1];
}

pub fn remove(self: *Self, id: usize) ido.Error!ido.Task {
    if (self.isIdValid(id)) return error.OutOfBounds;
    return self.impl.orderedRemove(id - 1);
}

fn isIdValid(self: Self, id: usize) bool {
    return id > self.impl.items.len or id == 0;
}
