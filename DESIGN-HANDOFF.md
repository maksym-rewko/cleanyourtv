# Design handoff

How to change the look of the launcher without touching the plumbing (ADB, debloat, install). Everything
here was checked against the Sony BRAVIA VH1 on 2026-10-20.

## Setup, once per terminal

```bash
cd ~/Claude/cleanyourtv
source env.sh                  # JAVA_HOME, ANDROID_HOME, TV_SONY, TV_HOST
```

TV addresses are kept in `env.local.sh`, which is gitignored and stays on this Mac. On a new computer, copy
`env.local.sh.example` to `env.local.sh` and fill them in.

The TV must be on, on the same Wi-Fi, with USB debugging on (Settings > System > Developer options).
Check the IP in Settings > Network first; it can change after a reboot.

## Two ways to change things

| You change | Needs a rebuild? | Command |
|---|---|---|
| Anything in `themes/maksym/look.json`, plus its `wallpaper.jpg` | No, live in a few seconds | `tools/push-theme.sh sony` (or `hisense`, `firetv`, or `all`) |
| Preview the merged config without pushing | n/a | `tools/push-theme.sh sony --dry` |
| Back to the built-in look on one TV | No | `TV_HOST=$TV_SONY tools/theme.sh --reset` |
| `config.xml`, layouts, drawables, fonts, animations, Java | Yes, about a minute | `launcher/build-and-install.sh` |
| Which packages are disabled | No | `tools/disable.sh examples/sony-bravia-vh1/debloat.txt` |
| Undo all debloat and bring the stock launcher back | No | `tools/restore.sh examples/sony-bravia-vh1/debloat.txt com.google.android.tvlauncher` |

Rebuilding when Home already belongs to this launcher leaves the stock launcher alone, so it is safe to
repeat. It resets the optional accessibility key services, which this setup does not use.

A theme can never break Home: a key it does not know is ignored, and a file that does not parse is ignored.

## What each part of the UI is controlled by

