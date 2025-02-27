swift build -c release

rm -rf /Applications/heic.app

# Create app bundle structure
mkdir -p /Applications/heic.app/Contents/MacOS

cp .build/release/heic /Applications/heic.app/Contents/MacOS/
cp -r .build/release/heic_heic.bundle /Applications/heic.app/heic_heic.bundle

# Launch the agent
ps -A | grep /Applications/heic.app | grep -v grep | grep -Eo '^[0-9]+' | while read pid; do kill $pid; done
/Applications/heic.app/Contents/MacOS/heic &

echo Done. Uninstall by deleting \`/Applications/heic.app\`
