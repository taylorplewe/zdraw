const std = @import("std");
// const min = std.mem.min;
// const max = std.mem.max;
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

const SCALE = 5;
const SCREEN_WIDTH = 128;
const SCREEN_HEIGHT = SCREEN_WIDTH;
const BPP = 32;
const BPP8 = BPP / 8;

const COL_FG = 0xff000000;
const COL_BG = 0xffffffff;
const PENCIL_MAX_RADIUS = 28;
const PENCIL_MIN_RADIUS = 0;

const Pixel = packed struct {
    a: u8,
    b: u8,
    g: u8,
    r: u8,
};
const Point = struct {
    x: isize,
    y: isize,
};
const PointF = struct {
    x: f64,
    y: f64,
};

const MouseButton = enum {
    Left,
    Right,
    None,
};
var mouse_button_down: MouseButton = undefined;
var curr_mouse_point: PointF = undefined;
var last_mouse_point: PointF = undefined;

const State = struct {
    const Self = @This();
    allocator: std.mem.Allocator,

    // SDL resources
    window: *c.SDL_Window,
    renderer: *c.SDL_Renderer,
    surface: *c.SDL_Surface,

    // program resources
    drawn_pixels: []u8,
    pencil_radius: usize,

    fn new(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
            .window = undefined,
            .renderer = undefined,
            .surface = undefined,
            .drawn_pixels = undefined,
            .pencil_radius = (PENCIL_MAX_RADIUS - PENCIL_MIN_RADIUS) / 2,
        };
    }

    fn init(self: *State) !void {
        self.window = c.SDL_CreateWindow("Draw", SCREEN_WIDTH * SCALE, SCREEN_HEIGHT * SCALE, c.SDL_WINDOW_MOUSE_CAPTURE).?;
        self.renderer = c.SDL_CreateRenderer(self.window, null).?;
        self.surface = c.SDL_CreateSurface(SCREEN_WIDTH, SCREEN_HEIGHT, c.SDL_PIXELFORMAT_ABGR32);

        self.drawn_pixels = try self.allocator.alloc(u8, SCREEN_WIDTH * SCREEN_HEIGHT * BPP8);
        // var pencil_radius: usize = (PENCIL_MAX_RADIUS - PENCIL_MIN_RADIUS) / 2;
        @memset(self.drawn_pixels, COL_BG & 0xff);

        _ = c.SDL_CaptureMouse(true);
        _ = c.SDL_HideCursor();
    }

    fn update(self: *State) void {
        if (mouse_button_down != MouseButton.None) {
            const color: u32 = if (mouse_button_down == MouseButton.Left) 0 else 0xffffff; // debug
            fillSegment(self.drawn_pixels, last_mouse_point, curr_mouse_point, self.pencil_radius, color);
            fillCircle(self.drawn_pixels, @intFromFloat(curr_mouse_point.x), @intFromFloat(curr_mouse_point.y), self.pencil_radius, color);
        }
    }

    fn render(self: *State) void {
        _ = c.SDL_RenderClear(self.renderer);

        if (c.SDL_MUSTLOCK(self.surface)) {
            _ = c.SDL_LockSurface(self.surface);
        }

        // draw all drawn pixels to the surface
        const pixels: [*]u8 = @ptrCast(self.surface.*.pixels.?);
        @memcpy(pixels, self.drawn_pixels);

        // draw cursor
        fillCircle(pixels[0 .. SCREEN_WIDTH * SCREEN_HEIGHT * BPP8], @intFromFloat(curr_mouse_point.x), @intFromFloat(curr_mouse_point.y), self.pencil_radius, 0x00888888);

        if (c.SDL_MUSTLOCK(self.surface)) {
            _ = c.SDL_UnlockSurface(self.surface);
        }

        const scaled_surface = c.SDL_ScaleSurface(self.surface, SCREEN_WIDTH * SCALE, SCREEN_HEIGHT * SCALE, c.SDL_SCALEMODE_NEAREST);

        const tex = c.SDL_CreateTextureFromSurface(self.renderer, scaled_surface);
        defer c.SDL_DestroyTexture(tex);

        _ = c.SDL_RenderTexture(self.renderer, tex, null, null);
        _ = c.SDL_RenderPresent(self.renderer);
    }

    fn destroy(self: *State) void {
        c.SDL_DestroyWindow(self.window);
        c.SDL_DestroyRenderer(self.renderer);
        c.SDL_DestroySurface(self.surface);
        _ = c.SDL_CaptureMouse(false);
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    _ = c.SDL_Init(c.SDL_INIT_VIDEO);

    mouse_button_down = MouseButton.None;
    const state = try arena.allocator().create(State);
    state.* = State.new(arena.allocator());
    try state.init();
    defer state.destroy();

    // main loop
    var e: c.SDL_Event = undefined;
    var last_ticks: u64 = 0;

    mainloop: while (true) {
        const ticks = c.SDL_GetTicks();
        // const delta: f64 = @as(f64, @floatFromInt(ticks - last_ticks)) / 1000.0;
        last_ticks = ticks;

        while (c.SDL_PollEvent(&e)) {
            switch (e.type) {
                c.SDL_EVENT_QUIT => break :mainloop,
                c.SDL_EVENT_KEY_DOWN => {
                    if (e.key.scancode == c.SDL_SCANCODE_Q) break :mainloop;
                },
                c.SDL_EVENT_MOUSE_MOTION => {
                    curr_mouse_point = .{
                        .x = e.motion.x / SCALE,
                        .y = e.motion.y / SCALE,
                    };
                },
                c.SDL_EVENT_MOUSE_BUTTON_DOWN => {
                    last_mouse_point = curr_mouse_point;
                    switch (e.button.button) {
                        c.SDL_BUTTON_LEFT => mouse_button_down = MouseButton.Left,
                        c.SDL_BUTTON_RIGHT => mouse_button_down = MouseButton.Right,
                        else => {},
                    }
                },
                c.SDL_EVENT_MOUSE_BUTTON_UP => mouse_button_down = MouseButton.None,
                c.SDL_EVENT_MOUSE_WHEEL => {
                    if (e.wheel.y < 0) {
                        state.pencil_radius = min(state.pencil_radius + 1, PENCIL_MAX_RADIUS);
                    } else if (e.wheel.y > 0) {
                        state.pencil_radius = max(if (state.pencil_radius > 0) state.pencil_radius - 1 else 0, PENCIL_MIN_RADIUS);
                    }
                },
                else => {},
            }
        }

        state.update();
        state.render();
    }

    c.SDL_Quit();
}

