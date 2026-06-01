const std = @import("std");
const builtin = @import("builtin");
const os_tag = builtin.os.tag;

pub const KernelInfo = struct {
    name: [65:0]u8,
    nodename: [65:0]u8,
    release: [65:0]u8,
    version: [65:0]u8,
    machine: [65:0]u8,
};

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

pub fn readEntireFile(allocator: std.mem.Allocator, io: std.Io, path: []const u8) ![]u8 {
    var buf: [65536]u8 = undefined;
    const content = try std.Io.Dir.cwd().readFile(io, path, buf[0..]);
    return allocator.dupe(u8, content);
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

pub fn getKernelInfo() !KernelInfo {
    var info: KernelInfo = std.mem.zeroes(KernelInfo);

    if (comptime os_tag == .linux) {
        const os = std.os.linux;
        var buf: extern struct {
            sysname: [65]u8,
            nodename: [65]u8,
            release: [65]u8,
            version: [65]u8,
            machine: [65]u8,
            domainname: [65]u8,
        } = undefined;
        const rc = os.syscall3(.uname, @intFromPtr(&buf), 0, 0);
        if (rc != 0) return error.SyscallFailed;
        @memcpy(info.name[0..65], buf.sysname[0..65]);
        @memcpy(info.nodename[0..65], buf.nodename[0..65]);
        @memcpy(info.release[0..65], buf.release[0..65]);
        @memcpy(info.version[0..65], buf.version[0..65]);
        @memcpy(info.machine[0..65], buf.machine[0..65]);
    } else {
        var buf: extern struct {
            sysname: [256]u8,
            nodename: [256]u8,
            release: [256]u8,
            version: [256]u8,
            machine: [256]u8,
        } = undefined;
        if (c_uname(@ptrCast(&buf)) != 0) return error.SyscallFailed;
        @memcpy(info.name[0..65], buf.sysname[0..65]);
        @memcpy(info.nodename[0..65], buf.nodename[0..65]);
        @memcpy(info.release[0..65], buf.release[0..65]);
        @memcpy(info.version[0..65], buf.version[0..65]);
        @memcpy(info.machine[0..65], buf.machine[0..65]);
    }

    return info;
}

pub fn getUptime() !u64 {
    if (comptime os_tag == .linux) {
        const os = std.os.linux;
        var info: extern struct {
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
        } = undefined;
        const rc = os.syscall1(.sysinfo, @intFromPtr(&info));
        if (rc != 0) return error.SyscallFailed;
        return info.uptime;
    } else {
        const Timeval = extern struct {
            tv_sec: c_long,
            tv_usec: i32,
        };

        const mib = [2]c_int{ 1, 21 };
        var boot_time: Timeval = undefined;
        var boot_size: usize = @sizeOf(Timeval);
        if (c_sysctl(&mib, 2, @ptrCast(&boot_time), &boot_size, null, 0) != 0)
            return error.SyscallFailed;

        var now: Timeval = undefined;
        _ = c_gettimeofday(@ptrCast(&now), null);

        const uptime_sec = @as(u64, @intCast(now.tv_sec - boot_time.tv_sec));
        return uptime_sec;
    }
}

pub fn getMemoryInfo(allocator: std.mem.Allocator, io: std.Io) !MemoryInfo {
    if (comptime os_tag == .linux) {
        return linuxGetMemoryInfo(allocator, io);
    } else {
        return macosGetMemoryInfo();
    }
}

pub fn getDiskInfo() !DiskInfo {
    if (comptime os_tag == .linux) {
        return linuxGetDiskInfo();
    } else {
        return macosGetDiskInfo();
    }
}

fn linuxGetMemoryInfo(allocator: std.mem.Allocator, io: std.Io) !MemoryInfo {
    _ = allocator;
    var buf: [65536]u8 = undefined;
    const meminfo_content = try std.Io.Dir.cwd().readFile(io, "/proc/meminfo", buf[0..]);

    var memtotal: u64 = 0;
    var memavailable: u64 = 0;

    var lines = std.mem.splitScalar(u8, meminfo_content, '\n');

    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "MemTotal:")) {
            const value_str = line[9..];
            memtotal = try parseUint(u64, value_str);
        } else if (std.mem.startsWith(u8, line, "MemAvailable:")) {
            const value_str = line[13..];
            memavailable = try parseUint(u64, value_str);
        }
    }

    const used = memtotal - memavailable;
    const percentage: u8 = @trunc(@as(f64, @floatFromInt(used)) / @as(f64, @floatFromInt(memtotal)) * 100.0);

    return MemoryInfo{
        .total = memtotal,
        .used = used,
        .available = memavailable,
        .percentage = percentage,
    };
}

const vm_statistics64 = extern struct {
    free_count: u32,
    active_count: u32,
    inactive_count: u32,
    wire_count: u32,
    zero_fill_count: u64,
    reactivations: u64,
    pageins: u64,
    pageouts: u64,
    faults: u64,
    cow_faults: u64,
    lookups: u64,
    hits: u64,
    purges: u64,
    purgeable_count: u32,
    speculative_count: u32,
    decompressions: u64,
    compressions: u64,
    swapins: u64,
    swapouts: u64,
    compressor_page_count: u32,
    throttled_count: u32,
    external_page_count: u32,
    internal_page_count: u32,
    total_uncompressed_pages_in_compressor: u64,
};

