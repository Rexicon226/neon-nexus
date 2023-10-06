const std = @import("std");

pub const os = @import("dos");
const system = os.system;
const dpmi = os.dpmi;

// This is necessary to pull in the start code with Zig 0.11.
comptime {
    _ = @import("dos");
}

// Our default VGA video mode, 320x200x256
const VGA_256 = 0x13;
const VGA_ADDRESS = 0xA0000000;

// Our vram segment
var vram: dpmi.VideoMemBlock = undefined;

const stdout = std.io.getStdOut().writer();

const Vec2 = packed struct {
    x: u16,
    y: u16,
};

pub fn main() !void {
    vram = try dpmi.VideoMemBlock.alloc(VGA_ADDRESS);

    setVideoMode(VGA_256);

    var player_position = Vec2{ .x = 160, .y = 100 };
    var player_size = Vec2{ .x = 16, .y = 16 };

    while (true) {
        vram.clear(0xCA);

        // Draw the player as a red rectangle
        for (0..player_size.y) |y| {
            for (0..player_size.x) |x| {
                try vram.writePixel(
                    @as(u16, @intCast(player_position.x + x)),
                    @as(u16, @intCast(player_position.y + y)),
                    0xAC,
                );
            }
        }

        player_position.x += 1;
    }

    try stdout.print("The colors #Programming Discussion\r\n", .{});
    try stdout.print("THE COLORS!!!\r\n", .{});
}

inline fn setVideoMode(video_mode: u8) void {
    _ = os.system.int(0x10, .{ .eax = video_mode });
}
