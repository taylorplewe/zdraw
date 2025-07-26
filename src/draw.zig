const std = @import("std");
const shared = @import("shared.zig");
const min = shared.min;
const max = shared.max;
const input_events = @import("input_events.zig");
const PixelMatrix = @import("PixelMatrix.zig");
const Self = @This();

const COL_FG = 0xff000000;
const COL_BG = 0xffffffff;
const BG_PIXEL: shared.Pixel = .{
    .r = COL_BG & 0xff,
    .g = (COL_BG >> 8) & 0xff,
    .b = (COL_BG >> 16) & 0xff,
    .a = 0xff,
};
pub const PENCIL_MAX_RADIUS = 28;
pub const PENCIL_MIN_RADIUS = 0;

pub var drawn_pixels: *PixelMatrix = undefined;
pub var overlay_pixels: *PixelMatrix = undefined;

var mouse_button_down: shared.MouseButton = .None;
var cursor_pos: shared.PointF = undefined;
var last_cursor_pos: ?shared.PointF = null;
pub var pencil_radius: usize = undefined;

pub fn init(allocator: std.mem.Allocator, width: isize, height: isize) !void {
    const drawn_pixel_buf = try allocator.alloc(shared.Pixel, @intCast(width * height));
    drawn_pixels = try allocator.create(PixelMatrix);
    drawn_pixels.* = PixelMatrix{
        .pixels = drawn_pixel_buf,
        .width = width,
        .height = height,
    };

    const overlay_pixel_buf = try allocator.alloc(shared.Pixel, @intCast(width * height));
    overlay_pixels = try allocator.create(PixelMatrix);
    overlay_pixels.* = PixelMatrix{
        .pixels = overlay_pixel_buf,
        .width = width,
        .height = height,
    };

    @memset(drawn_pixels.pixels, BG_PIXEL);

    pencil_radius = (PENCIL_MAX_RADIUS - PENCIL_MIN_RADIUS) / 2;
}

/// Updates the state of the underlying pixels based on input events.
pub fn update(event: input_events.InputEvent) void {
    switch (event) {
        .MouseButtonEvent => mouse_button_down = event.MouseButtonEvent.button,
        .MouseMotionEvent => cursor_pos = .{
            .x = event.MouseMotionEvent.x,
            .y = event.MouseMotionEvent.y,
        },
        .MouseWheelEvent => {
            if (event.MouseWheelEvent.delta < 0) {
                pencil_radius = min(pencil_radius + 1, PENCIL_MAX_RADIUS);
            } else if (event.MouseWheelEvent.delta > 0) {
                pencil_radius = max(if (pencil_radius > 0) pencil_radius - 1 else 0, PENCIL_MIN_RADIUS);
            }
        },
        else => {},
    }
    if (mouse_button_down != shared.MouseButton.None) {
        const color: u32 = if (mouse_button_down == shared.MouseButton.Left) 0 else 0xffffff;
        drawn_pixels.fillSegment(if (last_cursor_pos != null) last_cursor_pos.? else cursor_pos, cursor_pos, @intCast(pencil_radius), color);
        drawn_pixels.fillCircle(@intFromFloat(cursor_pos.x), @intFromFloat(cursor_pos.y), @intCast(pencil_radius), color);

        last_cursor_pos = cursor_pos;
    } else {
        last_cursor_pos = null;
    }

    // draw cursor on overlay layer
    @memset(overlay_pixels.pixels, shared.Pixel{
        .a = 0,
        .b = 0,
        .g = 0,
        .r = 0,
    }); // transparent
    overlay_pixels.fillCircle(@intFromFloat(cursor_pos.x), @intFromFloat(cursor_pos.y), @as(isize, @intCast(pencil_radius)), 0x888888);
}
