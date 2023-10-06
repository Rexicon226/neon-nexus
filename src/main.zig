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

// Our vram segment
var vram: dpmi.VideoMemBlock = undefined;

const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    vram = try dpmi.VideoMemBlock.alloc(0xA0000000);

    setVideoMode(VGA_256);

    var c: u16 = 0;
    while (true) {
        // Draw 10 pixels
        for (0..320 * 200) |i| {
            const x = @as(u16, @intCast(i % 320));
            const y = @as(u16, @intCast(i / 320));
            try vram.write(x, y, @as(u8, @intCast((c + x & y) & 255)));
        }
        c += 1;
    }

    try stdout.print("The colors #Programming Discussion\r\n", .{});
    try stdout.print("THE COLORS!!!\r\n", .{});
}

inline fn setVideoMode(video_mode: u8) void {
    _ = os.system.int(0x10, .{ .eax = video_mode });
}