fn colorPixel(mem: []u8, x: usize, y: usize, color: u32) void {
    const index = ((y * SCREEN_WIDTH) + x) * BPP8;
    if (index < 0 or index >= SCREEN_WIDTH * SCREEN_HEIGHT * BPP8) return;

    const pixel = Pixel{
        .r = @intCast(color & 0xff),
        .g = @intCast((color >> 8) & 0xff),
        .b = @intCast((color >> 16) & 0xff),
        .a = 0xff,
    };

    const pixels: []u32 = @ptrCast(@alignCast(mem));
    const pixel_ptr: *const u32 = @ptrCast(&pixel);
    pixels[index / 4] = pixel_ptr.*;
}

fn fillCircle(mem: []u8, x: isize, y: isize, r: usize, color: u32) void {
    for (0..(r * 2 + 1)) |w| {
        for (0..(r * 2 + 1)) |h| {
            const dx: isize = @as(isize, @intCast(r)) - @as(isize, @intCast(w));
            const dy: isize = @as(isize, @intCast(r)) - @as(isize, @intCast(h));
            const offset_x: isize = @mod((dx + x), SCREEN_WIDTH);
            const offset_y: isize = dy + y;
            if (((dx * dx) + (dy * dy) >= r * r) or (dx + x < 0) or (offset_y < 0) or ((dx + x) >= SCREEN_WIDTH)) continue;

            colorPixel(mem, @as(usize, @intCast(offset_x)), @as(usize, @intCast(offset_y)), color);
        }
    }
}

