#!/bin/bash

echo "Building MTMR with local code signing..."

# Build the project in Debug configuration (avoids signing certificate issues)
xcodebuild -project MTMR.xcodeproj -scheme MTMR -configuration Debug build

if [ $? -eq 0 ]; then
    echo "Build successful! Now signing the app..."
    
    # Path to the built app
    APP_PATH="/Users/toan.pham/Library/Developer/Xcode/DerivedData/MTMR-fcrvrqvjqrrauohhluskjogoyega/Build/Products/Debug/MTMR.app"
    
    # Check if the app exists
    if [ -d "$APP_PATH" ]; then
        # Remove any existing signatures
        codesign --remove-signature "$APP_PATH"
        
        # Sign with local developer identity
        codesign --force --deep --sign - "$APP_PATH"
        
        echo "✅ App signed successfully!"
        echo "🔐 The app is now signed and should install without developer warnings"
        echo "📱 You can now copy this app to Applications folder without issues"
        
        # Verify the signature
        echo "Verifying signature..."
        codesign --verify --verbose=4 "$APP_PATH"
        
        # Optionally open the app
        read -p "Would you like to open the signed app now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            open "$APP_PATH"
        fi
    else
        echo "❌ Error: Built app not found at $APP_PATH"
        exit 1
    fi
else
    echo "❌ Build failed!"
    exit 1
fi
