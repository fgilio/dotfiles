# ZSH Profile
alias zsh-e="edit ~/.zshrc"
alias zsh-r="source ~/.zshrc"

# Edit HOSTS file
alias hosts-e="edit /etc/hosts"

# Show/Hide .dotfiles
alias dfiles-s="defaults wite com.apple.finder AppleShowAllFiles YES; killall Finder /System/Library/CoreServices/Finder.app"
alias dfiles-h="defaults write com.apple.finder AppleShowAllFiles NO; killall Finder /System/Library/CoreServices/Finder.app"

# Servers
alias php-srv="open http://localhost:4444 && php -S localhost:4444"

# Copy Public Keys
alias copy-ssh="cat ~/.ssh/id_rsa.pub | pbcopy"

alias h='history'
alias rm='rm -i'
alias cp='cp -iv'
alias mv='mv -iv'
alias mkdir='mkdir -pv'

# Colorful 'ls' implementation
alias ls='ls -G'
# Detailed 'ls' implementation
alias ll='ls -FGlAhp'

alias ..='cd ..'
alias ~="cd ~"
alias c='clear'
alias r='~ && c'

f () {
    open -a Finder ./
}

# Edit file or folder
edit() {
    if [ -z "$1" ] ; then
        sublime .
    else
        sublime $1
    fi
}

alias dir-size="du -hs"
trash () { command mv "$@" ~/.Trash ; }     # trash:        Moves a file to the MacOS trash

alias ipinfo="curl ipinfo.io"
alias myip=ipinfo

alias flushDNS='dscacheutil -flushcache'

alias a="php artisan"
alias t="php artisan tinker"

alias ocr='screencapture -i ~/tmp/screenshot.png && tesseract ~/tmp/screenshot.png stdout | pbcopy && rm -f ~/tmp/screenshot.png'

alias top="sudo htop"

alias ping='prettyping --nolegend'

## Laravel and PHP development
alias artisan="php artisan"
alias tinker="php artisan tinker"
alias ptest="php ./vendor/phpunit/phpunit/phpunit"
alias phpstorm="~/phpstorm"
alias vapor="php vendor/bin/vapor"

################
################
# GIT aliases
alias nah='git reset --hard; git clean -df'
gdesktop () {
    open -a GitHub\ Desktop .
}
