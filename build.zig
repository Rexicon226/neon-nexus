const std = @import("std");
const Build = std.Build;
const Cpu = std.Target.Cpu;

const FileRecipeStep = @import("src/build/FileRecipeStep.zig");

pub fn build(b: *Build) !void {
    const optimize = switch (b.standardOptimizeOption(.{})) {
        .Debug => .ReleaseSafe, // TODO: Support debug builds.
        else => |opt| opt,
    };

    const program_name: []const u8 = b.option([]const u8, "program", "Which program to build from the src/programs directory") orelse return error.@"No Program was selected. Please run with -Dprogram=";

    const neon_nexus_coff = b.addExecutable(.{
        .name = "output.exe", // Name overriden later.
        .target = .{
            .cpu_arch = .x86,
            .cpu_model = .{ .explicit = Cpu.Model.generic(.x86) },
            .os_tag = .other,
        },
        .optimize = optimize,
        .root_source_file = .{ .path = b.fmt("src/programs/{s}.zig", .{program_name}) },
        .single_threaded = true,
    });

    neon_nexus_coff.addModule("dos", b.addModule("dos", .{
        .source_file = .{ .path = "src/dos.zig" },
    }));

    neon_nexus_coff.setLinkerScriptPath(.{ .path = "src/djcoff.ld" });
    neon_nexus_coff.disable_stack_probing = true;
    neon_nexus_coff.strip = true;

    const neon_nexus_exe_inputs = [_]Build.LazyPath{
        .{ .path = "deps/cwsdpmi/bin/CWSDSTUB.EXE" },
        neon_nexus_coff.addObjCopy(.{ .format = .bin }).getOutput(),
    };
    const neon_nexus_exe = FileRecipeStep.create(b, concatFiles, &neon_nexus_exe_inputs, .bin, b.fmt("{s}.exe", .{program_name}));

    const installed_neon_nexus = b.addInstallBinFile(neon_nexus_exe.getOutput(), b.fmt("{s}.exe", .{program_name}));
    b.getInstallStep().dependOn(&installed_neon_nexus.step);

    const run_in_dosbox = b.addSystemCommand(&[_][]const u8{ "dosbox", "-conf", "dosbox_config.ini" });
    run_in_dosbox.addFileArg(installed_neon_nexus.source);

    const run = b.step("run", "Run the demo program in DOSBox");
    run.dependOn(&run_in_dosbox.step);
}

fn concatFiles(_: *Build, inputs: []std.fs.File, output: std.fs.File) !void {
    for (inputs) |input| try output.writeFileAll(input, .{});
}
