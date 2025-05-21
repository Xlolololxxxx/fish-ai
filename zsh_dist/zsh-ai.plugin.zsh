#!/usr/bin/env zsh

#
# Supported major.minor versions of Python.
# Unit tests are run in CI against these versions.
#
typeset -ga supported_versions=(3.9 3.10 3.11 3.12 3.13)

#
# This section contains the keybindings for zsh-ai. If you want to change the
# default keybindings, use the environment variables:
#
#   - ZSH_AI_KEYMAP_1 (defaults to Ctrl + P)
#   - ZSH_AI_KEYMAP_2 (defaults to Ctrl + Space)
#
# These should be set to the key binding escape sequence for a keyboard shortcut
# you want to use + any flags. You can get the key binding escape sequence using
# the command `showkey -a` or by examining your terminal's settings.
#

if [[ -n "$ZSH_AI_KEYMAP_1" ]]; then
    typeset -g keymap_1="$ZSH_AI_KEYMAP_1"
else
    typeset -g keymap_1="^P" # Ctrl + P
fi
if [[ -n "$ZSH_AI_KEYMAP_2" ]]; then
    typeset -g keymap_2="$ZSH_AI_KEYMAP_2"
else
    # Ctrl+Space is tricky and terminal dependent.
    # "^@" is a common representation for Ctrl+Space (ASCII NUL).
    # Some terminals might send " " (space) with a modifier.
    # For now, using "^@" as a default. Users might need to adjust.
    typeset -g keymap_2="^@" # Typically Ctrl+Space or Ctrl+@
fi

# Zsh doesn't have a direct equivalent of fish_vi_key_bindings check for simple bindkey
# We'll assume standard emacs mode bindings. If vi mode is needed, users
# often use plugins like zsh-vi-mode which handle keybindings differently.
# For now, directly use bindkey.
# TODO: Revisit if specific vi-mode insert bindings are critical.
bindkey "$keymap_1" _zsh_ai_codify_or_explain
bindkey "$keymap_2" _zsh_ai_autocomplete_or_fix


#
# This section contains the plugin lifecycle hooks.
# In Zsh, these are typically functions called by the plugin manager or user.
#

# Corresponds to _fish_ai_install
zsh_ai_install() {
    set_python_version
    if command -v uv &>/dev/null; then
        echo "🥡 Setting up a virtual environment using uv..."
        uv venv --seed --python "$python_version" ~/.zsh-ai
    else
        echo "🥡 Setting up a virtual environment using venv..."
        "python$python_version" -m venv ~/.zsh-ai
    fi
    if [[ $? -ne 0 ]]; then
        echo "💔 Installation failed. Check previous terminal output for details."
        return 1
    fi

    echo "🍬 Installing dependencies. This may take a few seconds..."
    ~/.zsh-ai/bin/pip -qq install "$(get_installation_url)"
    if [[ $? -ne 0 ]]; then
        echo "💔 Installation from '$(get_installation_url)' failed. Check previous terminal output for details."
        return 2
    fi
    python_version_check
    notify_custom_keybindings
    symlink_truststore
    autoconfig_gh_models
    if [[ ! -f ~/.config/zsh-ai.ini ]]; then
        echo "🤗 You must create a configuration file before the plugin can be used!"
    fi
}

# Corresponds to _fish_ai_update
zsh_ai_update() {
    set_python_version
    if command -v uv &>/dev/null; then
        uv venv --seed --python "$python_version" ~/.zsh-ai # uv handles upgrades implicitly
    else
        # venv --upgrade is not standard, recreate or ensure paths are updated
        # For simplicity, we'll rely on pip to upgrade packages in the existing venv
        # If python version changes, a full reinstall might be more robust.
        echo "Ensuring virtual environment exists for Python $python_version..."
        "python$python_version" -m venv ~/.zsh-ai
    fi
    if [[ $? -ne 0 ]]; then
        echo "💔 Update process failed during venv setup. Check previous terminal output for details."
        return 1
    fi

    echo "🐍 Now using $(~/.zsh-ai/bin/python3 --version)."
    echo "🍬 Upgrading dependencies. This may take a few seconds..."
    ~/.zsh-ai/bin/pip install -qq --upgrade "$(get_installation_url)"
    if [[ $? -ne 0 ]]; then
        echo "💔 Upgrade failed. Check previous terminal output for details."
        return 2
    fi
    python_version_check
    notify_custom_keybindings
    symlink_truststore
    warn_plaintext_api_keys
}

