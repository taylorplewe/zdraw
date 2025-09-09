pub const SCALE = 5;
pub const BPP = 32;
pub const BPP8 = BPP / 8;

pub const MouseButton = enum {
    Left,
    Right,
    None,
};
pub const Pixel = packed struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};
pub const Point = struct {
    x: isize,
    y: isize,
};
pub const PointF = struct {
    x: f64,
    y: f64,
};

pub fn min(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return if (a < b) a else b;
}
pub fn max(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return if (a > b) a else b;
}
