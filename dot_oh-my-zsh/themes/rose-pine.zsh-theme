# -*- mode: sh; -*-
# vim: set ft=sh :
# Rose Pine Theme based on Dracula Theme
#
# https://github.com/rose-pine/rose-pine-theme
#
# Adapted from Dracula Theme
# Copyright 2019, All rights reserved
#
# Code licensed under the MIT license
# http://zenorocha.mit-license.org
#
# @author Zeno Rocha <hi@zenorocha.com>
# @maintainer Avalon Williams <avalonwilliams@protonmail.com>
# @adapted [Your Name] - Rose Pine adaptation

# Initialization {{{
source ${0:A:h}/lib/async.zsh
autoload -Uz add-zsh-hook
setopt PROMPT_SUBST
async_init
PROMPT=''
# }}}

# Rose Pine Colors {{{
# Base: #191724 (dark background)
# Surface: #1f1d2e (lighter background)
# Overlay: #26233a (lightest background)
# Muted: #6e6a86 (muted foreground)
# Subtle: #908caa (subtle foreground)
# Text: #e0def4 (primary foreground)
# Love: #eb6f92 (red)
# Gold: #f6c177 (yellow/orange)
# Rose: #ebbcba (pink/rose)
# Pine: #31748f (teal/blue)
# Foam: #9ccfd8 (cyan)
# Iris: #c4a7e7 (purple)
# }}}

# Options {{{
# Set to 0 to disable the git status
ROSEPINE_DISPLAY_GIT=${ROSEPINE_DISPLAY_GIT:-1}

# Set to 1 to show the date
ROSEPINE_DISPLAY_TIME=${ROSEPINE_DISPLAY_TIME:-0}

# Set to 1 to show the 'context' segment
ROSEPINE_DISPLAY_CONTEXT=${ROSEPINE_DISPLAY_CONTEXT:-0}

# Changes the arrow icon
ROSEPINE_ARROW_ICON=${ROSEPINE_ARROW_ICON:-❯ }

# Set to 1 to use a new line for commands
ROSEPINE_DISPLAY_NEW_LINE=${ROSEPINE_DISPLAY_NEW_LINE:-0}

# Set to 1 to show full path of current working directory
ROSEPINE_DISPLAY_FULL_CWD=${ROSEPINE_DISPLAY_FULL_CWD:-0}

# function to detect if git has support for --no-optional-locks
rosepine_test_git_optional_lock() {
	local git_version=${DEBUG_OVERRIDE_V:-"$(git version | cut -d' ' -f3)"}
	local git_version="$(git version | cut -d' ' -f3)"
	# test for git versions < 2.14.0
	case "$git_version" in
		[0-1].*)
			echo 0
			return 1
			;;
		2.[0-9].*)
			echo 0
			return 1
			;;
		2.1[0-3].*)
			echo 0
			return 1
			;;
	esac

	# if version > 2.14.0 return true
	echo 1
}

# use --no-optional-locks flag on git
ROSEPINE_GIT_NOLOCK=${ROSEPINE_GIT_NOLOCK:-$(rosepine_test_git_optional_lock)}

# time format string
if [[ -z "$ROSEPINE_TIME_FORMAT" ]]; then
	ROSEPINE_TIME_FORMAT="%-H:%M"
	# check if locale uses AM and PM
	if locale -ck LC_TIME 2>/dev/null | grep -q '^t_fmt="%r"$'; then
		ROSEPINE_TIME_FORMAT="%-I:%M%p"
	fi
fi
# }}}

# Status segment {{{
rosepine_arrow() {
	if [[ "$1" = "start" ]] && (( ! ROSEPINE_DISPLAY_NEW_LINE )); then
		print -P "$ROSEPINE_ARROW_ICON"
	elif [[ "$1" = "end" ]] && (( ROSEPINE_DISPLAY_NEW_LINE )); then
		print -P "\n$ROSEPINE_ARROW_ICON"
	fi
}

# arrow is Pine (blue) if last command was successful, Love (red) if not, 
# turns Gold (yellow) in vi command mode
PROMPT+='%(1V:%F{221}:%(?:%F{73}:%F{204}))%B$(rosepine_arrow start)'
# }}}

# Time segment {{{
rosepine_time_segment() {
	if (( ROSEPINE_DISPLAY_TIME )); then
		print -P "%D{$ROSEPINE_TIME_FORMAT} "
	fi
}

PROMPT+='%F{73}%B$(rosepine_time_segment)'
# }}}

