//! Detached blink daemon: `blink` spawns the current binary with `_daemon`,
//! records its pid, and any later `on`/`off` kills it first.

use std::fs;
use std::path::PathBuf;
use std::process::{Command, Stdio};
use std::time::Duration;

use crate::led;

fn pidfile() -> PathBuf {
    let user = std::env::var("USER")
        .or_else(|_| std::env::var("USERNAME"))
        .unwrap_or_else(|_| "unknown".into());
    std::env::temp_dir().join(format!("capslock-indicator-{user}.pid"))
}

/// Kill a running blink daemon, if any. Returns true if one was stopped.
pub fn stop() -> bool {
    let pf = pidfile();
    let Ok(contents) = fs::read_to_string(&pf) else {
        return false;
    };
    let _ = fs::remove_file(&pf);
    let Ok(pid) = contents.trim().parse::<u32>() else {
        return false;
    };
    kill(pid)
}

#[cfg(unix)]
fn kill(pid: u32) -> bool {
    // SIGTERM; the daemon's signal handling is simple LED-off-on-exit via
    // default termination — we turn the LED off ourselves after stopping.
    unsafe { libc_kill(pid as i32, 15) == 0 }
}

#[cfg(unix)]
extern "C" {
    #[link_name = "kill"]
    fn libc_kill(pid: i32, sig: i32) -> i32;
}

#[cfg(windows)]
fn kill(pid: u32) -> bool {
    Command::new("taskkill")
        .args(["/PID", &pid.to_string(), "/F"])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
}

pub fn start(interval: f64, target: led::Target) -> Result<(), String> {
    stop();
    let exe = std::env::current_exe().map_err(|e| e.to_string())?;
    let mut cmd = Command::new(exe);
    cmd.arg("_daemon")
        .arg(interval.to_string())
        .arg(target.as_str())
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null());
    #[cfg(unix)]
    {
        use std::os::unix::process::CommandExt;
        cmd.process_group(0);
    }
    #[cfg(windows)]
    {
        use std::os::windows::process::CommandExt;
        const DETACHED_PROCESS: u32 = 0x0000_0008;
        const CREATE_NEW_PROCESS_GROUP: u32 = 0x0000_0200;
        cmd.creation_flags(DETACHED_PROCESS | CREATE_NEW_PROCESS_GROUP);
    }
    let child = cmd.spawn().map_err(|e| format!("spawn failed: {e}"))?;
    fs::write(pidfile(), child.id().to_string()).map_err(|e| e.to_string())?;
    Ok(())
}

/// The daemon loop itself (runs in the spawned process).
pub fn run(interval: f64, target: led::Target) -> ! {
    let backend = match led::backend(target) {
        Ok(b) => b,
        Err(_) => std::process::exit(1),
    };
    let mut state = true;
    loop {
        let _ = backend.set(state);
        state = !state;
        std::thread::sleep(Duration::from_secs_f64(interval));
    }
}
