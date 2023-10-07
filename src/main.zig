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
// VGA input status 1
const VGA_INPUT_STATUS_1 = 0x03DA;
// VRetrace
const VGA_VRETRACE = 0x08;

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

    // Set the video mode to 320x200x256
    setVideoMode(VGA_256);

    // Setup the player
    var player_position = Vec2{ .x = 0, .y = 0 };
    var player_size = Vec2{ .x = 16, .y = 16 };

    // Game loop
    while (true) {
        // Move the player to the right
        player_position.x += 5;
        player_position.x %= 320;
        player_position.y += 2;
        player_position.y %= 200;

        // Clear the screen to cyan
        clearFrameBuffer(vram_backbuffer_segment, 0x03);

        // Draw the player as a red rectangle
        for (0..player_size.y) |y| {
            for (0..player_size.x) |x| {
                // If the position is out of bounds, skip it
                if (((player_position.x + x) >= 320) or ((player_position.y + y) >= 200)) {
                    continue;
                }
                try drawPixel(
                    vram_backbuffer_segment,
                    @as(u16, @intCast(player_position.x + x)),
                    @as(u16, @intCast(player_position.y + y)),
                    0x04,
                );
            }
        }

        // Wait for the next frame
        waitFrame();
        // Copy the backbuffer to vram
        copyBackBufferToVram();
    }

    try stdout.print("The colors #Programming Discussion\r\n", .{});
    try stdout.print("THE COLORS!!!\r\n", .{});
}

fn waitFrame() void {
    // Wait until we're not in vertical sync, so we can catch leading edge
    while (system.inp(VGA_INPUT_STATUS_1) & VGA_VRETRACE != 0) {}
    // Wait until we are in vertical sync
    while (system.inp(VGA_INPUT_STATUS_1) & VGA_VRETRACE == 0) {}
}

inline fn setVideoMode(video_mode: u8) void {
    _ = os.system.int(0x10, .{ .eax = video_mode });
}

fn drawPixel(frame_buffer: dpmi.Segment, x: u16, y: u16, color: u8) !void {
    var far_ptr = frame_buffer.farPtr();
    far_ptr.offset = (y << 8) + (y << 6) + x;
    var writer = far_ptr.writer();
    try writer.writeInt(u8, color, .Little);
}

fn clearFrameBuffer(frame_buffer: dpmi.Segment, color: u8) void {
    var far_ptr = frame_buffer.farPtr();
    far_ptr.writeRepeat(color, VGA_256_SIZE);
}

fn copyBackBufferToVram() void {
    var far_ptr = vram_segment.farPtr();
    var backbuffer_far_ptr = vram_backbuffer_segment.farPtr();
    far_ptr.copyFrom(backbuffer_far_ptr, VGA_256_SIZE);
}