# User context segment {{{
rosepine_context() {
	if (( ROSEPINE_DISPLAY_CONTEXT )); then
		if [[ -n "${SSH_CONNECTION-}${SSH_CLIENT-}${SSH_TTY-}" ]] || (( EUID == 0 )); then
			echo '%n@%m '
		else
			echo '%n '
		fi
	fi
}

PROMPT+='%F{183}%B$(rosepine_context)'
# }}}

# Directory segment {{{
rosepine_directory() {
	if (( ROSEPINE_DISPLAY_FULL_CWD )); then
		print -P '%~ '
	else
		print -P '%c '
	fi
}

PROMPT+='%F{73}%B$(rosepine_directory)'
# }}}

# Custom variable {{{
custom_variable_prompt() {
	[[ -z "$ROSEPINE_CUSTOM_VARIABLE" ]] && return
	echo "%F{221}$ROSEPINE_CUSTOM_VARIABLE "
}

PROMPT+='$(custom_variable_prompt)'
# }}}

# Async git segment {{{

rosepine_git_status() {
	(( ! ROSEPINE_DISPLAY_GIT )) && return
	cd "$1"
	
	local ref branch lockflag
	
	(( ROSEPINE_GIT_NOLOCK )) && lockflag="--no-optional-locks"

	ref=$(=git $lockflag symbolic-ref --quiet HEAD 2>/dev/null)

	case $? in
		0)   ;;
		128) return ;;
		*)   ref=$(=git $lockflag rev-parse --short HEAD 2>/dev/null) || return ;;
	esac

	branch=${ref#refs/heads/}
	
	if [[ -n $branch ]]; then
		echo -n "${ZSH_THEME_GIT_PROMPT_PREFIX}${branch}"

		local git_status icon
		git_status="$(LC_ALL=C =git $lockflag status 2>&1)"
		
		if [[ "$git_status" =~ 'new file:|deleted:|modified:|renamed:|Untracked files:' ]]; then
			echo -n "$ZSH_THEME_GIT_PROMPT_DIRTY"
		else
			echo -n "$ZSH_THEME_GIT_PROMPT_CLEAN"
		fi

		echo -n "$ZSH_THEME_GIT_PROMPT_SUFFIX"
	fi
}

rosepine_git_callback() {
	ROSEPINE_GIT_STATUS="$3"
	zle && zle reset-prompt
	async_stop_worker rosepine_git_worker rosepine_git_status "$(pwd)"
}

rosepine_git_async() {
	async_start_worker rosepine_git_worker -n
	async_register_callback rosepine_git_worker rosepine_git_callback
	async_job rosepine_git_worker rosepine_git_status "$(pwd)"
}

add-zsh-hook precmd rosepine_git_async

PROMPT+='$ROSEPINE_GIT_STATUS'

ZSH_THEME_GIT_PROMPT_CLEAN=") %F{73}%B✔ "
ZSH_THEME_GIT_PROMPT_DIRTY=") %F{221}%B✗ "
ZSH_THEME_GIT_PROMPT_PREFIX="%F{152}%B("
ZSH_THEME_GIT_PROMPT_SUFFIX="%f%b"
# }}}

# Linebreak {{{
PROMPT+='%(1V:%F{221}:%(?:%F{73}:%F{204}))%B$(rosepine_arrow end)'
# }}}

# define widget without clobbering old definitions
rosepine_defwidget() {
	local fname=rosepine-wrap-$1
	local prev=($(zle -l -L "$1"))
	local oldfn=${prev[4]:-$1}

	# if no existing zle functions, just define it normally
	if [[ -z "$prev" ]]; then
		zle -N $1 $2
		return
	fi

	# if already defined, return
	[[ "${prev[4]}" = $fname ]] && return
	
	oldfn=${prev[4]:-$1}

	zle -N rosepine-old-$oldfn $oldfn

	eval "$fname() { $2 \"\$@\"; zle rosepine-old-$oldfn -- \"\$@\"; }"

	zle -N $1 $fname
}

# ensure vi mode is handled by prompt
rosepine_zle_update() {
	if [[ $KEYMAP = vicmd ]]; then
		psvar[1]=vicmd
	else
		psvar[1]=''
	fi

	zle reset-prompt
	zle -R
}

rosepine_defwidget zle-line-init rosepine_zle_update
rosepine_defwidget zle-keymap-select rosepine_zle_update

# Ensure effects are reset
PROMPT+='%f%b'
