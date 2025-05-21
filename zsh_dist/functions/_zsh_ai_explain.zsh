#!/usr/bin/env zsh

# Description: Turn a command into a comment using AI.
# @param command The command string.
_zsh_ai_explain() {
    local command="$1"
    local output

    if [[ "$(~/.zsh-ai/bin/lookup_setting "debug")" == "True" ]]; then
        output="$(~/.zsh-ai/bin/explain "$command")"
    else
        output="$(~/.zsh-ai/bin/explain "$command" 2>/dev/null)"
    fi
    echo -n "$output"
}
