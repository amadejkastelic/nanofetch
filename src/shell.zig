const std = @import("std");

pub fn getShell(environ_map: *std.process.Environ.Map) []const u8 {
    const shell_path = environ_map.get("SHELL") orelse return "unknown";
    return std.fs.path.basename(shell_path);
}
