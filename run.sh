#!/bin/bash

echo "Building MTMR project..."
xcodebuild -project MTMR.xcodeproj -scheme MTMR -configuration Debug build

if [ $? -eq 0 ]; then
    echo "Build successful! Now signing the app to prevent developer warnings..."
    
    # Path to the built app
    APP_PATH="/Users/toan.pham/Library/Developer/Xcode/DerivedData/MTMR-fcrvrqvjqrrauohhluskjogoyega/Build/Products/Debug/MTMR.app"
    
    if [ -d "$APP_PATH" ]; then
        # Remove any existing signatures
        codesign --remove-signature "$APP_PATH"
        
        # Sign with local developer identity
        codesign --force --deep --sign - "$APP_PATH"
        
        echo "✅ App signed successfully! No more developer warnings!"
        echo "Running MTMR..."
        open "$APP_PATH"
    else
        echo "Error: Built app not found at $APP_PATH"
        exit 1
    fi
else
    echo "Build failed!"
    exit 1
fi