fn fillSegment(mem: []u8, p1: PointF, p2: PointF, r: usize, color: u32) void {
    // mouse_button_down = MouseButton.None; // debug

    const theta: f64 = std.math.atan2(p2.y - p1.y, p2.x - p1.x);

    if (r > 0) {
        const theta_perp: f64 = theta + std.math.pi / 2.0;
        const x_offs: f64 = @as(f64, @floatFromInt(r)) * std.math.cos(theta_perp);
        const y_offs: f64 = @as(f64, @floatFromInt(r)) * std.math.sin(theta_perp);
        const A: PointF = .{ .x = p2.x + x_offs, .y = p2.y + y_offs };
        const B: PointF = .{ .x = p1.x + x_offs, .y = p1.y + y_offs };
        const C: PointF = .{ .x = p2.x - x_offs, .y = p2.y - y_offs };
        const D: PointF = .{ .x = p1.x - x_offs, .y = p1.y - y_offs };
        const AB: PointF = .{ .x = B.x - A.x, .y = B.y - A.y };
        const AC: PointF = .{ .x = C.x - A.x, .y = C.y - A.y };
        const len1_sq: f64 = (AB.x * AB.x) + (AB.y * AB.y);
        const len2_sq: f64 = (AC.x * AC.x) + (AC.y * AC.y);

        const bound_top: usize = @intFromFloat(min(max(min(A.y, min(B.y, min(C.y, D.y))), 0), SCREEN_HEIGHT - 1));
        const bound_bottom: usize = @intFromFloat(min(max(max(A.y, max(B.y, max(C.y, D.y))), 0), SCREEN_HEIGHT - 1));
        const bound_left: usize = @intFromFloat(min(max(min(A.x, min(B.x, min(C.x, D.x))), 0), SCREEN_WIDTH - 1));
        const bound_right: usize = @intFromFloat(min(max(max(A.x, max(B.x, max(C.x, D.x))), 0), SCREEN_WIDTH - 1));

        for (bound_top..bound_bottom + 1) |row| {
            for (bound_left..bound_right + 1) |col| {
                const P: Point = .{ .x = @intCast(col), .y = @intCast(row) };
                const AP: PointF = .{ .x = @as(f64, @floatFromInt(P.x)) - A.x, .y = @as(f64, @floatFromInt(P.y)) - A.y };
                const dot1: f64 = AB.x * AP.x + AB.y * AP.y;
                const dot2: f64 = AC.x * AP.x + AC.y * AP.y;

                if (0 <= dot1 and dot1 <= len1_sq and 0 <= dot2 and dot2 <= len2_sq)
                    colorPixel(mem, @intCast(P.x), @intCast(P.y), color);
            }
        }
    } else {
        // Bresenham's algorithm
        var p1_int: Point = .{ .x = @intFromFloat(p1.x), .y = @intFromFloat(p1.y) };
        const p2_int: Point = .{ .x = @intFromFloat(p2.x), .y = @intFromFloat(p2.y) };
        const dx: isize = @intCast(@abs(p2_int.x - p1_int.x));
        const dy: isize = @intCast(-@as(isize, @intCast(@abs(p2_int.y - p1_int.y))));
        const sx: isize = if (p1_int.x < p2_int.x) 1 else -1;
        const sy: isize = if (p1_int.y < p2_int.y) 1 else -1;
        var err = dx + dy;

        // safe bounds
        const num_pixels: usize = @intCast(if (dx > -dy) dx else -dy);
        for (0..num_pixels) |_| {
            if (p1_int.x >= 0 and p1_int.x < SCREEN_WIDTH and p1_int.y >= 0 and p1_int.y < SCREEN_HEIGHT)
                colorPixel(mem, @intCast(p1_int.x), @intCast(p1_int.y), color);

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

    last_mouse_point = curr_mouse_point;
}

fn min(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return if (a < b) a else b;
}
fn max(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return if (a > b) a else b;
}
