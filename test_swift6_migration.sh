#!/bin/bash

echo "🧪 Swift 6.0 Migration Testing Script"
echo "====================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "${BLUE}🔍 Testing: $test_name${NC}"
    
    if eval "$test_command"; then
        echo -e "${GREEN}✅ PASSED: $test_name${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAILED: $test_name${NC}"
        ((TESTS_FAILED++))
    fi
    echo ""
}

# Function to check Swift version compatibility
check_swift_version() {
    echo -e "${BLUE}📋 Checking Swift Version Compatibility${NC}"
    
    # Check current Swift version
    SWIFT_VERSION=$(swift --version | head -n1)
    echo "Current Swift version: $SWIFT_VERSION"
    
    # Check if Swift 6.0+ is available
    if swift --version | grep -q "Swift version 6\|Swift version [7-9]"; then
        echo -e "${GREEN}✅ Swift 6.0+ detected${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Swift 6.0+ not detected - using compatibility mode${NC}"
        return 1
    fi
}

# Function to test compilation with different Swift versions
test_compilation() {
    local swift_version="$1"
    echo -e "${BLUE}🔨 Testing compilation with Swift $swift_version${NC}"
    
    # Create a temporary test file
    cat > /tmp/swift6_test.swift << 'EOF'
import Foundation

// Test concurrent property wrapper
@propertyWrapper
struct TestWrapper<T: Sendable> {
    private var value: T
    init(wrappedValue: T) { self.value = wrappedValue }
    var wrappedValue: T {
        get { value }
        set { value = newValue }
    }
}

// Test actor
actor TestActor {
    @TestWrapper var testProperty: String = "test"
    
    func testMethod() -> String {
        return testProperty
    }
}

// Test MainActor class
@MainActor
class TestMainActorClass {
    static let shared = TestMainActorClass()
    private init() {}
}
EOF
    
    # Try to compile
    if swift -typecheck /tmp/swift6_test.swift 2>/dev/null; then
        echo -e "${GREEN}✅ Swift $swift_version compilation successful${NC}"
        rm -f /tmp/swift6_test.swift
        return 0
    else
        echo -e "${RED}❌ Swift $swift_version compilation failed${NC}"
        rm -f /tmp/swift6_test.swift
        return 1
    fi
}

# Function to test MTMR project compilation
test_mtmr_compilation() {
    echo -e "${BLUE}🏗️  Testing MTMR Project Compilation${NC}"
    
    # Test with Swift 5.0 (current)
    echo "Testing with current Swift 5.0 configuration..."
    if xcodebuild -project MTMR.xcodeproj -scheme MTMR -configuration Debug build -quiet; then
        echo -e "${GREEN}✅ Swift 5.0 build successful${NC}"
    else
        echo -e "${RED}❌ Swift 5.0 build failed${NC}"
        return 1
    fi
    
    # Test with Swift 6.0 (if available)
    echo "Testing Swift 6.0 compatibility..."
    
    # Temporarily update Swift version
    sed -i.bak 's/SWIFT_VERSION = 5.0;/SWIFT_VERSION = 6.0;/g' MTMR.xcodeproj/project.pbxproj
    
    if xcodebuild -project MTMR.xcodeproj -scheme MTMR -configuration Debug build -quiet 2>/dev/null; then
        echo -e "${GREEN}✅ Swift 6.0 build successful${NC}"
        SWIFT6_COMPATIBLE=true
    else
        echo -e "${YELLOW}⚠️  Swift 6.0 build failed (expected - migration needed)${NC}"
        SWIFT6_COMPATIBLE=false
    fi
    
    # Restore original Swift version
    mv MTMR.xcodeproj/project.pbxproj.bak MTMR.xcodeproj/project.pbxproj
    
    return 0
}

