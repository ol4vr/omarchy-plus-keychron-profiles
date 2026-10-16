# Keychron Profiles

Keychron Profiles is the owned Omarchy+ Quickshell plugin for Hugin's wired
Keychron K10 HE. It contributes one directly clickable **Gamepad Mode** toggle
to the existing center Indicators flyout:

- OFF selects and reflects Default, hardware profile index 0.
- ON selects and reflects Gamepad, hardware profile index 2.
- The icon changes only after the helper verifies the hardware response.
- Fn+F9 and Fn+F10 remain firmware-owned and are reflected by the next poll.
- Profile 2, disconnected, ambiguous, unsupported, permission, timeout, and
  protocol-error states are visible as unavailable and cannot be clicked.

There is no profile panel, popup, submenu, app-triggered switching, or separate
top-bar widget.

The permanent plugin ID is `io.github.ol4vr.keychron-profiles`. Version 0.1.1
is intentionally limited to wired K10 HE ANSI (`3434:0ea0`) and ISO
(`3434:0ea1`). An exact serial can be configured in the widget settings when
more than one supported keyboard may be present. Serial values belong to the
local Omarchy shell configuration and are never part of public plugin source.

## Architecture and safety

Omarchy 4.0.4 does not expose a manifest entry for adding one third-party
indicator. It does explicitly support owned clones of `omarchy.indicators`.
This plugin uses that supported clone contract, preserves the standard
Indicators behavior and styling, and adds only `indicators/GamepadMode.qml`.
See `THIRD_PARTY.md` for exact source provenance and licensing.

One process-wide Quickshell service invokes a short-lived standard-library
Python helper approximately every two seconds. Per-monitor indicator instances
consume that shared state; no UI instance owns a polling process or daemon.

The helper can emit only `AMC_GET_PROFILES_INFO` (`a9 10`) and
`AMC_SELECT_PROFILE` (`a9 11`). Selection accepts only index 0 or index 2. A
SELECT is skipped when GET already reports the requested profile. After a
write, a separate GET must verify the hardware state. A lost SELECT response
triggers one GET and never a blind SELECT retry.

Device selection requires a supported wired USB identity, the exact verified
`ff60:61` 32-byte input/output report descriptor, and—when configured—the exact
serial. Multiple matches without a unique serial fail closed. The helper has no
firmware, calibration, curve, mapping, profile-content, save-profile, or
raw-byte interface.

## Validation

Static validation does not open `/dev/hidraw*`:

```bash
./scripts/validate
./scripts/dev-deploy --check
```

The focused tests use temporary sysfs/device fixtures and fake transports.
Live hardware commands remain separate, explicit acceptance operations:

```bash
./keychron-profiles --serial KEYBOARD_SERIAL status
./keychron-profiles --serial KEYBOARD_SERIAL select default
./keychron-profiles --serial KEYBOARD_SERIAL select gamepad
```

Only these commands exist. `select` rejects every value except `default` and
`gamepad` before opening a device.

## Development deployment and recovery

The authoritative checkout is the Git repository named
`omarchy-plus-keychron-profiles`.
Development deployment is marker-owned and refuses a Git-managed production
checkout or an unrecognized directory:

```bash
./scripts/dev-deploy
./scripts/dev-remove
```

Deployment validates first, copies only `runtime-files.txt`, requests the
supported shell plugin rescan, and fails unless the plugin appears in the
authoritative plugin list within the bounded registration check. It never
restarts the shell. Enabling this plugin replaces the stock
`omarchy.indicators` widget in place through Omarchy's clone lifecycle, keeping
the center placement and inherited settings. Disabling it restores the stock
widget. Neither operation selects a keyboard profile.

A full shell-restart acceptance test remains a separate, explicitly authorized
live operation. When RAM Tetris is active, that test must use the OpenRGB
lifecycle's reviewed handoff procedure; `dev-deploy` does not initiate it.

Publication, central `config/plugins.json` pinning, and final acceptance remain
owned by the central Omarchy+ repository.

## Production installation and recovery

Production is never installed from the development helper. The central
Omarchy+ `config/plugins.json` pins an exact commit and
`scripts/plugins/reconcile` installs a clean detached Git checkout at:

```text
~/.config/omarchy/plugins/io.github.ol4vr.keychron-profiles
```

Enabling the production plugin replaces stock `omarchy.indicators` in place
through Omarchy's clone lifecycle, retaining its center location and existing
indicator settings. Disabling it restores stock `omarchy.indicators`. Recovery
therefore consists of restoring the central repository, running its plugin
reconciler on Hugin, and validating the exact pinned checkout and hardware
state; there is no plugin database, profile backup, daemon, or mutable state to
restore. The keyboard's hardware profiles, mappings, curves, and calibration
remain firmware-owned and are not recovery payloads.

Before reconciling a production checkout over a development copy, run
`scripts/dev-remove` from this authoritative source repository. It refuses
unrecognized and Git-managed targets.

## Omarchy Indicators clone maintenance

The plugin is intentionally coupled to the Omarchy 4.0.4 Indicators contract.
After any Omarchy shell upgrade that changes `Indicators.qml`, `BarIndicator`,
the standard indicator set, plugin clone metadata, service proxies, or bar
lifecycle, compare the new packaged sources with the pinned v4.0.4 provenance
in `THIRD_PARTY.md`. Selectively reconcile the owned clone, preserve
`GamepadMode.qml`, rerun the complete source and live acceptance checks, and
update provenance before changing the central commit pin. Never overwrite the
clone automatically from a mutable upstream branch.

## Permissions and limitations

Hugin's existing packaged OpenRGB udev rules grant the logged-in seat user
`uaccess` to the K10 HE raw HID nodes. The plugin never elevates or changes
permissions. A missing ACL is reported as unavailable.

Version 0.1.1 supports only the wired K10 HE. It does not support 2.4 GHz,
Bluetooth, Q1 HE, or Q1 HE 8K. Do not
run Keychron Launcher/VIA concurrently with selection; hidraw does not provide
exclusive protocol ownership across unrelated applications.

## License

Original Omarchy+ Keychron Profiles work is MIT licensed; see `LICENSE`.
Vendored source notices are retained in `THIRD_PARTY.md`.
