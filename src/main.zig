const std = @import("std");

pub const os = @import("dos");
const system = os.system;
const dpmi = os.dpmi;

// This is necessary to pull in the start code with Zig 0.11
comptime {
    _ = @import("dos");
}

// Our default VGA video mode, 320x200x256
const VGA_256 = 0x13;
// The size of the VGA video mode in bytes
const VGA_256_SIZE = 320 * 200;
// Address of the memory mapped VGA card
const VGA_ADDRESS = 0xA0000000;

// Our vram segment
var vram: dpmi.VideoMemBlock = undefined;
// Get the vram segment, we get this from the vram block
var vram_segment: dpmi.Segment = undefined;
// Our vram backbuffer
var vram_backbuffer: dpmi.ExtMemBlock = undefined;
// Our vram backbuffer segment, this isn't initialized until we call createSegment
var vram_backbuffer_segment: dpmi.Segment = undefined;

const stdout = std.io.getStdOut().writer();

// Simple 32 bit vector
const Vec2 = packed struct {
    x: u16,
    y: u16,
};

pub fn main() !void {
    // Attempt to allocate a 64k block of memory for our vram
    vram = try dpmi.VideoMemBlock.alloc(VGA_ADDRESS);
    // Get the segment for the vram block
    vram_segment = vram.getSegment();

    // Attempt to allocate a 64k block of memory for our vram backbuffer
    vram_backbuffer = try dpmi.ExtMemBlock.alloc(VGA_256_SIZE);
    // Get the segment for the vram backbuffer
    vram_backbuffer_segment = vram_backbuffer.createSegment(.data);

    // Draw buffer
    var frame_buffer = vram_backbuffer_segment.farPtr();
    _ = frame_buffer;

    // Set the video mode to 320x200x256
    setVideoMode(VGA_256);

    // Setup the player
    var player_position = Vec2{ .x = 160, .y = 100 };
    _ = player_position;
    var player_size = Vec2{ .x = 16, .y = 16 };
    _ = player_size;

    // Game loop
    while (true) {
        // Clear the screen to cyan
        vram.clear(0xCA);

        wait30Frames();

        // Draw the player as a red rectangle
        // for (0..player_size.y) |y| {
        //     _ = y;
        //     for (0..player_size.x) |x| {
        //         _ = x;
        //         var fp = vram_backbuffer_segment.farPtr();
        //         _ = fp;
        //         // try vram.writePixel(
        //         //     @as(u16, @intCast(player_position.x + x)),
        //         //     @as(u16, @intCast(player_position.y + y)),
        //         //     0xAC,
        //         // );
        //     }
        // }

        // Move the player to the right
        // player_position.x += 1;
    }

    try stdout.print("The colors #Programming Discussion\r\n", .{});
    try stdout.print("THE COLORS!!!\r\n", .{});
}

fn wait30Frames() void {
    //     for (i=0; i<30; i++) {
    //       /* Wait until we’re not in vertical sync, so we can catch leading edge */
    //       while ((inp(INPUT_STATUS_1) & 0×08) != 0) ;
    //       /* Wait until we are in vertical sync */
    //       while ((inp(INPUT_STATUS_1) & 0×08) == 0) ;
    //    }

    for (0..30) |_| {
        while (system.inp(0x3DA) & 0x08 != 0) {}
        while (system.inp(0x3DA) & 0x08 == 0) {}
    }
}

inline fn setVideoMode(video_mode: u8) void {
    _ = os.system.int(0x10, .{ .eax = video_mode });
}
