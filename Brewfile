# Taps
# Homebrew now requires explicit trust for third-party taps (see fresh.sh).
# laravel/moat repo has no `homebrew-` prefix, so the short form resolves to a
# 404; the explicit URL is required (matches Moat's own install instructions).
tap 'laravel/moat', 'https://github.com/laravel/moat' # moat (security auditing)
tap 'modem-dev/tap'       # hunk
tap 'steipete/tap'        # codexbar
tap 'teamookla/speedtest' # official Ookla speedtest CLI

# Binaries
brew 'awscli'
brew 'bash' # Latest Bash version
brew 'nushell'
brew 'bat'
brew 'btop' # Modern htop alternative
brew 'coreutils' # Those that come with macOS are outdated
brew 'ffmpeg'
brew 'whisper-cpp' # Local audio transcription (Whisper via Metal)
brew 'mozjpeg' # JPEG compression for screenshot optimization
brew 'vips' # Image processing for screenshot optimization
brew 'gh'
brew 'git'
brew 'git-lfs'
brew 'git-open'
brew 'glab' # GitLab CLI
brew 'grep'
brew 'lazygit' # Terminal UI for git
brew 'fd'    # Fast find replacement, used with fzf
brew 'fzf'   # Fuzzy finder (ctrl-r / ctrl-t / alt-c)
brew 'oha' # HTTP load generator (Rust, faster than hey)
brew 'httpie'
brew 'jq' # JSON processor
brew 'mackup'
brew 'mas' # Mac App Store manager
brew 'mole' # System cleanup utility
brew 'mkcert' # Local HTTPS certificates
brew 'pkgconf' # renamed from pkg-config; https://github.com/driesvints/dotfiles/issues/20
brew 'prettyping'
brew 'qpdf'
brew 'ripgrep' # Fast grep alternative
brew 'speedtest' # Official Ookla CLI (replaced deprecated speedtest-cli)
brew 'starship' # Shell prompt
brew 'tesseract'
brew 'tesseract-lang' # Extra OCR language data
brew 'tree'
brew 'wget'
brew 'yazi' # Terminal file manager
brew 'yt-dlp' # YouTube downloader (replaces youtube-dl)
brew 'zoxide' # Smarter cd command
brew 'zsh-autosuggestions'
brew 'zsh-syntax-highlighting' # Live command coloring; sourced BEFORE autosuggestions (order rationale in .zshrc)
brew 'lefthook'   # Git hooks manager
brew 'shellcheck' # Shell script static analysis
brew 'shfmt'      # Shell script formatter (bash/sh; not zsh)
brew 'actionlint' # GitHub Actions workflow linter
brew 'luacheck'   # Lua static analysis (Hammerspoon config)
brew 'gitleaks'   # Secret scanning (pre-commit + CI)
brew 'moat'       # Security posture auditing for GitHub orgs/repos (laravel/moat)
brew 'mtr'        # traceroute and ping in one tool
brew 'pandoc'     # Document converter
brew 'tokei'      # Source line counter
brew 'jpegoptim'  # Lossless JPEG optimiser
brew 'pdftk-java' # PDF page and metadata surgery
brew 'epubcheck'  # EPUB validator (publica.la files)
brew 'marp-cli'   # Markdown to slide decks
brew 'hugo'       # Static site generator

# Development
# PHP is managed by Laravel Herd (see cask 'herd' below), not Homebrew
brew 'biome' # Fast formatter/linter
# Bun is installed by fresh.sh instead: the formula lags every release
brew 'cloudflared' # Cloudflare tunnel
# Composer is bundled with Herd
brew 'imagemagick'
# PHP language server used by Zed (zed/settings.json). Installed here instead of
# letting the Zed PHP extension manage its own copy: a binary on PATH is also
# usable by CLI agents, and Zed prefers the PATH build when present.
brew 'phpantom-lsp'
brew 'cmake'            # Required to build native node and python modules
brew 'go'
brew 'rustup'           # Rust toolchain manager; rustc/cargo are not brew-managed
brew 'pnpm'
brew 'pipx'             # Isolated installs of python CLIs
brew 'git-filter-repo'  # History rewriting for repo migrations
brew 'k6'               # Load testing
brew 'pgloader'         # MySQL to Postgres migration
brew 'pscale'           # PlanetScale CLI
brew 'mysql-client@8.4', link: false # keg-only; PATH is set in .zshrc. No server
brew 'modem-dev/tap/hunk' # Terminal diff viewer; shadows homebrew/core/hunk
brew 'ollama'           # Local LLM runtime. LaunchAgent is off: no models pulled

