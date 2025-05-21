#!/usr/bin/env zsh

zsh_ai_bug_report() {
    local error_found=false # Initialize error flag

    _print_header "Environment"
    _print_environment

    _print_header "Key bindings"
    _print_key_bindings

    _print_header "Dependencies"
    _print_dependencies

    _print_header "Zsh plugins (Example)"
    _print_zsh_plugins_example # Renamed and adapted

    _print_header "Configuration"
    _print_configuration

    _print_header "Functionality tests"
    _perform_functionality_tests

    _print_header "Compatibility check"
    _perform_compatibility_check

    _print_header "Logs from the last session"
    _print_logs

    if [[ "$error_found" == "true" ]]; then
        echo "❌ Problems were found (see output above for details)."
        return 1
    fi
    return 0
}

_print_header() {
    local title="$1"
    # Using ANSI escape codes for bold blue
    echo -e "\033[1;34m$title\033[0m"
    echo ""
}

_print_environment() {
    echo "Zsh version: $ZSH_VERSION"
    if [[ -f /etc/os-release ]]; then
        # Attempt to read PRETTY_NAME, handling cases where it might not exist or be empty
        local pretty_name
        pretty_name=$(awk -F= '/^PRETTY_NAME=/ {gsub(/"/, "", $2); print $2}' /etc/os-release)
        if [[ -n "$pretty_name" ]]; then
            echo "Running on $pretty_name"
        else
            echo "Running on $(cat /etc/issue.net 2>/dev/null || cat /etc/issue 2>/dev/null || echo 'Unknown Linux')"
        fi
        echo "Machine hardware: $(uname -m)"
    elif command -v sw_vers &>/dev/null; then
        echo "Running on macOS $(sw_vers -productVersion)"
        echo "Machine hardware: $(uname -m)"
    else
        echo "❌ Running on an unsupported platform or OS detection failed."
        error_found=true
    fi
    echo ""
}

_print_key_bindings() {
    echo "Key bindings related to _zsh_ai (from 'bindkey'):"
    bindkey | grep --color=never '_zsh_ai' || echo "No _zsh_ai bindings found."
    echo ""
    # Zsh keymap detection is different.
    # This shows the current keymap for the 'main' (emacs/vi insert) state.
    echo "Current ZLE keymap: $(bindkey -v | awk '/^"main" / {print $2}') (typically emacs or viins)"
    echo ""
}

_print_dependencies() {
    if [[ ! -d ~/.zsh-ai ]]; then
        echo "❌ The virtual environment '$(echo ~/.zsh-ai)' does not exist."
        error_found=true
        return
    fi

    if command -v uv &>/dev/null; then
        echo "😎 This system has uv installed."
    fi
    echo "Python version used by zsh-ai: $(~/.zsh-ai/bin/python3 --version 2>/dev/null || echo 'not found')"
    if command -v python3 &>/dev/null; then
        echo "Python version used by the system: $(python3 --version 2>/dev/null || echo 'not found')"
    fi
    echo "Zsh version: $ZSH_VERSION"
    # git version is fine
    if command -v git &>/dev/null; then
        git --version
    else
        echo "git not found."
    fi
    echo ""

    ~/.zsh-ai/bin/pip list 2>/dev/null || echo "pip list failed or venv not fully functional."
    if ! ~/.zsh-ai/bin/pip list 2>/dev/null | grep -q 'zsh_ai'; then # Assuming package name might change
        echo "❌ The Python package 'zsh_ai' (or equivalent) could not be found in the venv."
        # error_found=true # This might be too strict if the package name is different
    fi
    echo ""
}

_print_zsh_plugins_example() {
    echo "Listing Zsh plugins is specific to the plugin manager (e.g., Oh My Zsh, Antigen, Zinit)."
    echo "Example for Oh My Zsh (if applicable):"
    if [[ -n "$ZSH_CUSTOM" && -d "$ZSH_CUSTOM/plugins" ]]; then
        echo "Oh My Zsh custom plugins: $(ls "$ZSH_CUSTOM/plugins")"
    elif [[ -n "$ZSH_PLUGINS_ALIAS_TIPS" ]]; then # Oh My Zsh specific check
        echo "Oh My Zsh plugins loaded (from \$plugins array): ${plugins[@]}"
    else
        echo "Could not determine Zsh plugin manager or list plugins."
    fi
    echo ""
}

_print_configuration() {
    local config_file=~/.config/zsh-ai.ini
    if [[ ! -f "$config_file" ]]; then
        echo "😕 The configuration file '$config_file' does not exist."
    else
        echo "Configuration from $config_file (API keys and passwords redacted):"
        # Use sed to remove lines containing api_key or password
        sed -e '/api_key/d' -e '/password/d' "$config_file"
    fi
    echo ""
}

