const std = @import("std");
const testing = std.testing;
const ExeRunner = @import("ExeRunner.zig");

// relative to the tmp dir
const binary = "../../../zig-out/bin/ido";
const run_on_test_ido = .{ binary, "-f", "test.ido" };

test "file not found" {
    var runner = ExeRunner.init();
    defer runner.deinit();
    // don't add any files

    var res = try runner.run(testing.allocator, run_on_test_ido);
    defer res.deinit(testing.allocator);

    try testing.expectEqual(ExeRunner.Result.Status.failure, res.status);
}

test "empty file" {
    var runner = ExeRunner.init();
    defer runner.deinit();

    try runner.addFile("test.ido", "");
    var res = try runner.run(testing.allocator, run_on_test_ido);
    defer res.deinit(testing.allocator);

    try testing.expectEqual(ExeRunner.Result.Status.success, res.status);
    try testing.expectEqual(@as(usize, 0), res.stdout.len);
    try testing.expectEqual(@as(usize, 0), res.stderr.len);
}
