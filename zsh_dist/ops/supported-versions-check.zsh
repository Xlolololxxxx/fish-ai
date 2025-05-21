#!/usr/bin/env zsh

# Make sure the Python versions tested in the "Python tests" workflow
# correspond to the compatibility check being performed during the
# installation.

if ! command -v yq &>/dev/null; then
    echo "❌ 'yq' is not installed."
    echo "See https://github.com/mikefarah/yq/#install for installation instructions."
    exit 1
fi

# yq outputting multiple lines will be read into an array by zsh's `typeset -a` or `array=(${(f)"$(command)"})`
# The Fish script implicitly treats $tested_versions as a list/array.
# We'll do the same in Zsh.
typeset -a tested_versions_array
tested_versions_array=(${(f)"$(yq '.jobs."python-tests".strategy.matrix."python-version"[]' .github/workflows/python-tests.yaml)"})

# Path to the Zsh plugin file, assuming it's relative to the repo root
# This might need adjustment based on where this script is run from.
# For now, assume it's run from the repo root.
ZSH_PLUGIN_FILE="zsh_dist/zsh-ai.plugin.zsh" # Corrected path based on previous subtasks

if [[ ! -f "$ZSH_PLUGIN_FILE" ]]; then
    echo "❌ Zsh plugin file not found at $ZSH_PLUGIN_FILE"
    echo "Ensure the main plugin file has been created and the path is correct."
    exit 1
fi

# Source the Zsh plugin file to get the 'supported_versions' array.
# The 'supported_versions' should be declared as a global array (e.g., typeset -ga supported_versions)
# in the plugin file for it to be available here.
# We need to be careful about what the sourced script does (e.g., if it tries to run ZLE commands).
# For this specific check, we only need the supported_versions variable.
# A safer way would be for the plugin file to *only* define variables if sourced with a specific flag,
# or for this script to parse the variable directly from the file without full sourcing.
# However, for direct translation:
source "$ZSH_PLUGIN_FILE"

# Check if supported_versions array is available after sourcing
if ! (( ${+supported_versions[@]} )); then
    echo "❌ 'supported_versions' array not defined or empty in $ZSH_PLUGIN_FILE."
    echo "Ensure it's declared as a global array (e.g., typeset -ga supported_versions)."
    exit 1
fi


# Convert arrays to strings for comparison, ensuring elements are sorted for consistency
# This handles cases where order might differ but content is the same.
# Sorting also normalizes space-separated vs newline-separated elements if they become strings.
local tested_versions_str sorted_tested_str
local supported_versions_str sorted_supported_str

# Sort and join array elements into a string
sorted_tested_str=$(echo ${(F)tested_versions_array} | tr ' ' '\n' | sort | paste -sd ' ')
sorted_supported_str=$(echo ${(F)supported_versions} | tr ' ' '\n' | sort | paste -sd ' ')


if [[ "$sorted_tested_str" != "$sorted_supported_str" ]]; then
    echo "Version mismatch detected!"
    echo "Supported versions (from $ZSH_PLUGIN_FILE): '${supported_versions[@]}'"
    echo "Tested versions (from .github/workflows/python-tests.yaml): '${tested_versions_array[@]}'"
    echo ""
    echo "Sorted Supported: '$sorted_supported_str'"
    echo "Sorted Tested:   '$sorted_tested_str'"
    echo ""
    echo "Please update the 'supported_versions' array in '$ZSH_PLUGIN_FILE' to match the GitHub workflow."
    exit 1
else
    echo "✅ Supported versions in '$ZSH_PLUGIN_FILE' match the versions in GitHub Actions."
    echo "Supported: '${supported_versions[@]}'"
    echo "Tested:    '${tested_versions_array[@]}'"
fi

exit 0
