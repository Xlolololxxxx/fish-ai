#!/usr/bin/env zsh

# Description: Autocomplete the current command or fix the previous command using ZLE.
_zsh_ai_autocomplete_or_fix() {
    local previous_status=$?
    local input="$BUFFER"
    local output
    local previous_command

    # Assuming show_progess_indicator is available from the main plugin file
    # and has been translated to a Zsh function.
    # If it's a simple echo, it might interfere with ZLE.
    # For now, let's call it. If it causes issues, it might need to be removed
    # or integrated differently for ZLE widgets.
    # show_progess_indicator # This might print to stdout, potentially messing with ZLE.
                             # Consider a ZLE-specific way to show progress if needed.

    if [[ -z "$input" && $previous_status -ne 0 ]]; then
        # Fix the previous command.
        # `fc -ln -1` gets the last command.
        previous_command=$(fc -ln -1)
        # Remove leading whitespace that fc might add
        previous_command="${previous_command##*( )}"

        # Call the _zsh_ai_fix function (which needs to be defined/translated)
        output=$(_zsh_ai_fix "$previous_command")
        if [[ -n "$output" ]]; then
            BUFFER="$output"
            CURSOR=${#output} # Move cursor to the end
        fi
    elif [[ -n "$input" ]]; then
        # Autocomplete the current command.
        local current_cursor_pos=$CURSOR
        # Call the _zsh_ai_autocomplete function (which needs to be defined/translated)
        output=$(_zsh_ai_autocomplete "$input" "$current_cursor_pos")

        if [[ -n "$output" ]]; then
            local input_len=${#input}
            local output_len=${#output}
            local completion_length=$((output_len - input_len))

            BUFFER="$output"
            CURSOR=$((current_cursor_pos + completion_length))
        fi
    fi

    zle .redisplay
}
