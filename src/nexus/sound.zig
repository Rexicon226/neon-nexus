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
    const self = @This();

    var mode: SoundCard = undefined;

    pub fn init(mode_: SoundCard) !void {
        mode = mode_;

        switch (mode.id) {
            .SoundBlaster => {},

            .PCSpeaker => {},
        }
    }

    pub fn beep(hz: u16) !void {
        switch (mode.id) {
            .PCSpeaker => {
                _ = asm volatile (
                    \\movw %[hz], %%bx
                    \\movw 0x34DD, %%ax
                    \\movw 0x0012, %%dx
                    \\cmp %%bx, %%dx
                    \\jnc 1f
                    \\div %%bx
                    \\movw %%ax, %%bx
                    \\inb $0x61, %%al
                    \\testb $0x3, %%al
                    \\orb $0x3, %%al
                    \\outb %%al, $0x61
                    \\movb $0xB6, %%al
                    \\outb %%al, $0x43
                    \\jnz 99f
                    \\orb $0x3, %%al
                    \\outb %%al, $0x61
                    \\movb 0x0B6, %%al
                    \\outb %%al, $0x43
                    \\call 2f
                    \\
                    \\1:
                    \\  ret
                    \\
                    \\99:
                    \\  movb %%bl, %%al
                    \\  outb %%al, $0x42
                    \\  movb %%bh, %%al
                    \\  outb %%al, $0x42
                    \\
                    \\2:
                    \\  inb $0x61, %%al
                    \\  andb $0xFC, %%al
                    \\  outb %%al, $0x61
                    \\  ret
                    :
                    : [hz] "{bx}" (hz),
                );
            },
            .SoundBlaster => {
                return error.Unsupported;
            },
        }
    }
};
