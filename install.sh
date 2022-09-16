#!/bin/bash

echo "Configure directories..."

#mkdir HackMyResume

mkdir backup

mkdir output
cd output
mkdir resume

# shellcheck disable=SC2103
cd ..
mkdir tmp

echo "Installing HackMyResume..."
git clone "https://github.com/bormaxi8080/HackMyResume.git"
cd HackMyResume
sudo npm install hackmyresume
cd ..

#echo "Installing jq..."
## MacOS:
#brew install jq
## or Linux:
#sudo apt-get install jq

echo "Done"
