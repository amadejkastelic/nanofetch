const std = @import("std");

pub fn getShell(allocator: std.mem.Allocator) ![]const u8 {
    _ = allocator;

    const shell_path = std.posix.getenv("SHELL") orelse return "unknown";

    const shell_name = std.fs.path.basename(shell_path);

    return shell_name;
}
