const std = @import("std");

pub var use_color: bool = true;

pub fn initColors() void {
    if (std.posix.getenv("NO_COLOR")) |_| {
        use_color = false;
    } else {
        use_color = true;
    }
}

pub const Color = enum {
    black,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
    bright_black,
    bright_red,
    bright_green,
    bright_yellow,
    bright_blue,
    bright_magenta,
    bright_cyan,
    bright_white,
    reset,
};

pub fn colorCode(color: Color) []const u8 {
    return switch (color) {
        .black => "\x1b[30m",
        .red => "\x1b[31m",
        .green => "\x1b[32m",
        .yellow => "\x1b[33m",
        .blue => "\x1b[34m",
        .magenta => "\x1b[35m",
        .cyan => "\x1b[36m",
        .white => "\x1b[37m",
        .bright_black => "\x1b[90m",
        .bright_red => "\x1b[91m",
        .bright_green => "\x1b[92m",
        .bright_yellow => "\x1b[93m",
        .bright_blue => "\x1b[94m",
        .bright_magenta => "\x1b[95m",
        .bright_cyan => "\x1b[96m",
        .bright_white => "\x1b[97m",
        .reset => "\x1b[0m",
    };
}

pub fn wrap(text: []const u8, color: Color) []const u8 {
    if (!use_color) return text;

    const code = colorCode(color);
    const reset = colorCode(.reset);

    var buffer: [512]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buffer);
    const writer = fbs.writer();

    writer.writeAll(code) catch return text;
    writer.writeAll(text) catch return text;
    writer.writeAll(reset) catch return text;

    return fbs.getWritten();
}
