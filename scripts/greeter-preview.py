#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p "python3.withPackages(ps: [ ps.pygobject3 ])" gtk3 gobject-introspection
"""Standalone preview of the lightdm-mini-greeter login screen.

WHY THIS EXISTS
    `lightdm --test-mode` is a dead end on this host: the NixOS
    `/etc/pam.d/lightdm-greeter` stack requires `user = lightdm` in every
    phase, but test-mode runs the greeter as the invoking user, so
    `pam_open_session` fails and the greeter dies before drawing (see
    .eca/docs/gotchas.md). This reproduces the greeter's look in a normal
    session so you can tune font-size / the password box WITHOUT logging out.

WHAT IT DOES
    Reads /etc/lightdm/lightdm-mini-greeter.conf (or a path you pass) and
    rebuilds, byte-for-byte where it matters, the greeter's GTK CSS and widget
    tree from upstream src/ui.c (tag 0.5.1):
      - a fullscreen `#background` window drawing `background-image` CENTERED
        and UNSCALED (GTK `background-position: center`, no `background-size`),
        which is exactly why a panel-sized image fills and a small one does not;
      - a centered `#main` box (window-color fill, border) padded by
        `layout-space`, holding a grid of the `Password:` label to the LEFT of
        the `#password` entry, the entry `width_chars` = `password-input-width`.

FIDELITY CAVEAT (font size)
    The CSS uses `font-size` in `em`, relative to THIS session's GTK base font,
    which may not equal the greeter session's base. So the box-to-font RATIO is
    faithful, but the ABSOLUTE size may differ from what you saw at login. Tune
    the ratio here, then confirm once at a real login. Everything else (the
    wallpaper fill, colors, box geometry, border) is exact.

USAGE
    GUI preview (pulls GTK via the nix-shell shebang):
        ./scripts/greeter-preview.py [CONF_PATH]
    Headless CSS dry-run (no display, no GTK needed):
        python3 scripts/greeter-preview.py --print-css [CONF_PATH]
    Esc quits the preview window.
"""

import sys
import configparser


def load_config(conf_path):
    """Parse the mini-greeter conf into the fields ui.c reads.

    configparser splits on the first `=`, so `password-label-text = Password:`
    keeps its trailing colon in the value. Interpolation is disabled because
    color/size values are literal (and could contain `%`).
    """
    cp = configparser.ConfigParser(interpolation=None)
    # Preserve unknown/extra keys quietly; a missing file yields empty sections.
    cp.read(conf_path)

    g = cp["greeter"] if cp.has_section("greeter") else {}
    t = cp["greeter-theme"] if cp.has_section("greeter-theme") else {}

    def unquote(s):
        if s is None:
            return s
        s = s.strip()
        if len(s) >= 2 and s[0] == '"' and s[-1] == '"':
            return s[1:-1]
        return s

    def get(sec, key, default=None):
        try:
            return sec[key]
        except (KeyError, TypeError):
            return default

    def as_int(val, default):
        try:
            return int(val)
        except (TypeError, ValueError):
            return default

    align = (get(g, "password-alignment", "right") or "right").strip().lower()

    cfg = {
        # [greeter]
        "show_label": (get(g, "show-password-label", "true").strip().lower()
                       == "true"),
        "label_text": unquote(get(g, "password-label-text", "Password:")),
        "width_chars": as_int(get(g, "password-input-width", "-1"), -1),
        "align": {"left": 0.0, "center": 0.5, "right": 1.0}.get(align, 1.0),
        # [greeter-theme] (colors/image keep GKeyFile semantics: as written)
        "font": unquote(get(t, "font", "Sans")),
        "font_size": unquote(get(t, "font-size", "1em")),
        "font_weight": unquote(get(t, "font-weight", "bold")),
        "font_style": unquote(get(t, "font-style", "normal")),
        "text_color": unquote(get(t, "text-color", "#080800")),
        "error_color": unquote(get(t, "error-color", "#F8F8F0")),
        "bg_color": unquote(get(t, "background-color", "#1B1D1E")),
        "window_color": unquote(get(t, "window-color", "#F92672")),
        "border_color": unquote(get(t, "border-color", "#080800")),
        "border_width": unquote(get(t, "border-width", "2px")),
        "pw_color": unquote(get(t, "password-color", "#F8F8F0")),
        "pw_bg": unquote(get(t, "password-background-color", "#1B1D1E")),
        "pw_border_c": unquote(get(t, "password-border-color",
                                   unquote(get(t, "border-color", "#080800")))),
        "pw_border_w": unquote(get(t, "password-border-width",
                                   unquote(get(t, "border-width", "2px")))),
        "pw_radius": unquote(get(t, "password-border-radius", "0.341125em")),
        "layout_space": as_int(get(t, "layout-space", "15"), 15),
        # image keeps its quotes, exactly like config->background_image in ui.c
        "bg_image": (get(t, "background-image", '""') or '""').strip(),
    }
    cfg["has_image"] = cfg["bg_image"] not in (None, '""', '', '"')
    return cfg


