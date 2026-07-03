#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

PS1='[\u@\h \W]\$ '

# History settings
HISTSIZE=1000
HISTFILESIZE=2000

# Aliases
alias ls='ls --color=auto'
alias grep='grep --colour=auto'
alias diff='diff --color=auto'
alias c='claude --dangerously-skip-permissions'