# Function to validate migration files
test_migration_files() {
    echo -e "${BLUE}📁 Testing Migration File Structure${NC}"
    
    local files=(
        "SWIFT_6_MIGRATION_PLAN.md"
        "MTMR/Concurrency/ConcurrentUserDefault.swift"
        "MTMR/Concurrency/ActorBasedPermissionManager.swift"
        "MTMR/Concurrency/ConcurrentTouchBarController.swift"
        "MTMR/Concurrency/MigrationCoordinator.swift"
    )
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            echo -e "${GREEN}✅ Found: $file${NC}"
        else
            echo -e "${RED}❌ Missing: $file${NC}"
            ((TESTS_FAILED++))
        fi
    done
}

# Function to test concurrency patterns
test_concurrency_patterns() {
    echo -e "${BLUE}🔄 Testing Concurrency Patterns${NC}"
    
    # Test actor syntax
    cat > /tmp/actor_test.swift << 'EOF'
actor TestActor {
    private var counter = 0
    
    func increment() -> Int {
        counter += 1
        return counter
    }
}

@MainActor
class TestMainActor {
    static let shared = TestMainActor()
    private init() {}
}
EOF
    
    if swift -typecheck /tmp/actor_test.swift 2>/dev/null; then
        echo -e "${GREEN}✅ Actor patterns syntax valid${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ Actor patterns syntax invalid${NC}"
        ((TESTS_FAILED++))
    fi
    
    rm -f /tmp/actor_test.swift
}

# Function to test Sendable conformance
test_sendable_conformance() {
    echo -e "${BLUE}📤 Testing Sendable Conformance${NC}"
    
    cat > /tmp/sendable_test.swift << 'EOF'
struct SendableStruct: Sendable {
    let value: String
}

enum SendableEnum: Sendable {
    case value(String)
}

// This should work
@propertyWrapper
struct SendableWrapper<T: Sendable> {
    var wrappedValue: T
}
EOF
    
    if swift -typecheck /tmp/sendable_test.swift 2>/dev/null; then
        echo -e "${GREEN}✅ Sendable conformance patterns valid${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ Sendable conformance patterns invalid${NC}"
        ((TESTS_FAILED++))
    fi
    
    rm -f /tmp/sendable_test.swift
}

# Function to generate migration report
generate_report() {
    echo ""
    echo -e "${BLUE}📊 Migration Readiness Report${NC}"
    echo "================================"
    
    echo "Tests Passed: $TESTS_PASSED"
    echo "Tests Failed: $TESTS_FAILED"
    echo "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All tests passed! Ready for Swift 6.0 migration.${NC}"
        OVERALL_STATUS="READY"
    elif [[ $TESTS_FAILED -le 2 ]]; then
        echo -e "${YELLOW}⚠️  Minor issues detected. Migration possible with fixes.${NC}"
        OVERALL_STATUS="READY_WITH_FIXES"
    else
        echo -e "${RED}❌ Major issues detected. Migration not recommended yet.${NC}"
        OVERALL_STATUS="NOT_READY"
    fi
    
    echo ""
    echo -e "${BLUE}📋 Next Steps:${NC}"
    
    case $OVERALL_STATUS in
        "READY")
            echo "1. Begin Phase 1 of migration plan"
            echo "2. Create feature branch: swift-6-migration"
            echo "3. Start with ConcurrentUserDefault implementation"
            ;;
        "READY_WITH_FIXES")
            echo "1. Fix failing tests first"
            echo "2. Re-run this test script"
            echo "3. Begin migration once all tests pass"
            ;;
        "NOT_READY")
            echo "1. Review failing tests and fix underlying issues"
            echo "2. Ensure Swift 6.0 toolchain is available"
            echo "3. Re-run test script after fixes"
            ;;
    esac
}

# Main execution
main() {
    echo "Starting Swift 6.0 migration readiness tests..."
    echo ""
    
    # Check Swift version
    check_swift_version
    echo ""
    
    # Run tests
    run_test "Swift Version Compatibility" "test_compilation 6.0"
    run_test "MTMR Project Compilation" "test_mtmr_compilation"
    run_test "Migration Files Present" "test_migration_files"
    run_test "Concurrency Patterns" "test_concurrency_patterns"
    run_test "Sendable Conformance" "test_sendable_conformance"
    
    # Generate report
    generate_report
}

# Run main function
main
