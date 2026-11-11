"""Trace the X idle counter and every gate on idle locking and blanking.

Appends one line per sample to $XDG_STATE_HOME/idle-trace/<date>.log and
deletes day files older than the retention window.  A line holds what the
lock stack in nix-conf/modules/desktop/screen-lock.nix reads: the idle
counter, the X screensaver and DPMS state, xidlehook's fullscreen and audio
gates, which idle chain runs, whether the locker is up, and the raw input
each device sent since the previous line.

An idle reset with an empty `ev=` field came from a client (an
XResetScreenSaver call), not from a device.
"""

import datetime
import json
import os
import pathlib
import select
import subprocess
import time

from Xlib import X, display, error
from Xlib.ext import ge, xinput
from Xlib.protocol import rq

SAMPLE_SECONDS = float(os.environ.get("IDLE_TRACE_SAMPLE_SECONDS", "5"))
KEEP_DAYS = int(os.environ.get("IDLE_TRACE_KEEP_DAYS", "2"))
STATE_HOME = os.environ.get("XDG_STATE_HOME") or os.path.expanduser(
    "~/.local/state")
LOG_DIR = pathlib.Path(STATE_HOME) / "idle-trace"
LOCKER = "i3lock-color"

# python-xlib parses no XI2 raw event; this is the fixed head of one.
RAW_EVENT = rq.Struct(
    xinput.DEVICEID("deviceid"),
    rq.Card32("time"),
    rq.Card32("detail"),
    xinput.DEVICEID("sourceid"),
    rq.Card16("valuators_len"),
    rq.Card32("flags"),
    rq.Pad(4),
)
RAW_KINDS = {
    xinput.RawKeyPress: "k",
    xinput.RawButtonPress: "b",
    xinput.RawMotion: "m",
}
SCREENSAVER_STATES = {0: "off", 1: "on", 2: "cycle", 3: "disabled"}
DPMS_LEVELS = {0: "on", 1: "standby", 2: "suspend", 3: "off"}


def announce_xi_2_2(d):
    """Announce XI 2.2 so raw events arrive while another client grabs.

    The server sends raw events to a root listener during a grab (the
    locker grabs everything) only when the client announced 2.1 or later;
    python-xlib's own `xinput_query_version' announces 2.0.
    """
    return xinput.XIQueryVersion(
        display=d.display,
        opcode=d.display.get_extension_major(xinput.extname),
        major_version=2,
        minor_version=2,
    )


def device_names(d):
    """Map each XI2 device id to its name, spaces made underscores."""
    reply = d.xinput_query_device(xinput.AllDevices)
    return {dev.deviceid: dev.name.replace(" ", "_")
            for dev in reply.devices}


def fullscreen_windows(window, state_atom, fullscreen_atom):
    """Return every window under WINDOW whose _NET_WM_STATE is fullscreen.

    Walks the whole tree like xidlehook's `--not-when-fullscreen', which
    blocks on ANY fullscreen window, hidden or not, not the active one.
    """
    found = []
    try:
        children = window.query_tree().children
    except error.XError:
        return found
    for child in children:
        try:
            prop = child.get_full_property(state_atom, X.AnyPropertyType)
        except error.XError:
            continue
        if prop is not None and fullscreen_atom in prop.value:
            try:
                wm_class = child.get_wm_class()
            except error.XError:
                wm_class = None
            label = wm_class[1] if wm_class else "?"
            found.append("%s:0x%x" % (label.replace(" ", "_"), child.id))
        found.extend(
            fullscreen_windows(child, state_atom, fullscreen_atom))
    return found


def playing_streams():
    """Name each uncorked sink input: xidlehook's `--not-when-audio' gate."""
    try:
        out = subprocess.run(
            ["pactl", "-f", "json", "list", "sink-inputs"],
            capture_output=True, text=True, timeout=3, check=True).stdout
        streams = json.loads(out)
    except (OSError, subprocess.SubprocessError, ValueError):
        return ["?"]
    names = []
    for stream in streams:
        if stream.get("corked"):
            continue
        props = stream.get("properties", {})
        name = props.get("application.name") or props.get("media.name")
        names.append((name or "?").replace(" ", "_"))
    return names


