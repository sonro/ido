const std = @import("std");
const testing = std.testing;
const ido = @import("ido");
const util = @import("test-util");
const allocator = testing.allocator;

const fixtures = @import("fixtures");
const expected_simple = fixtures.simple;
const SIMPLE_IDO_FILE_PATH = "tests/fixtures/simple.ido";

test "load simple ido file" {
    var store = ido.FileStore(ido.Format).init(allocator, SIMPLE_IDO_FILE_PATH);
    defer store.deinit();
    var manager = try ido.Manager.init(allocator, store.taskStore());
    try manager.load();
    defer manager.deinit();

    try util.expectTaskSliceEqual(&expected_simple.tasks, manager.allTasks());
    try testing.expectEqualStrings(expected_simple.ido_content, store.contents);
}

test "save simple ido file" {
    // setup temporary directory
    var tmp_dir = testing.tmpDir(.{});
    defer tmp_dir.cleanup();

    const dir_path = try tmp_dir.dir.realpathAlloc(allocator, ".");
    defer allocator.free(dir_path);

    const tmp_path = try std.fs.path.join(allocator, &[_][]const u8{ dir_path, "output.ido" });
    defer allocator.free(tmp_path);

    // setup ido.manager
    var store = ido.FileStore(ido.Format).init(allocator, tmp_path);
    defer store.deinit();

    var manager = try ido.Manager.init(allocator, store.taskStore());
    defer manager.deinit();

    // add tasks to the manager then save
    for (expected_simple.tasks) |task| {
        _ = try manager.addTask(task);
    }
    try manager.save();

    // max size of the expected files
    const bufsize = expected_simple.ido_content.len * 2;

    // create expected string
    var expected: [bufsize]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&expected);
    try ido.Format.serializeTaskList(&expected_simple.tasks, fbs.writer());

    // read actual file
    const actual = try std.fs.cwd().readFileAlloc(allocator, tmp_path, bufsize);
    defer allocator.free(actual);

    try testing.expectEqualStrings(expected[0..actual.len], actual);
}