# Corresponds to _fish_ai_uninstall
zsh_ai_uninstall() {
    if [[ -d ~/.zsh-ai ]]; then
        echo "💣 Nuking the virtual environment..."
        rm -r ~/.zsh-ai
    fi
    # Consider removing config file as well, or provide an option
    # if [[ -f ~/.config/zsh-ai.ini ]]; then
    #   echo "🗑️ Removing configuration file ~/.config/zsh-ai.ini"
    #   rm ~/.config/zsh-ai.ini
    # fi
}

set_python_version() {
    if [[ -n "$ZSH_AI_PYTHON_VERSION" ]]; then
        echo "🐍 Using Python $ZSH_AI_PYTHON_VERSION as specified by the environment variable 'ZSH_AI_PYTHON_VERSION'."
        typeset -g python_version="$ZSH_AI_PYTHON_VERSION"
    elif command -v uv &>/dev/null; then
        # Use the last supported version of Python
        typeset -g python_version="${supported_versions[-1]}"
    else
        # Use the Python version provided by the system (python3)
        # Check if python3 is available
        if command -v python3 &>/dev/null; then
            typeset -g python_version="3" # Will use `python3` command
        else
            echo "💔 python3 command not found. Please install Python 3 or set ZSH_AI_PYTHON_VERSION."
            return 1
        fi
    fi
}

get_installation_url() {
    # TODO: Zsh plugin managers (like Oh My Zsh, Antigen, Zgen, etc.) have different ways
    # to determine a plugin's source directory.
    # For now, defaulting to current directory, assuming manual install or development.
    # A more robust solution would check common plugin manager paths or use an env var.
    # Example for Oh My Zsh custom plugin:
    # local plugin_dir="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai"
    # if [[ -d "$plugin_dir" ]]; then
    #   echo -n "$plugin_dir"
    #   return
    # fi
    if [[ -n "$ZSH_AI_PLUGIN_DIR" ]]; then
        echo -n "$ZSH_AI_PLUGIN_DIR"
    else
        # Fallback for manual install or if run from plugin dir
        echo -n "$(pwd)"
    fi
    # Original logic for GitHub installation:
    # else
    #   # Install from GitHub (example, needs a way to get org/repo)
    #   echo -n "zsh-ai@git+https://github.com/ORG/REPO"
}

python_version_check() {
    local current_python_version
    current_python_version=$(~/.zsh-ai/bin/python3 -c 'import platform; major, minor, _ = platform.python_version_tuple(); print(f"{major}.{minor}")')
    if [[ $? -ne 0 ]]; then
        echo "🔔 Could not determine Python version from virtual environment."
        return
    fi

    # Zsh array check
    if [[ ! " ${supported_versions[@]} " =~ " ${current_python_version} " ]]; then
        echo "🔔 This plugin has not been tested with Python $current_python_version and may not function correctly."
        echo "The following versions are supported: ${supported_versions[*]}" # Print all elements
        echo "Consider setting the environment variable 'ZSH_AI_PYTHON_VERSION' to a supported version and reinstalling the plugin. For example:"
        # TODO: Implement Zsh equivalent for set_color or use tput / ANSI codes
        echo ""
        echo "  # Example for reinstalling with a specific Python version:"
        echo "  export ZSH_AI_PYTHON_VERSION=${supported_versions[-1]}"
        echo "  # (Command to remove/reinstall plugin depends on plugin manager)"
        echo "  # e.g., rm -rf ~/.zsh-ai && zsh_ai_install"
        echo ""
    fi
}

