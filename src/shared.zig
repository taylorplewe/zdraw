pub const SCALE = 5;
pub const BPP = 32;
pub const BPP8 = BPP / 8;

pub const MouseButton = enum {
    Left,
    Right,
    None,
};
pub const Pixel = packed struct {
    a: u8,
    b: u8,
    g: u8,
    r: u8,
};
pub const Point = struct {
    x: isize,
    y: isize,
};
pub const PointF = struct {
    x: f64,
    y: f64,
};
