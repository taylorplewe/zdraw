const std = @import("std");
const draw = @import("draw.zig");
const input_events = @import("input_events.zig");
const shared = @import("shared.zig");

const WIDTH = 128;
const HEIGHT = 128;

var buffer: [1024 * 1024]u8 = undefined; // 1MB buffer
var fba = std.heap.FixedBufferAllocator.init(&buffer);
var allocator = fba.allocator();
var pixels_ptr: [*]shared.Pixel = undefined;

export fn init() void {
    draw.init(allocator, WIDTH, HEIGHT) catch {};
    pixels_ptr = draw.update(null).ptr;
}

export fn update_mouse_button(button: u32) void {
    const btn = switch (button) {
        0 => shared.MouseButton.Left,
        1 => shared.MouseButton.Right,
        else => shared.MouseButton.None,
    };
    const event = input_events.InputEvent{ .MouseButtonEvent = .{ .button = btn } };
    pixels_ptr = draw.update(event).ptr;
}

export fn update_mouse_motion(x: f32, y: f32) void {
    const event = input_events.InputEvent{ .MouseMotionEvent = .{ .x = x, .y = y } };
    pixels_ptr = draw.update(event).ptr;
}

export fn update_mouse_wheel(delta: f32) void {
    const event = input_events.InputEvent{ .MouseWheelEvent = .{ .delta = delta } };
    pixels_ptr = draw.update(event).ptr;
}

export fn update_program_event(event_type: u32) void {
    const prog_event = switch (event_type) {
        0 => input_events.ProgramEvent.Undo,
        1 => input_events.ProgramEvent.Redo,
        else => input_events.ProgramEvent.Quit,
    };
    const event = input_events.InputEvent{ .ProgramEvent = prog_event };
    pixels_ptr = draw.update(event).ptr;
}

export fn get_pixels() [*]shared.Pixel {
    return pixels_ptr;
}

export fn get_width() isize {
    return WIDTH;
}

export fn get_height() isize {
    return HEIGHT;
}

export fn get_pencil_radius() f32 {
    return draw.pencil_radius;
}
