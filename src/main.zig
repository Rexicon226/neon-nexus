const std = @import("std");

pub const os = @import("dos");
const system = os.system;
const dpmi = os.dpmi;

// This is necessary to pull in the start code with Zig 0.11.
comptime {
    _ = @import("dos");
}

const VGA_256 = 0x13;

var video_buffer: system.FarPtr = system.FarPtr{
    .offset = 0x0000,
    .segment = 0xA000,
};

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("What's up Sinon!!! Let's FUCKIN GOOOOOOOOO!!!!!!\r\n", .{});

    setVideoMode(VGA_256);

    // Draw 10 pixels
    for (0..10) |x| {
        try drawPixel(@as(u16, @intCast(10 + x)), @as(u16, 20), 0xFF);
    }
}

fn drawPixel(x: u16, y: u16, color: u8) !void {
    var offset = video_buffer.offset;
    var vb_writer = video_buffer.writer();
    video_buffer.offset = offset + ((y << 8) + (y << 6)) + x;
    try vb_writer.writeInt(u8, color, .Little);
    video_buffer.offset = offset;
}

fn setVideoMode(video_mode: u8) void {
    _ = os.system.int(0x10, .{ .eax = video_mode });
}
