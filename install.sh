swift build -c release

rm -rf /Applications/heic.app

# Create app bundle structure
mkdir -p /Applications/heic.app/Contents/MacOS
echo "Build contents:"
ls .build/release/
cp .build/release/heic /Applications/heic.app/Contents/MacOS/
cp -r .build/release/heic_heic.bundle /Applications/heic.app/heic_heic.bundle

# Launch the agent
/Applications/heic.app/Contents/MacOS/heic >/dev/null 2>&1 &

echo Done. Uninstall by deleting \`/Applications/heic.app\`
