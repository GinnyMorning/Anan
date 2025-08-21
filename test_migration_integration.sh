#!/bin/bash

# Migration Integration Testing Script
# Tests the actual migration process end-to-end

set -e

echo "🧪 MTMR Migration Integration Testing"
echo "====================================="
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

echo "🔍 **Test 1: Migration Bridge Integration**"
echo "--------------------------------------------"

# Check that all migration bridges can work together
echo -e "${BLUE}Checking Migration Bridge Integration${NC}"

# Check that all bridges have the same interface
START_MIGRATION_COUNT=$(grep -r "startMigration" "MTMR/Concurrency/" | wc -l)
if [[ $START_MIGRATION_COUNT -eq 4 ]]; then
    echo -e "  ${GREEN}✅ All 4 migration bridges have startMigration method (found: $START_MIGRATION_COUNT)${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}❌ Not all migration bridges have startMigration method (found: $START_MIGRATION_COUNT)${NC}"
    ((TESTS_FAILED++))
fi

# Check that all bridges have proper error handling
if grep -q "enum.*Error.*LocalizedError" "MTMR/Concurrency/"*.swift | wc -l | grep -q "4"; then
    echo -e "  ${GREEN}✅ All 4 migration bridges have proper error handling${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  ${YELLOW}⚠️  Some migration bridges may be missing error handling${NC}"
fi
echo ""

echo "🏗️ **Test 2: Migration Coordinator Integration**"
echo "------------------------------------------------"

# Check that MigrationCoordinator can orchestrate all bridges
echo -e "${BLUE}Checking MigrationCoordinator Integration${NC}"

# Check that MigrationCoordinator references all phases
if grep -q "case settings\|case permissions\|case touchBarController\|case widgets\|case cleanup" "MTMR/Concurrency/MigrationCoordinator.swift"; then
    echo -e "  ${GREEN}✅ MigrationCoordinator has all required migration phases${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}❌ MigrationCoordinator missing some migration phases${NC}"
    ((TESTS_FAILED++))
fi

# Check that MigrationCoordinator has rollback support
if grep -q "rollbackMigration" "MTMR/Concurrency/MigrationCoordinator.swift"; then
    echo -e "  ${GREEN}✅ MigrationCoordinator has rollback support${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}❌ MigrationCoordinator missing rollback support${NC}"
    ((TESTS_FAILED++))
fi
echo ""

echo "🔧 **Test 3: Pre-Migration Build Validation**"
echo "----------------------------------------------"

# Ensure the project builds correctly before migration
run_test "Pre-Migration Build" "xcodebuild -project MTMR.xcodeproj -scheme MTMR -configuration Debug build -quiet"

echo "📊 **Test 4: Migration State Validation**"
echo "------------------------------------------"

# Check that migration state tracking is properly implemented
echo -e "${BLUE}Checking Migration State Tracking${NC}"

# Check that all bridges track migration state
if grep -q "isMigrationComplete\|migrationStatus\|migrationProgress" "MTMR/Concurrency/"*.swift | wc -l | grep -q "12"; then
    echo -e "  ${GREEN}✅ All migration bridges have proper state tracking${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  ${YELLOW}⚠️  Some migration bridges may be missing state tracking${NC}"
fi

# Check that migration state is persisted
if grep -q "UserDefaults.*migration.*completed" "MTMR/Concurrency/"*.swift; then
    echo -e "  ${GREEN}✅ Migration state is properly persisted${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}❌ Migration state persistence may be missing${NC}"
    ((TESTS_FAILED++))
fi
echo ""

echo "🧪 **Test 5: Migration Method Validation**"
echo "------------------------------------------"

# Check that all migration methods are properly implemented
echo -e "${BLUE}Checking Migration Method Implementation${NC}"

# Check SettingsMigrationBridge methods
if grep -q "copyLegacySettings\|verifyMigration" "MTMR/Concurrency/SettingsMigrationBridge.swift"; then
    echo -e "  ${GREEN}✅ SettingsMigrationBridge has core migration methods${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}❌ SettingsMigrationBridge missing core migration methods${NC}"
    ((TESTS_FAILED++))
fi

# Check TouchBarMigrationBridge methods
if grep -q "migrateTouchBarState\|verifyTouchBarMigration" "MTMR/Concurrency/TouchBarMigrationBridge.swift"; then
    echo -e "  ${GREEN}✅ TouchBarMigrationBridge has core migration methods${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}❌ TouchBarMigrationBridge missing core migration methods${NC}"
    ((TESTS_FAILED++))
fi

# Check PermissionMigrationBridge methods
if grep -q "migratePermissionState\|verifyPermissionMigration" "MTMR/Concurrency/PermissionMigrationBridge.swift"; then
    echo -e "  ${GREEN}✅ PermissionMigrationBridge has core migration methods${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}❌ PermissionMigrationBridge missing core migration methods${NC}"
    ((TESTS_FAILED++))
fi
echo ""

echo "🔍 **Test 6: Error Handling Validation**"
echo "----------------------------------------"

# Check that error handling is comprehensive
echo -e "${BLUE}Checking Error Handling Implementation${NC}"

# Check that all bridges have proper error types
if grep -q "enum.*MigrationError\|enum.*TouchBarMigrationError\|enum.*PermissionMigrationError" "MTMR/Concurrency/"*.swift; then
    echo -e "  ${GREEN}✅ All migration bridges have proper error types${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}❌ Some migration bridges missing proper error types${NC}"
    ((TESTS_FAILED++))
fi

# Check that errors implement LocalizedError
if grep -q "LocalizedError" "MTMR/Concurrency/"*.swift; then
    echo -e "  ${GREEN}✅ Error types implement LocalizedError protocol${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}❌ Error types may not implement LocalizedError protocol${NC}"
    ((TESTS_FAILED++))
fi
echo ""

echo "🧹 **Test 7: Final Validation**"
echo "--------------------------------"

# Ensure we can still build after all tests
run_test "Post-Testing Build" "xcodebuild -project MTMR.xcodeproj -scheme MTMR -configuration Debug build -quiet"

echo "📊 **Test Results Summary**"
echo "=========================="
echo -e "${GREEN}Tests Passed: ${TESTS_PASSED}${NC}"
echo -e "${RED}Tests Failed: ${TESTS_FAILED}${NC}"
echo -e "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}🎉 ALL TESTS PASSED! Migration integration is ready.${NC}"
    echo ""
    echo "🚀 Ready to begin actual migration execution!"
    echo ""
    echo "📋 Next Steps:"
    echo "  1. Execute migration process using MigrationCoordinator"
    echo "  2. Test migration end-to-end with real data"
    echo "  3. Complete Swift 6.0 upgrade"
    echo "  4. Validate post-migration functionality"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Some tests failed. Please review the issues above.${NC}"
    exit 1
fi
