const std = @import("std");
const testing = std.testing;
const ido = @import("ido");
const util = @import("test-util");
const allocator = testing.allocator;

const expected_simple = @import("fixtures").simple.tasks;

const SIMPLE_IDO_FILE_PATH = "tests/fixtures/simple.ido";

test "load simple ido file" {
    var store = ido.FileStore(ido.Format).init(allocator, SIMPLE_IDO_FILE_PATH);
    defer store.deinit();
    const manager = try ido.Manager.init(allocator, store.taskStore());
    defer manager.deinit();

    try util.expectTaskSliceEqual(&expected_simple, manager.allTasks());
}
