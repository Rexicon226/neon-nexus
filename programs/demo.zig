// A Demo Program for Neon Nexus

const std = @import("std");

const nexus = @import("nexus");

// Required for pulling symbols.
pub const os = nexus.os;
comptime {
    _ = @import("nexus").os;
}

pub fn main() !void {
    std.debug.print("Hello, World!\n", .{});
}
