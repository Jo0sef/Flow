# Flow

A free media and file downloader for iPhone (iOS 15+) with a glass UI. English and Egyptian Arabic, colour themes, pure black mode. Objective-C, UIKit, no dependencies.

**Personal use only. Download only content you own or have permission to download.** You are responsible for following the terms of the sites you use and the laws where you live. Flow is not affiliated with YouTube, Facebook, Instagram, TikTok, X or any other site. It does not bypass logins, paywalls or DRM, and only public videos work.

## What it does
- Fast downloads with several parallel connections, a downloads list, and a file manager (folders, import, rename, move, share, Trash with restore).
- Link extractors for public videos (YouTube, Facebook, Instagram, TikTok, X) with a quality picker.
- Tools: convert to MP4 or M4A, ringtone maker, remove background (people).

## Updatable extractors
All site-specific logic lives in `extractors.js`. The app runs it with JavaScriptCore and checks for a newer copy when it opens and once a day (Settings > Downloads > Extractors). It tries these addresses in order:

1. `https://raw.githubusercontent.com/Jo0sef/Flow/main/extractors.js`
2. `https://cdn.jsdelivr.net/gh/Jo0sef/Flow@main/extractors.js`
3. `https://jo0sef.github.io/Flow/extractors.js`

A downloaded file is installed only if it parses, defines `flowExtract`, has a higher `FLOW_VERSION`, passes a short self-test, and does not need a newer app (`FLOW_MIN_NATIVE`). The previous copy is kept and restored automatically if the new one fails with a code error.

To publish a fix: edit `extractors.js`, raise `FLOW_VERSION`, commit to `main`.

## Build without a Mac
`build.sh` compiles `main.m` (the concatenation of the `p*.m` parts) with clang and the iPhoneOS SDK. Put the binary, `Info.plist`, `extractors.js` and the icons in `Payload/Flow.app/`, zip `Payload` as `.ipa`, then sign with your Apple ID (3uTools, Sideloadly, AltStore).
