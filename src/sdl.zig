const shared = @import("shared.zig");
const input_events = @import("input_events.zig");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

var window: *c.SDL_Window = undefined;
var renderer: *c.SDL_Renderer = undefined;
var surface: *c.SDL_Surface = undefined;

/// Allocate and initialize SDL resources.
pub fn init(width: usize, height: usize) void {
    _ = c.SDL_Init(c.SDL_INIT_VIDEO);

    const c_width: c_int = @intCast(width);
    const c_height: c_int = @intCast(height);
    window = c.SDL_CreateWindow("zdraw", c_width * shared.SCALE, c_height * shared.SCALE, c.SDL_WINDOW_MOUSE_CAPTURE).?;
    renderer = c.SDL_CreateRenderer(window, null).?;
    surface = c.SDL_CreateSurface(c_width, c_height, c.SDL_PIXELFORMAT_ABGR32);

    _ = c.SDL_CaptureMouse(true);
    _ = c.SDL_HideCursor();
}

/// Poll for input events and return the first one, or null if no events are available.
pub fn getInput() ?input_events.InputEvent {
    var e: c.SDL_Event = undefined;
    while (c.SDL_PollEvent(&e)) {
        switch (e.type) {
            c.SDL_EVENT_QUIT => return input_events.InputEvent{ .ProgramEvent = input_events.ProgramEvent.Quit },
            c.SDL_EVENT_KEY_DOWN => {
                if (e.key.scancode == c.SDL_SCANCODE_Q) return input_events.InputEvent{ .ProgramEvent = input_events.ProgramEvent.Quit };
            },
            c.SDL_EVENT_MOUSE_MOTION => {
                return input_events.InputEvent{ .MouseMotionEvent = .{
                    .x = e.motion.x / shared.SCALE,
                    .y = e.motion.y / shared.SCALE,
                } };
            },
            c.SDL_EVENT_MOUSE_BUTTON_DOWN => {
                return input_events.InputEvent{ .MouseButtonEvent = .{
                    .button = switch (e.button.button) {
                        c.SDL_BUTTON_LEFT => shared.MouseButton.Left,
                        else => shared.MouseButton.Right,
                    },
                } };
            },
            c.SDL_EVENT_MOUSE_BUTTON_UP => return input_events.InputEvent{ .MouseButtonEvent = .{
                .button = shared.MouseButton.None,
            } },
            c.SDL_EVENT_MOUSE_WHEEL => return input_events.InputEvent{ .MouseWheelEvent = .{
                .delta = e.wheel.y,
            } },
            else => {},
        }
    }

    return null;
}

/// Render the given pixel layers to the screen.
pub fn render(pixel_layers: [][]shared.Pixel) void {
    _ = c.SDL_RenderClear(renderer);

    for (pixel_layers) |layer| {
        if (c.SDL_MUSTLOCK(surface)) {
            _ = c.SDL_LockSurface(surface);
        }

        // draw all layer pixels to the surface
        const pixels: [*]u8 = @ptrCast(surface.*.pixels.?);
        @memcpy(pixels, @as([]u8, @ptrCast(layer)));

        if (c.SDL_MUSTLOCK(surface)) {
            _ = c.SDL_UnlockSurface(surface);
        }

        const scaled_surface = c.SDL_ScaleSurface(surface, surface.w * shared.SCALE, surface.h * shared.SCALE, c.SDL_SCALEMODE_NEAREST);

        const tex = c.SDL_CreateTextureFromSurface(renderer, scaled_surface);
        defer c.SDL_DestroyTexture(tex);

        _ = c.SDL_RenderTexture(renderer, tex, null, null);
    }
    _ = c.SDL_RenderPresent(renderer);
}

pub fn destroy() void {
    c.SDL_DestroyWindow(window);
    c.SDL_DestroyRenderer(renderer);
    c.SDL_DestroySurface(surface);
    _ = c.SDL_CaptureMouse(false);
}

pub const quit = c.SDL_Quit;