# Apps
# @beta on purpose: stable lags months behind, the 2.x line targets macOS 26+
cask 'thaw@beta' # Menu bar manager (maintained Ice fork)
cask '1password'
cask '1password-cli'
cask 'ghostty'
cask 'cloudflare-warp' # Cloudflare WARP VPN (1.1.1.1)
cask 'discord'
cask 'orbstack' # Docker/Linux VMs (replaces Docker Desktop; provides docker CLI)
cask 'dockdoor' # Window preview on Dock hover
cask 'finetune' # Per-app volume mixer
cask 'github'
cask 'gitup-app'
cask 'handbrake-app'
cask 'imageoptim'
cask 'google-drive'
cask 'google-chrome'
cask 'gcloud-cli' # Google Cloud CLI (gcloud, gsutil, bq)
cask 'firefox@developer-edition'
cask 'slack'
cask 'sublime-text'
cask 'zed'
cask 'cursor'
# Agent CLIs exec'd by bin/cl, bin/cx, bin/cr, bin/oc
# Codex is installed by fresh.sh instead: the cask lags every release
cask 'codexbar' # Codex menu-bar companion (steipete/tap)
cask 'cursor-cli'
cask 'tableplus'
cask 'cyberduck'
cask 'postman'
cask 'herd' # Manages PHP versions, nginx, dnsmasq for Laravel dev
cask 'calibre'
cask 'grandperspective'
cask 'hammerspoon' # macOS automation via Lua scripts
cask 'exodus'
cask 'mac-mouse-fix'
cask 'namechanger'
cask 'nightowl'
cask 'rectangle'
cask 'spotify'
cask 'stremio'
cask 'visual-studio-code'
cask 'vlc'
cask 'zoom'
cask 'the-unarchiver'
cask 'jetbrains-toolbox'
cask 'pocket-casts'
cask 'raycast'
cask 'tinkerwell'
cask 'whatsapp'
cask 'stats' # Menu-bar system monitor
cask 'android-platform-tools' # adb and fastboot
cask 'mysql-shell' # mysqlsh
cask 'session-manager-plugin' # AWS SSM sessions for awscli

# Dictation
# Self-updates via Sparkle, so `brew upgrade --cask` skips it and the recorded
# version goes stale. That is expected; do not use --greedy here.
cask 'fluidvoice'  # altic-dev/FluidVoice - local STT, Parakeet/Whisper models

# Quicklook
# Unsigned app - requires right-click > Open on first launch to bypass Gatekeeper
cask 'syntax-highlight'
cask 'thumbhost3mf'
cask 'quickjson'

# Fonts
cask 'font-open-sans'
cask 'font-roboto'
cask 'font-jetbrains-mono'
cask 'font-source-code-pro'
cask 'font-source-sans-3'  # renamed from font-source-sans-pro
cask 'font-source-serif-4' # renamed from font-source-serif-pro

# Mac App Store
mas "Actions", id: 1586435171
mas "Battery Indicator", id: 1206020918
mas "Compare Folders", id: 816042486
mas "Dato", id: 1470584107
mas "Day Progress", id: 6450280202
mas "Developer", id: 640199958
mas "Folder Quick Look", id: 6753110395
mas "Key Codes", id: 414568915
mas "Keynote", id: 409183694
mas "Lungo", id: 1263070803
mas "Menu Bar Calendar", id: 1558360383
mas "Numbers", id: 409203825
mas "Pages", id: 409201541
mas "Short Run", id: 6745427035
mas "Speedtest", id: 1153157709
mas "TestFlight", id: 899247664
