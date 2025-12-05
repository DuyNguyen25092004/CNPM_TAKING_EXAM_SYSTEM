#!/bin/bash

echo "🔨 Building Flutter web..."
flutter build web --release --base-href "/CNPM_TAKING_EXAM_SYSTEM/"

echo "📦 Deploying to GitHub Pages..."
cd build/web
git add .
git commit -m "Deploy: $(date +'%Y-%m-%d %H:%M:%S')"
git push -f origin master:gh-pages

cd ../..
echo "✅ Deploy completed!"
