# aZKit
Apps that flow
# aZKit                                                                                                                                                                                                           
                                         
  ## What It Does                                                                                                                                                                                                   
  Autonomous agent system that researches, proposes, and installs/uninstalls                                                                                                                                        
  software with full user control and intelligent learning.                                                                                                                                                         
                                                            
  ## Quick Start
  ```bash
  ask "install the best weather app for my system"
  ask "uninstall gnome weather"

  Features                                                                                                                                                                                                          
   
  - ✅ Autonomous research via Claude API                                                                                                                                                                           
  - ✅ Interactive proposal with user choices               
  - ✅ Explicit approval before executing
  - ✅ Full TTY support (passwords, prompts work)
  - ✅ Intelligent learning (remembers solutions)
  - ✅ Works with dnf, apt, flatpak                                                                                                                                                                                 
  - ✅ Uninstall with verification
                                                                                                                                                                                                                    
  How It Works                                              

  1. Research options (Claude)
  2. Present choices to user
  3. Get approval
  4. Execute with proper TTY control
  5. Teach user how to use                                                                                                                                                                                          
  6. Learn for next time
                                                                                                                                                                                                                    
  Installation                                              

  - Clone repo
  - Source ~/.bashrc
  - Ready to use

  Requirements

  - Linux (tested on Fedora)
  - bash 4+
  - curl, jq
  - ANTHROPIC_API_KEY set
                                                                                                                                                                                                                    
  Architecture
                                                                                                                                                                                                                    
  - ask() - Routes install/uninstall to agents              
  - interactive-install.sh - Full install workflow
  - Knowledge base - Stores learned solutions

  License

  Apache 2.0 - See LICENSE file

  Author

  ajax80 - Built with Claude  
