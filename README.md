# Keychron Profiles

Keychron Profiles is the owned Omarchy+ Quickshell plugin for Hugin's wired
Keychron K10 HE and Q1 HE. It contributes one directly clickable **Gamepad Mode** toggle
to the existing center Indicators flyout:

- OFF selects and reflects Default, hardware profile index 0.
- ON selects and reflects Gamepad, hardware profile index 2.
- The icon changes only after the helper verifies the hardware response.
- Physical profile changes remain firmware-owned and are reflected by the next poll.
- Profile 2, disconnected, ambiguous, unsupported, permission, timeout, and
  protocol-error states are visible as unavailable and cannot be clicked.

There is no profile panel, popup, submenu, app-triggered switching, or separate
top-bar widget.

The permanent plugin ID is `io.github.ol4vr.keychron-profiles`. The
`0.2.0-candidate.1` source candidate supports the accepted K10 HE identities
(`3434:0ea0`, `3434:0ea1`) and Hugin's observed Q1 HE identity
(`3434:0b16`). Exactly one supported keyboard must be connected. If both are
present, the integration reports an ambiguous, non-actionable state rather
than choosing a device. No keyboard serial is required or stored by the UI.

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

Device selection requires a model-specific wired USB identity, product name,
and the exact verified `ff60:61` 32-byte input/output report descriptor.
Multiple supported keyboards fail closed even if the legacy diagnostic
`--serial` option is supplied. The helper has no
firmware, calibration, curve, mapping, profile-content, save-profile, or
raw-byte interface.

## Accepted FS25 analog baseline

Hugin's physically accepted Farming Simulator 25 configuration keeps the K10
HE and Q1 HE hardware profiles independent while giving both the same effective
Gamepad profile contract:

| Key | Gamepad output |
| --- | --- |
| W | Left Stick Up |
| A | Left Stick Left |
| S | Left Stick Down |
| D | Left Stick Right |

FS25's existing logical `AXIS_1` and `AXIS_2` bindings reuse the complete left
stick for walking, vehicle steering, acceleration, and braking. W/S are not
mapped to controller triggers. The owner accepted the Q1 through Steam's
native controller tester and by physically testing analog walking and driving
in FS25. Temporary keyboard-to-controller button assignments used during Steam
setup were removed afterward.

Steam retains distinct Linux SDL records for Q1 `3434:0b16` and K10
`3434:0ea1`. The Q1 record maps `leftx:a0` and `lefty:a1`; the remaining
generic controller fields are Steam-owned and do not imply that keyboard keys
are assigned to those buttons. Never replace the established K10 record when
recovering Q1 support, and do not modify FS25 bindings to recreate this
accepted behavior.

The Keychron helper cannot read or back up mappings, curves, calibration, or
other profile content. An ordinary Keychron keymap JSON is not a complete HE
analog-profile export. Hugin therefore preserves the exact Q1 Steam mapping
and its device-specific configset/preferences in a protected local backup with
checksums, while hardware-profile recovery still requires verified
owner-controlled Keychron Launcher evidence and repeat physical acceptance.
No Steam account data, device serial, or private mapping payload belongs in
this public repository.

The accepted local snapshot is stored under
`~/.local/state/omarchy-plus/keychron-he/fs25-analog/backups/` with manifest
SHA-256
`beb25c4fdcf0cfeda380e9f8d55674c50aba2ffaa99b3a27d360a289b64920a8`.
Its independently verified encrypted copy is on HUGIN_4TB at
`Omarchy-Plus/Keychron-HE/keychron-he-dual-fs25-accepted-20261022T235439+0200`.
The external bundle manifest SHA-256 is
`f27a3340ffbf0ddee57a571b1443077a51a3f4718f87299192dea6d7121ca9dd`;
it includes separate K10 recovery evidence and an explicit scope statement,
but still cannot restore either keyboard's onboard HE analog profile.

## Validation

Static validation does not open `/dev/hidraw*`:

```bash
./scripts/validate
./scripts/dev-deploy --check
```

The focused tests use temporary sysfs/device fixtures and fake transports.
Live hardware commands remain separate, explicit acceptance operations:

```bash
./keychron-profiles status
./keychron-profiles select default
./keychron-profiles select gamepad
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
`uaccess` to the K10 HE raw HID nodes. The owned
`system/udev/70-keychron-profiles.rules` adds the same active-seat mechanism
only for the Q1 HE `3434:0b16` profile-control HID at USB interface `01`.
It does not grant access to the Q1 keyboard or gamepad interfaces, use a
hardware serial, set a world-writable mode, or change the existing K10 rule.
The reviewed system destination is
`/etc/udev/rules.d/70-keychron-profiles.rules`.
Installing or removing this privileged rule remains a separate authorized
system operation; the plugin never elevates or changes permissions itself, and
a missing ACL is reported as unavailable.

This candidate supports only the verified wired identities above. It does not
support 2.4 GHz, Bluetooth, Q1 HE 8K, or unverified Q1 layout/firmware IDs. Do
not run Keychron Launcher/VIA concurrently with selection; hidraw does not
provide exclusive protocol ownership across unrelated applications.

## License

Original Omarchy+ Keychron Profiles work is MIT licensed; see `LICENSE`.
Vendored source notices are retained in `THIRD_PARTY.md`.
