# MTMR Troubleshooting Guide

## Volume Control Issues

### Symptoms
- Volume slider doesn't respond to touch
- Volume slider shows incorrect value
- Volume changes don't affect system audio
- Volume control crashes the app

### Common Causes & Solutions

#### 1. Accessibility Permissions
**Problem**: MTMR needs accessibility permissions to control system volume.

**Solution**:
1. Go to **System Preferences** > **Security & Privacy** > **Privacy** > **Accessibility**
2. Click the lock icon and enter your password
3. Add MTMR to the list of allowed applications
4. Restart MTMR

#### 2. Audio Device Issues
**Problem**: Audio device not properly detected or configured.

**Solution**:
```bash
# Restart audio system
sudo killall coreaudiod

# Check audio devices
system_profiler SPAudioDataType
```

#### 3. Code Signing Issues
**Problem**: macOS blocks unsigned applications from controlling system features.

**Solution**:
```bash
# Build and sign the app
xcodebuild -project MTMR.xcodeproj -scheme MTMR -configuration Debug build

# Sign with local developer identity
codesign --force --deep --sign - /path/to/MTMR.app
```

## Weather Widget Issues

### Symptoms
- Weather shows "⏳" indefinitely
- Weather shows error messages
- Location not working
- API errors

### Common Causes & Solutions

#### 1. Invalid API Key
**Problem**: OpenWeatherMap API key is missing, expired, or invalid.

**Solution**:
1. Get a free API key from [OpenWeatherMap](https://openweathermap.org/api)
2. Wait 20 minutes for activation
3. Update your `items.json` configuration:

```json
{
  "type": "weather",
  "refreshInterval": 1800,
  "units": "metric",
  "api_key": "YOUR_ACTUAL_API_KEY_HERE",
  "icon_type": "text",
  "align": "right"
}
```

#### 2. Location Permissions
**Problem**: MTMR doesn't have permission to access location.

**Solution**:
1. Go to **System Preferences** > **Security & Privacy** > **Privacy** > **Location Services**
2. Enable Location Services
3. Add MTMR to the list of allowed applications
4. Restart MTMR

#### 3. Network Issues
**Problem**: Cannot connect to OpenWeatherMap API.

**Solution**:
```bash
# Test connectivity
ping api.openweathermap.org

# Check firewall settings
sudo pfctl -s rules
```

## Brightness Control Issues

### Symptoms
- Brightness slider doesn't respond
- Brightness slider shows incorrect value
- Brightness changes don't affect display
- App crashes when adjusting brightness

### Common Causes & Solutions

#### 1. Accessibility Permissions
**Problem**: Same as volume control - needs accessibility access.

**Solution**: Follow the same steps as volume control permissions.

#### 2. macOS Version Compatibility
**Problem**: CoreDisplay framework not available on older macOS versions.

**Solution**: 
- macOS 10.13+ required for CoreDisplay
- Older versions fall back to IOKit (may be less reliable)

#### 3. Display Driver Issues
**Problem**: Display system not responding to brightness commands.

**Solution**:
```bash
# Restart display system (use carefully - will log you out)
sudo killall WindowServer

# Check display services
system_profiler SPDisplaysDataType
```

## General Troubleshooting Steps

### 1. Run the Debug Script
```bash
chmod +x debug_mtmr.sh
./debug_mtmr.sh
```

### 2. Check Console Logs
1. Open **Console.app**
2. Filter by "MTMR" or your username
3. Look for error messages and debug output

### 3. Verify Configuration
1. Check `~/Library/Application Support/MTMR/items.json`
2. Ensure JSON syntax is valid
3. Verify all required fields are present

### 4. Reset Permissions
```bash
# Reset accessibility permissions
tccutil reset Accessibility com.toxblh.mtmr

# Reset location permissions
tccutil reset Location com.toxblh.mtmr
```

### 5. Rebuild and Reinstall
```bash
# Clean build
xcodebuild clean -project MTMR.xcodeproj

# Rebuild
xcodebuild -project MTMR.xcodeproj -scheme MTMR -configuration Debug build

# Sign and install
codesign --force --deep --sign - /path/to/MTMR.app
```

## Configuration Examples

### Working Volume Configuration
```json
{
  "type": "volume",
  "width": 120,
  "bordered": false,
  "align": "left"
}
```

### Working Brightness Configuration
```json
{
  "type": "brightness",
  "refreshInterval": 1.0,
  "width": 120,
  "bordered": false,
  "align": "left"
}
```

### Working Weather Configuration
```json
{
  "type": "weather",
  "refreshInterval": 1800,
  "units": "metric",
  "api_key": "your_actual_api_key_here",
  "icon_type": "text",
  "align": "right",
  "bordered": false
}
```

## Advanced Debugging

### Enable Verbose Logging
Add this to your configuration to see detailed debug information:
```json
{
  "type": "staticButton",
  "title": "Debug",
  "action": "shellScript",
  "executablePath": "/usr/bin/log",
  "shellArguments": ["stream", "--predicate", "process == 'MTMR'"]
}
```

### Check System Status
```bash
# Check Touch Bar status
system_profiler SPBluetoothDataType | grep -i touch

# Check audio status
system_profiler SPAudioDataType

# Check display status
system_profiler SPDisplaysDataType
```

## Getting Help

If you're still experiencing issues:

1. **Check the debug output** from the debug script
2. **Review Console logs** for specific error messages
3. **Verify your configuration** against the working examples
4. **Test with minimal configuration** to isolate the problem
5. **Check GitHub issues** for similar problems
6. **Provide debug information** when asking for help

## Common Error Messages

- `"MTMR: Volume control initialized with device ID: 0"` → No audio device found
- `"MTMR: Weather widget - API error: Invalid API key"` → Invalid OpenWeatherMap key
- `"MTMR: Brightness control initialized - Current level: 0.5"` → Using fallback brightness
- `"MTMR: Failed to get default audio device"` → Audio system not accessible
- `"MTMR: Weather widget - Location permission denied"` → Location access blocked

## Prevention

1. **Always grant necessary permissions** when prompted
2. **Keep your API keys current** and valid
3. **Use the debug script** before reporting issues
4. **Test with minimal configuration** first
5. **Keep MTMR updated** to the latest version
