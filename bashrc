# shellcheck shell=bash
# Interactive non-login shells (typing `bash`, some editor terminals) read
# ~/.bashrc, never ~/.bash_profile — so without this they ran with bash's
# defaults, including HISTFILESIZE=500, and on exit truncated the shared
# ~/.bash_history to 500 lines. Login shells (every Ghostty tab) read only
# ~/.bash_profile, which doesn't source this file, so nothing runs twice.
# shellcheck source=bash_profile
[ -r "${HOME}/.bash_profile" ] && . "${HOME}/.bash_profile"
