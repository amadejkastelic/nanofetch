const std = @import("std");

pub fn getDesktop(allocator: std.mem.Allocator) ![]const u8 {
    _ = allocator;

    if (std.posix.getenv("XDG_CURRENT_DESKTOP")) |de| {
        return de;
    }

    if (std.posix.getenv("DESKTOP_SESSION")) |de| {
        return de;
    }

    if (std.posix.getenv("WAYLAND_DISPLAY")) |_| {
        return "Wayland";
    }

    if (std.posix.getenv("DISPLAY")) |_| {
        return "X11";
    }

    return "tty";
}
