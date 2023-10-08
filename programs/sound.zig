const std = @import("std");

const nexus = @import("nexus");

// Required for pulling symbols.
pub const os = nexus.os;
comptime {
    _ = @import("nexus").os;
}

const sound = nexus.sound.Sound;
const sound_card = nexus.sound.SoundCards;

pub fn main() !void {
    try sound.init(sound_card.PCSpeaker);

    // Test Beep 1000 times.
    var i: u32 = 0;
    while (i < 1000) : (i += 1) {
        try sound.beep(i);
    }
}
