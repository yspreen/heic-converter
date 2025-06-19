# HEIC/WebP to JPG Converter

## One-Line Install

```bash
/bin/bash -c "$(curl -L https://raw.githubusercontent.com/yspreen/heic-converter/refs/heads/main/clone.sh)"
```

A lightweight macOS application that automatically converts HEIC and WebP images to JPG format in your Downloads folder.

## Features

- 🔄 **Automatic Conversion**: Monitors your Downloads folder and converts images in real-time
- 📱 **HEIC Support**: Converts iPhone/iPad HEIC images to JPG
- 🌐 **WebP Support**: Converts WebP images to JPG (macOS 11+ required)
- 🎯 **Smart Detection**: Only processes new files added after installation
- 📁 **In-Place Conversion**: Creates JPG files alongside originals
- 🚀 **Background Operation**: Runs silently in the background
- ⚡ **Launch Agent**: Automatically starts on system boot

## System Requirements

- macOS 10.13+ (High Sierra) for HEIC support
- macOS 11+ (Big Sur) for WebP support
- Swift runtime

This command will:

1. Clone the repository
2. Build the application
3. Install it to `/Applications/heic.app`
4. Set up the launch agent for automatic startup

## Manual Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/yspreen/heic-converter.git
   cd heic-converter
   ```

2. Build and install:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

## How It Works

1. **Background Monitoring**: The app runs as a background process and checks your Downloads folder every 10 seconds
2. **Smart File Detection**: Only processes HEIC and WebP files that are newer than the app installation
3. **Quality Preservation**: Converts with 85% JPEG quality while maintaining original orientation
4. **Duplicate Prevention**: Skips files that already have a corresponding JPG version

## File Support

| Format | Extension | macOS Version | Status       |
| ------ | --------- | ------------- | ------------ |
| HEIC   | `.heic`   | 10.13+        | ✅ Supported |
| WebP   | `.webp`   | 11.0+         | ✅ Supported |
| Output | `.jpg`    | All           | ✅ Generated |

## Usage

Once installed, the converter works automatically:

1. **Download** any HEIC or WebP image to your Downloads folder
2. **Wait** a few seconds for automatic conversion
3. **Find** the converted JPG file in the same location

### Example

```
Downloads/
├── IMG_1234.heic          # Original HEIC file
├── IMG_1234.jpg           # ✅ Auto-generated JPG
├── photo.webp             # Original WebP file
└── photo.jpg              # ✅ Auto-generated JPG
```

## Uninstalling

To remove the application:

```bash
# Stop the launch agent
launchctl unload ~/Library/LaunchAgents/co.spreen.heic.plist

# Remove files
rm -rf /Applications/heic.app
rm ~/Library/LaunchAgents/co.spreen.heic.plist
```

## Development

### Building from Source

```bash
# Build the project
swift build -c release

# Create application bundle
mkdir -p /Applications/heic.app/Contents/MacOS
cp .build/release/heic /Applications/heic.app/Contents/MacOS/
```

### Project Structure

```
heic/
├── Sources/heic/
│   ├── main.swift         # Main application logic
│   └── heic.plist        # Launch agent configuration
├── Package.swift          # Swift package manifest
├── clone.sh              # Installation script
├── install.sh            # Build and install script
└── README.md             # This file
```

## Troubleshooting

### WebP Not Supported

If you see "WebP format not supported" messages, you're running macOS 10.15 or earlier. WebP support requires macOS 11+.

### Permission Issues

The app must be installed in `/Applications/` to work properly. If you see a "Launch Error" dialog, ensure you're running the installer with proper permissions.

### Launch Agent Not Working

If the app doesn't start automatically on boot:

```bash
# Manually load the launch agent
launchctl load ~/Library/LaunchAgents/co.spreen.heic.plist
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is open source. Feel free to use, modify, and distribute according to your needs.

## Author

Created with ❤️ for seamless image conversion on macOS.
