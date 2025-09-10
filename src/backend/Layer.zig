const std = @import("std");
const shared = @import("../shared.zig");
const min = shared.min;
const max = shared.max;
const Self = @This();

pixels: []shared.Pixel,
width: isize,
height: isize,

/// Set a certain pixel at the given coordinates to the given color.
fn setPixel(self: *Self, x: isize, y: isize, color: u32) void {
    const index = (y * self.width) + x;
    if (index < 0 or index >= self.width * self.height) return;

    self.pixels[@intCast(index)].r = @intCast(color & 0xff);
    self.pixels[@intCast(index)].g = @intCast((color >> 8) & 0xff);
    self.pixels[@intCast(index)].b = @intCast((color >> 16) & 0xff);
    self.pixels[@intCast(index)].a = 0xff;
}

pub fn fillCircle(self: *Self, x: isize, y: isize, r: isize, color: u32) void {
    for (0..(@as(usize, @intCast(r)) * 2 + 1)) |w| {
        for (0..(@as(usize, @intCast(r)) * 2 + 1)) |h| {
            const dx: isize = r - @as(isize, @intCast(w));
            const dy: isize = r - @as(isize, @intCast(h));
            const offset_x: isize = @mod((dx + x), self.width);
            const offset_y: isize = dy + y;
            if (((dx * dx) + (dy * dy) >= r * r) or (dx + x < 0) or (offset_y < 0) or ((dx + x) >= self.width)) continue;

            self.setPixel(offset_x, offset_y, color);
        }
    }
}

pub fn fillSegment(self: *Self, p1: shared.PointF, p2: shared.PointF, r: isize, color: u32) void {
    const theta: f64 = std.math.atan2(p2.y - p1.y, p2.x - p1.x);

    if (r > 0) {
        const theta_perp: f64 = theta + std.math.pi / 2.0;
        const x_offs: f64 = @as(f64, @floatFromInt(r)) * std.math.cos(theta_perp);
        const y_offs: f64 = @as(f64, @floatFromInt(r)) * std.math.sin(theta_perp);
        const A: shared.PointF = .{ .x = p2.x + x_offs, .y = p2.y + y_offs };
        const B: shared.PointF = .{ .x = p1.x + x_offs, .y = p1.y + y_offs };
        const C: shared.PointF = .{ .x = p2.x - x_offs, .y = p2.y - y_offs };
        const D: shared.PointF = .{ .x = p1.x - x_offs, .y = p1.y - y_offs };
        const AB: shared.PointF = .{ .x = B.x - A.x, .y = B.y - A.y };
        const AC: shared.PointF = .{ .x = C.x - A.x, .y = C.y - A.y };
        const len1_sq: f64 = (AB.x * AB.x) + (AB.y * AB.y);
        const len2_sq: f64 = (AC.x * AC.x) + (AC.y * AC.y);

        const bound_top: usize = @intFromFloat(min(max(min(A.y, min(B.y, min(C.y, D.y))), 0), @as(f64, @floatFromInt(self.height)) - 1));
        const bound_bottom: usize = @intFromFloat(min(max(max(A.y, max(B.y, max(C.y, D.y))), 0), @as(f64, @floatFromInt(self.height)) - 1));
        const bound_left: usize = @intFromFloat(min(max(min(A.x, min(B.x, min(C.x, D.x))), 0), @as(f64, @floatFromInt(self.width)) - 1));
        const bound_right: usize = @intFromFloat(min(max(max(A.x, max(B.x, max(C.x, D.x))), 0), @as(f64, @floatFromInt(self.width)) - 1));

        for (bound_top..bound_bottom + 1) |row| {
            for (bound_left..bound_right + 1) |col| {
                const P: shared.Point = .{ .x = @intCast(col), .y = @intCast(row) };
                const AP: shared.PointF = .{ .x = @as(f64, @floatFromInt(P.x)) - A.x, .y = @as(f64, @floatFromInt(P.y)) - A.y };
                const dot1: f64 = AB.x * AP.x + AB.y * AP.y;
                const dot2: f64 = AC.x * AP.x + AC.y * AP.y;

                if (0 <= dot1 and dot1 <= len1_sq and 0 <= dot2 and dot2 <= len2_sq)
                    self.setPixel(P.x, P.y, color);
            }
        }
    } else {
        // Bresenham's algorithm
        var p1_int: shared.Point = .{ .x = @intFromFloat(p1.x), .y = @intFromFloat(p1.y) };
        const p2_int: shared.Point = .{ .x = @intFromFloat(p2.x), .y = @intFromFloat(p2.y) };
        const dx: isize = @intCast(@abs(p2_int.x - p1_int.x));
        const dy: isize = @intCast(-@as(isize, @intCast(@abs(p2_int.y - p1_int.y))));
        const sx: isize = if (p1_int.x < p2_int.x) 1 else -1;
        const sy: isize = if (p1_int.y < p2_int.y) 1 else -1;
        var err = dx + dy;

        // safe bounds
        const num_pixels: usize = @intCast(if (dx > -dy) dx else -dy);
        for (0..num_pixels) |_| {
            if (p1_int.x >= 0 and p1_int.x < self.width and p1_int.y >= 0 and p1_int.y < self.height)
                self.setPixel(p1_int.x, p1_int.y, color);

            const e2 = err * 2;
            if (e2 >= dy) {
                if (p1_int.x == p2_int.x) break;
                err += dy;
                p1_int.x = p1_int.x + sx;
            }
            if (e2 <= dx) {
                if (p1_int.y == p2_int.y) break;
                err += dx;
                p1_int.y = p1_int.y + sy;
            }
        }
    }
}