_perform_functionality_tests() {
    local config_file=~/.config/zsh-ai.ini
    if [[ ! -f "$config_file" ]]; then
        echo "😴 No configuration available. Skipping functionality tests."
        echo ""
        return
    fi

    echo "🔥 Running functionality tests..."
    local start_time result duration

    # Test codify
    start_time=$(date +%s)
    # Ensure _zsh_ai_codify is available and executable
    if command -v _zsh_ai_codify &>/dev/null; then
        result=$(_zsh_ai_codify 'print the current date')
        duration=$(( $(date +%s) - start_time ))
        echo "codify 'print the current date' -> '$result' (in $duration seconds)"
    else
        echo "❌ _zsh_ai_codify function not found."
        error_found=true
    fi

    # Test explain
    start_time=$(date +%s)
    if command -v _zsh_ai_explain &>/dev/null; then
        result_explain=$(_zsh_ai_explain 'date')
        # Zsh string manipulation: remove leading "# " and shorten
        local trimmed_result="${result_explain##\# }" # Remove leading "# "
        local shortened_result="${trimmed_result:0:50}" # Shorten to 50 chars
        duration=$(( $(date +%s) - start_time ))
        echo "explain 'date' -> '$shortened_result' (in $duration seconds)"
    else
        echo "❌ _zsh_ai_explain function not found."
        error_found=true
    fi
    echo ""
}

_perform_compatibility_check() {
    # This function assumes the main zsh-ai.plugin.zsh has been sourced
    # and `supported_versions` array is available globally.
    if [[ -z "$supported_versions" ]]; then
        echo "🔔 'supported_versions' array not found. Cannot perform compatibility check."
        echo "   Ensure the main zsh-ai.plugin.zsh script is sourced correctly."
        # error_found=true # Decide if this is critical enough to set error_found
        echo ""
        return
    fi

    local current_python_version
    current_python_version=$(~/.zsh-ai/bin/python3 -c 'import platform; major, minor, _ = platform.python_version_tuple(); print(f"{major}.{minor}")' 2>/dev/null)

    if [[ -z "$current_python_version" ]]; then
        echo "❌ Could not determine Python version from virtual environment ~/.zsh-ai."
        error_found=true
        echo ""
        return
    fi

    if [[ ! " ${supported_versions[@]} " =~ " ${current_python_version} " ]]; then
        echo "🔔 This plugin has not been tested with Python $current_python_version and may not function correctly."
        echo "The following versions are supported: ${supported_versions[*]}"
        error_found=true
    else
        echo "👍 Python $current_python_version is supported."
    fi
    echo ""
}

_print_logs() {
    local log_file_path
    # Ensure lookup_setting is executable and provides a valid path
    if ! command -v ~/.zsh-ai/bin/lookup_setting &> /dev/null; then
        echo "❌ lookup_setting script not found or not executable in ~/.zsh-ai/bin/"
        error_found=true
        return
    fi

    log_file_path=$(~/.zsh-ai/bin/lookup_setting "log" 2>/dev/null)
    if [[ -z "$log_file_path" || "$log_file_path" == "None" ]]; then # Handle if lookup_setting returns "None" or empty
        echo "😴 Log file path not configured or lookup_setting failed."
        return
    fi
    
    # Expand tilde if present
    eval "expanded_log_file_path=$log_file_path"

    if [[ ! -f "$expanded_log_file_path" ]]; then
        echo "😴 No log file available at '$expanded_log_file_path'."
        return
    fi

    echo "Displaying last session from log file: $expanded_log_file_path"
    # Use awk to find the last session
    awk '
    /----- BEGIN SESSION -----/ {
        session_lines = ""
    }
    {
        if (session_lines != "") session_lines = session_lines "\n" $0
        else session_lines = $0
    }
    END {
        if (session_lines != "") print session_lines
        else print "No session markers found in log."
    }
    ' "$expanded_log_file_path"

    if [[ "$(~/.zsh-ai/bin/lookup_setting "debug" 2>/dev/null)" != "True" ]]; then
        echo ""
        echo "🙏 Consider enabling debug mode to get more log output (set debug=True in $HOME/.config/zsh-ai.ini)."
    fi
}

# Make the main function callable if the script is sourced.
# If run directly, it could also be executed.
# zsh_ai_bug_report

# Ensure helper functions are prefixed to avoid clashes if this file is sourced.
# The script relies on _zsh_ai_codify and _zsh_ai_explain being available
# from other translated function files if this script is sourced in an environment
# where they are also loaded.
