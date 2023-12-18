const std = @import("std");
const fs = std.fs;
const allocPrint = std.fmt.allocPrint;
const print = std.debug.print;
const CrossTarget = std.zig.CrossTarget;

pub fn build(b: *std.Build) !void {
    var run_all_step = b.step("run-all", "Run all examples");
    const target = b.standardTargetOptions(.{});

    try addExample(b, run_all_step, target);
}

fn addExample(b: *std.Build, run_all: *std.build.Step, target: CrossTarget) !void {
    const src_dir = try fs.cwd().openIterableDir("src", .{});

    var it = src_dir.iterate();
    while (try it.next()) |entry| {
        switch (entry.kind) {
            .file => {
                const name = std.mem.trimRight(u8, entry.name, ".zig");
                print("Add example {s}...\n", .{name});

                const exe = b.addExecutable(.{
                    .name = try allocPrint(b.allocator, "examples-{s}", .{name}),
                    .root_source_file = .{ .path = try allocPrint(b.allocator, "src/{s}.zig", .{name}) },
                    .target = target,
                    .optimize = .Debug,
                });
                b.installArtifact(exe);
                const run_step = &b.addRunArtifact(exe).step;
                b.step(try allocPrint(b.allocator, "run-{s}", .{name}), try allocPrint(
                    b.allocator,
                    "Run example {s}",
                    .{name},
                )).dependOn(run_step);

                run_all.dependOn(run_step);
            },
            else => {},
        }
    }
}
