#!/usr/bin/env zsh

if ! command -v what-bump &>/dev/null; then
    echo "❌ 'what-bump' is not installed."
    echo "See https://docs.rs/crate/what-bump/latest for installation instructions."
    exit 1
fi

git fetch --all >/dev/null
start_hash=$(git show-ref --hash refs/remotes/origin/main)
# Ensure start_hash is not empty before proceeding
if [[ -z "$start_hash" ]]; then
    echo "❌ Could not get hash for refs/remotes/origin/main. Ensure the remote is configured and fetched."
    exit 1
fi

main_version=$(git show "$start_hash:pyproject.toml" | grep version | head -n 1 | cut -d'"' -f2)
current_version=$(cat pyproject.toml | grep version | head -n 1 | cut -d '"' -f2)

# Ensure main_version is not empty before calling what-bump
if [[ -z "$main_version" ]]; then
    echo "❌ Could not extract version from pyproject.toml on main branch."
    exit 1
fi

next_version=$(what-bump --from "$main_version" "$start_hash")

if [[ "$main_version" == "$next_version" ]]; then
    echo "No version bump needed based on main branch version ($main_version)."
    exit 0
fi
if [[ "$current_version" == "$next_version" ]]; then
    echo "Current version ($current_version) is already the next version ($next_version)."
    exit 0
fi

# Check if next_version is empty (e.g. what-bump failed or no changes)
if [[ -z "$next_version" ]]; then
    echo "ℹ️ 'what-bump' did not suggest a new version. No changes made."
    exit 0
fi

# Using a temporary file for sed -i on macOS compatibility (though -i '' should work on Linux too)
# For broader compatibility, especially if GNU sed is not guaranteed:
sed -i.bak -E "s/^version = .+/version = \"$next_version\"/" pyproject.toml && rm pyproject.toml.bak
# If GNU sed is assumed:
# sed -i -E "s/^version = .+/version = \"$next_version\"/" pyproject.toml

echo "🎉 The version has been bumped from $current_version to $next_version."
echo "To accept the change, run the following commands:"
echo "  git add pyproject.toml"
echo "  git commit --amend --no-edit --no-verify"
# The original script exits 1 here, suggesting this is an informative "action needed" state.
exit 1
