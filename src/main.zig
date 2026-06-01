const std = @import("std");
const builtin = @import("builtin");
const os_tag = builtin.os.tag;
const colors = @import("colors.zig");
const system = @import("system.zig");
const shell = @import("shell.zig");
const desktop = @import("desktop.zig");
const osinfo = @import("osinfo.zig");
const logo = @import("logo.zig");
const config = @import("config.zig");
const syscall = @import("syscall.zig");

const winsize = extern struct {
    ws_row: u16,
    ws_col: u16,
    ws_xpixel: u16,
    ws_ypixel: u16,
};

const TIOCGWINSZ: c_ulong = if (os_tag == .linux) 0x5413 else 0x40087468;

fn getTerminalWidth(environ_map: *std.process.Environ.Map) ?usize {
    const fd = std.posix.STDOUT_FILENO;
    var ws: winsize = undefined;

    if (comptime os_tag == .linux) {
        const rc = std.os.linux.ioctl(fd, TIOCGWINSZ, @intFromPtr(&ws));
        if (rc != -1) return ws.ws_col;
    } else {
        const rc = syscall.c_ioctl(fd, TIOCGWINSZ, @ptrCast(&ws));
        if (rc != -1) return ws.ws_col;
    }

    if (environ_map.get("COLUMNS")) |cols_str| {
        return std.fmt.parseInt(usize, cols_str, 10) catch null;
    }

    return null;
}

const icons = [_][]const u8{
    "",
    "\xef\x8c\x93",
    "\xee\x9c\x92",
    "\xee\x9e\x95",
    "\xef\x80\x97",
    "\xef\x8b\x92",
    "\xef\x92\xbc",
    "\xf3\xb1\xa5\x8e",
    "\xee\x88\xab",
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const env_map = init.environ_map;

    colors.initColors(env_map);

    const kernel_info = try system.getKernelInfo();
    const os_name = try osinfo.getOsName(allocator, io);
    defer allocator.free(os_name);

    const term_width = getTerminalWidth(env_map);
    const term_wide_enough = if (term_width) |w| w >= config.min_width_for_logo else false;
    const show_logo = config.show_logo and term_wide_enough;

    const selected_logo: ?[]const u8 = if (std.mem.eql(u8, config.logo, "auto"))
        os_name
    else
        config.logo;

    const logo_data = if (show_logo) logo.getLogo(colors.use_color, selected_logo) else null;

    const uptime_seconds = try system.getUptime();
    const uptime_str = system.formatUptime(uptime_seconds);
    const mem_info = try system.getMemoryInfo(allocator, io);
    const mem_str_arr = system.formatMemory(mem_info);
    const mem_str = mem_str_arr[0..];
    const disk_info = try system.getDiskInfo();
    const disk_str_arr = system.formatDisk(disk_info);
    const disk_str = disk_str_arr[0..];
    const shell_name = shell.getShell(env_map);
    const desktop_name = desktop.getDesktop(env_map);

    const username = env_map.get("USER") orelse "unknown";
    const nodename = std.mem.sliceTo(&kernel_info.nodename, 0);

    var stdout_buf: [16384]u8 = undefined;
    var file_writer = std.Io.File.stdout().writer(io, &stdout_buf);
    var w = &file_writer.interface;

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
                    try w.writeAll(logo_data.?.color_map[segment.color]);
                }
                try w.writeAll(segment.text);
            }
        }

        if (i == 0) {
            if (colors.use_color) {
                try w.writeAll(colors.colorCode(.blue));
            }
            try w.writeAll(username);
            try w.writeAll("@");
            if (colors.use_color) {
                try w.writeAll(colors.colorCode(.red));
            }
            try w.writeAll(nodename);
            try w.writeAll(" ~");
            try w.writeAll("\n");
            continue;
        } else if (i < labels.len) {
            if (colors.use_color) try w.writeAll(colors.colorCode(.cyan));
            try w.writeAll(icons[i]);
            try w.writeAll("  ");
            if (colors.use_color) try w.writeAll(colors.colorCode(.blue));
            try w.writeAll(labels[i]);
            if (colors.use_color) try w.writeAll(colors.colorCode(.reset));
            const padding = @max(0, 13 - labels[i].len);
            for (0..padding) |_| try w.writeAll(" ");
            try w.writeAll("\xee\x98\xa1");
            try w.writeAll(" ");
        }

        switch (i) {
            1 => {
                try w.writeAll(os_name);
                try w.writeAll("\n");
            },
            2 => {
                const kernel_ver = kernel_info.release[0 .. std.mem.findScalar(u8, &kernel_info.release, 0) orelse kernel_info.release.len];
                const arch = system.getKernelArch(&kernel_info);
                try w.writeAll(kernel_ver);
                try w.writeAll(" (");
                try w.writeAll(arch);
                try w.writeAll(")");
                try w.writeAll("\n");
            },
            3 => {
                try w.writeAll(shell_name);
                try w.writeAll("\n");
            },
            4 => {
                const uptime_end = std.mem.findScalar(u8, &uptime_str, 0) orelse uptime_str.len;
                try w.writeAll(uptime_str[0..uptime_end]);
                try w.writeAll("\n");
            },
            5 => {
                try w.writeAll(desktop_name);
                if (env_map.get("WAYLAND_DISPLAY")) |_| {
                    try w.writeAll(" (Wayland)");
                } else if (env_map.get("DISPLAY")) |_| {
                    try w.writeAll(" (X11)");
                }
                try w.writeAll("\n");
            },
            6 => {
                const mem_end = std.mem.findScalar(u8, mem_str, 0) orelse mem_str.len;
                try w.writeAll(mem_str[0..mem_end]);
                if (colors.use_color) {
                    try w.writeAll(" (");
                    try w.writeAll(colors.colorCode(.cyan));
                    var mem_pct_buf: [4]u8 = undefined;
                    try w.writeAll(std.fmt.bufPrint(&mem_pct_buf, "{}%", .{mem_info.percentage}) catch unreachable);
                    try w.writeAll("\x1b[0m");
                    try w.writeAll(")");
                }
                try w.writeAll("\n");
            },
            7 => {
                const disk_end = std.mem.findScalar(u8, disk_str, 0) orelse disk_str.len;
                try w.writeAll(disk_str[0..disk_end]);
                if (colors.use_color) {
                    try w.writeAll(" (");
                    try w.writeAll(colors.colorCode(.cyan));
                    var disk_pct_buf: [4]u8 = undefined;
                    try w.writeAll(std.fmt.bufPrint(&disk_pct_buf, "{}%", .{disk_info.percentage}) catch unreachable);
                    try w.writeAll("\x1b[0m");
                    try w.writeAll(")");
                }
                try w.writeAll("\n");
            },
            8 => {
                if (colors.use_color) {
                    try w.writeAll("\x1b[34m");
                    try w.writeAll("\xef\x84\x91");
                    try w.writeAll("  ");
                    try w.writeAll("\x1b[36m");
                    try w.writeAll("\xef\x84\x91");
                    try w.writeAll("  ");
                    try w.writeAll("\x1b[32m");
                    try w.writeAll("\xef\x84\x91");
                    try w.writeAll("  ");
                    try w.writeAll("\x1b[33m");
                    try w.writeAll("\xef\x84\x91");
                    try w.writeAll("  ");
                    try w.writeAll("\x1b[31m");
                    try w.writeAll("\xef\x84\x91");
                    try w.writeAll("  ");
                    try w.writeAll("\x1b[35m");
                    try w.writeAll("\xef\x84\x91");
                }
                try w.writeAll("\n");
            },
            else => {},
        }
    }

    try file_writer.flush();
}
