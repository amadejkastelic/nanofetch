const std = @import("std");
const os = std.os.linux;
const fs = std.fs;

pub const SystemInfo = extern struct {
    uptime: u64,
    loads: [3]u64,
    totalram: u64,
    freeram: u64,
    sharedram: u64,
    bufferram: u64,
    totalswap: u64,
    freeswap: u64,
    procs: u16,
    totalhigh: u64,
    freehigh: u64,
    mem_unit: u32,
    _f: [20 - 2 * @sizeOf(u64) - @sizeOf(u32)]u8,
};

pub const StatFs = extern struct {
    f_type: u64,
    f_bsize: u64,
    f_blocks: u64,
    f_bfree: u64,
    f_bavail: u64,
    f_files: u64,
    f_ffree: u64,
    f_fsid: [2]i32,
    f_namelen: u64,
    f_frsize: u64,
    f_flags: u64,
    f_spare: [4]u64,
};

pub const UtsName = extern struct {
    sysname: [65]u8,
    nodename: [65]u8,
    release: [65]u8,
    version: [65]u8,
    machine: [65]u8,
    domainname: [65]u8,
};

pub fn syscall_uname() !UtsName {
    var uname_buf: UtsName = undefined;
    const rc = os.syscall3(.uname, @intFromPtr(&uname_buf), 0, 0);
    if (rc != 0) return error.SyscallFailed;
    return uname_buf;
}

pub fn syscall_sysinfo() !SystemInfo {
    var info: SystemInfo = undefined;
    const rc = os.syscall1(.sysinfo, @intFromPtr(&info));
    if (rc != 0) return error.SyscallFailed;
    return info;
}

pub fn syscall_statfs(path: []const u8) !StatFs {
    var stat: StatFs = undefined;
    const rc = os.syscall3(.statfs, @intFromPtr(path.ptr), @intFromPtr(&stat), 0);
    if (rc != 0) return error.SyscallFailed;
    return stat;
}

pub fn readEntireFile(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const file = try std.fs.openFileAbsolute(path, .{});
    defer file.close();

    const size = try file.getEndPos();
    const buffer = try allocator.alloc(u8, size);
    errdefer allocator.free(buffer);

    const bytes_read = try file.readAll(buffer);

    return buffer[0..bytes_read];
}

pub fn parseUint(comptime T: type, str: []const u8) !T {
    var result: T = 0;
    var started = false;
    for (str) |c| {
        if (c >= '0' and c <= '9') {
            result = result * 10 + @as(T, @intCast(c - '0'));
            started = true;
        } else if (c == ' ' or c == '\t' or c == '\n' or c == '\r') {
            if (started) break;
        } else {
            return error.InvalidDigit;
        }
    }
    return result;
}

test "parseUint basic" {
    const result = try parseUint(u64, "12345");
    try std.testing.expectEqual(@as(u64, 12345), result);
}

test "parseUint with trailing space" {
    const result = try parseUint(u64, "12345 ");
    try std.testing.expectEqual(@as(u64, 12345), result);
}