# Use the bundle with CA certificates trusted by the OS.
symlink_truststore() {
    local certifi_path
    certifi_path=$(~/.zsh-ai/bin/python3 -c 'import certifi; print(certifi.where())' 2>/dev/null)
    if [[ -z "$certifi_path" ]]; then
        echo "🔔 Could not determine certifi path. Skipping CA certificate symlinking."
        return
    fi

    if [[ -f /etc/ssl/certs/ca-certificates.crt ]]; then
        echo "🔑 Symlinking to certificates stored in /etc/ssl/certs/ca-certificates.crt."
        ln -snf /etc/ssl/certs/ca-certificates.crt "$certifi_path"
    elif [[ -f /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem ]]; then
        echo "🔑 Symlinking to certificates stored in /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem."
        ln -snf /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem "$certifi_path"
    elif [[ -f /etc/ssl/cert.pem ]]; then
        echo "🔑 Symlinking to certificates stored in /etc/ssl/cert.pem."
        ln -snf /etc/ssl/cert.pem "$certifi_path"
    else
        echo "🔔 No common system CA bundle found to symlink. Using default certifi bundle."
    fi
}

# Warn about plaintext API keys.
warn_plaintext_api_keys() {
    if grep -q "^api_key" ~/.config/zsh-ai.ini 2>/dev/null; then
        # TODO: Implement Zsh equivalent for set_color or use tput / ANSI codes
        echo "🚨 One or more plaintext API keys are stored in ~/.config/zsh-ai.ini."
        echo "Consider moving them to your keyring. (Keyring integration for Zsh might require 'keyring' Python package and backend)."
        # echo "Use a command like 'zsh_ai_put_api_key' (if implemented)."
    fi
}

# Deploy configuration for GitHub Models.
autoconfig_gh_models() {
    if [[ -f ~/.config/zsh-ai.ini ]]; then
        return
    fi
    if ! command -v gh &>/dev/null; then
        return
    fi
    local gh_token
    gh_token=$(gh auth token 2>/dev/null)
    if [[ -z "$gh_token" ]]; then
        return
    fi
    # Assuming 'gh ext list' and grep works similarly.
    if ! gh ext list | grep "gh models" &>/dev/null; then
        return
    fi

    # Create directory if it doesn't exist
    mkdir -p ~/.config

    echo "[zsh-ai]" >>~/.config/zsh-ai.ini
    echo "configuration = github" >>~/.config/zsh-ai.ini
    echo "" >>~/.config/zsh-ai.ini
    echo "[github]" >>~/.config/zsh-ai.ini
    echo "provider = self-hosted" >>~/.config/zsh-ai.ini
    echo "server = https://models.inference.ai.azure.com" >>~/.config/zsh-ai.ini
    echo "api_key = $gh_token" >>~/.config/zsh-ai.ini
    echo "model = gpt-4o-mini" >>~/.config/zsh-ai.ini

    echo "😺 Access to GitHub Models has been automatically configured for you in ~/.config/zsh-ai.ini!"
}

# Show a progress indicator.
# TODO: This function is highly dependent on shell specifics (fish_right_prompt).
# A simple Zsh equivalent might involve using RPROMPT or precmd/preexec hooks.
# For now, a placeholder or simpler version.
show_progess_indicator() {
    # Zsh's RPROMPT is the typical place for right-side content.
    # This function might need to be integrated with RPROMPT handling or
    # use a more complex method to temporarily draw at the right of the current line.
    # A simple spinner at the current cursor position:
    # echo -n '⏳'
    # To clear it, you'd need to echo '\b \b'.
    # For now, let's just print a message as the original complex cursor math is hard to translate directly.
    echo -n '⏳ Processing...' # Simplified
}

