const std = @import("std");

const BuildEnv = struct {
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    modules: []const Module,
};

const Module = struct {
    name: []const u8,
    module: *std.Build.Module,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_module = b.addModule("ido", .{
        .root_source_file = b.path("src/ido.zig"),
        .target = target,
        .optimize = optimize,
    });

    const test_util_module = b.addModule("test-util", .{
        .root_source_file = b.path("tests/util/util.zig"),
        .target = target,
        .optimize = optimize,
    });
    test_util_module.addImport("ido", lib_module);

    const build_env = BuildEnv{
        .b = b,
        .target = target,
        .optimize = optimize,
        .modules = &.{
            .{ .name = "ido", .module = lib_module },
            .{ .name = "test-util", .module = test_util_module },
        },
    };

    buildExe(build_env);
    buildTests(build_env);
}

const TestType = struct {
    name: []const u8,
    path: []const u8,
    description: []const u8,
};

const TEST_TYPES = [_]TestType{
    .{
        .name = "test-lib",
        .path = "tests/unit/tests.zig",
        .description = "Test library unit tests",
    },
    .{
        .name = "test-exe",
        .path = "src/main.zig",
        .description = "Test executable unit tests",
    },
    .{
        .name = "test-integration",
        .path = "tests/integration/tests.zig",
        .description = "Test integration tests",
    },
};

fn buildTests(env: BuildEnv) void {
    const test_filters = env.b.option(
        []const []const u8,
        "test-filter",
        "Skip tests that do not match any filter",
    ) orelse &[0][]const u8{};

    var test_runs: [TEST_TYPES.len]*std.Build.Step.Run = undefined;

    for (TEST_TYPES, 0..) |test_type, i| {
        const t = env.b.addTest(.{
            .name = test_type.name,
            .root_source_file = env.b.path(test_type.path),
            .target = env.target,
            .optimize = env.optimize,
            .filters = test_filters,
        });
        env.b.installArtifact(t);
        for (env.modules) |module| {
            t.root_module.addImport(module.name, module.module);
        }
        const run_test = env.b.addRunArtifact(t);
        test_runs[i] = run_test;
        const test_step = env.b.step(test_type.name, test_type.description);
        test_step.dependOn(&run_test.step);
    }

    const test_all_step = env.b.step("test", "Run all tests");
    for (test_runs) |run_test| {
        test_all_step.dependOn(&run_test.step);
    }
}

fn buildExe(env: BuildEnv) void {
    const exe = env.b.addExecutable(.{
        .name = "ido",
        .root_source_file = env.b.path("src/main.zig"),
        .target = env.target,
        .optimize = env.optimize,
    });
    exe.root_module.addImport(env.modules[0].name, env.modules[0].module);
    env.b.installArtifact(exe);
    const run_cmd = env.b.addRunArtifact(exe);
    run_cmd.step.dependOn(env.b.getInstallStep());
    if (env.b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = env.b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
