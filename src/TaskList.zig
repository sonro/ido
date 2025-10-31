const std = @import("std");
const ido = @import("ido.zig");
const Error = ido.Error;

const ListImpl = std.ArrayList(ido.Task);
const empty_list_impl = ListImpl.empty;

pub const TaskList = @This();
const Self = @This();

impl: ListImpl = empty_list_impl,

pub const empty: Self = .{
    .impl = empty_list_impl,
};

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
