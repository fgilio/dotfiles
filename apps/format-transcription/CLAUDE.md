# FormatTranscription.app

Background-only macOS app: formats a whisper transcript into Markdown with Apple's on-device model (FoundationModels). On-device only: no network, no API keys. Needs macOS 26+ with Apple Intelligence.

## Caller

The app is launched by the Transcribe Audio Quick Action: `workflows/Services/Transcribe Audio.workflow/Contents/document.wflow` (Automator-generated XML, edited in Automator, never by hand). Read it before changing the app's arguments, output path or exit behavior.

## Why a .app wrapper instead of a CLI tool?

Finder Quick Actions run under Automator's XPC runner (WorkflowServiceRunner), which is a sandboxed context with restricted TCC entitlements. Every non-.app approach fails there:

1. **Compiled CLI binary** (`swiftc` output): FoundationModels silently fails (exit 1) in the Quick Action XPC context
2. **`swift` interpreter**: TCC denies file access to `~/Downloads` for child processes spawned by Automator
3. **`launchctl submit`**: same TCC denial on `~/Downloads`
4. **`osascript -e 'do shell script "..."'`**: doesn't escape the parent process sandbox

A proper `.app` bundle (even background-only, ad-hoc signed) gets its own TCC identity. On first run, macOS prompts the user to allow Downloads access, and FoundationModels works because the app has proper process attribution.

Key: Terminal.app has `com.apple.private.tcc.allow-prompting` for `kTCCServiceAll`. Automator doesn't. The .app wrapper is the simplest way to get proper TCC prompting.

## Build and test

```bash
./build.sh && cp -R build/FormatTranscription.app ~/Applications/   # fresh.sh does both on setup
open -W -n -g ~/Applications/FormatTranscription.app --args ~/Downloads/some.txt ~/Downloads/some.md
automator -i ~/Downloads/audio.opus ~/Library/Services/Transcribe\ Audio.workflow   # full pipeline
```

## Key Decisions

- **Ad-hoc signing** (`codesign --sign -`): sufficient for TCC. Real signing only needed for distribution

`bin/check` pins the on-device invariants across `Info.plist` (`LSBackgroundOnly`, `LSMinimumSystemVersion`), `build.sh` (`-target`) and `main.swift` (FoundationModels imported, FoundationNetworking absent), and checks a locally built bundle too. A target bump changes all of them plus `MACOS_TARGET` in `bin/check`, then rebuilds, or the commit fails.

## Prompt Engineering Notes

- "Keep the ORIGINAL LANGUAGE" is critical: without it, the ~3B model translates everything to English
- "without wrapping it in code fences": the model tends to wrap output in ```markdown blocks

## Gotchas

- **TCC**: the Downloads-folder grant is keyed to the bundle ID (`com.fgilio.format-transcription`); a rebuild keeps it, a new ID re-prompts.
- **Whisper language**: the workflow uses `-l auto` for whisper-cli. Default is `-l en` which forces English transcription (translation, not transcription)
