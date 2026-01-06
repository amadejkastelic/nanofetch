const std = @import("std");
const colors = @import("colors.zig");
const system = @import("system.zig");
const shell = @import("shell.zig");
const desktop = @import("desktop.zig");
const osinfo = @import("osinfo.zig");
const logo = @import("logo.zig");

const winsize = extern struct {
    ws_row: u16,
    ws_col: u16,
    ws_xpixel: u16,
    ws_ypixel: u16,
};

const TIOCGWINSZ = 0x5413;

fn getTerminalWidth() ?usize {
    const fd = std.posix.STDOUT_FILENO;
    var ws: winsize = undefined;

    const rc = std.os.linux.ioctl(fd, TIOCGWINSZ, @intFromPtr(&ws));
    if (rc != -1) return ws.ws_col;

    if (std.posix.getenv("COLUMNS")) |cols_str| {
        return std.fmt.parseInt(usize, cols_str, 10) catch null;
    }

    return null;
}

const MIN_WIDTH_FOR_LOGO: usize = 70;

const icons = [_][]const u8{
    "", // 0 - empty
    "\xef\x8c\x93", // 1 - NixOS logo (U+F233)
    "\xee\x9c\x92", // 2 - kernel (U+E712)
    "\xee\x9e\x95", // 3 - shell (U+E795)
    "\xef\x80\x97", // 4 - uptime (U+F017)
    "\xef\x8b\x92", // 5 - desktop (U+F2D2)
    "\xef\x92\xbc", // 6 - memory (U+F49C)
    "\xf3\xb1\xa5\x8e", // 7 - storage (U+E75E) - 4 bytes
    "\xee\x88\xab", // 8 - colors (U+E22B)
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    colors.initColors();

    const term_width = getTerminalWidth();
    const show_logo = if (term_width) |w| w >= MIN_WIDTH_FOR_LOGO else false;
    const logo_data = if (show_logo) logo.getLogo(colors.use_color) else null;

    const kernel_info = try system.getKernelInfo();
    const uptime_seconds = try system.getUptime();
    const uptime_str = system.formatUptime(uptime_seconds);
    const mem_info = try system.getMemoryInfo(allocator);
    const mem_str_arr = system.formatMemory(mem_info);
    const mem_str = mem_str_arr[0..];
    const disk_info = try system.getDiskInfo(allocator);
    const disk_str_arr = system.formatDisk(disk_info);
    const disk_str = disk_str_arr[0..];
    const shell_name = try shell.getShell(allocator);
    const desktop_name = try desktop.getDesktop(allocator);
    const os_name = try osinfo.getOsName(allocator);

    const username = std.posix.getenv("USER") orelse "unknown";
    const nodename = std.mem.sliceTo(&kernel_info.nodename, 0);

    var output_buffer: [16384]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&output_buffer);
    const writer = fbs.writer();

    const labels = [_][]const u8{
        "",
        "System",
        "Kernel",
        "Shell",
        "Uptime",
        "Desktop",
        "Memory",
        "Storage (/)",
        "Colors",
    };

    for (0..9) |i| {
        if (show_logo) {
            const segments = logo_data.?.lines[i];
            for (segments) |segment| {
                if (colors.use_color) {
                    try writer.writeAll(logo_data.?.color_map[segment.color]);
                }
                try writer.writeAll(segment.text);
            }
        }

        if (i == 0) {
            if (colors.use_color) {
                try writer.writeAll(colors.colorCode(.blue));
            }
            try writer.writeAll(username);
            try writer.writeAll("@");
            if (colors.use_color) {
                try writer.writeAll(colors.colorCode(.red));
            }
            try writer.writeAll(nodename);
            try writer.writeAll(" ~");
            try writer.writeAll("\n");
            continue;
        } else if (i < labels.len) {
            // Icon + label
            if (colors.use_color) try writer.writeAll(colors.colorCode(.cyan));
            try writer.writeAll(icons[i]);
            try writer.writeAll("  ");
            if (colors.use_color) try writer.writeAll(colors.colorCode(.blue));
            try writer.writeAll(labels[i]);
            // Reset color before padding/separator
            if (colors.use_color) try writer.writeAll(colors.colorCode(.reset));
            // Align: label + padding = 13 chars, then separator
            const padding = @max(0, 13 - labels[i].len);
            for (0..padding) |_| try writer.writeAll(" ");
            // Separator
            try writer.writeAll("\xee\x98\xa1");
            try writer.writeAll(" ");
        }

        switch (i) {
            1 => {
                try writer.writeAll(os_name);
                try writer.writeAll("\n");
            },
            2 => {
                const kernel_ver = kernel_info.release[0 .. std.mem.indexOfScalar(u8, &kernel_info.release, 0) orelse kernel_info.release.len];
                const arch = system.getKernelArch(&kernel_info);
                try writer.writeAll(kernel_ver);
                try writer.writeAll(" (");
                try writer.writeAll(arch);
                try writer.writeAll(")");
                try writer.writeAll("\n");
            },
            3 => {
                try writer.writeAll(shell_name);
                try writer.writeAll("\n");
            },
            4 => {
                const uptime_end = std.mem.indexOfScalar(u8, &uptime_str, 0) orelse uptime_str.len;
                try writer.writeAll(uptime_str[0..uptime_end]);
                try writer.writeAll("\n");
            },
            5 => {
                try writer.writeAll(desktop_name);
                if (std.posix.getenv("WAYLAND_DISPLAY")) |_| {
                    try writer.writeAll(" (Wayland)");
                } else if (std.posix.getenv("DISPLAY")) |_| {
                    try writer.writeAll(" (X11)");
                }
                try writer.writeAll("\n");
            },
            6 => {
                const mem_end = std.mem.indexOfScalar(u8, mem_str, 0) orelse mem_str.len;
                try writer.writeAll(mem_str[0..mem_end]);
                if (colors.use_color) {
                    try writer.writeAll(" (");
                    try writer.writeAll(colors.colorCode(.cyan));
                    var mem_pct_buf: [4]u8 = undefined;
                    try writer.writeAll(std.fmt.bufPrint(&mem_pct_buf, "{}%", .{mem_info.percentage}) catch unreachable);
                    try writer.writeAll("\x1b[0m");
                    try writer.writeAll(")");
                }
                try writer.writeAll("\n");
            },
            7 => {
                const disk_end = std.mem.indexOfScalar(u8, disk_str, 0) orelse disk_str.len;
                try writer.writeAll(disk_str[0..disk_end]);
                if (colors.use_color) {
                    try writer.writeAll(" (");
                    try writer.writeAll(colors.colorCode(.cyan));
                    var disk_pct_buf: [4]u8 = undefined;
                    try writer.writeAll(std.fmt.bufPrint(&disk_pct_buf, "{}%", .{disk_info.percentage}) catch unreachable);
                    try writer.writeAll("\x1b[0m");
                    try writer.writeAll(")");
                }
                try writer.writeAll("\n");
            },
            8 => {
                if (colors.use_color) {
                    try writer.writeAll("\x1b[34m");
                    try writer.writeAll("\xef\x84\x91");
                    try writer.writeAll("  ");
                    try writer.writeAll("\x1b[36m");
                    try writer.writeAll("\xef\x84\x91");
                    try writer.writeAll("  ");
                    try writer.writeAll("\x1b[32m");
                    try writer.writeAll("\xef\x84\x91");
                    try writer.writeAll("  ");
                    try writer.writeAll("\x1b[33m");
                    try writer.writeAll("\xef\x84\x91");
                    try writer.writeAll("  ");
                    try writer.writeAll("\x1b[31m");
                    try writer.writeAll("\xef\x84\x91");
                    try writer.writeAll("  ");
                    try writer.writeAll("\x1b[35m");
                    try writer.writeAll("\xef\x84\x91");
                }
                try writer.writeAll("\n");
            },
            else => {},
        }
    }

    try std.fs.File.stdout().writeAll(fbs.getWritten());
}
