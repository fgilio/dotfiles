# FormatTranscription.app

Background-only macOS app that formats raw whisper transcriptions into clean Markdown using Apple's on-device LLM (FoundationModels framework, ~3B param, Metal-accelerated).

100% local, zero network, zero API keys. Requires macOS 26+ with Apple Intelligence enabled.

## Architecture

```
Finder Quick Action (right-click audio file)
  -> Automator workflow (workflows/Services/Transcribe Audio.workflow)
    -> ffmpeg converts to WAV
    -> whisper-cli transcribes to .txt
    -> open -W -n -g FormatTranscription.app --args input.txt output.md
      -> FoundationModels LLM formats to .md
```

## Why a .app wrapper instead of a CLI tool?

Finder Quick Actions run under Automator's XPC runner (WorkflowServiceRunner), which is a sandboxed context with restricted TCC entitlements. We discovered through extensive testing that:

1. **Compiled CLI binary** (`swiftc` output) - FoundationModels silently fails (exit 1) in the Quick Action XPC context
2. **`swift` interpreter** - TCC denies file access to `~/Downloads` for child processes spawned by Automator
3. **`launchctl submit`** - Same TCC denial on `~/Downloads`
4. **`osascript -e 'do shell script "..."'`** - Doesn't escape the parent process sandbox

A proper `.app` bundle (even background-only, ad-hoc signed) gets its own TCC identity. On first run, macOS prompts the user to allow Downloads access, and FoundationModels works because the app has proper process attribution.

Key: Terminal.app has `com.apple.private.tcc.allow-prompting` for `kTCCServiceAll`. Automator doesn't. The .app wrapper is the simplest way to get proper TCC prompting.

## Files

| File | Purpose |
|------|---------|
| `main.swift` | App entry point - reads input file, calls LLM, writes output |
| `Info.plist` | Bundle config - `LSBackgroundOnly`, bundle ID, min macOS version |
| `build.sh` | Compiles with `swiftc` + `codesign`, no Xcode needed |
| `build/` | Pre-built .app committed to repo (88KB, reproducible from source) |

## Build & Install

```bash
# Build (output: build/FormatTranscription.app)
./build.sh

# Install
cp -R build/FormatTranscription.app ~/Applications/
```

`fresh.sh` does this automatically during machine setup.

## Manual Test

```bash
# Direct app invocation
open -W -n -g ~/Applications/FormatTranscription.app --args \
    ~/Downloads/some-transcription.txt \
    ~/Downloads/some-transcription.md

# Or test the full workflow via automator CLI
automator -i ~/Downloads/audio.opus ~/Library/Services/Transcribe\ Audio.workflow
```

## Key Decisions

- **`LSBackgroundOnly`** not `LSUIElement` - we're a faceless worker, no UI at all
- **`open -W -n -g`** - `-W` waits for exit, `-n` forces new instance per run, `-g` prevents focus stealing
- **Ad-hoc signing** (`codesign --sign -`) - sufficient for TCC. Real signing only needed for distribution
- **`-O` optimization flag** - faster runtime since the LLM call is the bottleneck anyway
- **`-target arm64-apple-macos26.0`** - Apple Silicon only, matches dotfiles target
- **Atomic write** (`atomically: true`) - prevents partial .md files if interrupted
- **Best-effort** - workflow uses `|| true` so .txt is always kept even if formatting fails

## Prompt Engineering Notes

- "Keep the ORIGINAL LANGUAGE" is critical - without it, the ~3B model translates everything to English
- "without wrapping it in code fences" - the model tends to wrap output in ```markdown blocks
- The model handles paragraph breaks and headers well but occasionally invents section titles

## Gotchas

- **First run after install**: macOS will prompt for Downloads folder access. The TCC grant persists for the bundle ID (`com.fgilio.format-transcription`)
- **After rebuild**: if the bundle ID stays the same, TCC grants carry over. If you change it, the user gets prompted again
- **Model availability**: check `SystemLanguageModel.default.availability` - can be `.unavailable(.deviceNotEligible)`, `.unavailable(.appleIntelligenceNotEnabled)`, or `.unavailable(.modelNotReady)`
- **Whisper language**: the workflow uses `-l auto` for whisper-cli. Default is `-l en` which forces English transcription (translation, not transcription)
