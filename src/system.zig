const std = @import("std");
const syscall = @import("syscall.zig");

pub const KernelInfo = syscall.KernelInfo;
pub const MemoryInfo = syscall.MemoryInfo;
pub const DiskInfo = syscall.DiskInfo;

pub fn getKernelArch(kernel_info: *const KernelInfo) []const u8 {
    return std.mem.sliceTo(&kernel_info.machine, 0);
}

pub fn getKernelInfo() !KernelInfo {
    return syscall.getKernelInfo();
}

pub fn getUptime() !u64 {
    return syscall.getUptime();
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

pub fn getMemoryInfo(allocator: std.mem.Allocator, io: std.Io) !MemoryInfo {
    return syscall.getMemoryInfo(allocator, io);
}

pub fn formatMemory(mem: MemoryInfo) [32]u8 {
    var result: [32]u8 = undefined;

    const total_gb = @as(f64, @floatFromInt(mem.total)) / 1024.0 / 1024.0;
    const used_gb = @as(f64, @floatFromInt(mem.used)) / 1024.0 / 1024.0;

    _ = std.fmt.bufPrint(&result, "{d:.2} GiB / {d:.2} GiB", .{ used_gb, total_gb }) catch unreachable;

    return result;
}

pub fn getDiskInfo() !DiskInfo {
    return syscall.getDiskInfo();
}

pub fn formatDisk(disk: DiskInfo) [32]u8 {
    var result: [32]u8 = undefined;

    const total_gb = @as(f64, @floatFromInt(disk.total)) / (1024 * 1024 * 1024);
    const used_gb = @as(f64, @floatFromInt(disk.used)) / (1024 * 1024 * 1024);

    _ = std.fmt.bufPrint(&result, "{d:.2} GiB / {d:.2} GiB", .{ used_gb, total_gb }) catch unreachable;

    return result;
}
