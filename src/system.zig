const std = @import("std");
const syscall = @import("syscall.zig");

pub const KernelInfo = struct {
    name: [65:0]u8,
    nodename: [65:0]u8,
    release: [65:0]u8,
    version: [65:0]u8,
    machine: [65:0]u8,
};

pub fn getKernelArch(kernel_info: *const KernelInfo) []const u8 {
    return std.mem.sliceTo(&kernel_info.machine, 0);
}

pub const MemoryInfo = struct {
    total: u64,
    used: u64,
    available: u64,
    percentage: u8,
};

pub const DiskInfo = struct {
    total: u64,
    used: u64,
    percentage: u8,
};

pub fn getKernelInfo() !KernelInfo {
    const uname = try syscall.syscall_uname();

    var kernel_info: KernelInfo = undefined;

    @memcpy(kernel_info.name[0..uname.sysname.len], uname.sysname[0..]);
    @memcpy(kernel_info.nodename[0..uname.nodename.len], uname.nodename[0..]);
    @memcpy(kernel_info.release[0..uname.release.len], uname.release[0..]);
    @memcpy(kernel_info.version[0..uname.version.len], uname.version[0..]);
    @memcpy(kernel_info.machine[0..uname.machine.len], uname.machine[0..]);

    return kernel_info;
}

pub fn getUptime() !u64 {
    const info = try syscall.syscall_sysinfo();
    return info.uptime;
}

pub fn formatUptime(seconds: u64) [32]u8 {
    var result: [32]u8 = undefined;

    const days = seconds / 86400;
    const hours = (seconds / 3600) % 24;
    const mins = (seconds / 60) % 60;

    var written: usize = 0;
    var has_prev: bool = false;

    if (days > 0) {
        const suffix = if (days == 1) " day" else " days";
        const buf = std.fmt.bufPrint(result[written..], "{}{s}", .{ days, suffix }) catch unreachable;
        written += buf.len;
        has_prev = true;
    }

    if (hours > 0) {
        if (has_prev) {
            const buf = std.fmt.bufPrint(result[written..], ", ", .{}) catch unreachable;
            written += buf.len;
        }
        const suffix = if (hours == 1) " hour" else " hours";
        const buf = std.fmt.bufPrint(result[written..], "{}{s}", .{ hours, suffix }) catch unreachable;
        written += buf.len;
        has_prev = true;
    }

    if (mins > 0) {
        if (has_prev) {
            const buf = std.fmt.bufPrint(result[written..], ", ", .{}) catch unreachable;
            written += buf.len;
        }
        const suffix = if (mins == 1) " minute" else " minutes";
        const buf = std.fmt.bufPrint(result[written..], "{}{s}", .{ mins, suffix }) catch unreachable;
        written += buf.len;
        has_prev = true;
    }

    if (!has_prev) {
        _ = std.fmt.bufPrint(&result, "less than a minute", .{}) catch unreachable;
    }

    return result;
}

pub fn getMemoryInfo(allocator: std.mem.Allocator) !MemoryInfo {
    const meminfo_content = try std.fs.cwd().readFileAlloc(allocator, "/proc/meminfo", 65536);
    defer allocator.free(meminfo_content);

    var memtotal: u64 = 0;
    var memavailable: u64 = 0;

    var lines = std.mem.splitScalar(u8, meminfo_content, '\n');

    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "MemTotal:")) {
            const value_str = line[9..];
            memtotal = try syscall.parseUint(u64, value_str);
        } else if (std.mem.startsWith(u8, line, "MemAvailable:")) {
            const value_str = line[13..];
            memavailable = try syscall.parseUint(u64, value_str);
        }
    }

    const used = memtotal - memavailable;
    const percentage: u8 = @intFromFloat(@as(f64, @floatFromInt(used)) / @as(f64, @floatFromInt(memtotal)) * 100.0);

    return MemoryInfo{
        .total = memtotal,
        .used = used,
        .available = memavailable,
        .percentage = percentage,
    };
}

pub fn formatMemory(mem: MemoryInfo) [32]u8 {
    var result: [32]u8 = undefined;

    const total_gb = @as(f64, @floatFromInt(mem.total)) / 1024.0 / 1024.0;
    const used_gb = @as(f64, @floatFromInt(mem.used)) / 1024.0 / 1024.0;

    _ = std.fmt.bufPrint(&result, "{d:.2} GiB / {d:.2} GiB", .{ used_gb, total_gb }) catch unreachable;

    return result;
}

pub fn getDiskInfo(allocator: std.mem.Allocator) !DiskInfo {
    _ = allocator;

    const stat = try syscall.syscall_statfs("/");

    const total_blocks = stat.f_blocks;
    const avail_blocks = stat.f_bavail;
    const used_blocks = total_blocks - avail_blocks;

    const percentage: u8 = @intFromFloat(@as(f64, @floatFromInt(used_blocks)) / @as(f64, @floatFromInt(total_blocks)) * 100.0);

    return DiskInfo{
        .total = total_blocks * stat.f_bsize,
        .used = used_blocks * stat.f_bsize,
        .percentage = percentage,
    };
}

pub fn formatDisk(disk: DiskInfo) [32]u8 {
    var result: [32]u8 = undefined;

    const total_gb = @as(f64, @floatFromInt(disk.total)) / (1024 * 1024 * 1024);
    const used_gb = @as(f64, @floatFromInt(disk.used)) / (1024 * 1024 * 1024);

    _ = std.fmt.bufPrint(&result, "{d:.2} GiB / {d:.2} GiB", .{ used_gb, total_gb }) catch unreachable;

    return result;
}
