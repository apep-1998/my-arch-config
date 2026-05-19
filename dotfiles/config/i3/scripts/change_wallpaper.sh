#! /bin/bash

imageURL="https://bing.com$(curl http://www.bing.com/HPImageArchive.aspx\?format\=js\&idx\=0\&n\=1\&mkt\=en-US | jq -r '.images[0].url')"
imageDir=~/.config/i3/wallpapers/
imageName="wallpaper.jpg"


mkdir -p "${imageDir}"

newImageAddress="${imageDir}${imageName}"

if [ -f $newImageAddress ]; then
	backupName=$(sha256sum -b $newImageAddress | cut -d " " -f 1)
	mv "${newImageAddress}" "${imageDir}${backupName}.jpg"
fi

echo $imageURL

curl "${imageURL}" --output "${newImageAddress}"

if [ $? -eq 0 ]; then
    feh --bg-scale "${newImageAddress}"
else
    feh --bg-scale "${imageDir}${backupName}.jpg"
fi
