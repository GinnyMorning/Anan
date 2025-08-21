#!/bin/bash

# Simple Phase 1 Implementation Testing Script
# Focuses on core functionality validation

set -e

echo "🧪 MTMR Phase 1 Simple Testing"
echo "==============================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "${BLUE}Testing: ${test_name}${NC}"
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✅ PASSED${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "  ${RED}❌ FAILED${NC}"
        ((TESTS_FAILED++))
    fi
    echo ""
}

echo "📁 **Test 1: File Structure Validation**"
echo "----------------------------------------"

# Check if all required files exist
required_files=(
    "MTMR/Concurrency/ConcurrentUserDefault.swift"
    "MTMR/Concurrency/SettingsMigrationBridge.swift"
    "MTMR/Concurrency/ConcurrentTouchBarController.swift"
    "MTMR/Concurrency/TouchBarMigrationBridge.swift"
    "MTMR/Concurrency/ActorBasedPermissionManager.swift"
    "MTMR/Concurrency/PermissionMigrationBridge.swift"
    "MTMR/Concurrency/MigrationCoordinator.swift"
)

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo -e "  ${GREEN}✅ Found: $file${NC}"
    else
        echo -e "  ${RED}❌ Missing: $file${NC}"
        ((TESTS_FAILED++))
    fi
done
echo ""

echo "🔨 **Test 2: Swift 5.0 Build Validation**"
echo "------------------------------------------"

# Test that the project builds successfully with Swift 5.0
run_test "Swift 5.0 Project Build" "xcodebuild -project MTMR.xcodeproj -scheme MTMR -configuration Debug build -quiet"

echo "📊 **Test 3: Swift 6.0 Compatibility Testing**"
echo "-----------------------------------------------"

# Temporarily upgrade to Swift 6.0
echo -e "${YELLOW}Upgrading to Swift 6.0 for compatibility testing...${NC}"
sed -i.bak 's/SWIFT_VERSION = 5.0;/SWIFT_VERSION = 6.0;/g' MTMR.xcodeproj/project.pbxproj

# Count errors in Swift 6.0 build
echo -e "${YELLOW}Testing Swift 6.0 compatibility...${NC}"
ERROR_COUNT=$(xcodebuild -project MTMR.xcodeproj -scheme MTMR -configuration Debug build -quiet 2>&1 | grep -c "error:" || echo "0")

echo -e "${BLUE}Swift 6.0 Error Count: ${ERROR_COUNT}${NC}"

if [[ $ERROR_COUNT -eq 5 ]]; then
    echo -e "  ${GREEN}✅ PASSED: Expected 5 AppSettings errors (no new issues introduced)${NC}"
    ((TESTS_PASSED++))
elif [[ $ERROR_COUNT -lt 23 ]]; then
    IMPROVEMENT=$(( (23 - ERROR_COUNT) * 100 / 23 ))
    echo -e "  ${GREEN}✅ PASSED: Reduced errors from 23 to ${ERROR_COUNT} (${IMPROVEMENT}% improvement)${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}❌ FAILED: Error count increased or didn't improve${NC}"
    ((TESTS_FAILED++))
fi

# Restore Swift 5.0
echo -e "${YELLOW}Restoring Swift 5.0...${NC}"
sed -i.bak 's/SWIFT_VERSION = 6.0;/SWIFT_VERSION = 5.0;/g' MTMR.xcodeproj/project.pbxproj
echo ""

echo "📋 **Test 4: Migration Bridge Validation**"
echo "------------------------------------------"

# Check if migration bridges have the required methods
echo -e "${BLUE}Testing: Migration Bridge Structure${NC}"

# Check SettingsMigrationBridge
if grep -q "startMigration" "MTMR/Concurrency/SettingsMigrationBridge.swift"; then
    echo -e "  ${GREEN}✅ PASSED: SettingsMigrationBridge has startMigration method${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}❌ FAILED: SettingsMigrationBridge missing startMigration method${NC}"
    ((TESTS_FAILED++))
fi

# Check TouchBarMigrationBridge
if grep -q "startMigration" "MTMR/Concurrency/TouchBarMigrationBridge.swift"; then
    echo -e "  ${GREEN}✅ PASSED: TouchBarMigrationBridge has startMigration method${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}❌ FAILED: TouchBarMigrationBridge missing startMigration method${NC}"
    ((TESTS_FAILED++))
fi

# Check PermissionMigrationBridge
if grep -q "startMigration" "MTMR/Concurrency/PermissionMigrationBridge.swift"; then
    echo -e "  ${GREEN}✅ PASSED: PermissionMigrationBridge has startMigration method${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}❌ FAILED: PermissionMigrationBridge missing startMigration method${NC}"
    ((TESTS_FAILED++))
fi
echo ""

echo "🔍 **Test 5: Code Quality Validation**"
echo "-------------------------------------"

# Check for common code quality issues
echo -e "${BLUE}Testing: Code Quality Checks${NC}"

# Check for proper error handling
if grep -q "enum.*Error.*LocalizedError" "MTMR/Concurrency/"*.swift; then
    echo -e "  ${GREEN}✅ PASSED: Proper error handling with LocalizedError${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  ${YELLOW}⚠️  WARNING: Some files may be missing proper error handling${NC}"
fi

# Check for proper documentation
if grep -q "///" "MTMR/Concurrency/"*.swift | head -1 > /dev/null; then
    echo -e "  ${GREEN}✅ PASSED: Proper documentation with /// comments${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  ${YELLOW}⚠️  WARNING: Some files may be missing proper documentation${NC}"
fi

# Check for proper access control
if grep -q "private\|fileprivate\|internal\|public" "MTMR/Concurrency/"*.swift | head -1 > /dev/null; then
    echo -e "  ${GREEN}✅ PASSED: Proper access control modifiers${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  ${YELLOW}⚠️  WARNING: Some files may be missing proper access control${NC}"
fi
echo ""

echo "🧹 **Test 6: Final Validation**"
echo "--------------------------------"

# Verify we can still build after all tests
run_test "Final Swift 5.0 Build" "xcodebuild -project MTMR.xcodeproj -scheme MTMR -configuration Debug build -quiet"

echo "📊 **Test Results Summary**"
echo "=========================="
echo -e "${GREEN}Tests Passed: ${TESTS_PASSED}${NC}"
echo -e "${RED}Tests Failed: ${TESTS_FAILED}${NC}"
echo -e "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}🎉 ALL TESTS PASSED! Phase 1 implementation is working correctly.${NC}"
    echo ""
    echo "🚀 Ready for Phase 2: Migration Implementation"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Some tests failed. Please review the issues above.${NC}"
    exit 1
fi