def idle_chain():
    """Name the running idle chain unit, or `none'."""
    units = ["xidlehook.service", "xidlehook-caffeinated.service"]
    try:
        out = subprocess.run(
            ["systemctl", "--user", "is-active", *units],
            capture_output=True, text=True, timeout=3).stdout.split()
    except (OSError, subprocess.SubprocessError):
        return "?"
    labels = ["normal", "caffeinated"]
    active = [label for label, state in zip(labels, out)
              if state == "active"]
    return ",".join(active) or "none"


def locker_running():
    """Report whether the locker process is up."""
    for comm in pathlib.Path("/proc").glob("[0-9]*/comm"):
        try:
            if comm.read_text().strip() == LOCKER:
                return True
        except OSError:
            continue
    return False


def format_events(counts, names):
    """Render per-device raw event counts, or `-' when there were none."""
    parts = []
    for source, kinds in sorted(counts.items()):
        tally = "/".join("%s%d" % (k, kinds[k]) for k in sorted(kinds))
        parts.append("%s:%s" % (names.get(source, source), tally))
    return ",".join(parts) or "-"


def sample_line(d, root, atoms, counts, names):
    """Build one trace line from the server state and COUNTS."""
    info = root.screensaver_query_info()
    saver = d.get_screen_saver()
    dpms = d.dpms_info()
    dpms_timeouts = d.dpms_get_timeouts()
    fullscreen = fullscreen_windows(root, *atoms)
    audio = playing_streams()
    fields = [
        datetime.datetime.now().isoformat(timespec="seconds"),
        "idle=%.1f" % (info.idle / 1000),
        "ss=%s/%d" % (SCREENSAVER_STATES.get(info.state, info.state),
                      saver.timeout),
        "dpms=%s/%s/%d" % (DPMS_LEVELS.get(dpms.power_level, "?"),
                           "en" if dpms.state else "dis",
                           dpms_timeouts.off_timeout),
        "lock=%d" % locker_running(),
        "chain=%s" % idle_chain(),
        "fs=%s" % (",".join(fullscreen) or "-"),
        "audio=%s" % (",".join(audio) or "-"),
        "ev=%s" % format_events(counts, names),
    ]
    return " ".join(fields)


def prune(today):
    """Delete day files older than the retention window."""
    oldest = today - datetime.timedelta(days=KEEP_DAYS - 1)
    for path in LOG_DIR.glob("*.log"):
        try:
            day = datetime.date.fromisoformat(path.stem)
        except ValueError:
            continue
        if day < oldest:
            path.unlink(missing_ok=True)


def main():
    d = display.Display()
    root = d.screen().root
    announce_xi_2_2(d)
    opcode = d.display.get_extension_major(xinput.extname)
    for kind in RAW_KINDS:
        d.ge_add_event_data(opcode, kind, RAW_EVENT)
    raw_mask = 0
    for kind in RAW_KINDS:
        raw_mask |= 1 << kind
    root.xinput_select_events([
        (xinput.AllMasterDevices, raw_mask),
        (xinput.AllDevices, xinput.HierarchyChangedMask),
    ])
    d.flush()
    atoms = (d.intern_atom("_NET_WM_STATE"),
             d.intern_atom("_NET_WM_STATE_FULLSCREEN"))
    names = device_names(d)
    LOG_DIR.mkdir(parents=True, exist_ok=True)

    counts = {}
    day = None
    log = None
    next_sample = time.monotonic()
    while True:
        wait = max(0.0, next_sample - time.monotonic())
        if not d.pending_events():
            select.select([d.fileno()], [], [], wait)
        while d.pending_events():
            event = d.next_event()
            if event.type != ge.GenericEventCode:
                continue
            if event.evtype in RAW_KINDS:
                kinds = counts.setdefault(event.data.sourceid, {})
                kind = RAW_KINDS[event.evtype]
                kinds[kind] = kinds.get(kind, 0) + 1
            elif event.evtype == xinput.HierarchyChanged:
                names = device_names(d)
        now = time.monotonic()
        if now < next_sample:
            continue
        # Schedule from now, not from the missed slot, so a suspend or a
        # stall never bursts out a run of catch-up lines.
        next_sample = now + SAMPLE_SECONDS
        today = datetime.date.today()
        if today != day:
            if log:
                log.close()
            day = today
            prune(today)
            log = open(LOG_DIR / ("%s.log" % today), "a", buffering=1)
        log.write(sample_line(d, root, atoms, counts, names) + "\n")
        counts = {}


if __name__ == "__main__":
    main()
