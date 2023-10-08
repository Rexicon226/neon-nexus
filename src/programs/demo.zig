// A Demo Program for Neon Nexus

// This is required for the custom '_start'

pub const os = @import("dos");
const system = os.system;
const dpmi = os.dpmi;
comptime {
    _ = @import("dos");
}

const std = @import("std");
pub fn main() !void {
    std.debug.print("Hello, World!\n", .{});
}
