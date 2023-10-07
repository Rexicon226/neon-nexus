const std = @import("std");

pub const os = @import("dos");
const system = os.system;
const dpmi = os.dpmi;

const gfx = @import("gfx.zig").Graphics;
const gfx_mode = @import("gfx.zig").GraphicsModes;

// This is necessary to pull in the start code with Zig 0.11
comptime {
    _ = @import("dos");
}

const stdout = std.io.getStdOut().writer();

// Simple 32 bit vector
const Vec2 = packed struct {
    x: u16,
    y: u16,
};

pub fn main() !void {
    try gfx.init(gfx_mode.VGA_320x200x8bpp);

    // Setup the player
    var player_position = Vec2{ .x = 0, .y = 0 };
    var player_size = Vec2{ .x = 16, .y = 16 };

    // Game loop
    while (true) {
        // Move the player to the right
        player_position.x += 1;
        player_position.x %= 320;
        player_position.y += 1;
        player_position.y %= 200;

        // // Clear the screen to cyan
        gfx.clear(0xAC);

        // Draw the player as a red rectangle
        for (0..player_size.y) |y| {
            for (0..player_size.x) |x| {
                // If the position is out of bounds, skip it
                if (((player_position.x + x) >= 320) or ((player_position.y + y) >= 200)) {
                    continue;
                }
                try gfx.drawPixel(
                    @as(u16, @intCast(player_position.x + x)),
                    @as(u16, @intCast(player_position.y + y)),
                    0x04,
                );
            }
        }

        gfx.present();
    }
}
