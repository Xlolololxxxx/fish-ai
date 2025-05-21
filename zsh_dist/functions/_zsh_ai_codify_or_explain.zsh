#!/usr/bin/env zsh

# Description: Transform a command into a comment and vice versa using ZLE.
_zsh_ai_codify_or_explain() {
    local input="$BUFFER"
    local output

    # Assuming show_progess_indicator is available from the main plugin file
    # show_progess_indicator # Potentially problematic in ZLE, as noted before

    if [[ -z "$input" ]]; then
        return
    fi

    # Check if the input starts with "# "
    if [[ "${input:0:2}" == "# " ]]; then
        # Call the _zsh_ai_codify function (needs to be defined/translated)
        output=$(_zsh_ai_codify "$input")
    else
        # Call the _zsh_ai_explain function (needs to be defined/translated)
        output=$(_zsh_ai_explain "$input")
    fi

    if [[ -n "$output" ]]; then
        BUFFER="$output"
        CURSOR=${#output} # Move cursor to the end
    fi

    zle .redisplay
}
