# Nanofetch

Lightning-fast Linux system information fetch tool written in Zig. Minimal and blazing fast.

<img width="1202" height="340" alt="image" src="https://github.com/user-attachments/assets/d872ba6e-abd8-4151-8f77-f8f171c1b071" />

## Features

- ⚡ **Ultra-fast** - Executes in under 1ms
- 📦 **Tiny binary** - Compiled size ~43KB
- 🖥️ **System info** - Kernel, shell, uptime, desktop environment
- 💾 **Resource monitoring** - Memory and disk usage with percentages
- 🎨 **Color palette** - Displays terminal color support
- 🔧 **Zero dependencies** - Pure Zig implementation
- 🐧 **Multi-distro** - Logos for NixOS, Arch, Ubuntu, auto-detection

## Installation

### Using Zig

```bash
git clone https://github.com/yourusername/nanofetch.git
cd nanofetch
zig build -Doptimize=ReleaseSmall
sudo cp zig-out/bin/nanofetch /usr/local/bin/
```

### Using Nix (Flake)

```bash
nix run github:amadejkastelic/nanofetch
```

Or add to your `flake.nix`:

```nix
inputs.nanofetch.url = "github:amadejkastelic/nanofetch";
```

And configuration:
```nix
environment.systemPackages [ inputs.nanofetch.packages.${pkgs.stdenv.hostPlatform.system}.nanofetch ];
```
## Usage

Simply run `nanofetch`:

```bash
nanofetch
```

### Disable Colors

Set `NO_COLOR` environment variable:

```bash
NO_COLOR=1 nanofetch
```

## Configuration

Configuration is done by editing the source code directly.

Edit `src/config.zig` to customize:

```zig
// Toggle logo display
pub const show_logo = true;

// Minimum terminal width to show logo
pub const min_width_for_logo: usize = 70;

// Logo selection: "auto" to detect OS, or specific name
// Available logos: "NixOS", "Arch", "Ubuntu"
pub const logo = "auto";
```

### Logo Customization

Add new logos or modify existing ones in `src/logos.zig`:

```zig
pub const logos = [_]Logo{
    .{
        .name = "MyDistro",
        .segments = [9][3]LogoSegment{
            // ASCII art lines with color indices
            .{ .text = "art here", .color = 0 },
            // ... more lines
        },
        .color_map = &[_][]const u8{
            "\x1b[34m", // blue
            // ... more colors
        },
        .aliases = &[_][]const u8{"mydistro", "alias2"},
    },
};
```

For advanced customization (colors, icons), edit:
- `src/colors.zig` - Color scheme
- `src/main.zig` - Icons and labels

After editing, rebuild:

```bash
zig build -Doptimize=ReleaseSmall
```

## Building

### Development Build

```bash
zig build
```

### Release Builds

```bash
# Small binary
zig build -Doptimize=ReleaseSmall

# Fast execution (default)
zig build -Doptimize=ReleaseFast

# Balanced
zig build -Doptimize=ReleaseSafe

# Debug build
zig build -Doptimize=Debug
```

## Performance

Benchmarks comparing nanofetch with other popular fetch tools:

| Tool       | Binary Size | Execution Time | Comparison |
|------------|-------------|----------------|------------|
| nanofetch  | ~42 KB      | 234 µs         | **Fastest**  |
| microfetch | ~120 KB     | 473 µs         | 2x slower |
| fastfetch  | ~2 MB       | 105 ms         | 449x slower |
| neofetch   | ~50 KB      | 452 ms         | 1930x slower |

## Acknowledgments

Inspired by and designed to match the output of [microfetch](https://github.com/NotAShelf/microfetch) by NotAShelf.
