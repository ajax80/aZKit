#!/bin/bash
# Interactive install agent - present options, get approval, install, teach

source ~/.bashrc 2>/dev/null

if [ -z "$1" ]; then
  echo "Usage: interactive-install.sh \"what do you want to install\""
  exit 1
fi

task="$1"
timestamp=$(date '+%Y-%m-%d %H:%M:%S')
log_file="$HOME/agents/logs/install-$(date +%s).log"
mkdir -p "$HOME/agents/logs"

# Initialize log file
{
  echo "═══════════════════════════════════════════════════════════"
  echo "INTERACTIVE INSTALLATION AGENT"
  echo "═══════════════════════════════════════════════════════════"
  echo ""
  echo "Your request: $task"
  echo "Time: $timestamp"
  echo ""
  echo "━━━ STEP 1: Checking Memory for Similar Installs ━━━"
} | tee "$log_file"

# Check knowledge
knowledge=$(~/agents/search-knowledge.sh "$task" "solutions" 2>/dev/null | head -20)

if [ -n "$knowledge" ] && ! echo "$knowledge" | grep -q "No matching"; then
  {
    echo "✓ Found similar installation in memory!"
    echo ""
    echo "$knowledge"
    echo ""
  } | tee -a "$log_file"
else
  echo "✗ No similar installation found - researching..." | tee -a "$log_file"
fi

# Research options - OUTSIDE of subshell so variables persist
{
  echo ""
  echo "━━━ STEP 2: RESEARCHING OPTIONS ━━━"
  echo ""
} | tee -a "$log_file"

research=$(curl -s https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d "{\"model\":\"claude-opus-4-6\",\"max_tokens\":1500,\"messages\":[{\"role\":\"user\",\"content\":\"User wants to: $task\n\nProvide:\n1. Top 3-5 options (apps/tools) for this task\n2. For EACH option, list:\n   - Name\n   - Why it's good\n   - Installation command (apt/dnf/flatpak/brew)\n   - How to launch it\n3. Mark which ONE is the best overall choice\n\nFormat as numbered list. Be specific with exact commands.\"}]}" 2>/dev/null)

options=$(echo "$research" | jq -r '.content[0].text' 2>/dev/null)

if [ -z "$options" ]; then
  echo "✗ Could not research options" | tee -a "$log_file"
  exit 1
fi

echo "$options" | tee -a "$log_file"

{
  echo ""
  echo "━━━ STEP 3: ASKING YOUR PREFERENCE ━━━"
  echo ""
  echo "Which option appeals to you most? (Enter option number or name)"
  echo "Or type 'research more' for additional alternatives"
  echo ""
} | tee -a "$log_file"

# Get user choice
read -p "→ Your choice: " user_choice

