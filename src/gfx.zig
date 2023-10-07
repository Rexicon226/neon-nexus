const std = @import("std");

const os = @import("dos");
const system = os.system;
const dpmi = os.dpmi;

const GraphicsModeId = union(enum) {
    vga: u8,
};

pub const GraphicsMode = struct {
    mode_id: GraphicsModeId,
    width: u16,
    height: u16,
    size: u32,
    bpp: u8,
    memory_address: u32,
};

pub const VgaDeviceSpec = struct {
    pub const INPUT_STATUS_1 = 0x3DA;
    pub const INPUT_STATUS_1_VRETRACE = 0x08;
};

pub const GraphicsModes = struct {
    pub const VGA_320x200x8bpp = GraphicsMode{
        .mode_id = .{ .vga = 0x13 },
        .width = 320,
        .height = 200,
        .size = 320 * 200,
        .bpp = 8,
        .memory_address = 0xA0000000,
    };
    // TODO(SeedyROM): Add other graphics modes...
};

pub const Graphics = struct {
    const Self = @This();

    /// The current graphics mode
    var mode: GraphicsMode = undefined;
    /// Our vram segment
    var vram: dpmi.VideoMemBlock = undefined;
    /// Get the vram segment, we get this from the vram block
    var vram_segment: dpmi.Segment = undefined;
    /// Our vram backbuffer
    var vram_backbuffer: dpmi.ExtMemBlock = undefined;
    /// Our vram backbuffer segment, this isn't initialized until we call createSegment
    var vram_backbuffer_segment: dpmi.Segment = undefined;

    // Reusable far ptrs
    var far_ptr: system.FarPtr = undefined;
    var backbuffer_far_ptr: system.FarPtr = undefined;

    /// Initialize the graphics system
    pub fn init(mode_: GraphicsMode) !void {
        try initializeVram();
        setMode(mode_);
    }

    inline fn initializeVram() !void {
        switch (mode.mode_id) {
            GraphicsModeId.vga => {
                // Attempt to allocate a 64k block of memory for our vram
                vram = try dpmi.VideoMemBlock.alloc(mode.memory_address);
                // Get the segment for the vram block
                vram_segment = vram.getSegment();

                // Attempt to allocate a 64k block of memory for our vram backbuffer
                vram_backbuffer = try dpmi.ExtMemBlock.alloc(mode.size);
                // Get the segment for the vram backbuffer
                vram_backbuffer_segment = vram_backbuffer.createSegment(.data);
            },
        }
    }

    /// Set the graphics mode
    inline fn setMode(mode_: GraphicsMode) void {
        _ = os.system.int(0x10, .{ .eax = @intFromEnum(mode_.mode_id) });
    }

    /// Wait for the next frame
    pub inline fn waitForNextFrame() void {
        switch (mode.mode_id) {
            GraphicsModeId.vga => {
                const spec = VgaDeviceSpec;
                while (os.system.inp(spec.INPUT_STATUS_1) & spec.INPUT_STATUS_1_VRETRACE != 0) {}
                while (os.system.inp(spec.INPUT_STATUS_1) & spec.INPUT_STATUS_1_VRETRACE == 0) {}
            },
        }
    }

    /// Draw a pixel
    pub inline fn drawPixel(x: u16, y: u16, color: u8) !void {
        far_ptr = vram_backbuffer_segment.farPtr();
        far_ptr.offset = (y << 8) + (y << 6) + x;
        var writer = far_ptr.writer();
        try writer.writeInt(u8, color, .Little);
    }

    /// Clear the screen
    pub inline fn clear(color: u8) void {
        far_ptr = vram_backbuffer_segment.farPtr();
        far_ptr.writeRepeat(color, mode.size);
    }

    /// Present the backbuffer
    pub inline fn present() void {
        waitForNextFrame();

        far_ptr = vram_segment.farPtr();
        backbuffer_far_ptr = vram_backbuffer_segment.farPtr();
        far_ptr.copyFrom(backbuffer_far_ptr, mode.size);
    }
};
