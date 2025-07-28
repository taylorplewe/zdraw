const std = @import("std");
const shared = @import("shared.zig");
const input_events = @import("input_events.zig");
const draw = @import("draw.zig");
const sdl = @import("sdl.zig");

pub const SCREEN_WIDTH = 128;
pub const SCREEN_HEIGHT = SCREEN_WIDTH;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    try draw.init(arena.allocator(), SCREEN_WIDTH, SCREEN_HEIGHT);
    sdl.init(SCREEN_WIDTH, SCREEN_HEIGHT);
    defer sdl.destroy();

    while (true) {
        const event = sdl.getInput();
        if (event != null and event.? == .ProgramEvent and event.?.ProgramEvent == input_events.ProgramEvent.Quit)
            break;

        const pixels = draw.update(event);
        sdl.render(pixels);
    }

    sdl.quit();
}
