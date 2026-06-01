const std = @import("std");
const os_tag = @import("builtin").os.tag;

pub fn getDesktop(environ_map: *std.process.Environ.Map) []const u8 {
    if (environ_map.get("XDG_CURRENT_DESKTOP")) |de| {
        return de;
    }

    if (environ_map.get("DESKTOP_SESSION")) |de| {
        return de;
    }

    if (environ_map.get("WAYLAND_DISPLAY")) |_| {
        return "Wayland";
    }

    if (environ_map.get("DISPLAY")) |_| {
        return "X11";
    }

    if (os_tag == .macos) {
        return "Aqua";
    }

    return "tty";
}