def build_css(cfg):
    """Mirror src/ui.c attach_config_colors_to_screen (tag 0.5.1)."""
    return f"""* {{
  font-family: {cfg['font']};
  font-size: {cfg['font_size']};
  font-weight: {cfg['font_weight']};
  font-style: {cfg['font_style']};
}}
label {{
  color: {cfg['text_color']};
}}
label#error {{
  color: {cfg['error_color']};
}}
#background {{
  background-color: {cfg['bg_color']};
}}
#background.with-image {{
  background-image: image(url({cfg['bg_image']}), {cfg['bg_color']});
  background-repeat: no-repeat;
  background-position: center;
}}
#main, #password {{
  border-width: {cfg['border_width']};
  border-color: {cfg['border_color']};
  border-style: solid;
}}
#main {{
  background-color: {cfg['window_color']};
  padding: {cfg['layout_space']}px;
}}
#password {{
  color: {cfg['pw_color']};
  caret-color: {cfg['pw_color']};
  background-color: {cfg['pw_bg']};
  border-width: {cfg['pw_border_w']};
  border-color: {cfg['pw_border_c']};
  border-radius: {cfg['pw_radius']};
  background-image: none;
  box-shadow: none;
  border-image-width: 0;
}}
"""


def run_gui(cfg, css):
    """Render the greeter look. GTK imports live here so --print-css and
    py_compile work in an environment without PyGObject."""
    import gi
    gi.require_version("Gtk", "3.0")
    gi.require_version("Gdk", "3.0")
    from gi.repository import Gtk, Gdk

    provider = Gtk.CssProvider()
    provider.load_from_data(css.encode())
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(), provider,
        Gtk.STYLE_PROVIDER_PRIORITY_USER + 1)

    bg = Gtk.Window(type=Gtk.WindowType.TOPLEVEL)
    bg.set_name("background")
    if cfg["has_image"]:
        bg.get_style_context().add_class("with-image")
    bg.connect("destroy", Gtk.main_quit)

    def on_key(_w, event):
        if event.keyval == Gdk.KEY_Escape:
            Gtk.main_quit()
        return False

    bg.connect("key-press-event", on_key)

    overlay = Gtk.Overlay()
    bg.add(overlay)
    overlay.add(Gtk.Box())  # base child; the overlay fills the fullscreen bg

    main = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
    main.set_name("main")
    main.set_halign(Gtk.Align.CENTER)
    main.set_valign(Gtk.Align.CENTER)

    grid = Gtk.Grid()
    grid.set_column_spacing(5)
    grid.set_row_spacing(5)

    entry = Gtk.Entry()
    entry.set_name("password")
    entry.set_visibility(False)
    entry.set_alignment(cfg["align"])
    if cfg["width_chars"] >= 0:
        entry.set_width_chars(cfg["width_chars"])
    grid.attach(entry, 0, 0, 1, 1)

    if cfg["show_label"]:
        label = Gtk.Label(label=cfg["label_text"])
        grid.attach_next_to(label, entry, Gtk.PositionType.LEFT, 1, 1)

    main.add(grid)
    overlay.add_overlay(main)

    # Fill the primary monitor so the centered-unscaled wallpaper fills exactly
    # as the greeter draws it.
    display = Gdk.Display.get_default()
    mon = display.get_primary_monitor() or display.get_monitor(0)
    geo = mon.get_geometry()
    bg.set_default_size(geo.width, geo.height)
    bg.fullscreen()

    bg.show_all()
    entry.grab_focus()
    Gtk.main()


def main(argv):
    args = [a for a in argv[1:]]
    print_css = "--print-css" in args
    args = [a for a in args if a != "--print-css"]
    conf_path = args[0] if args else "/etc/lightdm/lightdm-mini-greeter.conf"

    cfg = load_config(conf_path)
    css = build_css(cfg)

    if print_css:
        print(f"# conf: {conf_path}")
        print(f"# has_image: {cfg['has_image']}  width_chars: {cfg['width_chars']}")
        print(css, end="")
        return 0

    print(f"conf: {conf_path}   (Esc to quit)")
    run_gui(cfg, css)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
