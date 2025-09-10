const std = @import("std");
const shared = @import("shared");
const draw = shared.draw;
const input_events = shared.input_events;

const WIDTH = 128;
const HEIGHT = 128;

var allocator = std.heap.wasm_allocator;
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
    const event = input_events.InputEvent{ .ProgramEvent = @enumFromInt(event_type) };
    pixels_ptr = draw.update(event).ptr;
}

export fn get_pixels() [*]shared.Pixel {
    return pixels_ptr;
}
