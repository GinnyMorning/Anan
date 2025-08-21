# 🚀 MTMR Build Solutions - Fix "Unidentified Developer" Error

## The Problem
When building apps from source code, macOS shows "unidentified developer" warnings because the app isn't code-signed by a recognized developer.

## ✅ Solutions Available

### 1. **Quick Fix - Sign Existing Build** ⚡
```bash
./sign-existing.sh
```
- Signs your existing debug build
- Prevents developer warnings
- Good for immediate use

### 2. **Enhanced Build & Sign** 🔧
```bash
./run.sh
```
- Builds + signs in one command
- Updated to include code signing
- No more developer warnings

### 3. **Release Build with Signing** 📦
```bash
./build-signed.sh
```
- Builds in Release configuration
- Includes proper code signing
- Better performance than debug builds

### 4. **Professional DMG Installer** 🎯
```bash
./build-dmg.sh
```
- Creates a proper DMG installer
- Includes code signing
- Professional distribution ready

## 🔐 How Code Signing Fixes the Problem

**Before (Unidentified Developer):**
- macOS blocks installation
- Shows security warnings
- Requires manual override in System Preferences

**After (Code Signed):**
- ✅ No security warnings
- ✅ Easy installation
- ✅ Trusted by macOS

## 🛠️ Technical Details

### Local Code Signing
```bash
codesign --force --deep --sign - /path/to/MTMR.app
```
- `--force`: Overwrites existing signatures
- `--deep`: Signs all nested components
- `--sign -`: Uses local developer identity

### What This Means
- The app is signed with your local developer certificate
- macOS recognizes it as "signed locally"
- No more "unidentified developer" errors
- Safe to install and run

## 📱 Installation Options

### Option A: Copy to Applications
```bash
cp -R /path/to/MTMR.app /Applications/
```

### Option B: Use DMG Installer
```bash
./build-dmg.sh
# Then double-click the generated .dmg file
```

### Option C: Run from Build Directory
```bash
./run.sh
# App runs directly from build location
```

## 🚨 Important Notes

1. **Local Signing Only**: This solution works for your machine and trusted machines
2. **Not for Distribution**: For public distribution, you need an Apple Developer account
3. **Security**: The app is still safe - it's just signed locally instead of by Apple
4. **Updates**: You'll need to re-sign after each rebuild

## 🔄 Workflow

**For Development:**
```bash
./run.sh          # Build + Sign + Run
```

**For Testing:**
```bash
./build-signed.sh # Build Release + Sign
```

**For Distribution:**
```bash
./build-dmg.sh    # Create signed DMG installer
```

## 🆘 Troubleshooting

### If signing fails:
```bash
# Check if app exists
ls -la /path/to/MTMR.app

# Try manual signing
codesign --force --deep --sign - /path/to/MTMR.app

# Verify signature
codesign --verify --verbose=4 /path/to/MTMR.app
```

### If app still shows warnings:
1. Make sure you ran the signing script
2. Check that the app path is correct
3. Try removing and re-adding the app
4. Restart macOS if needed

## 🎯 Next Steps

1. **Try the quick fix**: `./sign-existing.sh`
2. **Use enhanced build**: `./run.sh` (now includes signing)
3. **Create installer**: `./build-dmg.sh` for distribution

All scripts are now executable and ready to use! 🎉
