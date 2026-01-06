const std = @import("std");
const colors = @import("colors.zig");

pub const LogoSegment = struct {
    text: []const u8,
    color: usize,
};

const Logo = struct {
    name: []const u8,
    segments: [9][3]LogoSegment,
    color_map: []const []const u8,
    aliases: []const []const u8,
};

pub const logos = [_]Logo{
    .{
        .name = "NixOS",
        .segments = [_][3]LogoSegment{
            .{
                .{ .text = "     ▟█▖    ", .color = 0 },
                .{ .text = "▝█▙ ▗█▛         ", .color = 1 },
                .{ .text = "", .color = 0 },
            },
            .{
                .{ .text = "  ▗▄▄▟██▄▄▄▄▄", .color = 0 },
                .{ .text = "▝█▙█▛  ", .color = 1 },
                .{ .text = "▖       ", .color = 0 },
            },
            .{
                .{ .text = "  ▀▀▀▀▀▀▀▀▀▀▀▘", .color = 0 },
                .{ .text = "▝██  ", .color = 1 },
                .{ .text = "▟█▖      ", .color = 0 },
            },
            .{
                .{ .text = "     ▟█▛       ", .color = 1 },
                .{ .text = "▝█▘", .color = 1 },
                .{ .text = "▟█▛       ", .color = 0 },
            },
            .{
                .{ .text = "▟█████▛          ", .color = 1 },
                .{ .text = "▟█████▛    ", .color = 0 },
                .{ .text = "", .color = 0 },
            },
            .{
                .{ .text = "   ▟█▛", .color = 1 },
                .{ .text = "▗█▖       ", .color = 0 },
                .{ .text = "▟█▛         ", .color = 0 },
            },
            .{
                .{ .text = "  ▝█▛  ", .color = 1 },
                .{ .text = "██▖", .color = 0 },
                .{ .text = "▗▄▄▄▄▄▄▄▄▄▄       ", .color = 1 },
            },
            .{
                .{ .text = "   ▝  ", .color = 1 },
                .{ .text = "▟█▜█▖", .color = 0 },
                .{ .text = "▀▀▀▀▀██▛▀▀▘      ", .color = 1 },
            },
            .{
                .{ .text = "     ▟█▘ ▜█▖    ", .color = 0 },
                .{ .text = "▝█▛         ", .color = 1 },
                .{ .text = "", .color = 0 },
            },
        },
        .color_map = &[_][]const u8{
            "\x1b[34m", // blue
            "\x1b[36m", // cyan
        },
        .aliases = &[_][]const u8{"nixos"},
    },
    .{
        .name = "Arch",
        .segments = [_][3]LogoSegment{
            .{
                .{ .text = "       /\\       ", .color = 0 },
                .{ .text = "", .color = 0 },
                .{ .text = "", .color = 0 },
            },
            .{
                .{ .text = "      /  \\      ", .color = 0 },
                .{ .text = "", .color = 0 },
                .{ .text = "", .color = 0 },
            },
            .{
                .{ .text = "     /    \\     ", .color = 0 },
                .{ .text = "", .color = 0 },
                .{ .text = "", .color = 0 },
            },
            .{
                .{ .text = "    /      \\    ", .color = 0 },
                .{ .text = "", .color = 0 },
                .{ .text = "", .color = 0 },
            },
            .{
                .{ .text = "   /   ,,   \\   ", .color = 0 },
                .{ .text = "", .color = 0 },
                .{ .text = "", .color = 0 },
            },
            .{
                .{ .text = "  /   |  |   \\  ", .color = 0 },
                .{ .text = "", .color = 0 },
                .{ .text = "", .color = 0 },
            },
            .{
                .{ .text = " /_-''    ''-_\\ ", .color = 0 },
                .{ .text = "", .color = 0 },
                .{ .text = "", .color = 0 },
            },
            .{
                .{ .text = "                ", .color = 0 },
                .{ .text = "", .color = 0 },
                .{ .text = "", .color = 0 },
            },
            .{
                .{ .text = "                ", .color = 0 },
                .{ .text = "", .color = 0 },
                .{ .text = "", .color = 0 },
            },
        },
        .color_map = &[_][]const u8{
            "\x1b[34m", // blue
        },
        .aliases = &[_][]const u8{ "arch", "archlinux" },
    },
    .{
        .name = "Ubuntu",
        .segments = [_][3]LogoSegment{
            .{
                .{ .text = "         .        ", .color = 0 },
                .{ .text = "", .color = 0 },
                .{ .text = "", .color = 0 },
            },
            .{
                .{ .text = "        / \\       ", .color = 0 },
                .{ .text = "", .color = 0 },
                .{ .text = "", .color = 0 },
            },
            .{
                .{ .text = "       /   \\      ", .color = 0 },
                .{ .text = "", .color = 0 },
                .{ .text = "", .color = 0 },
            },
            .{
                .{ .text = "      /_____\\     ", .color = 0 },
                .{ .text = "", .color = 0 },
                .{ .text = "", .color = 0 },
            },
            .{
                .{ .text = "      |     |     ", .color = 0 },
                .{ .text = "", .color = 0 },
                .{ .text = "", .color = 0 },
            },
            .{
                .{ .text = "      |     |     ", .color = 0 },
                .{ .text = "", .color = 0 },
                .{ .text = "", .color = 0 },
            },
            .{
                .{ .text = "      |     |     ", .color = 0 },
                .{ .text = "", .color = 0 },
                .{ .text = "", .color = 0 },
            },
            .{
                .{ .text = "      |     |     ", .color = 0 },
                .{ .text = "", .color = 0 },
                .{ .text = "", .color = 0 },
            },
            .{
                .{ .text = "      |     |     ", .color = 0 },
                .{ .text = "", .color = 0 },
                .{ .text = "", .color = 0 },
            },
        },
        .color_map = &[_][]const u8{
            "\x1b[31m", // orange/red
        },
        .aliases = &[_][]const u8{ "ubuntu", "debian" },
    },
};

pub const NixOSLogo = struct {
    lines: [9][]const LogoSegment,
    color_map: []const []const u8,
    reset_code: []const u8 = "\x1b[0m",
};

pub fn getLogo(use_color: bool, os_name: ?[]const u8) NixOSLogo {
    const selected_logo = findLogo(os_name);

    var logo: NixOSLogo = undefined;

    if (use_color) {
        logo.color_map = selected_logo.color_map;
    } else {
        logo.color_map = &[_][]const u8{""};
    }

    for (0..9) |i| {
        logo.lines[i] = &selected_logo.segments[i];
    }

    return logo;
}

fn findLogo(os_name: ?[]const u8) *const Logo {
    if (os_name) |name| {
        var buf: [256]u8 = undefined;
        var i: usize = 0;

        for (name) |c| {
            if (c >= 'A' and c <= 'Z') {
                buf[i] = c + 32;
            } else {
                buf[i] = c;
            }
            i += 1;
        }

        const lower_name = buf[0..i];

        for (&logos) |*logo| {
            for (logo.aliases) |alias| {
                if (std.mem.eql(u8, alias, lower_name)) {
                    return logo;
                }
            }
        }
    }

    return &logos[0]; // Default to NixOS
}
