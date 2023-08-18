#!/usr/bin/env bash

# A build/deploy script to deploy litelist to litelist.andrewlalis.com
# Builds the front-end app, builds the API, and deploys them to the server.

echo "Building app"
cd litelist-app
rm -rf dist
npm run build
cd ..

echo "Building api"
cd litelist-api
dub clean
dub build --build=release --compiler=/opt/ldc2/ldc2-1.33.0-linux-x86_64/bin/ldc2
cd ..

# Now deploy
ssh -f root@andrewlalis.com 'systemctl stop litelist-api.service'
echo "Copying litelist-api binary to server"
scp litelist-api/litelist-api root@andrewlalis.com:/opt/litelist/
echo "Copying app distribution to server"
rsync -rav -e ssh --delete litelist-app/dist/* root@andrewlalis.com:/opt/litelist/app-content
ssh -f root@andrewlalis.com 'systemctl start litelist-api.service'
