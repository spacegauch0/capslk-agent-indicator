# capslock-agent-indicator

Turn your keyboard's **Caps Lock LED** into a status light for the Claude Code
agent:

| LED state | Meaning |
|-----------|---------|
| Solid on  | Agent is working |
| Blinking  | Agent needs your attention (permission prompt / notification) |
| Off       | Agent is idle |

Cross-platform (macOS, Linux, Windows). Written in Rust — one small static
binary (~400 KB), no runtime dependencies.

On Mac laptops you can alternatively use the **keyboard backlight** as the
indicator (`--backlight`) — solid bright while the agent works, flashing when
it needs you, and your previous brightness is restored when it goes idle. This
avoids the caps-lock caveat below entirely.

## Install

### Homebrew (macOS/Linux)

```sh
brew install spacegauch0/tap/capslock-indicator
```

(Available once the tap is published — see **Releasing & Homebrew** below.)

### From source

```sh
cargo build --release
# optionally put it on your PATH:
cp target/release/capslock-indicator ~/.local/bin/
```

### Wire it into Claude Code

```sh
capslock-indicator install-hooks              # caps lock LED
capslock-indicator --backlight install-hooks  # or: keyboard backlight (macOS)
```

Build on each platform you use (or cross-compile with the matching Rust
target). `install-hooks` wires the indicator into Claude Code's hook system
(`~/.claude/settings.json`) using the binary's own absolute path:

- `UserPromptSubmit` → LED on (agent started working)
- `Stop` → LED off (agent finished)
- `Notification` → LED blinks (agent is waiting on you)
- `SessionEnd` → LED off (cleanup)

Restart your Claude Code session to pick up the hooks. Existing hooks in
settings.json are preserved; re-running `install-hooks` is idempotent (it
replaces its own entries, e.g. after moving the binary). Remove them any time
with `capslock-indicator uninstall-hooks`.

## Manual usage

```sh
capslock-indicator on          # solid LED
capslock-indicator blink       # flash (default 0.4s); `blink 0.2` for faster
capslock-indicator off         # LED off (also stops blinking)
capslock-indicator toggle
capslock-indicator status      # print on/off
```

`blink` spawns a small detached daemon; any subsequent `on`/`off` kills it and
restores a steady state.

All commands accept `--target capslock|backlight` (or the `--backlight`
shorthand) to pick which light to drive; caps lock is the default.

## How it works per platform

- **macOS (caps lock)** — calls IOKit's
  `IOHIDSetModifierLockState(kIOHIDCapsLockState)` directly via FFI (links the
  IOKit framework; no cgo-style toolchain pain, which is why this is Rust and
  not Go).
- **macOS (backlight)** — talks to `KeyboardBrightnessClient` in the private
  `CoreBrightness.framework` via `dlopen` + the Objective-C runtime, so
  nothing private is linked at build time. `on` saves your current brightness
  to a temp file and goes to full; `off` restores it. Being a private
  framework, this could break in a future macOS release (works on current
  macOS 26). Note the system's automatic keyboard-backlight dimming may still
  adjust brightness on top of what we set.
- **Linux** — writes to `/sys/class/leds/*capslock*/brightness`, which drives
  the LED *without* changing typing state. Falls back to `xset led` under X11.
- **Windows** — synthesizes a `VK_CAPITAL` key press via `user32.keybd_event`.

### Caveat: caps lock is caps lock

On macOS and Windows the LED is tied to the actual caps-lock modifier state,
so while the light is on, **typing produces CAPITALS**. If you type into other
apps while the agent works, that may be annoying — it's inherent to how those
OSes expose the LED. On Linux the sysfs backend changes only the LED.

### Linux permissions

`/sys/class/leds/.../brightness` is root-writable by default. Grant your user
access with a udev rule:

```sh
sudo tee /etc/udev/rules.d/99-capslock-led.rules <<'EOF'
ACTION=="add", SUBSYSTEM=="leds", KERNEL=="*capslock*", RUN+="/bin/chmod 0666 /sys%p/brightness"
EOF
sudo udevadm control --reload && sudo udevadm trigger -s leds
```

## Building for other platforms

Each backend uses platform-native FFI (IOKit/CoreBrightness on macOS, `user32`
on Windows, sysfs on Linux) behind `#[cfg]` gates, so **binaries are built on
the target OS**, not cross-compiled from one machine. The
`.github/workflows/release.yml` matrix does exactly this on push of a `vX.Y.Z`
tag:

| Target | Runner | Rust target |
|--------|--------|-------------|
| macOS universal (arm64 + x86_64) | `macos-latest` | both, merged with `lipo` |
| Linux x86_64 | `ubuntu-latest` | `x86_64-unknown-linux-gnu` |
| Linux aarch64 | `ubuntu-24.04-arm` | `aarch64-unknown-linux-gnu` |
| Windows x86_64 | `windows-latest` | `x86_64-pc-windows-msvc` |

It uploads a `.tar.gz`/`.zip` per platform and attaches them to a GitHub
Release.

You *can* cross-compile locally (`rustup target add …` then
`cargo build --target …`), but only for the host OS's own arches without extra
toolchains — Mac→Mac universal works locally; Mac→Linux/Windows needs a cross
linker (`cross`, mingw, etc.), which is why CI is the recommended path.

## Releasing & Homebrew

Prerequisites: this must be a Git repo pushed to GitHub.

```sh
git init && git add -A && git commit -m "initial commit"
git remote add origin git@github.com:spacegauch0/capslock-agent-indicator.git
git push -u origin main
```

**Cut a release** — tag and push; the workflow builds all four binaries and
publishes a Release:

```sh
git tag v0.1.0 && git push origin v0.1.0
```

**Publish the Homebrew tap** — `Formula/capslock-indicator.rb` builds from
source (`depends_on "rust"`). Put it in a repo named `homebrew-tap`:

1. Create `github.com/spacegauch0/homebrew-tap`.
2. In `Formula/capslock-indicator.rb`, fill in `sha256`:
   ```sh
   curl -sL https://github.com/spacegauch0/capslock-agent-indicator/archive/refs/tags/v0.1.0.tar.gz | shasum -a 256
   ```
3. Commit it to the tap repo. Users then run
   `brew install spacegauch0/tap/capslock-indicator`.

Homebrew's core repo (`brew install capslock-indicator` with no tap) has its
own acceptance bar — notability, no HEAD-only, stable versioning — so a
personal tap is the practical route unless the project gets popular.

## License

MIT

