const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const libModule = b.addModule("ido", .{
        .root_source_file = b.path("src/ido.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "ido",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("ido", libModule);
    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const test_filters = b.option(
        []const []const u8,
        "test-filter",
        "Skip tests that do not match any filter",
    ) orelse &[0][]const u8{};

    const lib_unit_tests = b.addTest(.{
        .name = "unit-lib",
        .root_source_file = b.path("src/ido.zig"),
        .target = target,
        .optimize = optimize,
        .filters = test_filters,
    });
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .name = "unit-exe",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .filters = test_filters,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const integration_tests = b.addTest(.{
        .name = "integration",
        .root_source_file = b.path("tests/tests.zig"),
        .target = target,
        .optimize = optimize,
        .filters = test_filters,
    });
    b.installArtifact(integration_tests);
    integration_tests.root_module.addImport("ido", libModule);
    const run_integration_tests = b.addRunArtifact(integration_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
    test_step.dependOn(&run_integration_tests.step);
}
