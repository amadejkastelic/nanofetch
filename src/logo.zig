const std = @import("std");
const logos = @import("logos.zig");

pub const LogoSegment = logos.LogoSegment;
pub const NixOSLogo = logos.NixOSLogo;

pub fn getLogo(use_color: bool, os_name: ?[]const u8) NixOSLogo {
    return logos.getLogo(use_color, os_name);
}
