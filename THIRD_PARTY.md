# Third-party source

This repository carries the Omarchy Indicators widget and its standard
indicator files because Omarchy's supported third-party customization contract
is an owned clone, not an individual indicator-contribution manifest.

## Omarchy Indicators

- Upstream: <https://github.com/basecamp/omarchy>
- Revision: `c668141e9c42b13c80c9ca4ea108e11708c5e8a5` (`v4.0.4`)
- Installed package used for the import: `omarchy 4.0.4-1`
- Imported files: `Indicators.qml`, `indicators/Dictation.qml`,
  `indicators/Dnd.qml`, `indicators/NightLight.qml`,
  `indicators/Reminder.qml`, `indicators/ScreenRecording.qml`, and
  `indicators/StayAwake.qml`
- Local changes: the clone always contributes `GamepadMode`, configures its
  own Keychron service, and resolves indicator files from the cloned local
  directory.
- Update policy: compare every relevant packaged Indicators change after an
  Omarchy upgrade, selectively reconcile this owned clone, and repeat source
  plus live acceptance before changing the central production pin. No mutable
  upstream branch is an automatic update authority.
- License: MIT
- Copyright: David Heinemeier Hansson

> Copyright (c) David Heinemeier Hansson
>
> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the "Software"), to deal
> in the Software without restriction, including without limitation the rights
> to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
> copies of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in
> all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
> SOFTWARE.

## Discord PTT indicator

- Source: <https://github.com/ol4vr/omarchy-plus-discord-ptt>
- Revision: `623fff9ea45e9e7952dca80450965b49c17a4fba`
- Imported file: `indicators/PttMode.qml`
- Local changes: none; the imported file was byte-for-byte identical to the
  Hugin-installed indicator at import time.
- License: MIT, copyright 2026 ol4vr. See the source repository's
  `LICENSE`.
