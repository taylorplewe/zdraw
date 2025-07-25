const std = @import("std");
const shared = @import("shared.zig");
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
var last_cursor_pos: shared.PointF = undefined;
pub var pencil_radius: usize = undefined;

pub fn init(allocator: std.mem.Allocator, width: isize, height: isize) !void {
    const pixel_buf = try allocator.alloc(shared.Pixel, @intCast(width * height));
    drawn_pixels = try allocator.create(PixelMatrix);
    drawn_pixels.* = PixelMatrix{
        .pixels = pixel_buf,
        .width = width,
        .height = height,
    };

    @memset(drawn_pixels.pixels, BG_PIXEL);
    pencil_radius = (PENCIL_MAX_RADIUS - PENCIL_MIN_RADIUS) / 2;
}

pub fn update(mouse_button_down: shared.MouseButton, cursor_pos: shared.PointF) void {
    if (mouse_button_down != shared.MouseButton.None) {
        const color: u32 = if (mouse_button_down == shared.MouseButton.Left) 0 else 0xffffff;
        drawn_pixels.fillSegment(last_cursor_pos, cursor_pos, @intCast(pencil_radius), color);
        drawn_pixels.fillCircle(@intFromFloat(cursor_pos.x), @intFromFloat(cursor_pos.y), @intCast(pencil_radius), color);
        last_cursor_pos = cursor_pos;
    }
}