if [ "$user_choice" = "research more" ]; then
  {
    echo ""
    echo "🔍 Researching more alternatives..."
    echo ""
  } | tee -a "$log_file"

  alt_research=$(curl -s https://api.anthropic.com/v1/messages \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "{\"model\":\"claude-opus-4-6\",\"max_tokens\":1500,\"messages\":[{\"role\":\"user\",\"content\":\"User wants: $task\n\nBut wants DIFFERENT/ALTERNATIVE options (not the mainstream ones).\n\nProvide lesser-known alternatives that might be better:\n1. List 3-5 more unique options\n2. Installation commands\n3. Why they might be BETTER than mainstream choices\"}]}" 2>/dev/null)

  options=$(echo "$alt_research" | jq -r '.content[0].text' 2>/dev/null)

  echo "$options" | tee -a "$log_file"

  {
    echo ""
    echo "Now, which of these alternatives would you like to try? (number or name)"
    echo ""
  } | tee -a "$log_file"

  read -p "→ Your choice: " user_choice
fi

{
  echo ""
  echo "━━━ STEP 4: CONFIRMATION ━━━"
  echo ""
  echo "You selected: $user_choice"
  echo ""
  echo "Ready to install this? (yes/no)"
  echo ""
} | tee -a "$log_file"

read -p "→ Proceed with installation? (yes/no): " approval

if [ "$approval" != "yes" ] && [ "$approval" != "y" ]; then
  {
    echo ""
    echo "❌ Installation cancelled"
  } | tee -a "$log_file"
  exit 1
fi

# Now extract the install command with options available
{
  echo ""
  echo "✅ Proceeding with installation..."
  echo ""
  echo "━━━ STEP 5: INSTALLING ━━━"
  echo ""
} | tee -a "$log_file"

# Ask Claude to extract the install command based on user choice
cmd_payload=$(jq -n --arg opts "$options" --arg choice "$user_choice" \
  '{model:"claude-opus-4-6",max_tokens:100,messages:[{role:"user",content:("From these options:\n\n" + $opts + "\n\nUser selected: " + $choice + "\n\nGive ONLY the install command for that option. For Fedora systems use dnf if available. Just the command, no explanation.")}]}')

cmd_response=$(curl -s https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d "$cmd_payload" 2>/dev/null)

raw_text=$(echo "$cmd_response" | jq -r '.content[0].text // empty' 2>/dev/null)
install_cmd=$(echo "$raw_text" | sed 's/^[`]*//' | sed 's/[`]*$//' | sed '/^bash$/d' | sed '/^$/d' | grep -E "(sudo|apt|dnf|flatpak|brew|pip|npm|yarn)" | head -1 | xargs)

{
  echo "Installing: $install_cmd"
  echo ""
} | tee -a "$log_file"

# Execute installation interactively with full TTY access
if [ -n "$install_cmd" ]; then
  echo "Running: $install_cmd" | tee -a "$log_file"
  echo "" | tee -a "$log_file"

  # Run command with full TTY access in current shell (not subshell)
  # eval executes directly, preserving all terminal control for sudo
  eval "$install_cmd"
  install_status=$?

  # Log that command completed
  {
    echo ""
    echo "(Installation output shown above)"
  } | tee -a "$log_file"
else
  {
    echo "⚠ Could not extract installation command"
    echo "Response was: $raw_text"
  } | tee -a "$log_file"
  install_status=1
fi

{
  echo ""
  if [ $install_status -eq 0 ]; then
    echo "✓ Installation successful!"
  else
    echo "⚠ Installation may have issues - check output above"
  fi

  echo ""
  echo "━━━ STEP 6: HOW TO USE ━━━"
  echo ""
} | tee -a "$log_file"

# First, extract the app name from the options based on user choice
app_name_payload=$(jq -n --arg opts "$options" --arg choice "$user_choice" \
  '{model:"claude-opus-4-6",max_tokens:50,messages:[{role:"user",content:("From these options:\n\n" + $opts + "\n\nWhat is the name of the tool/app in option " + $choice + "? Respond with ONLY the app name.")}]}')

app_name_response=$(curl -s https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d "$app_name_payload" 2>/dev/null)

app_name=$(echo "$app_name_response" | jq -r '.content[0].text // empty' 2>/dev/null | xargs | head -1)

# Get usage guide
usage_payload=$(jq -n --arg app "$app_name" \
  '{model:"claude-opus-4-6",max_tokens:800,messages:[{role:"user",content:("User just installed: " + $app + "\n\nProvide a quick start guide:\n1. How to launch it\n2. First things to try\n3. Key features\n4. Where to find help\n\nWrite for someone who just installed it.")}]}')

usage=$(curl -s https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d "$usage_payload" 2>/dev/null)

usage_guide=$(echo "$usage" | jq -r '.content[0].text' 2>/dev/null)

echo "$usage_guide" | tee -a "$log_file"

{
  echo ""
  echo "━━━ STEP 7: LEARNING ━━━"
  echo ""
} | tee -a "$log_file"

# Store for future reference
full_learning="**Task:** $task
**Chosen:** $app_name
**Installation Command:** $install_cmd
**User Approval:** Yes
**How to Use:**
$usage_guide

**Execution:** $timestamp
**Status:** Installed successfully

**For Future Agents:**
User approved and installed: $app_name
This is now a verified solution for: $task"

~/agents/learn.sh "solutions" "Install: $app_name" "$full_learning" 2>/dev/null

{
  echo "✓ Stored in collective memory for next time"
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "✅ INSTALLATION COMPLETE"
  echo "═══════════════════════════════════════════════════════════"
} | tee -a "$log_file"

echo ""
echo "→ Full log: $log_file"
