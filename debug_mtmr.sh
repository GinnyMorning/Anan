#!/bin/bash

echo "🔍 MTMR Debug Script - Diagnosing Volume, Weather, and Brightness Issues"
echo "========================================================================"

# Check if MTMR is running
echo "1. Checking MTMR Application Status..."
if pgrep -f "MTMR" > /dev/null; then
    echo "✅ MTMR is running"
    MTMR_PID=$(pgrep -f "MTMR")
    echo "   Process ID: $MTMR_PID"
else
    echo "❌ MTMR is not running"
fi

echo ""

# Check configuration file
echo "2. Checking MTMR Configuration..."
CONFIG_PATH="$HOME/Library/Application Support/MTMR/items.json"
if [ -f "$CONFIG_PATH" ]; then
    echo "✅ Configuration file found at: $CONFIG_PATH"
    echo "   File size: $(ls -lh "$CONFIG_PATH" | awk '{print $5}')"
    echo "   Last modified: $(ls -l "$CONFIG_PATH" | awk '{print $6, $7, $8}')"
    
    # Check if volume, weather, and brightness are configured
    echo "   Configuration contents:"
    echo "   - Volume control: $(grep -c "volume" "$CONFIG_PATH" || echo "0") instances"
    echo "   - Weather widget: $(grep -c "weather" "$CONFIG_PATH" || echo "0") instances"
    echo "   - Brightness control: $(grep -c "brightness" "$CONFIG_PATH" || echo "0") instances"
else
    echo "❌ Configuration file not found at: $CONFIG_PATH"
    echo "   Creating default configuration..."
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$CONFIG_PATH")"
    
    # Create a working configuration
    cat > "$CONFIG_PATH" << 'EOF'
[
  {
    "type": "escape",
    "width": 64,
    "align": "left"
  },
  {
    "type": "dnd",
    "align": "left",
    "width": 38
  },
  { 
    "type": "brightness", 
    "refreshInterval": 1.0,
    "width": 120, 
    "bordered": false, 
    "align": "left" 
  },
  {
    "type": "volume",
    "width": 120,
    "bordered": false,
    "align": "left"
  },
  {
    "type": "weather",
    "refreshInterval": 1800,
    "units": "metric",
    "api_key": "YOUR_API_KEY_HERE",
    "icon_type": "text",
    "align": "right",
    "bordered": false
  },
  {
    "type": "battery",
    "align": "right",
    "bordered": false
  },
  {
    "type": "timeButton",
    "formatTemplate": "HH:mm",
    "align": "right",
    "bordered": false
  }
]
EOF
    echo "✅ Default configuration created"
fi

echo ""

# Check system permissions
echo "3. Checking System Permissions..."
echo "   Accessibility permissions:"
if tccutil reset Accessibility com.toxblh.mtmr > /dev/null 2>&1; then
    echo "   ✅ Accessibility permissions can be reset"
else
    echo "   ⚠️  Accessibility permissions may need manual setup"
fi

echo "   Location services:"
if [ "$(defaults read com.apple.locationd LocationServicesEnabled 2>/dev/null)" = "1" ]; then
    echo "   ✅ Location services are enabled"
else
    echo "   ❌ Location services are disabled"
fi

echo ""

# Check audio system
echo "4. Checking Audio System..."
if command -v osascript > /dev/null; then
    AUDIO_LEVEL=$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)
    if [ "$AUDIO_LEVEL" != "" ]; then
        echo "✅ Audio system accessible - Current volume: $AUDIO_LEVEL%"
    else
        echo "❌ Audio system not accessible"
    fi
else
    echo "❌ osascript not available"
fi

echo ""

# Check display brightness
echo "5. Checking Display Brightness..."
if command -v osascript > /dev/null; then
    BRIGHTNESS=$(osascript -e 'tell application "System Events" to get value of slider 1 of group 1 of window 1 of process "System Preferences"' 2>/dev/null)
    if [ "$BRIGHTNESS" != "" ]; then
        echo "✅ Display brightness accessible - Current level: $BRIGHTNESS"
    else
        echo "❌ Display brightness not accessible"
    fi
else
    echo "❌ osascript not available"
fi

echo ""

# Check network connectivity for weather
echo "6. Checking Network Connectivity..."
if ping -c 1 api.openweathermap.org > /dev/null 2>&1; then
    echo "✅ OpenWeatherMap API accessible"
else
    echo "❌ OpenWeatherMap API not accessible"
fi

echo ""

# Check macOS version
echo "7. Checking macOS Version..."
MACOS_VERSION=$(sw_vers -productVersion)
echo "   macOS Version: $MACOS_VERSION"

# Check if CoreDisplay framework is available
if [ -d "/System/Library/Frameworks/CoreDisplay.framework" ]; then
    echo "   ✅ CoreDisplay framework available"
else
    echo "   ❌ CoreDisplay framework not available"
fi

echo ""

# Check MTMR build
echo "8. Checking MTMR Build..."
if [ -d "MTMR.xcodeproj" ]; then
    echo "✅ MTMR project found"
    
    # Check if build is needed
    if [ ! -d "build" ] && [ ! -f "MTMR.app" ]; then
        echo "   ⚠️  MTMR needs to be built"
        echo "   Run: xcodebuild -project MTMR.xcodeproj -scheme MTMR -configuration Debug build"
    else
        echo "   ✅ MTMR appears to be built"
    fi
else
    echo "❌ MTMR project not found in current directory"
fi

echo ""

# Recommendations
echo "9. Recommendations:"
echo "   📱 For Volume Control:"
echo "      - Ensure MTMR has Accessibility permissions in System Preferences > Security & Privacy > Privacy > Accessibility"
echo "      - Check if audio output device is properly configured"
echo "      - Try restarting the audio system: sudo killall coreaudiod"
echo ""
echo "   🌤️  For Weather Widget:"
echo "      - Get a valid API key from https://openweathermap.org/api"
echo "      - Enable Location Services in System Preferences > Security & Privacy > Privacy > Location Services"
echo "      - Ensure MTMR has location permissions"
echo ""
echo "   💡 For Brightness Control:"
echo "      - Ensure MTMR has Accessibility permissions"
echo "      - Check if running on supported macOS version (10.13+)"
echo "      - Try restarting the display system: sudo killall WindowServer"
echo ""
echo "   🔧 General Troubleshooting:"
echo "      - Restart MTMR application"
echo "      - Check Console.app for error messages"
echo "      - Ensure Touch Bar is enabled in System Preferences"
echo "      - Try resetting Touch Bar: sudo pkill TouchBarServer"

echo ""
echo "========================================================================"
echo "🔍 Debug script completed. Check the recommendations above."
