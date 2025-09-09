const std = @import("std");
const shared = @import("shared.zig");
const min = shared.min;
const max = shared.max;
const input_events = @import("input_events.zig");
const history = @import("history.zig");
const Layer = @import("Layer.zig");
const Self = @This();

const COL_FG = 0xff000000;
const COL_BG = 0xffffffff;
const BG_PIXEL: shared.Pixel = .{
    .r = COL_BG & 0xff,
    .g = (COL_BG >> 8) & 0xff,
    .b = (COL_BG >> 16) & 0xff,
    .a = 0xff,
};
const PENCIL_INCREMENT = 0.2;
const PENCIL_MAX_RADIUS = 28;
const PENCIL_MIN_RADIUS = 0;

var drawn_layer: *Layer = undefined;
var overlay_layer: *Layer = undefined;
var combined_pixels: []shared.Pixel = undefined;
var drawn_pixels_history: history.PixelHistory = undefined;

var mouse_button_down: shared.MouseButton = .None;
var cursor_pos: shared.PointF = undefined;
var last_cursor_pos: ?shared.PointF = null;
pub var pencil_radius: f32 = undefined;

pub fn init(allocator: std.mem.Allocator, comptime width: isize, comptime height: isize) !void {
    const pixel_len: usize = @intCast(width * height);
    const drawn_pixel_buf = try allocator.alloc(shared.Pixel, pixel_len);
    drawn_layer = try allocator.create(Layer);
    drawn_layer.* = Layer{
        .pixels = drawn_pixel_buf,
        .width = width,
        .height = height,
    };

    const overlay_pixel_buf = try allocator.alloc(shared.Pixel, pixel_len);
    overlay_layer = try allocator.create(Layer);
    overlay_layer.* = Layer{
        .pixels = overlay_pixel_buf,
        .width = width,
        .height = height,
    };

    @memset(drawn_layer.pixels, BG_PIXEL);
    clearLayer(overlay_layer.pixels);
    combined_pixels = try allocator.alloc(shared.Pixel, pixel_len);

    pencil_radius = (PENCIL_MAX_RADIUS - PENCIL_MIN_RADIUS) / 2;

    drawn_pixels_history = history.PixelHistory.new(allocator, drawn_layer.pixels);
}

/// Updates the state of the underlying pixels based on input events.
pub fn update(event: ?input_events.InputEvent) []shared.Pixel {
    if (event != null) {
        switch (event.?) {
            .MouseButtonEvent => {
                mouse_button_down = event.?.MouseButtonEvent.button;
                if (mouse_button_down == shared.MouseButton.None) {
                    drawn_pixels_history.commit(drawn_layer.pixels);
                }
            },
            .MouseMotionEvent => cursor_pos = .{
                .x = event.?.MouseMotionEvent.x,
                .y = event.?.MouseMotionEvent.y,
            },
            .MouseWheelEvent => {
                if (event.?.MouseWheelEvent.delta < 0) {
                    pencil_radius = min(pencil_radius + PENCIL_INCREMENT, PENCIL_MAX_RADIUS);
                } else if (event.?.MouseWheelEvent.delta > 0) {
                    pencil_radius = max(if (pencil_radius > 0) pencil_radius - PENCIL_INCREMENT else 0, PENCIL_MIN_RADIUS);
                }
            },
            .ProgramEvent => {
                // undo
                if (event.?.ProgramEvent == input_events.ProgramEvent.Undo) {
                    copyPixelsToDrawnPixels(drawn_pixels_history.undo());
                } else if (event.?.ProgramEvent == input_events.ProgramEvent.Redo) {
                    copyPixelsToDrawnPixels(drawn_pixels_history.redo());
                }
            },
        }
    }
    if (mouse_button_down != shared.MouseButton.None) {
        const color: u32 = if (mouse_button_down == shared.MouseButton.Left) COL_FG else COL_BG;
        drawn_layer.fillSegment(if (last_cursor_pos != null) last_cursor_pos.? else cursor_pos, cursor_pos, @intFromFloat(pencil_radius), color);
        drawn_layer.fillCircle(@intFromFloat(cursor_pos.x), @intFromFloat(cursor_pos.y), @intFromFloat(pencil_radius), color);

        last_cursor_pos = cursor_pos;
    } else {
        last_cursor_pos = null;
    }

    // draw cursor on overlay layer
    clearLayer(overlay_layer.pixels);
    overlay_layer.fillCircle(@intFromFloat(cursor_pos.x), @intFromFloat(cursor_pos.y), @as(isize, @intFromFloat(pencil_radius)), 0x888888);

    // combine all layers, back to front
    var layers = [_]*Layer{
        drawn_layer,
        overlay_layer,
    };
    return combineLayersIntoPixelMatrix(&layers);
}

/// Set all pixels in a slice to be all 0s
inline fn clearLayer(layer_pixels: []shared.Pixel) void {
    @memset(layer_pixels, shared.Pixel{
        .a = 0, // transparent
        .b = 0,
        .g = 0,
        .r = 0,
    });
}

/// Combines the pixel data from all layers into a single pixel matrix.
inline fn combineLayersIntoPixelMatrix(layers: []*Layer) []shared.Pixel {
    // I'm not sure this clear is necessary
    // clearLayer(combined_pixels);

    for (layers) |layer| {
        for (layer.pixels, 0..) |pixel, index| {
            combined_pixels[index] = if (pixel.a == 0xff) pixel else combined_pixels[index];
        }
    }

    return combined_pixels;
}

inline fn copyPixelsToDrawnPixels(pixels_to_copy: []shared.Pixel) void {
    for (pixels_to_copy, 0..) |src, i| {
        drawn_layer.pixels[i] = src;
    }
}
