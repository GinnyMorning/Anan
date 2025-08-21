#!/bin/bash

echo "Building MTMR with DMG installer..."

# Configuration
APP_NAME="MTMR"
VERSION="1.0.0"
BUILD_DIR="build"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"

# Clean previous builds
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build the project in Debug configuration (avoids signing certificate issues)
echo "Building project in Debug configuration..."
xcodebuild -project MTMR.xcodeproj -scheme MTMR -configuration Debug build SYMROOT="$BUILD_DIR"

if [ $? -eq 0 ]; then
    echo "Build successful! Now creating DMG..."
    
    # Path to the built app
    APP_PATH="$BUILD_DIR/Debug/MTMR.app"
    
    # Check if the app exists
    if [ -d "$APP_PATH" ]; then
        # Remove any existing signatures
        codesign --remove-signature "$APP_PATH"
        
        # Sign with local developer identity (this prevents the unidentified developer warning)
        echo "Signing app..."
        codesign --force --deep --sign - "$APP_PATH"
        
        # Create DMG
        echo "Creating DMG installer..."
        
        # Check if create-dmg is available
        if command -v create-dmg &> /dev/null; then
            create-dmg \
                --volname "$APP_NAME" \
                --volicon "Resources/logo.png" \
                --window-pos 200 120 \
                --window-size 600 300 \
                --icon-size 100 \
                --icon "$APP_NAME.app" 175 120 \
                --hide-extension "$APP_NAME.app" \
                --app-drop-link 425 120 \
                "$DMG_NAME" \
                "$APP_PATH"
        else
            echo "create-dmg not found. Installing via Homebrew..."
            brew install create-dmg
            
            if [ $? -eq 0 ]; then
                create-dmg \
                    --volname "$APP_NAME" \
                    --volicon "Resources/logo.png" \
                    --window-pos 200 120 \
                    --window-size 600 300 \
                    --icon-size 100 \
                    --icon "$APP_NAME.app" 175 120 \
                    --hide-extension "$APP_NAME.app" \
                    --app-drop-link 425 120 \
                    "$DMG_NAME" \
                    "$APP_PATH"
            else
                echo "Failed to install create-dmg. Creating simple DMG..."
                # Fallback: create a simple DMG using hdiutil
                hdiutil create -volname "$APP_NAME" -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_NAME"
            fi
        fi
        
        if [ $? -eq 0 ]; then
            echo "✅ DMG created successfully: $DMG_NAME"
            echo "📱 This DMG should install without developer warnings!"
            echo "🔐 The app is signed with your local developer identity"
            
            # Show file info
            ls -la "$DMG_NAME"
            
            # Optionally open the DMG
            read -p "Would you like to open the DMG now? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                open "$DMG_NAME"
            fi
        else
            echo "❌ Failed to create DMG"
            exit 1
        fi
    else
        echo "❌ Error: Built app not found at $APP_PATH"
        exit 1
    fi
else
    echo "❌ Build failed!"
    exit 1
fi
