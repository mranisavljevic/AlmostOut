#!/bin/bash

echo "🚀 Deploying AlmostOut to Firebase..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Installing..."
    npm install -g firebase-tools
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo "🔐 Please log in to Firebase..."
    firebase login
fi

echo "📋 Deploying Firestore rules..."
firebase deploy --only firestore:rules

echo "📋 Deploying Firestore indexes..."
firebase deploy --only firestore:indexes

echo "💾 Deploying Storage rules..."
firebase deploy --only storage

echo "⚡ Building and deploying Cloud Functions..."
cd functions
npm install
npm run build
cd ..
firebase deploy --only functions

echo "✅ Deployment complete!"
echo "🔗 Console: https://console.firebase.google.com/project/$(firebase use)"