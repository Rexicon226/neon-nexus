const std = @import("std");

pub const os = @import("dos");
const system = os.system;
const dpmi = os.dpmi;

// This is necessary to pull in the start code with Zig 0.11.
comptime {
    _ = @import("dos");
}

const VGA_256 = 0x13;

var video_memory_segment: u16 = 0;

const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    try setupVideoMemoryAccess();
    setVideoMode(VGA_256);

    // Draw 10 pixels
    for (0..320 * 200) |i| {
        const x = @as(u16, @intCast(i % 320));
        const y = @as(u16, @intCast(i / 320));
        try drawPixel(x, y, @as(u8, @intCast(x & y & 255)));
    }

    try stdout.print("The colors Sinon... THE COLORS!!!\r\n", .{});
}

inline fn drawPixel(x: u16, y: u16, color: u8) !void {
    var far_ptr = system.FarPtr{
        .segment = video_memory_segment,
        .offset = (y << 8) + (y << 6) + x,
    };

    var vb_writer = far_ptr.writer();
    try vb_writer.writeInt(u8, color, .Big);
}

inline fn setVideoMode(video_mode: u8) void {
    _ = os.system.int(0x10, .{ .eax = video_mode });
}

inline fn setupVideoMemoryAccess() !void {
    var flags: u16 = 0;

    // Allocate a DPMI descriptor
    flags = asm volatile (
        \\ int $0x31
        \\ pushfw
        \\ popw %[flags]
        : [flags] "=r" (-> u16),
          [_] "={ax}" (video_memory_segment),
        : [_] "{ax}" (0x0000), // Call DPMI function 0
          [_] "{cx}" (1), // Allocate one descriptor
        : "cc"
    );
    if (flags & 1 != 0) return error.DpmiAllocError;

    // Set the segment base address to VGA memory
    flags = asm volatile (
        \\ int $0x31
        \\ pushfw
        \\ popw %[flags]
        : [flags] "=r" (-> u16),
        : [_] "{ax}" (0x0007), // Call DPMI function 7
          [_] "{bx}" (video_memory_segment),
          [_] "{cx}" (0x000A), // Segment base address
          [_] "{dx}" (0x0000),
        : "cc"
    );
    if (flags & 1 != 0) return error.DpmiSetSegmentBaseError;

    // Set the size of the segment to 64K
    flags = asm volatile (
        \\ int $0x31
        \\ pushfw
        \\ popw %[flags]
        : [flags] "=r" (-> u16),
        : [_] "{ax}" (0x0008), // Call DPMI function 8
          [_] "{cx}" (0x0002), // Segment limit
          [_] "{dx}" (0x00000),
        : "cc"
    );
    if (flags & 1 != 0) return error.DpmiSetSegmentLimitError;
}
