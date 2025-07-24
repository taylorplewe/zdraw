const std = @import("std");
const MouseButton = @import("shared.zig").MouseButton;
const Self = @This();

const Matrix = []u8;
const Pixel = packed struct {
    a: u8,
    b: u8,
    g: u8,
    r: u8,
};
const PixelMatrix = struct {
    pixels: []Pixel,
    width: isize,
    height: isize,

    fn setPixel(self: *PixelMatrix, x: isize, y: isize, color: u32) void {
        const index = ((y * self.width) + x);
        if (index < 0 or index >= self.width * self.height) return;

        self.pixels[index].r = @intCast(color & 0xff);
        self.pixels[index].g = @intCast((color >> 8) & 0xff);
        self.pixels[index].b = @intCast((color >> 16) & 0xff);
        self.pixels[index].a = 0xff;
    }
};
const Point = struct {
    x: isize,
    y: isize,
};
const PointF = struct {
    x: f64,
    y: f64,
};

const COL_FG = 0xff000000;
const COL_BG = 0xffffffff;
const PENCIL_MAX_RADIUS = 28;
const PENCIL_MIN_RADIUS = 0;

// comes from parent
allocator: std.mem.Allocator,
width: isize,
height: isize,

drawn_pixels: Matrix,
pencil_radius: usize,
curr_mouse_point: PointF,
last_mouse_point: PointF,

pub fn new(width: isize, height: isize, allocator: std.mem.Allocator) Self {
    return Self{
        .allocator = allocator,
        .width = width,
        .height = height,
    };
}

// pub fn update(self: *Self, mouse_button_down: MouseButton) void {
//     if (mouse_button_down != MouseButton.None) {
//         const color: u32 = if (mouse_button_down == MouseButton.Left) 0 else 0xffffff; // debug
//         fillSegment(self.drawn_pixels, self.last_mouse_point, self.curr_mouse_point, self.pencil_radius, color);
//         fillCircle(self.drawn_pixels, @intFromFloat(self.curr_mouse_point.x), @intFromFloat(self.curr_mouse_point.y), self.pencil_radius, color);
//     }
// }

// fn colorPixel(mem: []u8, x: usize, y: usize, color: u32) void {
//     const index = ((y * SCREEN_WIDTH) + x) * BPP8;
//     if (index < 0 or index >= SCREEN_WIDTH * SCREEN_HEIGHT * BPP8) return;

//     const pixel = Pixel{
//         .r = @intCast(color & 0xff),
//         .g = @intCast((color >> 8) & 0xff),
//         .b = @intCast((color >> 16) & 0xff),
//         .a = 0xff,
//     };

//     const pixels: []u32 = @ptrCast(@alignCast(mem));
//     const pixel_ptr: *const u32 = @ptrCast(&pixel);
//     pixels[index / 4] = pixel_ptr.*;
// }

// fn fillCircle(mem: []u8, x: isize, y: isize, r: usize, color: u32) void {
//     for (0..(r * 2 + 1)) |w| {
//         for (0..(r * 2 + 1)) |h| {
//             const dx: isize = @as(isize, @intCast(r)) - @as(isize, @intCast(w));
//             const dy: isize = @as(isize, @intCast(r)) - @as(isize, @intCast(h));
//             const offset_x: isize = @mod((dx + x), Self.width);
//             const offset_y: isize = dy + y;
//             if (((dx * dx) + (dy * dy) >= r * r) or (dx + x < 0) or (offset_y < 0) or ((dx + x) >= SCREEN_WIDTH)) continue;

//             colorPixel(mem, @as(usize, @intCast(offset_x)), @as(usize, @intCast(offset_y)), color);
//         }
//     }
// }

// fn fillSegment(mem: []u8, p1: PointF, p2: PointF, r: usize, color: u32) void {
//     // mouse_button_down = MouseButton.None; // debug

//     const theta: f64 = std.math.atan2(p2.y - p1.y, p2.x - p1.x);

