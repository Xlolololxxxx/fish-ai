#!/usr/bin/env zsh

# Description: Fix a command using AI.
# @param previous_command The previous command string to fix.
_zsh_ai_fix() {
    local previous_command="$1"
    local output

    if [[ "$(~/.zsh-ai/bin/lookup_setting "debug")" == "True" ]]; then
        output="$(~/.zsh-ai/bin/fix "$previous_command")"
    else
        output="$(~/.zsh-ai/bin/fix "$previous_command" 2>/dev/null)"
    fi
    echo -n "$output"
}
