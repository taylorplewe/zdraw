const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "zdraw",
        .root_module = exe_mod,
    });

    exe.addIncludePath(.{ .cwd_relative = "C:\\Users\\TaylorPlewe\\Documents\\SDL3-devel-3.2.18-VC\\SDL3-3.2.18\\include\\" });
    exe.addLibraryPath(.{ .cwd_relative = "C:\\Users\\TaylorPlewe\\lib" });
    exe.linkSystemLibrary("SDL3");
    exe.linkLibC();

    b.installArtifact(exe);
}
