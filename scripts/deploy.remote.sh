#!/bin/sh
echo "[ REMOTE ] | START"

cd public_html


folders=("static")
files=(
  "_redirects"
  "asset-manifest.json"
  "favicon.ico"
  "index.html"
  "logo192.png"
  "logo512.png"
  "manifest.json"
  "precache-manifest.*.js"
  "robots.txt"
  "service-worker.js"
)

echo "[ REMOTE ] | Delete folders"
for folder in ${folders[@]}
do
  rm -rf -v $folder
done

echo "[ REMOTE ] | Delete files"
for file in ${files[@]}
do
  rm -rf -v $file
done

echo "[ REMOTE ] | Moving files"
mv -v build/* ./

echo "[ REMOTE ] | Clean Deploy"
rm -rf build
rm ../deploy.remote.sh

echo "[ REMOTE ] | FINISH"
