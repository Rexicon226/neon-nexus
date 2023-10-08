const std = @import("std");
const Build = std.Build;
const Cpu = std.Target.Cpu;

const FileRecipeStep = @import("src/build/FileRecipeStep.zig");

pub fn build(b: *Build) !void {
    const optimize = switch (b.standardOptimizeOption(.{})) {
        .Debug => .ReleaseSafe, // TODO: Support debug builds.
        else => |opt| opt,
    };

    var files = std.ArrayList([]const u8).init(b.allocator);
    defer files.deinit();

    var dir = try std.fs.cwd().openIterableDir("src/programs", .{});
    var it = dir.iterate();
    while (try it.next()) |file| {
        if (file.kind != .file) {
            continue;
        }
        if (!std.mem.endsWith(u8, file.name, ".zig")) {
            continue;
        }
        try files.append(b.dupe(file.name));
    }

    for (files.items) |file_name| {
        const neon_nexus_coff = b.addExecutable(.{
            .name = "output.exe", // Name overriden later.
            .target = .{
                .cpu_arch = .x86,
                .cpu_model = .{ .explicit = Cpu.Model.generic(.x86) },
                .os_tag = .other,
            },
            .optimize = optimize,
            .root_source_file = .{ .path = b.fmt("src/programs/{s}", .{file_name}) },
            .single_threaded = true,
        });

        var file_split = std.mem.splitSequence(u8, file_name, ".");
        var file_stripped = file_split.next().?;

        const dos_mod = b.addModule("dos", .{
            .source_file = .{ .path = "src/dos.zig" },
        });

        const gfx_mod = b.addModule("gfx", .{
            .source_file = .{ .path = "src/gfx.zig" },
            .dependencies = &.{
                .{ .name = "dos", .module = dos_mod },
            },
        });

        neon_nexus_coff.addModule("dos", dos_mod);
        neon_nexus_coff.addModule("gfx", gfx_mod);

        neon_nexus_coff.setLinkerScript(.{ .path = "src/djcoff.ld" });
        neon_nexus_coff.disable_stack_probing = true;
        neon_nexus_coff.strip = true;

        const neon_nexus_exe_inputs = [_]Build.LazyPath{
            .{ .path = "deps/cwsdpmi/bin/CWSDSTUB.EXE" },
            neon_nexus_coff.addObjCopy(.{ .format = .bin }).getOutput(),
        };
        const neon_nexus_exe = FileRecipeStep.create(b, concatFiles, &neon_nexus_exe_inputs, .bin, b.fmt("{s}.exe", .{file_stripped[0..@min(file_stripped.len - 1, 7)]}));

        const installed_neon_nexus = b.addInstallBinFile(neon_nexus_exe.getOutput(), b.fmt("{s}.exe", .{file_stripped[0..@min(file_stripped.len - 1, 7)]}));
        b.step(file_stripped, b.fmt("Build the {s} program", .{file_stripped})).dependOn(&installed_neon_nexus.step);

        const run_in_dosbox = b.addSystemCommand(&[_][]const u8{ "dosbox", "-conf", "dosbox_config.ini" });
        run_in_dosbox.addFileArg(installed_neon_nexus.source);

        const run = b.step(b.fmt("run-{s}", .{file_stripped}), b.fmt("Run the {s} program in DOSBox", .{file_stripped}));
        run.dependOn(&run_in_dosbox.step);
    }
}

fn concatFiles(_: *Build, inputs: []std.fs.File, output: std.fs.File) !void {
    for (inputs) |input| try output.writeFileAll(input, .{});
}