extern "c" fn mach_host_self() std.c.mach_port_t;
extern "c" fn host_statistics64(host: std.c.mach_port_t, flavor: c_int, host_info: *anyopaque, host_info_count: *c_int) c_int;

const HOST_VM_INFO64_COUNT: c_int = @divExact(@sizeOf(vm_statistics64), @sizeOf(c_int));
const HOST_VM_INFO64: c_int = 4;

fn macosGetMemoryInfo() !MemoryInfo {
    var total: u64 = undefined;
    var total_size: usize = @sizeOf(u64);
    if (c_sysctlbyname("hw.memsize", @ptrCast(&total), &total_size, null, 0) != 0)
        return error.SyscallFailed;

    var page_size: u32 = undefined;
    var ps_size: usize = @sizeOf(u32);
    if (c_sysctlbyname("hw.pagesize", @ptrCast(&page_size), &ps_size, null, 0) != 0)
        return error.SyscallFailed;

    var vm_stats: vm_statistics64 = undefined;
    var count: c_int = HOST_VM_INFO64_COUNT;
    if (host_statistics64(mach_host_self(), HOST_VM_INFO64, @ptrCast(&vm_stats), &count) != 0)
        return error.SyscallFailed;

    const ps = @as(u64, page_size);
    const used = (@as(u64, vm_stats.active_count) + @as(u64, vm_stats.wire_count)) * ps;
    const available = (@as(u64, vm_stats.free_count) + @as(u64, vm_stats.inactive_count)) * ps;
    const percentage: u8 = @trunc(@as(f64, @floatFromInt(used)) / @as(f64, @floatFromInt(total)) * 100.0);

    return MemoryInfo{
        .total = total / 1024,
        .used = used / 1024,
        .available = available / 1024,
        .percentage = percentage,
    };
}

fn linuxGetDiskInfo() !DiskInfo {
    const os = std.os.linux;
    var stat: extern struct {
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
    } = undefined;
    const rc = os.syscall3(.statfs, @intFromPtr("/"), @intFromPtr(&stat), 0);
    if (rc != 0) return error.SyscallFailed;

    const total_blocks = stat.f_blocks;
    const avail_blocks = stat.f_bavail;
    const used_blocks = total_blocks - avail_blocks;
    const percentage: u8 = @trunc(@as(f64, @floatFromInt(used_blocks)) / @as(f64, @floatFromInt(total_blocks)) * 100.0);

    return DiskInfo{
        .total = total_blocks * stat.f_bsize,
        .used = used_blocks * stat.f_bsize,
        .percentage = percentage,
    };
}

fn macosGetDiskInfo() !DiskInfo {
    var stat: extern struct {
        f_bsize: u32,
        f_iosize: i32,
        f_blocks: u64,
        f_bfree: u64,
        f_bavail: u64,
        f_files: u64,
        f_ffree: u64,
        f_fsid: [2]i32,
        f_owner: u32,
        f_type: u32,
        f_flags: u32,
        f_fssubtype: u32,
        f_fstypename: [16]u8,
        f_mntonname: [1024]u8,
        f_mntfromname: [1024]u8,
        f_reserved: [8]u32,
    } = undefined;
    if (c_statfs("/", @ptrCast(&stat)) != 0) return error.SyscallFailed;

    const total_blocks = stat.f_blocks;
    const avail_blocks = stat.f_bavail;
    const used_blocks = total_blocks - avail_blocks;
    const percentage: u8 = @trunc(@as(f64, @floatFromInt(used_blocks)) / @as(f64, @floatFromInt(total_blocks)) * 100.0);

    return DiskInfo{
        .total = total_blocks * @as(u64, stat.f_bsize),
        .used = used_blocks * @as(u64, stat.f_bsize),
        .percentage = percentage,
    };
}

extern "c" fn uname(buf: *anyopaque) c_int;
pub const c_uname = uname;

extern "c" fn sysctl(name: [*]const c_int, namelen: u32, oldp: ?*anyopaque, oldlenp: ?*usize, newp: ?*const anyopaque, newlen: usize) c_int;
pub const c_sysctl = sysctl;

extern "c" fn sysctlbyname(name: [*:0]const u8, oldp: ?*anyopaque, oldlenp: ?*usize, newp: ?*const anyopaque, newlen: usize) c_int;
pub const c_sysctlbyname = sysctlbyname;

extern "c" fn gettimeofday(tv: *anyopaque, tz: ?*anyopaque) c_int;
pub const c_gettimeofday = gettimeofday;

extern "c" fn statfs(path: [*:0]const u8, buf: *anyopaque) c_int;
pub const c_statfs = statfs;

extern "c" fn ioctl(fd: c_int, request: c_ulong, ...) c_int;
pub const c_ioctl = ioctl;

test "parseUint basic" {
    const result = try parseUint(u64, "12345");
    try std.testing.expectEqual(@as(u64, 12345), result);
}

test "parseUint with trailing space" {
    const result = try parseUint(u64, "12345 ");
    try std.testing.expectEqual(@as(u64, 12345), result);
}
