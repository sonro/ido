const std = @import("std");
const ido = @import("ido");

const usage = "Usage: zig ido -f <file.ido>";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    const args = try Args.init(arena.allocator());

    var store = ido.FileStore(ido.Format).init(arena.allocator(), args.file);
    var manager = try ido.Manager.init(arena.allocator(), store.taskStore());

    try manager.load();

    var stdout = std.io.bufferedWriter(std.io.getStdOut().writer());
    try ido.Format.serializeTaskList(manager.allTasks(), stdout.writer());
    try stdout.flush();
}

const Args = struct {
    file: []const u8,

    pub fn init(allocator: std.mem.Allocator) !Args {
        const args = try std.process.argsAlloc(allocator);

        if (args.len != 3 or !std.mem.eql(u8, args[1], "-f")) {
            std.debug.print("{s}\n", .{usage});
            return error.InvalidArgs;
        }

        return Args{
            .file = args[2],
        };
    }

    pub fn deinit(self: Args, allocator: std.mem.Allocator) void {
        allocator.free(self.file);
    }
};
