<img width="128" alt="Pika icon, an eye against a multicoloured background" src="https://user-images.githubusercontent.com/449385/103492506-4dbd3700-4e23-11eb-97ca-44a959f171c6.png">

# Pika

Pika (pronounced pi·kuh, like picker) is an easy to use, open-source, native colour picker for macOS. Pika makes it easy to quickly find colours onscreen, in the format you need, so you can get on with being a speedy, successful designer.

**Download the latest version of the app at [superhighfives.com/pika](https://superhighfives.com/pika).**

Learn more about the [motivations behind the project](https://medium.com/superhighfives/introducing-pika-d7725c397585).

<img width="768" alt="Screenshots of the dark and light Pika interface" src="https://user-images.githubusercontent.com/449385/103492507-4e55cd80-4e23-11eb-9366-d31c2bb74030.png">

## Requirements

### OS

- macOS Catalina (Version 10.15+) and newer

### Development

- [Xcode](https://developer.apple.com/xcode/) 12.3
- Swift Package Manager
- [Mint](https://github.com/yonaskolb/Mint)

## Getting started with contributing

Make sure you have [mint](https://github.com/yonaskolb/Mint) installed, and bootstrap the toolchain dependencies:

```
brew install mint
mint bootstrap
```

Open `Pika.xcodeproj` and you should be good to go. If you into any problems, please [detail them in an issue](https://github.com/superhighfives/pika/issues/new/).

## Contributions

Any and all contributions are welcomed. Check for [open issues](https://github.com/superhighfives/pika/issues), look through the [project roadmap](https://github.com/superhighfives/pika/projects/1), and [submit a PR](https://github.com/superhighfives/pika/compare).

## Dependencies and thanks

- [Sparkle](https://github.com/sparkle-project/Sparkle) software update framework
- [Defaults](https://github.com/sindresorhus/Defaults)
- [Keyboard Shortcuts](https://github.com/sindresorhus/KeyboardShortcuts)
- [Launch At Login](https://github.com/sindresorhus/LaunchAtLogin)
- [NSWindow+Fade](https://gist.github.com/BenLeggiero/1ec89e5979bf88ca13e2393fdab15ecc)
- [Sweetercolor](https://github.com/jathu/sweetercolor) colour extension library for Swift (slightly tweaked for NSColor, rather than UIColor)
- Metal shader code in part thanks to [Smiley](https://github.com/aslr/Smiley)

And a huge thank you to [Stormnoid](https://twitter.com/stormoid) for the incredible [2D vector field visualisation](https://www.shadertoy.com/view/4tfSRj) on Shadertoy.
