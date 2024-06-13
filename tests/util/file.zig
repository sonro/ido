const std = @import("std");
const fs = std.fs;
const testing = std.testing;
const allocator = testing.allocator;

pub const TestFile = struct {
    path: []const u8,
    tmp_dir: testing.TmpDir,

    pub fn init(contents: []const u8) !TestFile {
        const filename = "ido_test_file";
        const tmp_dir = getTmpDir();

        const file = try tmp_dir.dir.createFile(filename, .{});
        defer file.close();

        const path = try tmp_dir.dir.realpathAlloc(allocator, filename);
        try file.writeAll(contents);

        return .{
            .path = path,
            .tmp_dir = tmp_dir,
        };
    }

    pub fn deinit(self: *TestFile) void {
        allocator.free(self.path);
        self.tmp_dir.cleanup();
    }
};

fn getTmpDir() testing.TmpDir {
    return testing.tmpDir(.{});
}
