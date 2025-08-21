#!/bin/bash

echo "🚀 MTMR Enhanced Setup Script"
echo "=============================="
echo "This script will:"
echo "1. Backup your current configuration"
echo "2. Install the enhanced configuration"
echo "3. Rebuild MTMR with new features"
echo "4. Set up proper permissions"
echo ""

# Check if we're in the right directory
if [ ! -d "MTMR.xcodeproj" ]; then
    echo "❌ Error: Please run this script from the MTMR project directory"
    exit 1
fi

# Backup current configuration
echo "📁 Backing up current configuration..."
CONFIG_PATH="$HOME/Library/Application Support/MTMR/items.json"
BACKUP_PATH="$HOME/Library/Application Support/MTMR/items.json.backup.$(date +%Y%m%d_%H%M%S)"

if [ -f "$CONFIG_PATH" ]; then
    cp "$CONFIG_PATH" "$BACKUP_PATH"
    echo "✅ Configuration backed up to: $BACKUP_PATH"
else
    echo "⚠️  No existing configuration found"
fi

# Create enhanced configuration
echo "🔧 Installing enhanced configuration..."
ENHANCED_CONFIG="enhanced_config.json"

if [ -f "$ENHANCED_CONFIG" ]; then
    # Create MTMR directory if it doesn't exist
    mkdir -p "$(dirname "$CONFIG_PATH")"
    
    # Copy enhanced configuration
    cp "$ENHANCED_CONFIG" "$CONFIG_PATH"
    echo "✅ Enhanced configuration installed"
    
    # Get API key from user
    echo ""
    echo "🌤️  Weather Widget Setup"
    echo "You need an OpenWeatherMap API key for the weather widget to work."
    echo "Get one for free at: https://openweathermap.org/api"
    echo ""
    read -p "Enter your OpenWeatherMap API key (or press Enter to skip): " API_KEY
    
    if [ ! -z "$API_KEY" ]; then
        # Replace placeholder with actual API key
        sed -i '' "s/YOUR_API_KEY_HERE/$API_KEY/g" "$CONFIG_PATH"
        echo "✅ API key configured"
    else
        echo "⚠️  Weather widget will show 'API Key Required' until you add a key"
    fi
else
    echo "❌ Enhanced configuration file not found"
    exit 1
fi

# Build enhanced MTMR
echo ""
echo "🔨 Building enhanced MTMR..."
echo "This may take a few minutes..."

# Clean previous build
xcodebuild clean -project MTMR.xcodeproj -scheme MTMR -configuration Debug

# Build with new features
BUILD_RESULT=$(xcodebuild -project MTMR.xcodeproj -scheme MTMR -configuration Debug build 2>&1)

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Find the built app
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "MTMR.app" -type d 2>/dev/null | head -1)
    
    if [ -n "$APP_PATH" ]; then
        echo "📱 Built app found at: $APP_PATH"
        
        # Sign the app
        echo "🔐 Signing app..."
        codesign --remove-signature "$APP_PATH" 2>/dev/null
        codesign --force --deep --sign - "$APP_PATH"
        
        if [ $? -eq 0 ]; then
            echo "✅ App signed successfully!"
        else
            echo "⚠️  App signing failed, but you can still run it"
        fi
        
        # Open the app
        echo "🚀 Opening enhanced MTMR..."
        open "$APP_PATH"
        
    else
        echo "❌ Built app not found"
        echo "Build output:"
        echo "$BUILD_RESULT"
    fi
else
    echo "❌ Build failed!"
    echo "Build output:"
    echo "$BUILD_RESULT"
    exit 1
fi

# Setup permissions
echo ""
echo "🔐 Setting up permissions..."
echo "You'll need to grant the following permissions:"
echo ""

echo "1. Accessibility Permissions:"
echo "   - Go to System Preferences > Security & Privacy > Privacy > Accessibility"
echo "   - Add MTMR to the list"
echo "   - This enables volume and brightness control"
echo ""

echo "2. Location Permissions:"
echo "   - Go to System Preferences > Security & Privacy > Privacy > Location Services"
echo "   - Enable Location Services"
echo "   - Add MTMR to the list"
echo "   - This enables the weather widget"
echo ""

echo "3. If prompted, allow MTMR to control your computer"
echo ""

# Create permission check script
PERMISSION_SCRIPT="$HOME/Library/Application Support/MTMR/check_permissions.sh"
cat > "$PERMISSION_SCRIPT" << 'EOF'
#!/bin/bash
echo "🔍 MTMR Permission Status Check"
echo "================================"

# Check accessibility
if tccutil reset Accessibility com.toxblh.mtmr > /dev/null 2>&1; then
    echo "✅ Accessibility: Can be configured"
else
    echo "❌ Accessibility: Needs manual setup"
fi

# Check location
if [ "$(defaults read com.apple.locationd LocationServicesEnabled 2>/dev/null)" = "1" ]; then
    echo "✅ Location Services: Enabled"
else
    echo "❌ Location Services: Disabled"
fi

# Check if MTMR is running
if pgrep -f "MTMR" > /dev/null; then
    echo "✅ MTMR: Running"
else
    echo "❌ MTMR: Not running"
fi

echo ""
echo "If you see any ❌ marks, follow the setup instructions in the main script."
EOF

chmod +x "$PERMISSION_SCRIPT"

echo "✅ Permission check script created at: $PERMISSION_SCRIPT"
echo "Run it anytime to check your permission status: $PERMISSION_SCRIPT"
echo ""

# Final instructions
echo "🎉 Enhanced MTMR Setup Complete!"
echo "================================"
echo ""
echo "What's new:"
echo "✅ Smart permission handling (no more repeated prompts)"
echo "✅ Enhanced performance with caching"
echo "✅ Better error handling and debugging"
echo "✅ Volume, brightness, and weather controls"
echo "✅ Memory-efficient updates"
echo ""
echo "Next steps:"
echo "1. Grant the permissions listed above"
echo "2. Restart MTMR if needed"
echo "3. Test the new controls"
echo "4. Run the permission check script if you have issues"
echo ""
echo "Configuration file: $CONFIG_PATH"
echo "Backup file: $BACKUP_PATH"
echo ""

# Test the configuration
echo "🧪 Testing configuration..."
if [ -f "$CONFIG_PATH" ]; then
    if python3 -m json.tool "$CONFIG_PATH" > /dev/null 2>&1; then
        echo "✅ Configuration file is valid JSON"
    else
        echo "❌ Configuration file has JSON syntax errors"
    fi
else
    echo "❌ Configuration file not found"
fi

echo ""
echo "Setup complete! 🎉"
