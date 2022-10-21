const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("dizzy", "src/main.zig");
    exe.setBuildMode(mode);
    exe.setTarget(target);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run Dizzy");
    run_step.dependOn(&run_cmd.step);

    const test_exe = b.addTest("src/main.zig");
    test_exe.setBuildMode(mode);
    exe.setTarget(target);

    const test_step = b.step("test", "Test Dizzy");
    test_step.dependOn(&test_exe.step);
}