# Print a message when custom keybindings are used.
notify_custom_keybindings() {
    if [[ -n "$ZSH_AI_KEYMAP_1_CUSTOM" ]]; then # Assuming a flag set if custom
        echo "🎹 Using custom keyboard shortcut for action 1 (originally '$keymap_1')."
    fi
    if [[ -n "$ZSH_AI_KEYMAP_2_CUSTOM" ]]; then # Assuming a flag set if custom
        echo "🎹 Using custom keyboard shortcut for action 2 (originally '$keymap_2')."
    fi
}

# Placeholder for the actual AI functions that will be bound
# These would call the Python backend.
_zsh_ai_codify_or_explain() {
    echo "Function _zsh_ai_codify_or_explain called. (Not yet implemented)"
    # Example: Call your python script
    # local query="$(zle get-line)" # Get current line from ZLE
    # local result
    # result=$(~/.zsh-ai/bin/python3 -m zsh_ai.main --explain "$query")
    # zle reset-prompt
    # print -P "%F{green}$result%f" # Print result with color
    # zle accept-line # Or some other ZLE widget
}

_zsh_ai_autocomplete_or_fix() {
    echo "Function _zsh_ai_autocomplete_or_fix called. (Not yet implemented)"
    # Example:
    # local query="$(zle get-line)"
    # local result
    # result=$(~/.zsh-ai/bin/python3 -m zsh_ai.main --autocomplete "$query")
    # zle backward-delete-char -n $#query # Delete current line
    # zle -U "$result" # Insert suggested text
}

# Example of how to load for Oh My Zsh (place in custom/plugins/zsh-ai/zsh-ai.plugin.zsh):
# And then add 'zsh-ai' to plugins array in .zshrc

# Standard Zsh plugin loading often involves sourcing this file.
# If you want to run install automatically when sourced, you could add:
# if [[ ! -d ~/.zsh-ai ]]; then
#   zsh_ai_install
# fi

echo "zsh-ai plugin loaded. Run 'zsh_ai_install' if this is the first time."

# TODO:
# - Finalize keybinding sequences for Ctrl+Space across terminals.
# - Implement robust `get_installation_url` for various plugin managers.
# - Replace `set_color` calls with Zsh equivalents (tput or ANSI escapes).
# - Implement the actual ZLE widget functions `_zsh_ai_codify_or_explain` and `_zsh_ai_autocomplete_or_fix`
#   to call the Python backend and interact with ZLE.
# - Test `python_version_check` array logic thoroughly.
# - `show_progress_indicator` needs a proper Zsh implementation if visual progress is desired.
# - `warn_plaintext_api_keys` needs color.
# - `notify_custom_keybindings`: The original Fish script checks if FISH_AI_KEYMAP_1 itself is set.
#   My Zsh version checks for ZSH_AI_KEYMAP_1_CUSTOM which is not how the original worked.
#   Corrected: check ZSH_AI_KEYMAP_1 and ZSH_AI_KEYMAP_2 against their defaults.

# Corrected notify_custom_keybindings logic
notify_custom_keybindings() {
    local default_keymap_1="^P"
    local default_keymap_2="^@"
    if [[ -n "$ZSH_AI_KEYMAP_1" && "$ZSH_AI_KEYMAP_1" != "$default_keymap_1" ]]; then
        echo "🎹 Using custom keyboard shortcut '$ZSH_AI_KEYMAP_1' instead of default Ctrl+P."
    fi
    if [[ -n "$ZSH_AI_KEYMAP_2" && "$ZSH_AI_KEYMAP_2" != "$default_keymap_2" ]]; then
        # Note: Default for Ctrl+Space might vary, "^@" is a common one.
        echo "🎹 Using custom keyboard shortcut '$ZSH_AI_KEYMAP_2' instead of default Ctrl+Space (or equivalent)."
    fi
}
