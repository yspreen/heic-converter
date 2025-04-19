#!/usr/bin/env bash

set -e

# Function to check and install dependencies
check_dependencies() {
    if ! command -v swift &>/dev/null; then
        echo "Xcode Command Line Tools (swift) not found."
        read -p "Do you want to attempt installation? (This requires Homebrew and may take a while) [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Installation cancelled by user."
            exit 1
        fi

        # Check/Install Homebrew
        if ! command -v brew &>/dev/null; then
            echo "Homebrew not found. Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            # Add Homebrew to PATH for the current script execution
            if [[ -x "/opt/homebrew/bin/brew" ]]; then
                # Apple Silicon
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [[ -x "/usr/local/bin/brew" ]]; then
                # Intel
                eval "$(/usr/local/bin/brew shellenv)"
            else
                echo "Error: Could not find brew executable after installation."
                exit 1
            fi
        fi

        # Install xcodes using Homebrew
        echo "Installing xcodes..."
        brew install --cask xcodes

        # Install latest Xcode
        echo "Installing latest Xcode via xcodes (this might take a long time and require sudo)..."
        xcodes install --latest --select

        # Verify swift is now available
        if ! command -v swift &>/dev/null; then
            echo "Error: swift command still not found after Xcode installation."
            echo "Please ensure Xcode and Command Line Tools are correctly installed and selected ('xcode-select -p')."
            exit 1
        fi
        echo "Dependencies installed successfully."
    else
        echo "Dependencies (Xcode Command Line Tools) found."
    fi
}

check_dependencies

swift build -c release

rm -rf /Applications/heic.app

# Create app bundle structure
mkdir -p /Applications/heic.app/Contents/MacOS

cp .build/release/heic /Applications/heic.app/Contents/MacOS/
cp -r .build/release/heic_heic.bundle /Applications/heic.app/heic_heic.bundle

# Launch the agent
ps -A | grep /Applications/heic.app | grep -v grep | grep -Eo '^[0-9]+' | while read pid; do kill $pid; done
/Applications/heic.app/Contents/MacOS/heic >/dev/null 2>&1 &

echo Done. Uninstall by deleting \`/Applications/heic.app\`
