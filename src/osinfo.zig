const std = @import("std");
const syscall = @import("syscall.zig");

pub fn getOsName(allocator: std.mem.Allocator) ![]const u8 {
    const content = try syscall.readEntireFile(allocator, "/etc/os-release");
    defer allocator.free(content);

    var pretty_name: ?[]const u8 = null;
    var name: ?[]const u8 = null;

    var lines = std.mem.splitScalar(u8, content, '\n');

    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "PRETTY_NAME=")) {
            const value = line[12..];
            if (value.len > 2 and value[0] == '"') {
                pretty_name = try allocator.dupe(u8, value[1 .. value.len - 1]);
            } else {
                pretty_name = try allocator.dupe(u8, value);
            }
        } else if (std.mem.startsWith(u8, line, "NAME=")) {
            const value = line[5..];
            if (value.len > 2 and value[0] == '"') {
                name = try allocator.dupe(u8, value[1 .. value.len - 1]);
            } else {
                name = try allocator.dupe(u8, value);
            }
        }
    }

    return pretty_name orelse name orelse try allocator.dupe(u8, "Linux");
}
