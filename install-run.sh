swift build -c release

# Create app bundle structure
mkdir -p /Applications/heic.app/Contents/MacOS
cp .build/release/heic /Applications/heic.app/Contents/MacOS/

# Launch the agent
/Applications/heic.app/Contents/MacOS/heic
