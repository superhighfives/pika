<img width="128" alt="Pika icon, an eye against a multicoloured background" src="https://user-images.githubusercontent.com/449385/103492506-4dbd3700-4e23-11eb-97ca-44a959f171c6.png">

# Pika

Pika (pronounced pi·kuh, like picker) is an easy to use, open-source, native colour picker for macOS. Pika makes it easy to quickly find colours onscreen, in the format you need, so you can get on with being a speedy, successful designer.

<img width="768" alt="Screenshots of the dark and light Pika interface" src="https://superhighfives.com/assets/pika-readme%402x.png">

## Download

**Download the latest version of the app at:<br />
[superhighfives.com/pika](https://superhighfives.com/pika)**

Or install with Homebrew:
```bash
brew install --cask pika
```

## Features

- Pick colours from anywhere on screen, with the macOS sampler or Pika's Pro picker and its live loupe
- Check contrast between a foreground and background with WCAG 2 or APCA
- Hex, RGB, HSB, HSL, LAB, OpenGL and OKLCH formats, in sRGB or Display P3
- Click, type, scrub or step any colour value
- Colour names, history, undo and redo
- Global shortcuts and a `pika://` URL scheme for automation

## Learn More

Learn more about the [motivations behind the project](https://medium.com/superhighfives/introducing-pika-d7725c397585), and the [product vision](https://github.com/superhighfives/pika/wiki).

<a href="https://www.producthunt.com/golden-kitty-awards/hall-of-fame?year=2022">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://user-images.githubusercontent.com/449385/215260970-a3c37e86-7d2c-458e-84f8-32a6e24b0cc7.png">
    <img width="250" alt="Golden Kitty Awards 2022 Finalist" src="https://user-images.githubusercontent.com/449385/215260971-e09cdbea-588a-45a9-955c-cbfd1822c2b9.png">
  </picture>
</a>

---

## Requirements

### OS

- macOS Sonoma (Version 14) and newer

## Basics

Colour contrast is the difference in lightness between text and whatever’s behind it. With too little, words blur into their background. That’s a real problem for people with low vision or colour blindness, and it catches everyone else too, like reading a phone in the sun or a laptop turned down low.

Accessibility guidelines set minimum contrast levels so text stays readable for as many people as possible. WCAG 2 is the standard most guidelines and laws point to, and APCA is a newer method that also weighs up font size and weight. Checking early is much easier than reworking a design later.

That’s where Pika comes in. Pick a foreground and background from anywhere on your screen, whether it’s a design file, a website or a screenshot, and Pika shows the contrast straight away, alongside the colours in the format you need, ready to copy.

- **Foreground and background**: The foreground is text or an icon; the background is the surface behind it. Press <kbd>X</kbd> to swap them.
- **Why check contrast**: Low-contrast text is hard to read, especially with low vision, colour blindness or glare.
- **WCAG and APCA**: WCAG 2 gives a ratio (AA needs 4.5:1 for text). APCA gives an Lc value that accounts for size and weight, but isn’t a standard yet.
- **Ways to pick a colour**: Basic uses the macOS sampler. Pro adds a live loupe and needs Screen Recording. <kbd>⌘ S</kbd> opens the macOS colour panel.
- **Editing values**: Click a value to type, drag or two-finger scroll to scrub, and press <kbd>↑</kbd> or <kbd>↓</kbd> to step. <kbd>⌘ Z</kbd> undoes.
- **Colour spaces**: sRGB matches CSS, Figma and most design tools, and is the default. Display P3 covers the more vivid colours of recent Macs. Contrast always uses sRGB.

Learn more about [WCAG contrast](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html) and [APCA](https://git.apcacontrast.com/documentation/APCA_in_a_Nutshell).

## Keyboard Shortcuts

Most shortcuts need Pika in front. Show/hide Pika and Pick pair (<kbd>⌥ ⌘ D</kbd>) work from any app; set them in Settings → Global Shortcut.

| Group | Shortcut | Action |
| --- | --- | --- |
| Pick | <kbd>⌘ D</kbd> | Pick foreground |
| Pick | <kbd>⌘ ⇧ D</kbd> | Pick background |
| Pick | <kbd>⌥ ⌘ D</kbd> | Pick foreground and background |
| Copy | <kbd>⌘ C</kbd> | Copy foreground |
| Copy | <kbd>⌘ ⇧ C</kbd> | Copy background |
| System picker | <kbd>⌘ S</kbd> | Use for foreground |
| System picker | <kbd>⌘ ⇧ S</kbd> | Use for background |
| Change format | <kbd>⌘ 1</kbd> | Format Hex |
| Change format | <kbd>⌘ 2</kbd> | Format RGB |
| Change format | <kbd>⌘ 3</kbd> | Format HSB |
| Change format | <kbd>⌘ 4</kbd> | Format HSL |
| Change format | <kbd>⌘ 5</kbd> | Format LAB |
| Change format | <kbd>⌘ 6</kbd> | Format OpenGL |
| Change format | <kbd>⌘ 7</kbd> | Format OKLCH |
| Actions | <kbd>X</kbd> | Swap colors |
| Actions | <kbd>H</kbd> | Toggle history |
| Actions | <kbd>C</kbd> | Toggle compliance |
| Actions | <kbd>P</kbd> | Toggle colour preview |
| Actions | <kbd>⌘ Z</kbd> | Undo last pick |
| Actions | <kbd>⌘ ⇧ Z</kbd> | Redo last pick |
| Actions | <kbd>⌘ ,</kbd> | Preferences |
| Actions | <kbd>⌘ Q</kbd> | Quit Pika |

## URL Triggers

You can also trigger Pika using the `pika://` URL scheme.

When picking or copying, you can append a format to the URL — `<format>` is one of `hex`, `rgb`, `hsb`, `hsl`, `lab`, `opengl`, or `oklch`. For example, `pika://pick/foreground/hex`.

| Group | URL | Action |
| --- | --- | --- |
| Pick | `pika://pick/foreground` | Pick foreground |
| Pick | `pika://pick/background` | Pick background |
| Pick | `pika://pick/contrast` | Pick foreground and background |
| Pick | `pika://pick/foreground/<format>` | Pick foreground in a specific format |
| Pick | `pika://pick/background/<format>` | Pick background in a specific format |
| System picker | `pika://system/foreground` | Use for foreground |
| System picker | `pika://system/background` | Use for background |
| Copy | `pika://copy/foreground` | Copy foreground |
| Copy | `pika://copy/background` | Copy background |
| Copy | `pika://copy/foreground/<format>` | Copy foreground in a specific format |
| Copy | `pika://copy/background/<format>` | Copy background in a specific format |
| Copy | `pika://copy/text` | Copy all colours as text |
| Copy | `pika://copy/json` | Copy all colours as JSON |
| Change format | `pika://format/hex` | Format Hex |
| Change format | `pika://format/rgb` | Format RGB |
| Change format | `pika://format/hsb` | Format HSB |
| Change format | `pika://format/hsl` | Format HSL |
| Change format | `pika://format/lab` | Format LAB |
| Change format | `pika://format/opengl` | Format OpenGL |
| Change format | `pika://format/oklch` | Format OKLCH |
| Actions | `pika://swap` | Swap colors |
| Actions | `pika://undo` | Undo last pick |
| Actions | `pika://redo` | Redo last pick |
| Set colour | `pika://set/foreground/<hex>` | Set foreground |
| Set colour | `pika://set/background/<hex>` | Set background |
| History | `pika://history/show` | Show history |
| History | `pika://history/hide` | Hide history |
| History | `pika://history/toggle` | Toggle history |
| Compliance | `pika://compliance/show` | Show compliance |
| Compliance | `pika://compliance/hide` | Hide compliance |
| Compliance | `pika://compliance/toggle` | Toggle compliance |
| Preview | `pika://preview/show` | Show colour preview |
| Preview | `pika://preview/hide` | Hide colour preview |
| Preview | `pika://preview/toggle` | Toggle colour preview |
| Windows | `pika://window/about` | Open About |
| Windows | `pika://window/help` | Open Help |
| Windows | `pika://window/preferences` | Open Preferences |
| Windows | `pika://window/splash` | Open Splash |
| Windows | `pika://window/resize/<w>/<h>` | Resize window |
| Appearance | `pika://appearance/light` | Force light appearance |
| Appearance | `pika://appearance/dark` | Force dark appearance |
| Appearance | `pika://appearance/system` | Restore system appearance |

## Development

- [Xcode](https://developer.apple.com/xcode/)
- Swift Package Manager
- [Mint](https://github.com/yonaskolb/Mint)

## Getting Started with Contributing

Make sure you have [mint](https://github.com/yonaskolb/Mint) installed, and bootstrap the toolchain dependencies:

```
brew install mint
mint bootstrap
```

Open `Pika.xcodeproj` and to run the project. [Sparkle](https://github.com/sparkle-project/Sparkle) requires that you have a [team and signing profile set](https://github.com/MonitorControl/MonitorControl/discussions/638) for the project, or it will crash with a dyld / signal SIGABRT error.

If you run into any problems, please [detail them in an issue](https://github.com/superhighfives/pika/issues/new/).

## Contributions

Any and all contributions are welcomed. Check for [open issues](https://github.com/superhighfives/pika/issues), look through the [project roadmap](https://github.com/superhighfives/pika/projects/1), help [translating the app](https://github.com/superhighfives/pika/tree/main/Pika/Assets) and [submit a PR](https://github.com/superhighfives/pika/compare).

## Dependencies and Thanks

- [Sparkle](https://github.com/sparkle-project/Sparkle) software update framework
- [Defaults](https://github.com/sindresorhus/Defaults)
- [Keyboard Shortcuts](https://github.com/sindresorhus/KeyboardShortcuts)
- [Launch At Login](https://github.com/sindresorhus/LaunchAtLogin)
- [NSWindow+Fade](https://gist.github.com/BenLeggiero/1ec89e5979bf88ca13e2393fdab15ecc)
- [Sweetercolor](https://github.com/jathu/sweetercolor) colour extension library for Swift (slightly tweaked for NSColor, rather than UIColor)
- [Color names](https://github.com/meodai/color-names)
- Metal shader code in part thanks to [Smiley](https://github.com/aslr/Smiley)

And a huge thank you to [Stormnoid](https://twitter.com/stormoid) for the incredible [2D vector field visualisation](https://www.shadertoy.com/view/4tfSRj) on Shadertoy.
