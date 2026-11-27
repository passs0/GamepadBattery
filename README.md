<p align="center">
  <img src="assets/icon_mac.png" width="160" height="160" alt="LifeBar Icon" />
</p>

<h1 align="center">LifeBar</h1>

<p align="center">
  A lightweight macOS menu bar battery monitor and low-battery HUD for PlayStation, Xbox, Nintendo Switch, and MFi controllers.
</p>

<p align="center">
  <a href="https://github.com/passs0/LifeBar/releases/latest"><img src="https://img.shields.io/github/v/release/passs0/LifeBar?label=Latest%20Release&color=007AFF" alt="Latest Release" /></a>
  <img src="https://img.shields.io/badge/macOS-13.0%2B%20%7C%20Apple%20Silicon%20%26%20Intel-black?logo=apple" alt="macOS 13.0+" />
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License" /></a>
</p>

<p align="center">
  <img src="assets/hud.png" width="340" alt="LifeBar Low-Battery HUD" />
  <br/><br/>
  <img src="assets/popover.png" width="340" alt="LifeBar Menu Bar Popover" />
</p>

---

## What it does

- **Menu bar battery status:** Sits quietly in the menu bar (`LSUIElement`) with an optional live percentage readout and hover tooltip.
- **Broad controller support:** Tracks Sony (DualSense, DualShock 4), Xbox, Nintendo (Switch Pro, Joy-Con), and MFi/HID controllers via `GameController.framework`.
- **Non-activating low-battery HUD:** Shows a floating capsule alert when a controller drops below your threshold (10%–30%) without stealing focus from full-screen games.
- **Launch at Login:** Uses `SMAppService` and refreshes automatically after sleep/wake.

## Install

Download **`LifeBar-v1.1.3.dmg`** from [Releases](https://github.com/passs0/LifeBar/releases/latest) and drag `LifeBar.app` to `/Applications`.

If Gatekeeper blocks the first launch:
```zsh
xattr -cr /Applications/LifeBar.app
```

Or build from source:
```zsh
git clone https://github.com/passs0/LifeBar.git && cd LifeBar
make install
```

## Credits

Built with [Google Antigravity](https://antigravity.google) — 100% AI-written code and UI, steered and tested by hand.

## License

[MIT](LICENSE)
