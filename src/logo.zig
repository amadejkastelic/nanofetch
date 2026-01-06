const std = @import("std");

const LogoSegment = struct {
    text: []const u8,
    color: usize,
};

pub const NixOSLogo = struct {
    lines: [9][]const LogoSegment,

    color_map: [6][]const u8 = .{
        "\x1b[34m", // blue (index 0)
        "\x1b[36m", // cyan (index 1)
        "\x1b[35m", // magenta (index 2)
        "\x1b[31m", // red (index 3)
        "\x1b[32m", // green (index 4)
        "\x1b[0m", // reset (index 5)
    },
};

// Static logo segments
const logo_segments = [9][3]LogoSegment{
    // Line 0
    .{
        .{ .text = "     ▟█▖    ", .color = 0 },
        .{ .text = "▝█▙ ▗█▛         ", .color = 1 },
        .{ .text = "", .color = 5 }, // empty
    },
    // Line 1
    .{
        .{ .text = "  ▗▄▄▟██▄▄▄▄▄", .color = 0 },
        .{ .text = "▝█▙█▛  ", .color = 1 },
        .{ .text = "▖       ", .color = 0 },
    },
    // Line 2
    .{
        .{ .text = "  ▀▀▀▀▀▀▀▀▀▀▀▘", .color = 0 },
        .{ .text = "▝██  ", .color = 1 },
        .{ .text = "▟█▖      ", .color = 0 },
    },
    // Line 3
    .{
        .{ .text = "     ▟█▛       ", .color = 1 },
        .{ .text = "▝█▘", .color = 1 },
        .{ .text = "▟█▛       ", .color = 0 },
    },
    // Line 4
    .{
        .{ .text = "▟█████▛          ", .color = 1 },
        .{ .text = "▟█████▛    ", .color = 0 },
        .{ .text = "", .color = 5 },
    },
    // Line 5
    .{
        .{ .text = "   ▟█▛", .color = 1 },
        .{ .text = "▗█▖       ", .color = 0 },
        .{ .text = "▟█▛         ", .color = 0 },
    },
    // Line 6
    .{
        .{ .text = "  ▝█▛  ", .color = 1 },
        .{ .text = "██▖", .color = 0 },
        .{ .text = "▗▄▄▄▄▄▄▄▄▄▄▄      ", .color = 1 },
    },
    // Line 7
    .{
        .{ .text = "   ▝  ", .color = 1 },
        .{ .text = "▟█▜█▖", .color = 0 },
        .{ .text = "▀▀▀▀▀██▛▀▀▘      ", .color = 1 },
    },
    // Line 8
    .{
        .{ .text = "     ▟█▘ ▜█▖    ", .color = 0 },
        .{ .text = "▝█▛         ", .color = 1 },
        .{ .text = "", .color = 5 },
    },
};

pub fn getLogo(use_color: bool) NixOSLogo {
    _ = use_color;

    var logo: NixOSLogo = undefined;

    logo.color_map[0] = "\x1b[34m"; // blue
    logo.color_map[1] = "\x1b[36m"; // cyan
    logo.color_map[2] = "\x1b[35m"; // magenta
    logo.color_map[3] = "\x1b[31m"; // red
    logo.color_map[4] = "\x1b[32m"; // green
    logo.color_map[5] = "\x1b[0m"; // reset

    for (0..9) |i| {
        logo.lines[i] = &logo_segments[i];
    }

    return logo;
}
