const ExeRunner = @This();

const std = @import("std");
const testing = std.testing;
const fixtures = @import("fixtures");

tmp_dir: std.testing.TmpDir,

pub const Result = struct {
    status: Status,
    exit_code: i32 = undefined,
    stdout: []const u8 = undefined,
    stderr: []const u8 = undefined,

    pub const Status = enum {
        success,
        failure,
        unknown,
    };

    pub fn deinit(self: *Result, allocator: std.mem.Allocator) void {
        allocator.free(self.stdout);
        allocator.free(self.stderr);
    }

    fn init_from_run_result(run_result: std.process.Child.RunResult) Result {
        switch (run_result.term) {
            .Exited => |code| return Result{
                .status = if (code == 0) .success else .failure,
                .exit_code = code,
                .stdout = run_result.stdout,
                .stderr = run_result.stderr,
            },
            else => return Result{ .status = .unknown },
        }
    }
};

pub fn init() ExeRunner {
    const tmp_dir = std.testing.tmpDir(.{});
    return ExeRunner{ .tmp_dir = tmp_dir };
}

pub fn deinit(self: *ExeRunner) void {
    self.tmp_dir.cleanup();
    self.* = undefined;
}

pub fn addFile(self: *ExeRunner, name: []const u8, content: []const u8) !void {
    try self.tmp_dir.dir.writeFile(.{ .sub_path = name, .data = content });
}

/// Get the absolute path of the temporary directory
/// Returned value must be freed with allocator
pub fn getDirPath(self: *ExeRunner, allocator: std.mem.Allocator) ![]const u8 {
    return try self.tmp_dir.dir.realpathAlloc(allocator, ".");
}

pub fn run(self: *ExeRunner, allocator: std.mem.Allocator, args: anytype) !Result {
    var argv: [argCount(args)][]const u8 = undefined;
    inline for (args, 0..) |arg, i| argv[i] = arg;

    const dir_path = try self.getDirPath(allocator);
    defer allocator.free(dir_path);

    const res = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &argv,
        .cwd = dir_path,
    }) catch |err| {
        switch (err) {
            error.FileNotFound => return error.UnknownExe,
            else => return err,
        }
    };

    return Result.init_from_run_result(res);
}

fn argCount(args: anytype) usize {
    const ArgType = @TypeOf(args);
    const arg_info = @typeInfo(ArgType);

    if (arg_info != .Struct) {
        @compileError("Expected struct type, found " ++ @typeName(ArgType));
    }

    if (!arg_info.Struct.is_tuple) {
        @compileError("Expected tuple type, found " ++ @typeName(ArgType));
    }

    if (arg_info.Struct.fields.len == 0) {
        @compileError("Expected at least one argument");
    }

    return arg_info.Struct.fields.len;
}

test "init" {
    var runner = ExeRunner.init();
    defer runner.deinit();
}

test "get dir path" {
    var runner = ExeRunner.init();
    defer runner.deinit();

    const dir_path = try runner.getDirPath(testing.allocator);
    defer testing.allocator.free(dir_path);

    var parent = dir_path;
    for (0..2) |_| parent = std.fs.path.dirname(parent).?;

    try testing.expectEqualStrings(".zig-cache", std.fs.path.basename(parent));
}

test "add file" {
    var runner = ExeRunner.init();
    defer runner.deinit();
    try runner.addFile("test.txt", fixtures.hello_txt);

    const file = try runner.tmp_dir.dir.openFile("test.txt", .{});
    defer file.close();

    const stat = try file.stat();
    const content = try file.readToEndAlloc(testing.allocator, stat.size);
    defer testing.allocator.free(content);

    try testing.expectEqualStrings(fixtures.hello_txt, content);
}

test "run zig" {
    var runner = ExeRunner.init();
    defer runner.deinit();

    var result = try runner.run(testing.allocator, .{ "zig", "--help" });
    defer result.deinit(testing.allocator);

    try testing.expectEqual(result.status, .success);
}

test "run zig build unknown cmd" {
    var runner = ExeRunner.init();
    defer runner.deinit();

    var res = try runner.run(testing.allocator, .{ "zig", "build", "unknown" });
    defer res.deinit(testing.allocator);

    try testing.expectEqual(res.status, .failure);
}

test "run unknown binary" {
    var runner = ExeRunner.init();
    defer runner.deinit();

    const res = runner.run(testing.allocator, .{"not_a_binary"});
    try testing.expectError(error.UnknownExe, res);
}
