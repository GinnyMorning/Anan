#!/bin/bash

echo "Signing existing MTMR debug build..."

# Path to the existing debug build
APP_PATH="/Users/toan.pham/Library/Developer/Xcode/DerivedData/MTMR-fcrvrqvjqrrauohhluskjogoyega/Build/Products/Debug/MTMR.app"

if [ -d "$APP_PATH" ]; then
    echo "Found app at: $APP_PATH"
    
    # Remove any existing signatures
    echo "Removing existing signatures..."
    codesign --remove-signature "$APP_PATH"
    
    # Sign with local developer identity
    echo "Signing with local developer identity..."
    codesign --force --deep --sign - "$APP_PATH"
    
    if [ $? -eq 0 ]; then
        echo "✅ App signed successfully!"
        echo "🔐 The app is now signed and should run without developer warnings"
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
        echo "❌ Failed to sign the app"
        exit 1
    fi
else
    echo "❌ Error: App not found at $APP_PATH"
    echo "Please run the build first: ./run.sh"
    exit 1
fi
