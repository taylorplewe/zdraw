const std = @import("std");
const shared = @import("shared.zig");
const input_events = @import("input_events.zig");
const draw = @import("draw.zig");
const sdl = @import("sdl.zig");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

pub const SCREEN_WIDTH = 128;
pub const SCREEN_HEIGHT = SCREEN_WIDTH;

var mouse_button_down: shared.MouseButton = undefined;
var curr_mouse_point: shared.PointF = undefined;
var last_mouse_point: shared.PointF = undefined;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    mouse_button_down = shared.MouseButton.None;

    try draw.init(arena.allocator(), SCREEN_WIDTH, SCREEN_HEIGHT);
    sdl.init(SCREEN_WIDTH, SCREEN_HEIGHT);
    defer sdl.destroy();

    while (true) {
        const event = sdl.getInput();
        if (event != null and event.? == .ProgramEvent and event.?.ProgramEvent == input_events.ProgramEvent.Quit)
            break;

        if (event != null) draw.update(event.?);
        sdl.render(draw.drawn_pixels.pixels);
    }

    sdl.quit();
}
