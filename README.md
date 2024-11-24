<img width="128" alt="Pika icon, an eye against a multicoloured background" src="https://user-images.githubusercontent.com/449385/103492506-4dbd3700-4e23-11eb-97ca-44a959f171c6.png">

# Pika

Pika (pronounced pi·kuh, like picker) is an easy to use, open-source, native colour picker for macOS. Pika makes it easy to quickly find colours onscreen, in the format you need, so you can get on with being a speedy, successful designer.

<img width="768" alt="Screenshots of the dark and light Pika interface" src="https://user-images.githubusercontent.com/449385/103492507-4e55cd80-4e23-11eb-9366-d31c2bb74030.png">

**Download the latest version of the app at:<br />
[superhighfives.com/pika](https://superhighfives.com/pika)**

Or you can install it with Homebrew:
```bash
brew install --cask pika
```

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

- macOS Catalina (Version 10.15+) and newer

## Keyboard Shortcuts

As of version `0.0.18`, Pika supports the following keyboard shortcuts:

### Pick colors
- <kbd>⌘ D</kbd>: Pick foreground
- <kbd>⌘ ⇧ D</kbd>: Pick background

### Copy colors
- <kbd>⌘ C</kbd>: Copy foreground
- <kbd>⌘ ⇧ C</kbd>: Copy background

### Use the system colour picker
- <kbd>⌘ S</kbd>: Use for foreground
- <kbd>⌘ ⇧ S</kbd>: Use for background

### Change formats
- <kbd>⌘ 1</kbd>: Format Hex
- <kbd>⌘ 2</kbd>: Format RGB
- <kbd>⌘ 3</kbd>: Format HSB
- <kbd>⌘ 4</kbd>: Format HSL

### Change colors
- <kbd>⌘ Z</kbd>: Undo last pick
- <kbd>⌘ ⇧ Z</kbd>: Redo last pick
- <kbd>X</kbd>: Swap colors

## URL Triggers

As of version `0.0.17`, you can trigger Pika using the `pika://` URL scheme.

You can also change the format by appending it to the URL when picking or copying. For example, `pika://pick/foreground/hex` (or rgb, hsl, hsb).

### Pick colors
- Pick foreground:
  - `pika://pick/foreground`
- Pick background:
  - `pika://pick/background`
- Pick colour with specific format:
  - `pika://pick/foreground/hex` (or rgb, hsl, hsb)
  - `pika://pick/background/hex` (or rgb, hsl, hsb)
- Use the system color picker for forground:
  - `pika://system/foreground`
- Use the system color picker for background:
  - `pika://system/background`

### Copy colors
- Copy foreground:
  - `pika://copy/foreground`
- Copy background:
  - `pika://copy/background`
- Copy colour with specific format:
  - `pika://copy/foreground/hex` (or rgb, hsl, hsb)
  - `pika://copy/background/hex` (or rgb, hsl, hsb)
- Copy text
  - `pika://copy/text`
- Copy JSON
  - `pika://copy/json`

### Change formats
- Format Hex
  - `pika://format/hex`
- Format RGB
  - `pika://format/rgb`
- Format HSB
  - `pika://format/hsb`
- Format HSL
  - `pika://format/hsl`

### Change colors
- Undo last pick
  - `pika://undo`
- Redo last pick
  - `pika://redo`
- Swap colors
  - `pika://swap`

## Development

- [Xcode](https://developer.apple.com/xcode/) 12.3
- Swift Package Manager
- [Mint](https://github.com/yonaskolb/Mint)

## Getting started with contributing

Make sure you have [mint](https://github.com/yonaskolb/Mint) installed, and bootstrap the toolchain dependencies:

```
brew install mint
mint bootstrap
```

Open `Pika.xcodeproj` and to run the project. [Sparkle](https://github.com/sparkle-project/Sparkle) requires that you have a [team and signing profile set](https://github.com/MonitorControl/MonitorControl/discussions/638) for the project, or it will crash with a dyld / signal SIGABRT error.

If you run into any problems, please [detail them in an issue](https://github.com/superhighfives/pika/issues/new/).

## Contributions

Any and all contributions are welcomed. Check for [open issues](https://github.com/superhighfives/pika/issues), look through the [project roadmap](https://github.com/superhighfives/pika/projects/1), and [submit a PR](https://github.com/superhighfives/pika/compare).

## Dependencies and thanks

- [Sparkle](https://github.com/sparkle-project/Sparkle) software update framework
- [Defaults](https://github.com/sindresorhus/Defaults)
- [Keyboard Shortcuts](https://github.com/sindresorhus/KeyboardShortcuts)
- [Launch At Login](https://github.com/sindresorhus/LaunchAtLogin)
- [NSWindow+Fade](https://gist.github.com/BenLeggiero/1ec89e5979bf88ca13e2393fdab15ecc)
- [Sweetercolor](https://github.com/jathu/sweetercolor) colour extension library for Swift (slightly tweaked for NSColor, rather than UIColor)
- [Color names](https://github.com/meodai/color-names)
- Metal shader code in part thanks to [Smiley](https://github.com/aslr/Smiley)

And a huge thank you to [Stormnoid](https://twitter.com/stormoid) for the incredible [2D vector field visualisation](https://www.shadertoy.com/view/4tfSRj) on Shadertoy.
