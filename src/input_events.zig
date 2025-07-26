const shared = @import("shared.zig");

/// delta is a float representing the Y-axis wheel delta.
pub const MouseWheelEvent = struct {
    delta: f32,
};

/// x and y are floats representing the current position of the cursor.
pub const MouseMotionEvent = struct {
    x: f32,
    y: f32,
};

pub const MouseButtonEvent = struct {
    button: shared.MouseButton,
};

pub const ProgramEvent = enum {
    Quit,
};

pub const InputEvent = union(enum) {
    MouseWheelEvent: MouseWheelEvent,
    MouseMotionEvent: MouseMotionEvent,
    MouseButtonEvent: MouseButtonEvent,
    ProgramEvent: ProgramEvent,
};
