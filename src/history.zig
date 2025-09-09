const std = @import("std");
const shared = @import("shared.zig");

const MAX_HISTORY = 64;

pub const PixelHistory = struct {
    history: std.ArrayList([]shared.Pixel),
    head: usize = 0,

    pub fn new(allocator: std.mem.Allocator, initial_pixels: []shared.Pixel) PixelHistory {
        var new_history = PixelHistory{
            .history = std.ArrayList([]shared.Pixel).init(allocator),
        };

        new_history.appendPixelArray(initial_pixels);
        new_history.head = 0;

        return new_history;
    }

    pub fn commit(self: *PixelHistory, pixels_to_commit: []shared.Pixel) void {
        self.appendPixelArray(pixels_to_commit);
    }

    /// Returns the transaction (array of pixels) from the history at history.head and returns it.
    pub fn undo(self: *PixelHistory) []shared.Pixel {
        self.head = if (self.head > 0) self.head - 1 else self.head;
        return self.itemAtHead();
    }

    pub fn redo(self: *PixelHistory) []shared.Pixel {
        self.head = if (self.head < self.history.items.len - 1) self.head + 1 else self.head;
        return self.itemAtHead();
    }

    fn appendPixelArray(self: *PixelHistory, pixels_to_append: []shared.Pixel) void {
        self.removeAndFreeAllItemsAfterHead();

        if (self.head < MAX_HISTORY) {
            self.head += 1;
        } else {
            const pixels_to_free = self.history.orderedRemove(0);
            self.history.allocator.free(pixels_to_free);
        }

        const new_pixels = self.history.allocator.dupe(shared.Pixel, pixels_to_append) catch {
            // std.debug.print("\x1b[31mERROR\x1b[0m could not allocate memory for history\n", .{});
            // std.process.exit(1);
            unreachable;
        };

        self.history.append(new_pixels) catch {
            // std.debug.print("\x1b[31mERROR\x1b[0m could not appendSlice() to history\n", .{});
            // std.process.exit(1);
            unreachable;
        };
    }

    fn itemAtHead(self: *PixelHistory) []shared.Pixel {
        return self.history.items[self.head];
    }

    fn removeAndFreeAllItemsAfterHead(self: *PixelHistory) void {
        while (self.history.items.len > self.head + 1) {
            const pixels_to_free = self.history.orderedRemove(self.head + 1);
            self.history.allocator.free(pixels_to_free);
        }
    }
};
