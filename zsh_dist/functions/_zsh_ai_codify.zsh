#!/usr/bin/env zsh

# Description: Turn a comment into a command using AI.
# @param comment The comment string.
_zsh_ai_codify() {
    local comment="$1"
    local output

    if [[ "$(~/.zsh-ai/bin/lookup_setting "debug")" == "True" ]]; then
        output="$(~/.zsh-ai/bin/codify "$comment")"
    else
        output="$(~/.zsh-ai/bin/codify "$comment" 2>/dev/null)"
    fi
    echo -n "$output"
}