//     if (r > 0) {
//         const theta_perp: f64 = theta + std.math.pi / 2.0;
//         const x_offs: f64 = @as(f64, @floatFromInt(r)) * std.math.cos(theta_perp);
//         const y_offs: f64 = @as(f64, @floatFromInt(r)) * std.math.sin(theta_perp);
//         const A: PointF = .{ .x = p2.x + x_offs, .y = p2.y + y_offs };
//         const B: PointF = .{ .x = p1.x + x_offs, .y = p1.y + y_offs };
//         const C: PointF = .{ .x = p2.x - x_offs, .y = p2.y - y_offs };
//         const D: PointF = .{ .x = p1.x - x_offs, .y = p1.y - y_offs };
//         const AB: PointF = .{ .x = B.x - A.x, .y = B.y - A.y };
//         const AC: PointF = .{ .x = C.x - A.x, .y = C.y - A.y };
//         const len1_sq: f64 = (AB.x * AB.x) + (AB.y * AB.y);
//         const len2_sq: f64 = (AC.x * AC.x) + (AC.y * AC.y);

//         const bound_top: usize = @intFromFloat(min(max(min(A.y, min(B.y, min(C.y, D.y))), 0), SCREEN_HEIGHT - 1));
//         const bound_bottom: usize = @intFromFloat(min(max(max(A.y, max(B.y, max(C.y, D.y))), 0), SCREEN_HEIGHT - 1));
//         const bound_left: usize = @intFromFloat(min(max(min(A.x, min(B.x, min(C.x, D.x))), 0), SCREEN_WIDTH - 1));
//         const bound_right: usize = @intFromFloat(min(max(max(A.x, max(B.x, max(C.x, D.x))), 0), SCREEN_WIDTH - 1));

//         for (bound_top..bound_bottom + 1) |row| {
//             for (bound_left..bound_right + 1) |col| {
//                 const P: Point = .{ .x = @intCast(col), .y = @intCast(row) };
//                 const AP: PointF = .{ .x = @as(f64, @floatFromInt(P.x)) - A.x, .y = @as(f64, @floatFromInt(P.y)) - A.y };
//                 const dot1: f64 = AB.x * AP.x + AB.y * AP.y;
//                 const dot2: f64 = AC.x * AP.x + AC.y * AP.y;

//                 if (0 <= dot1 and dot1 <= len1_sq and 0 <= dot2 and dot2 <= len2_sq)
//                     colorPixel(mem, @intCast(P.x), @intCast(P.y), color);
//             }
//         }
//     } else {
//         // Bresenham's algorithm
//         var p1_int: Point = .{ .x = @intFromFloat(p1.x), .y = @intFromFloat(p1.y) };
//         const p2_int: Point = .{ .x = @intFromFloat(p2.x), .y = @intFromFloat(p2.y) };
//         const dx: isize = @intCast(@abs(p2_int.x - p1_int.x));
//         const dy: isize = @intCast(-@as(isize, @intCast(@abs(p2_int.y - p1_int.y))));
//         const sx: isize = if (p1_int.x < p2_int.x) 1 else -1;
//         const sy: isize = if (p1_int.y < p2_int.y) 1 else -1;
//         var err = dx + dy;

//         // safe bounds
//         const num_pixels: usize = @intCast(if (dx > -dy) dx else -dy);
//         for (0..num_pixels) |_| {
//             if (p1_int.x >= 0 and p1_int.x < SCREEN_WIDTH and p1_int.y >= 0 and p1_int.y < SCREEN_HEIGHT)
//                 colorPixel(mem, @intCast(p1_int.x), @intCast(p1_int.y), color);

//             const e2 = err * 2;
//             if (e2 >= dy) {
//                 if (p1_int.x == p2_int.x) break;
//                 err += dy;
//                 p1_int.x = p1_int.x + sx;
//             }
//             if (e2 <= dx) {
//                 if (p1_int.y == p2_int.y) break;
//                 err += dx;
//                 p1_int.y = p1_int.y + sy;
//             }
//         }
//     }

//     last_mouse_point = curr_mouse_point;
// }

fn min(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return if (a < b) a else b;
}
fn max(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return if (a > b) a else b;
}
