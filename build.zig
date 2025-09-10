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
        const tsc_step = b.addSystemCommand(&[_][]const u8{
            "tsc",
        });
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
            .name = "zdraw",
            .root_module = wasm_mod,
        });
        wasm.entry = .disabled;
        wasm.rdynamic = true;
        wasm.step.dependOn(&tsc_step.step);
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

        // include paths to SDL3
        const include_path_option = b.option([]const u8, "include-path", "Path to SDL3 include directory; will use %INCLUDE% if not provided");
        const lib_path_option = b.option([]const u8, "lib-path", "Path to SDL3 lib directory; will use %LIB% if not provided");
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const include_path = if (include_path_option == null) std.process.getEnvVarOwned(arena.allocator(), "INCLUDE") catch "" else include_path_option.?;
        const lib_path = if (lib_path_option == null) std.process.getEnvVarOwned(arena.allocator(), "LIB") catch "" else lib_path_option.?;
        native.addIncludePath(.{ .cwd_relative = include_path });
        native.addLibraryPath(.{ .cwd_relative = lib_path });
        native.linkSystemLibrary("SDL3");
        native.linkLibC();

        b.installArtifact(native);
    }
}
