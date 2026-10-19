# shellcheck shell=bash
# Interactive bash setup. Package installs and git config live in the
# Brewfile and gitconfig — see install.sh.

export BASH_SILENCE_DEPRECATION_WARNING=1
export CLICOLOR=1
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export EDITOR="nvim"
export PATH="${HOME}/.local/bin:${PATH}"

# History
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups
# Timestamps: `history` shows when each command ran (stored as #epoch lines)
HISTTIMEFORMAT='%F %T  '
shopt -s histappend
# Flush each command to the history file as it runs; Ctrl+R (below) reads
# the other tabs' commands back in before searching
PROMPT_COMMAND='history -a'

# Shell options
shopt -s cdspell 2>/dev/null
shopt -s dirspell 2>/dev/null
shopt -s globstar 2>/dev/null
shopt -s checkwinsize
# `cd <project>` from anywhere: zoxide's cd tries a plain `cd` first, which
# looks through these — so a repo under ~/src works even before zoxide has
# learned it. The empty first entry is the current directory, so a local
# directory still wins — and unlike ".", it doesn't make cd print the path.
# Not exported: scripts that cd would start searching it too.
CDPATH=:~:~/src

# Homebrew (ARM: /opt/homebrew, Intel: /usr/local). What `brew shellenv`
# prints, written out: running it cost ~20 ms per shell.
for HOMEBREW_PREFIX in /opt/homebrew /usr/local ""; do
    [ -x "$HOMEBREW_PREFIX/bin/brew" ] && break
done
if [ -n "$HOMEBREW_PREFIX" ]; then
    export HOMEBREW_PREFIX HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar" HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX"
    [ "$HOMEBREW_PREFIX" = /usr/local ] && HOMEBREW_REPOSITORY=/usr/local/Homebrew
    export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin${PATH+:$PATH}"
    export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}"
else
    unset HOMEBREW_PREFIX
fi

# Completions, on demand. bash-completion sources every file in Homebrew's
# etc/bash_completion.d at startup (~50 files, ~70 ms); pointed at nothing, it
# doesn't, and _brew_completion_load sources a command's file on its first
# Tab instead. Files are named after their command, bar the few mapped here.
# Must come before fzf, which wraps whatever `complete -D` handler it finds.
export BASH_COMPLETION_COMPAT_DIR=/nonexistent
# shellcheck source=/dev/null
[[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]] && . "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
_brew_completion_load() {
    local cmd="${1##*/}" file
    case "$cmd" in
        aws) file=aws_bash_completer ;;
        kctx) file=kubectx ;;
        kns) file=kubens ;;
        http | https) file=httpie ;;
        *) file="$cmd" ;;
    esac
    file="$HOMEBREW_PREFIX/etc/bash_completion.d/$file"
    # shellcheck source=/dev/null
    if [[ -r "$file" ]] && . "$file" && complete -p "$cmd" &> /dev/null; then
        return 124 # tells bash to retry with the completion just defined
    fi
    declare -F _comp_complete_load > /dev/null && _comp_complete_load "$@"
}
complete -D -F _brew_completion_load

# `eval "$(tool init)"` cost 5-25 ms per tool per shell. For fzf, starship and
# zoxide the script only changes when the tool does (checked: same output in
# different environments), so it's cached in ~/.cache/bash-init and
# regenerated when the tool's Homebrew install receipt is newer (the binary's
# own mtime is its build date, older than the install). Not from Homebrew:
# evaluated live, as before.
_cached_init() {
    local tool="$1" receipt="$HOMEBREW_PREFIX/opt/$1/INSTALL_RECEIPT.json"
    shift
    local cache="$HOME/.cache/bash-init/$tool.bash"
    if [[ -f "$receipt" ]]; then
        if [[ ! "$cache" -nt "$receipt" ]]; then
            mkdir -p "${cache%/*}"
            "$tool" "$@" > "$cache.tmp" && mv "$cache.tmp" "$cache"
        fi
        # shellcheck source=/dev/null
        . "$cache"
    else
        eval "$("$tool" "$@")"
    fi
}

# Catppuccin Mocha FZF colors (matches Ghostty theme)
export FZF_DEFAULT_OPTS='--color=fg:#cdd6f4,bg:#1e1e2e,hl:#f38ba8 --color=fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8 --color=info:#cba6f7,prompt:#a6e3a1,pointer:#f5e0dc --color=marker:#b4befe,spinner:#f5e0dc,header:#94e2d5'
# Walk with fd instead of find: faster, includes dotfiles, and skips .git plus
# anything .gitignored (node_modules, build output).
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
# Ctrl+T: pick files, with a bat preview
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:300 {}'"
# Alt+C: cd into a directory, with a tree preview
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons --color=always {} | head -200'"
# `**<Tab>` completion (vim **<Tab>, cd **<Tab>) uses the same fd walk
_fzf_compgen_path() { fd --hidden --exclude .git . "$1"; }
_fzf_compgen_dir() { fd --type d --hidden --exclude .git . "$1"; }
_cached_init fzf --bash
# fzf's Ctrl+R searches this shell's in-memory history, so commands run in
# other tabs since this one opened were missing. `history -n` reads in what
# they've appended first. Only here, not at every prompt: Up-arrow keeps
# cycling this tab's own commands until Ctrl+R is used.
__fzf_history_all_tabs__() {
    builtin history -n
    __fzf_history__
}
if [[ ${BASH_VERSINFO[0]} -ge 4 ]] && declare -F __fzf_history__ > /dev/null; then
    bind -m emacs-standard -x '"\C-r": __fzf_history_all_tabs__'
    bind -m vi-command -x '"\C-r": __fzf_history_all_tabs__'
    bind -m vi-insert -x '"\C-r": __fzf_history_all_tabs__'
fi

# Tools
# Not cached: its output embeds the PATH it was generated with
eval "$(mise activate bash)"

# Prompt
# --print-full-init: plain `init bash` prints a one-liner that runs this anyway
_cached_init starship init bash --print-full-init

# Zoxide — replaces cd while preserving cd -, cd .., etc. (must be last)
_cached_init zoxide init bash --cmd=cd

# Aliases — modern CLI replacements.
# Deliberately not aliasing `find` to `fd`: they take incompatible arguments,
# so `find . -name '*.py'` would misbehave rather than fail loudly. Use `fd`.
alias cat='bat --paging=never'
alias ls='eza --icons --group-directories-first'
alias ll='eza --icons --group-directories-first -la'
alias lt='eza --icons --group-directories-first --tree --level=2'
alias du='dust'
alias top='btop'
alias diff='delta'
alias vim='nvim'
# gm is GraphicsMagick. Pin it to the Homebrew binary so a `gm` alias or
# function from elsewhere can't shadow it — oh-my-bash's git aliases made it `git merge`.
unalias gm 2>/dev/null
# shellcheck disable=SC2139  # expanding now is the point: a fixed path
alias gm="${HOMEBREW_PREFIX}/bin/gm"

# Machine-local env vars and secrets — never committed. API tokens,
# per-machine PATH entries, and work-specific config belong here.
# shellcheck source=/dev/null
[[ -r "${HOME}/.bash_profile.local" ]] && . "${HOME}/.bash_profile.local"
