const std = @import("std");

pub fn build(b: *std.Build) void {
    // const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const wasm = b.addExecutable(.{
        .name = "zdraw-wasm",
        .root_source_file = .{ .cwd_relative = "src/wasm_exports.zig" },
        .target = b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .freestanding }),
        .optimize = optimize,
    });
    wasm.entry = .disabled;
    wasm.rdynamic = true;

    // const exe = b.addExecutable(.{
    //     .name = "zdraw",
    //     .root_source_file = b.path("src/main.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });
    //
    // exe.addIncludePath(.{ .cwd_relative = "C:\\Users\\TaylorPlewe\\Documents\\SDL3-devel-3.2.18-VC\\SDL3-3.2.18\\include\\" });
    // exe.addLibraryPath(.{ .cwd_relative = "C:\\Users\\TaylorPlewe\\lib" });
    // exe.linkSystemLibrary("SDL3");
    // exe.linkLibC();
    //
    // b.installArtifact(exe);
    b.installArtifact(wasm);
}
