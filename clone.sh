#!/bin/bash

# /bin/bash -c "$(curl -L https://raw.githubusercontent.com/yspreen/heic-converter/refs/heads/main/clone.sh)"

cd /tmp

git clone https://github.com/yspreen/heic-converter.git
cd heic-converter
chmod +x install.sh
./install.sh
cd ..
rm -rf heic-converter
