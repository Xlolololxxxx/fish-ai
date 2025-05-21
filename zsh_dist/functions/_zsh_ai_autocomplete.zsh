#!/usr/bin/env zsh

# Description: Autocomplete the current command using AI.
# @param command The command string.
# @param cursor_position The cursor position in the command string.
_zsh_ai_autocomplete() {
    local command="$1"
    local cursor_position="$2"
    local selected_completion

    if [[ "$(~/.zsh-ai/bin/lookup_setting "debug")" == "True" ]]; then
        selected_completion="$(~/.zsh-ai/bin/autocomplete "$command" "$cursor_position")"
    else
        selected_completion="$(~/.zsh-ai/bin/autocomplete "$command" "$cursor_position" 2>/dev/null)"
    fi
    echo -n "$selected_completion"
}
