#!/usr/bin/env zsh

# Simulate argparse for -c/--contributors
local show_contributors=false
if [[ "$1" == "-c" || "$1" == "--contributors" ]]; then
    show_contributors=true
fi

current_tag=$(git tag --sort=-creatordate | sed -n 1p)
previous_tag=$(git tag --sort=-creatordate | sed -n 2p)

if [[ -z "$current_tag" || -z "$previous_tag" ]]; then
    echo "❌ Could not determine current or previous tag. Ensure you have at least two tags."
    exit 1
fi

# $A..$B selects all commits in B not in A
# Read commits into an array, one commit hash per line
commits_raw=$(git log "$previous_tag..$current_tag" --format='%H')
# Check if commits_raw is empty
if [[ -z "$commits_raw" ]]; then
    echo "ℹ️ No commits found between $previous_tag and $current_tag."
    # Output a minimal valid changelog or exit, depending on desired behavior
    echo "# What's new?"
    echo ""
    echo "No changes in this release."
    exit 0
fi


# Read breaking changes into an array
breaking_changes_raw=$(git log --grep='BREAKING CHANGE:' "$previous_tag..$current_tag" --format='%H')

declare -a commits fixes feats perfs deps breaking_changes
commits=(${(f)commits_raw}) # Split by newline
if [[ -n "$breaking_changes_raw" ]]; then
    breaking_changes=(${(f)breaking_changes_raw}) # Split by newline
fi


for commit_hash in "${commits[@]}"; do
    local message_header
    message_header=$(git log --format=%s -n 1 "$commit_hash")
    
    # Extract commit_type and commit_description
    # Using awk for safer parsing of ": " delimiter
    local commit_type=$(echo "$message_header" | awk -F': ' '{print $1; exit}')
    local commit_description=$(echo "$message_header" | awk -F': ' '{$1=""; sub(/^ */, ""); print; exit}')

    local short_hash=$(git log --format=%h -n 1 "$commit_hash")
    local long_hash=$(git log --format=%H -n 1 "$commit_hash") # Already have this as commit_hash
    local commit_link="https://github.com/realiserad/fish-ai/commit/$long_hash" # Update repo name if this script is for zsh-ai
    local message="$commit_description (in commit [\`#$short_hash\`]($commit_link))"

    if [[ "$commit_type" =~ ^fix(\([a-z]+\))?!?$ ]]; then
        fixes+=("$message")
    fi
    if [[ "$commit_type" =~ ^feat(\([a-z]+\))?!?$ ]]; then
        feats+=("$message")
    fi
    if [[ "$commit_type" =~ ^perf(\([a-z]+\))?!?$ ]]; then
        perfs+=("$message")
    fi
    if [[ "$commit_type" == "chore(deps)" ]]; then
        deps+=("$message")
    fi
done

echo "# What's new?"

if (( ${#fixes[@]} > 0 )); then
    echo ""
    echo "## 🐛 Bug fixes"
    echo ""
    for fix in "${fixes[@]}"; do
        echo "- $fix"
    done
fi

if (( ${#feats[@]} > 0 )); then
    echo ""
    echo "## 🌟 New features and improvements"
    echo ""
    for feat in "${feats[@]}"; do
        echo "- $feat"
    done
fi

if (( ${#perfs[@]} > 0 )); then
    echo ""
    echo "## ⚡ Performance improvements"
    echo ""
    for perf in "${perfs[@]}"; do
        echo "- $perf"
    done
fi

if (( ${#deps[@]} > 0 )); then
    echo ""
    echo "## ⬆ Dependency updates"
    echo ""
    for dep in "${deps[@]}"; do
        echo "- $dep"
    done
fi

if (( ${#breaking_changes[@]} > 0 )); then
    echo ""
    echo "## 💥 Breaking changes"
    for bc_hash in "${breaking_changes[@]}"; do
        local breaking_change_text
        # Extract text after "BREAKING CHANGE:"
        # Using sed for this specific transformation
        breaking_change_text=$(git log -n 1 "$bc_hash" --format="%b" | sed -n '/^BREAKING CHANGE:/s/^BREAKING CHANGE: *//p')
        echo ""
        local short_bc_hash=$(git rev-parse --short "$bc_hash")
        local bc_commit_link="https://github.com/realiserad/fish-ai/commit/$bc_hash" # Update repo name
        echo "$breaking_change_text See commit [\`#$short_bc_hash\`]($bc_commit_link) for more details."
    done
fi

if [[ "$show_contributors" == true ]]; then
    echo ""
    echo "## 🙌 Contributors"
    echo ""
    echo "The following developers made this release possible:"
    echo ""
    # Corrected range for contributors: it should be from previous_tag to current_tag
    local contributors_list_raw
    contributors_list_raw=$(git log "$previous_tag..$current_tag" --pretty=format:"%an ([%ae](mailto:%ae))" | sort -u)
    declare -a contributors_list
    contributors_list=(${(f)contributors_list_raw})

    for contributor in "${contributors_list[@]}"; do
        echo "- $contributor"
    done
fi
