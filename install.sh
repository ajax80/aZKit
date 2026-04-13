#!/bin/bash
# aZKit Installation Script
# Sets up the autonomous agent system safely

set -e

echo "═══════════════════════════════════════════════════════════"
echo "aZKit - Autonomous Agent System"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check requirements
echo "Checking requirements..."
for cmd in bash curl jq dnf apt flatpak; do
    if command -v "$cmd" &> /dev/null; then
        echo "✅ $cmd found"
    fi
done

echo ""
echo "Setting up agents directory..."

# Create agents directory
AGENTS_DIR="$HOME/agents"
mkdir -p "$AGENTS_DIR/logs"

# Copy agent scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/agents/interactive-install.sh" "$AGENTS_DIR/"
chmod +x "$AGENTS_DIR/interactive-install.sh"

echo "✅ Agents installed to $AGENTS_DIR"

# Check for API key
echo ""
echo "Checking for ANTHROPIC_API_KEY..."

if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo ""
    echo "⚠️  ANTHROPIC_API_KEY not found!"
    echo ""
    echo "You need a Claude API key to use aZKit."
    echo "Get one at: https://console.anthropic.com/account/keys"
    echo ""
    read -p "Enter your ANTHROPIC_API_KEY: " API_KEY

    if [ -z "$API_KEY" ]; then
        echo "❌ API key required. Exiting."
        exit 1
    fi

    # Add to bashrc
    echo ""
    echo "Adding API key to ~/.bashrc..."
    echo "export ANTHROPIC_API_KEY=\"$API_KEY\"" >> ~/.bashrc
    echo "✅ API key saved to ~/.bashrc"
else
    echo "✅ ANTHROPIC_API_KEY already set"
fi

# Add ask function to bashrc if not present
if ! grep -q "^ask()" ~/.bashrc; then
    echo ""
    echo "Adding ask() function to ~/.bashrc..."
    cat >> ~/.bashrc << 'EOF'

# aZKit - ask function
ask() {
    local prompt="$*"
    if [ -z "$prompt" ]; then
        echo "Usage: ask <question>"
        return 1
    fi

    # Route uninstall/remove requests FIRST
    if echo "$prompt" | grep -iq "uninstall\|remove.*app\|delete.*app"; then
        echo ""
        echo "🗑️  UNINSTALLING"
        echo ""
        local app_name=$(echo "$prompt" | sed 's/uninstall //g' | sed 's/remove //g' | sed 's/delete //g' | sed 's/app//g' | sed 's/\?$//' | xargs)

        if [ -z "$app_name" ]; then
            echo "Error: Couldn't determine app name"
            return 1
        fi

        echo "App to remove: $app_name"
        read -p "Confirm uninstall? (yes/no): " confirm

        if [ "$confirm" = "yes" ] || [ "$confirm" = "y" ]; then
            local pkg_name=$(echo "$app_name" | sed 's/ /-/g')
            if command -v dnf &> /dev/null; then
                eval "sudo dnf remove -y $pkg_name" 2>/dev/null || eval "sudo dnf remove -y $app_name"
            elif command -v apt &> /dev/null; then
                eval "sudo apt remove -y $pkg_name" 2>/dev/null || eval "sudo apt remove -y $app_name"
            elif command -v flatpak &> /dev/null; then
                eval "flatpak uninstall -y $pkg_name" 2>/dev/null || eval "flatpak uninstall -y $app_name"
            else
                echo "Error: Could not find package manager"
                return 1
            fi
            echo ""
            echo "✅ Uninstall complete"
        else
            echo "❌ Uninstall cancelled"
        fi
        return 0
    fi

    # Route installation requests to the agent
    if echo "$prompt" | grep -iq "install.*app\|install.*software\|install.*tool\|better.*than\|best.*for"; then
        if [ -x ~/agents/interactive-install.sh ]; then
            local task=$(echo "$prompt" | sed 's/^.*install/install/' | sed 's/please //g' | sed 's/can you //' | sed 's/\?$//')
            echo ""
            ~/agents/interactive-install.sh "$task"
            return $?
        fi
    fi

    # Default: send to Claude
    if [ -z "$ANTHROPIC_API_KEY" ]; then
        echo "Error: ANTHROPIC_API_KEY not set"
        return 1
    fi
    curl -s https://api.anthropic.com/v1/messages \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d "{\"model\":\"claude-opus-4-6\",\"max_tokens\":1024,\"messages\":[{\"role\":\"user\",\"content\":\"$prompt\"}]}" \
        | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["content"][0]["text"] if d.get("content") else "Error: " + str(d))'
}
EOF
    echo "✅ ask() function added"
fi

echo ""
echo "Reloading shell..."
source ~/.bashrc

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ Installation Complete!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Try it out:"
echo "  ask \"install the best weather app for my system\""
echo "  ask \"uninstall gnome weather\""
echo ""
echo "More info: https://github.com/ajax80/aZKit"
