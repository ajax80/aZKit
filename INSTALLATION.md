# Installation Guide

## Quick Start

```bash
git clone https://github.com/ajax80/aZKit.git
cd aZKit
bash install.sh
```

That's it! The installer will:
- ✅ Check your system requirements
- ✅ Set up the agents directory
- ✅ Prompt for your Claude API key (kept safe in ~/.bashrc)
- ✅ Add the `ask` function to your shell
- ✅ Test everything

## Requirements

- **Linux** (tested on Fedora, Ubuntu)
- **bash** 4+
- **curl** and **jq**
- One or more package managers: **dnf**, **apt**, or **flatpak**
- **Claude API key** (free tier available at https://console.anthropic.com/account/keys)

## Security

### API Keys
- Your `ANTHROPIC_API_KEY` is stored in `~/.bashrc` (local, never sent to GitHub)
- Never commit `.bashrc` to version control
- Your key is used only for Claude API calls
- Rotate your key if it's ever exposed

### Passwords
- Sudo passwords are NOT stored or logged
- Password prompts use full TTY control (echo is suppressed)
- Installation logs are saved locally only

### No Telemetry
- aZKit does not collect usage data
- All operations are local
- Only your Claude API requests leave your machine

## Manual Setup

If you prefer not to run the installer:

### 1. Create agents directory
```bash
mkdir -p ~/agents/logs
```

### 2. Copy agent files
```bash
cp agents/interactive-install.sh ~/agents/
chmod +x ~/agents/interactive-install.sh
```

### 3. Set API key
```bash
export ANTHROPIC_API_KEY="your-key-here"
echo 'export ANTHROPIC_API_KEY="your-key-here"' >> ~/.bashrc
```

### 4. Add ask function to ~/.bashrc
Copy the `ask()` function from `install.sh` and add it to your `~/.bashrc`

### 5. Reload shell
```bash
source ~/.bashrc
```

## Verify Installation

```bash
# Test the system
ask "what is the weather like today"

# Should respond from Claude API
```

## Troubleshooting

### "ANTHROPIC_API_KEY not set"
- Get a key: https://console.anthropic.com/account/keys
- Set it: `export ANTHROPIC_API_KEY="your-key"`
- Add to ~/.bashrc to persist it

### "Command not found: interactive-install.sh"
- Verify: `ls ~/agents/interactive-install.sh`
- Make executable: `chmod +x ~/agents/interactive-install.sh`

### "curl: command not found"
- Install: `sudo dnf install curl` (Fedora) or `sudo apt install curl` (Ubuntu)

### "jq: command not found"
- Install: `sudo dnf install jq` (Fedora) or `sudo apt install jq` (Ubuntu)

### Password prompt not working
- Ensure you have real terminal access (not piped/redirected)
- Some systems require: `sudo -S` configuration
- Try running directly: `ask "install weather app"`

## Next Steps

Try these:
```bash
ask "install a weather app for my system"
ask "uninstall gnome weather"
ask "what's the best terminal text editor"
```

## Support

- Issues: https://github.com/ajax80/aZKit/issues
- Questions: Check the README.md

## License

Apache 2.0 - See LICENSE file