| Part of the UI | Where | Rebuild? |
|---|---|---|
| Dock apps and order | `dock_apps` in the theme | No |
| Apps hidden from the grid | `hidden_apps` in the theme | No |
| Columns (1 to 8), rows left visible under the dock | `columns`, `rows_below_dock` | No |
| Dock as a band or as plain tiles, large dock title | `dock_row`, `dock_title` | No |
| Background colour, wallpaper, dimming, rotation | `background_color`, `wallpaper`, `wallpaper_dim`, `wallpaper_rotation_minutes` | No |
| Time-of-day gradient, cinematic top shelf | `sky_intensity`, `cinematic_home` | No |
| Apps below the dock, all-apps button | `grid_apps` (only these tiles below the dock), `app_library` (the button and the full app list), `library_in_top_bar` (button in the top bar, left of Inputs), `rows_below_dock` | No, but the launcher build must have them |
| Clock screensaver: plain black, centred | `dream_plain`. Pick the screensaver itself with `tools/venv/bin/python -I tools/tv.py 'settings put secure screensaver_components com.gathin.tvhome/.ClockDream'`; the delay is `settings put system screen_off_timeout 300000` (5 min) | No, but the launcher build must have it |
| Icon-only top buttons, fixed glow colour | `icon_only_pills`, `ambient_color` | No, but the launcher build must be one that has them (this repo's) |
| Gradient wallpaper (cool black to deep blue) | `python3 tools/make-wallpaper.py --from "#05070C" --to "#0A2A5E"` writes `themes/maksym/wallpaper.jpg`; `wallpaper: true` shows it | No |
| Motion: springs, focus lift, fades | `animations`, `reduced_motion`, `advanced_effects` | No |
| Greeting name, stats line under the clock | `greeting_name`, `show_stats` | No |
| Tile names and artwork | `app_labels`, `app_banners` (`banner_*` drawables) | Names no, new artwork yes |
| Glass panels, pills, tile backgrounds, icons | `launcher/app/src/main/res/drawable/` (`glass_panel`, `pill_bg`, `tile_bg`, `ic_*`) | Yes |
| Screen layouts | `res/layout/` (`activity_main.xml` is Home, `item_app.xml` a tile, `popup_inputs.xml` the Inputs menu, `dream_clock.xml` the screensaver) | Yes |
| Text styles | `res/values/styles.xml` | Yes |
| Font | `res/font/` (Outfit: extralight, light, regular, medium) | Yes |
| Animations | `res/anim/` (tile and app-open) and the springs in the Java files | Yes |
| Highlight, dock band, ambient glow | `GlassView.java`, `DockDecoration.java`, `HeroArt.java` | Yes |
| Strings and translations | `res/values/strings.xml` and `values-*` | Yes |

All keys are documented in `themes/README.md`.

**Colours are not in one place.** There is no `colors.xml`. Colours are written directly in the drawable and
layout XML and in about 16 Java files (for example `MainActivity.java`, `DockDecoration.java`, `HeroArt.java`).
Changing the palette means a search-and-replace across those, then a rebuild. The theme can only set the
background colour (`background_color`) and, for festival skins, `accent_color`.

## TV constraints to design for

- **Memory.** The Sony has about 2.9 GB. The launcher is built for sets with 1 GB, and the Hisense
  (SmartTV4KFFM) is unmeasured, so design for the weakest. No blur, no video backgrounds, no polling, no
  background services, no network.
- **Wallpapers.** Dark, 1920x1080, under about 300 KB. A picture over about 8.4 million pixels is not shown.
- **Resolution.** The Sony panel is 3840x2160 but the UI runs at 1920x1080 (density 320). Design on a
  1920x1080 canvas. A 4K asset gets scaled down.
- **10-foot UI.** Body text below about 28 px at 1080p is hard to read from a sofa. Keep contrast high; the
  clock, the hero name and the dock band are designed for a near-black background.
- **Focus.** Everything is navigated by D-pad, so every focusable thing needs a visible focus state (the
  glass highlight and the lifted tile). Up and Down move exactly one row, and the top buttons never fall
  through to tiles. Test every edge after a layout change.
- **Safe margins.** Keep important content about 5 percent in from every edge; some TVs overscan.
- **Reduced motion.** `"reduced_motion": true` gives a stiff spring with no overshoot and shorter fades.
  Use it if a TV stutters. Test a new animation with it on and off.
- **Three TVs, one design.** The design is edited once, in `themes/maksym/look.json`. What differs per TV is in
  `themes/maksym/tv/<tv>.json`: `sony.json` (tuner app `com.sony.dtv.tvx`, the Live TV package, hidden from the
  grid), `hisense.json` (tuner `com.vt.tv.tvcenter`) and `firetv.json` (no tuner; the Menu button opens the
  launcher). `tools/push-theme.sh sony|hisense|firetv|all` merges the two, and the per-TV file wins on a clash.
  Each TV's address is `TV_SONY`, `TV_HISENSE` or `TV_FIRETV` in `env.local.sh`. Do not put look settings in the
  per-TV files, or the TVs drift apart.
- **Dock apps differ by TV.** A package that is not installed is skipped, so `dock_apps` can list every variant
  (the Apple TV app's package is `com.apple.atve.sony.appletv` on the Sony and may differ on the Hisense).
- **Same launcher build.** A theme only matches if both TVs run the same APK. After any rebuild, install it on
  every TV (`TV_HOST=$TV_SONY launcher/build-and-install.sh`, then the same for the Hisense).
- **Fire TV.** Fire OS will not give Home to a third-party launcher, so the launcher is installed as an ordinary
  app (Phase 5, option B) and Amazon Home stays. Home and Live TV are handled by Fire OS before the launcher's
  `HomeKeyService` sees them, so the remote's Menu button opens the launcher instead (`app_keys` in
  `tv/firetv.json`; its in-app menu stops working). The service is enabled with `settings put secure
  enabled_accessibility_services com.gathin.tvhome/.HomeKeyService` and it reads the theme only when it connects,
  so after changing `app_keys` turn it off and on. To undo: `settings put secure enabled_accessibility_services ""`.
- **Debloat lists, one per TV.** `examples/sony-bravia-vh1/`, `examples/hisense-lushan-12/` and
  `examples/hisense-fire-tv-aftolcbc82/`. On the Google TV Hisense, `setupwraith` also answers Home and outranks
  a third-party launcher: forget and re-join Wi-Fi first, or disabling it deletes the saved network.

## Verify a change

```bash
tools/venv/bin/python -I tools/tv.py 'input keyevent KEYCODE_HOME'
tools/venv/bin/python -I tools/tv.py 'screencap -p /data/local/tmp/s.png' && tools/venv/bin/python -I tools/tv.py --pull /data/local/tmp/s.png s.png
```

Live TV and HDMI screenshots come back empty; press Home first. An injected key proves navigation only, not
what a physical remote button sends: for Home, Input, gear and mic, press the real remote.

## Safety net

If Home breaks: re-enable the stock launcher (Sony `com.google.android.tvlauncher`, Hisense Google TV
`com.google.android.apps.tv.launcherx` and `com.google.android.tungsten.setupwraith`), for example
`tools/venv/bin/python -I tools/tv.py 'pm enable --user 0 com.google.android.tvlauncher'`, then run the restore
command in the table above with that TV's list. The stock launcher is only disabled, never uninstalled.

## Before you leave the TV alone

Turn off USB debugging and Network/ADB debugging on the TV, revoke the USB debugging authorisations,
reboot, and confirm `nc -vz $TV_HOST 5555` fails.
