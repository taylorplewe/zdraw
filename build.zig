const std = @import("std");

pub fn build(b: *std.Build) void {
    const build_native_option = b.option(bool, "native", "Build the native SDL frontend");
    const build_wasm_option = b.option(bool, "wasm", "Build the WebAssembly frontend");
    const should_build_native = (build_wasm_option == null and build_native_option == null) or (build_native_option == true);
    const should_build_wasm = (build_wasm_option == null and build_native_option == null) or (build_wasm_option == true);

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // includes the shared constants, input events API, and draw code.
    const shared_mod = b.addModule("shared-mod", .{
        .root_source_file = b.path("src/shared.zig"),
        .optimize = optimize,
    });

    if (should_build_wasm) {
        const wasm_mod = b.addModule("zdraw-wasm-mod", .{
            .root_source_file = .{ .cwd_relative = "src/frontend/wasm/wasm.zig" },
            .target = b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .freestanding }),
            .optimize = optimize,
            .imports = &.{
                .{
                    .name = "shared",
                    .module = shared_mod,
                },
            },
        });
        const wasm = b.addExecutable(.{
            .name = "zdraw-wasm",
            .root_module = wasm_mod,
        });
        wasm.entry = .disabled;
        wasm.rdynamic = true;
        b.installArtifact(wasm);
    }

    if (should_build_native) {
        const native_mod = b.addModule("sdl-mod", .{
            .root_source_file = .{ .cwd_relative = "src/frontend/sdl/sdl_main.zig" },
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{
                    .name = "shared",
                    .module = shared_mod,
                },
            },
        });
        const native = b.addExecutable(.{
            .name = "zdraw",
            .root_module = native_mod,
        });
        native.addIncludePath(.{ .cwd_relative = "C:\\Users\\TaylorPlewe\\Documents\\SDL3-devel-3.2.18-VC\\SDL3-3.2.18\\include\\" });
        native.addLibraryPath(.{ .cwd_relative = "C:\\Users\\TaylorPlewe\\lib" });
        native.linkSystemLibrary("SDL3");
        native.linkLibC();
        b.installArtifact(native);
    }
}
