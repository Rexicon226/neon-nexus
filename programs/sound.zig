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

    // Test Beep 1 time.
    try sound.beep(400, 10);
}
