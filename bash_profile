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
shopt -s histappend
# Flush each command to the history file immediately so parallel tabs share it
PROMPT_COMMAND='history -a'

# Shell options
shopt -s cdspell 2>/dev/null
shopt -s dirspell 2>/dev/null
shopt -s globstar 2>/dev/null
shopt -s checkwinsize

# Homebrew (ARM: /opt/homebrew, Intel: /usr/local)
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Completions (installed via brew)
[[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]] && . "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"

# Catppuccin Mocha FZF colors (matches Ghostty theme)
export FZF_DEFAULT_OPTS='--color=fg:#cdd6f4,bg:#1e1e2e,hl:#f38ba8 --color=fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8 --color=info:#cba6f7,prompt:#a6e3a1,pointer:#f5e0dc --color=marker:#b4befe,spinner:#f5e0dc,header:#94e2d5'
eval "$(fzf --bash)"

# Tools
eval "$(mise activate bash)"

# Prompt
eval "$(starship init bash)"

# Zoxide — replaces cd while preserving cd -, cd .., etc. (must be last)
eval "$(zoxide init bash --cmd=cd)"

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
unalias gm 2>/dev/null
alias gm='/opt/homebrew/bin/gm'

# Machine-local env vars and secrets — never committed. API tokens,
# per-machine PATH entries, and work-specific config belong here.
[[ -r "${HOME}/.bash_profile.local" ]] && . "${HOME}/.bash_profile.local"
