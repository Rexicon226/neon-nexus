const std = @import("std");

const os = @import("../nexus.zig").os;
const dpmi = os.dpmi;
const system = os.system;

pub const SoundCardID = union(enum) {
    SoundBlaster: u8,
    PCSpeaker: u8,
};

const SoundCard = struct {
    id: SoundCardID,
};

pub const SoundCards = struct {

    // Default DOSBOX: SET BLASTER=A220 I7 D1 H5 T6
    // A = IO Port
    // I = IRQ
    // D = 8-bit DMA Channel
    // H = 16-bit DMA Channel

    pub const SoundBlaster = SoundCard{
        .id = .{ .SoundBlaster = 0x0 },
    };

    pub const PCSpeaker = SoundCard{
        .id = .{ .PCSpeaker = 0x1 },
    };
};

pub const Sound = struct {
    const Self = @This();

    var mode: SoundCard = undefined;

    pub fn init(mode_: SoundCard) !void {
        mode = mode_;

        switch (mode.id) {
            .SoundBlaster => {},

            .PCSpeaker => {},
        }
    }

    pub fn beep(hz: u16, milliseconds: u32) !void {
        _ = milliseconds;
        switch (mode.id) {
            .PCSpeaker => {
                _ = asm volatile (
                    \\mov %[hz], %%ax
                    \\call sound
                    \\xor %%ax, %%ax
                    \\int $0x16
                    \\call nosound
                    \\int $0x20
                    \\
                    \\
                    \\nosound:
                    \\  inb   $0x61, %%al
                    \\  andb  0xFC, %%al
                    \\  outb  %%al, $0x61
                    \\  ret
                    \\
                    \\
                    \\sound: 
                    \\  mov   %%ax, %%bx
                    \\  mov   0x12, %%dx
                    \\  mov   0x34DC, %%ax
                    \\  div   %%bx
                    \\  mov   %%al, %%bl
                    \\  mov   0xB6, %%al 
                    \\  outb  %%al, $0x43
                    \\  mov   %%bl, %%al
                    \\  outb  %%al, $0x42
                    \\  mov   %%ah, %%al
                    \\  outb  %%al, $0x42
                    \\  inb   $0x61, %%al
                    \\  or    $3, %%al
                    \\  outb  %%al, $0x61
                    \\  ret
                    : // Returns AX, BX, DX = undefined;
                    : [hz] "{ax}" (hz),
                );
            },
            .SoundBlaster => {
                return error.Unsupported;
            },
        }
    }
};
