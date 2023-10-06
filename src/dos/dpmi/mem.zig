const std = @import("std");
const FarPtr = @import("../far_ptr.zig").FarPtr;
const Segment = @import("segment.zig").Segment;

/// DosMemBlock represents an allocated block of memory that resides below the
/// 1 MiB address in physical memory and is accessible to DOS.
pub const DosMemBlock = struct {
    protected_mode_segment: Segment,
    real_mode_segment: u16,
    len: usize,

    pub fn alloc(size: u20) !DosMemBlock {
        const aligned_size = std.mem.alignForward(@TypeOf(size), size, 16);
        var protected_selector: u16 = 0;
        var real_segment: u16 = 0;
        const flags = asm volatile (
            \\ int $0x31
            \\ pushfw
            \\ popw %[flags]
            : [flags] "=r" (-> u16),
              [_] "={ax}" (real_segment),
              [_] "={dx}" (protected_selector),
            : [_] "{ax}" (@as(u16, 0x100)),
              [_] "{bx}" (aligned_size / 16),
            : "cc"
        );
        // TODO: Better error handling.
        if (flags & 1 != 0) return error.DpmiAllocError;
        return DosMemBlock{
            .protected_mode_segment = .{ .selector = protected_selector },
            .real_mode_segment = real_segment,
            .len = aligned_size,
        };
    }

    pub fn read(self: DosMemBlock, buffer: []u8) void {
        return self.protected_mode_segment.read(buffer);
    }

    pub fn write(self: DosMemBlock, bytes: []const u8) void {
        return self.protected_mode_segment.write(bytes);
    }
};

/// ExtMemBlock represents an allocated block of extended memory that resides
/// above the 1 MiB address in physical memory.
pub const ExtMemBlock = struct {
    addr: usize,
    len: usize,
    handle: usize,

    pub fn alloc(size: usize) !ExtMemBlock {
        var bx: u16 = undefined;
        var cx: u16 = undefined;
        var si: u16 = undefined;
        var di: u16 = undefined;

        const flags = asm volatile (
            \\ int $0x31
            \\ pushfw
            \\ popw %[flags]
            : [flags] "=r" (-> u16),
              [_] "={bx}" (bx),
              [_] "={cx}" (cx),
              [_] "={si}" (si),
              [_] "={di}" (di),
            : [_] "{ax}" (@as(u16, 0x501)),
              [_] "{bx}" (@as(u16, @truncate(size >> 16))),
              [_] "{cx}" (@as(u16, @truncate(size))),
        );
        // TODO: Better error handling.
        if (flags & 1 != 0) return error.DpmiAllocError;
        return ExtMemBlock{
            .addr = @as(usize, bx) << 16 | cx,
            .len = size,
            .handle = @as(usize, si) << 16 | di,
        };
    }

    pub fn createSegment(self: ExtMemBlock, seg_type: Segment.Type) Segment {
        const segment = Segment.alloc();
        segment.setBaseAddress(self.addr);
        segment.setAccessRights(seg_type);
        segment.setLimit(self.len - 1);
        return segment;
    }
};

pub const VideoMemBlock = struct {
    protected_mode_segment: Segment,

    var far_ptr: FarPtr = .{
        .segment = 0,
        .offset = 0,
    };

    pub fn alloc(address: u32) !VideoMemBlock {
        var protected_selector: u16 = 0;
        var flags: u16 = 0;

        // Allocate a DPMI descriptor
        flags = asm volatile (
            \\ int $0x31
            \\ pushfw
            \\ popw %[flags]
            : [flags] "=r" (-> u16),
              [_] "={ax}" (protected_selector),
            : [_] "{ax}" (0x0000), // Call DPMI function 0
              [_] "{cx}" (1), // Allocate one descriptor
            : "cc"
        );
        if (flags & 1 != 0) return error.DpmiAllocError;

        const addr_hi = @byteSwap(@as(u16, @intCast(address >> 16 & 0xFFFF))) >> 4;
        const addr_lo = @byteSwap(@as(u16, @intCast(address & 0xFFFF)));

        // Set the segment base address to VGA memory
        flags = asm volatile (
            \\ int $0x31
            \\ pushfw
            \\ popw %[flags]
            : [flags] "=r" (-> u16),
            : [_] "{ax}" (0x0007), // Call DPMI function 7
              [_] "{bx}" (protected_selector),
              [_] "{cx}" (addr_hi), // Segment base address
              [_] "{dx}" (addr_lo),
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
              [_] "{dx}" (0x0000),
            : "cc"
        );
        if (flags & 1 != 0) return error.DpmiSetSegmentLimitError;

        return VideoMemBlock{
            .protected_mode_segment = .{ .selector = protected_selector },
        };
    }

    pub inline fn write(self: VideoMemBlock, x: u16, y: u16, color: u8) !void {
        far_ptr = self.protected_mode_segment.farPtr();
        far_ptr.offset = (y << 8) + (y << 6) + x;
        var writer = far_ptr.writer();
        try writer.writeInt(u8, color, .Little);
    }
};
