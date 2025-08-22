# 🤝 Contributing to AnnaBo

Thank you for your interest in contributing to AnnaBo! This guide will help you get started and understand how to contribute effectively.

## 🎯 How to Contribute

### Types of Contributions

- 🐛 **Bug Reports** - Help us identify and fix issues
- 💡 **Feature Requests** - Suggest new ideas and improvements
- 🔧 **Code Contributions** - Submit bug fixes and new features
- 📚 **Documentation** - Improve guides, README, and code comments
- 🌍 **Localization** - Help translate AnnaBo to your language
- 🧪 **Testing** - Test features and report issues
- ⭐ **Star & Share** - Show your support and spread the word

---

## 🚀 Getting Started

### Prerequisites

- **macOS 11.0+** (Big Sur or later)
- **Xcode 13.0+** (for development)
- **Git** - For version control
- **Basic Swift knowledge** - For code contributions

### Setting Up Development Environment

1. **Fork the repository**
   - Go to [AnnaBo GitHub page](https://github.com/yourusername/annabo)
   - Click the "Fork" button in the top right
   - This creates your own copy of the project

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/annabo.git
   cd annabo
   ```

3. **Add the original repository as upstream**
   ```bash
   git remote add upstream https://github.com/yourusername/annabo.git
   ```

4. **Open in Xcode**
   ```bash
   open AnnaBo.xcodeproj
   ```

5. **Build and test**
   - Select the AnnaBo scheme
   - Choose your target device
   - Press Cmd+R to build and run

---

## 🔧 Development Workflow

### 1. Create a Feature Branch

Always work on a separate branch for your changes:

```bash
# Update your main branch
git checkout main
git pull upstream main

# Create and switch to a new feature branch
git checkout -b feature/amazing-feature

# Or for bug fixes
git checkout -b fix/bug-description
```

### 2. Make Your Changes

- Follow the [Development Checklist](DEVELOPMENT_CHECKLIST.md)
- Read the [Architecture Documentation](ARCHITECTURE.md)
- Use the [Best Practices Guide](README_BEST_PRACTICES.md)
- Write clear, readable code
- Add comprehensive comments for public APIs

### 3. Test Your Changes

- **Build the project** - Ensure no compilation errors
- **Run the app** - Test your changes manually
- **Check performance** - Use the built-in performance monitoring
- **Test edge cases** - Try different scenarios and configurations

### 4. Commit Your Changes

Use clear, descriptive commit messages:

```bash
# Good commit message
git commit -m "Add widget template library feature

- Implement template browsing interface
- Add template import/export functionality
- Include 10 pre-built widget templates
- Update documentation for new feature"

# Avoid vague messages like:
# git commit -m "fix stuff"  # ❌ Too vague
# git commit -m "update"     # ❌ Not descriptive
```

### 5. Push to Your Fork

```bash
git push origin feature/amazing-feature
```

### 6. Create a Pull Request

1. Go to your fork on GitHub
2. Click "Compare & pull request"
3. Fill out the PR template
4. Submit for review

---

## 📋 Pull Request Guidelines

### PR Template

When creating a pull request, please include:

- **Description** - What does this PR do?
- **Type of change** - Bug fix, feature, documentation, etc.
- **Testing** - How did you test your changes?
- **Screenshots** - If applicable, include screenshots
- **Related issues** - Link to any related issues

### PR Review Process

1. **Automated checks** - CI/CD pipeline runs tests
2. **Code review** - Maintainers review your code
3. **Feedback** - Address any review comments
4. **Approval** - Once approved, your PR will be merged

### PR Best Practices

- **Keep PRs small** - Focus on one feature or fix at a time
- **Include tests** - Add tests for new functionality
- **Update documentation** - Keep docs in sync with code changes
- **Follow style guidelines** - Use consistent code formatting
- **Respond to feedback** - Address review comments promptly

---

## 🎨 Code Style Guidelines

### Swift Style

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use meaningful variable and function names
- Add comprehensive documentation for public APIs
- Handle errors gracefully with proper error types

### SwiftUI Guidelines

- Use proper property wrappers (`@State`, `@ObservedObject`, `@Binding`)
- Implement proper error handling with user feedback
- Show loading states for async operations
- Ensure accessibility support

### AnnaBo-Specific Guidelines

- **Always use CentralizedPresetManager** for configuration changes
- **Check permissions** before TouchBar operations
- **Monitor performance** using built-in tools
- **Follow established patterns** for consistency

### Example Code

```swift
// ✅ Good: Clear, documented, follows patterns
/// Adds a new widget to the TouchBar configuration
/// - Parameter widget: The widget descriptor to add
/// - Returns: True if successful, false otherwise
func addWidget(_ widget: WidgetDescriptor) -> Bool {
    // Check permissions first
    guard EnhancedPermissionManager.shared.isPermissionGranted(for: "accessibility") else {
        print("MTMR: Accessibility permission required")
        return false
    }
    
    // Use centralized manager
    let result = CentralizedPresetManager.shared.addWidget(widget)
    
    // Log result for debugging
    print("MTMR: Widget addition result: \(result)")
    
    return result
}

// ❌ Bad: Unclear, undocumented, doesn't follow patterns
func add(w: Widget) -> Bool {
    if AXIsProcessTrusted() {
        // Direct file manipulation - wrong!
        let data = try? JSONSerialization.data(withJSONObject: w)
        try? data?.write(to: URL(fileURLWithPath: "path"))
        return true
    }
    return false
}
```

---

## 🧪 Testing Guidelines

### What to Test

- **New features** - Test all functionality thoroughly
- **Bug fixes** - Verify the bug is actually fixed
- **Edge cases** - Test unusual scenarios and configurations
- **Performance** - Ensure no performance regressions
- **Accessibility** - Test with VoiceOver and other accessibility tools

### Testing Checklist

- [ ] **Builds successfully** - No compilation errors
- [ ] **Runs without crashes** - App launches and functions normally
- [ ] **Feature works as expected** - New functionality behaves correctly
- [ ] **No regressions** - Existing features still work
- [ ] **Performance acceptable** - No significant performance impact
- [ ] **Accessibility maintained** - Works with accessibility tools

### Performance Testing

Use AnnaBo's built-in performance monitoring:

```swift
// Test operation performance
let startTime = CFAbsoluteTimeGetCurrent()
let result = CentralizedPresetManager.shared.addWidget(widget)
let duration = CFAbsoluteTimeGetCurrent() - startTime

print("MTMR: Widget addition took \(String(format: "%.3fs", duration))")

// Check for performance issues
if CentralizedPresetManager.shared.hasPerformanceIssues() {
    print("MTMR: Performance issues detected")
}
```

---

## 📚 Documentation Guidelines

### Code Documentation

- **Public APIs** - Add comprehensive `///` comments
- **Complex logic** - Explain non-obvious implementation details
- **Examples** - Provide usage examples for complex APIs
- **Parameters** - Document all parameters and return values

### Example Documentation

```swift
/// Manages TouchBar widget configurations with centralized preset management.
///
/// This class provides a single source of truth for all TouchBar configuration
/// operations, including widget addition, removal, duplication, and preset
/// management. It ensures data consistency and provides automatic backup
/// functionality.
///
/// ## Usage
///
/// ```swift
/// // Add a new widget
/// let widget = WidgetDescriptor(name: "Volume", type: "volume")
/// let success = CentralizedPresetManager.shared.addWidget(widget)
///
/// // Load a preset
/// let loaded = CentralizedPresetManager.shared.loadPreset("MyPreset")
/// ```
///
/// ## Performance
///
/// All operations are optimized for performance and include automatic
/// monitoring. Use `addWidgetWithPerformanceTracking()` for detailed
/// performance insights.
@MainActor
final class CentralizedPresetManager: ObservableObject {
    // Implementation...
}
```

### README Updates

When adding new features, update:

- [ ] **README.md** - Add feature description and usage
- [ ] **ARCHITECTURE.md** - Document new patterns and components
- [ ] **DEVELOPMENT_CHECKLIST.md** - Add development guidelines
- [ ] **Code comments** - Inline documentation

---

## 🐛 Bug Reports

### Before Reporting

1. **Check existing issues** - Search for similar problems
2. **Reproduce the bug** - Ensure it's consistently reproducible
3. **Check documentation** - Verify it's not user error
4. **Test on different devices** - Check if it's device-specific

### Bug Report Template

```markdown
## Bug Description
Brief description of what the bug is.

## Steps to Reproduce
1. Step 1
2. Step 2
3. Step 3

## Expected Behavior
What should happen.

## Actual Behavior
What actually happens.

## Environment
- macOS Version: [e.g., 12.0.1]
- AnnaBo Version: [e.g., 1.0.0]
- Device: [e.g., MacBook Pro 2021]
- TouchBar: [Yes/No]

## Additional Information
- Screenshots (if applicable)
- Error messages
- Console logs
- Configuration files
```

---

## 💡 Feature Requests

### Before Requesting

1. **Check existing features** - Ensure it's not already implemented
2. **Search issues** - Look for similar feature requests
3. **Think about implementation** - Consider complexity and impact
4. **Check roadmap** - See if it's already planned

### Feature Request Template

```markdown
## Feature Description
Brief description of the feature you'd like to see.

## Problem Statement
What problem does this feature solve?

## Proposed Solution
How would you like this feature to work?

## Alternatives Considered
What other approaches have you considered?

## Additional Context
Any other information that might be helpful.
```

---

## 🌍 Localization

### Adding New Languages

1. **Create language file** - Add new `.strings` files
2. **Translate all text** - Ensure complete coverage
3. **Test layout** - Verify text fits in UI elements
4. **Update documentation** - Document new language support

### Translation Guidelines

- **Maintain context** - Ensure translations make sense
- **Test with native speakers** - Get feedback from native users
- **Consider cultural differences** - Adapt to local preferences
- **Keep consistent terminology** - Use consistent translations

---

## 🏆 Recognition

### Contributor Levels

- **Contributor** - First successful contribution
- **Regular Contributor** - Multiple contributions over time
- **Core Contributor** - Significant contributions and leadership
- **Maintainer** - Project maintenance and review responsibilities

### Recognition Methods

- **GitHub profile** - Contributions appear on your profile
- **Release notes** - Contributors credited in releases
- **Contributors list** - Listed in project documentation
- **Special thanks** - Acknowledged in README and releases

---

## 🆘 Getting Help

### When You're Stuck

1. **Check documentation** - Start with README and guides
2. **Search issues** - Look for similar problems
3. **Ask in discussions** - Use GitHub Discussions
4. **Join community** - Connect with other contributors

### Resources

- [Development Checklist](DEVELOPMENT_CHECKLIST.md) - Step-by-step development guide
- [Architecture Documentation](ARCHITECTURE.md) - System design and patterns
- [Best Practices](README_BEST_PRACTICES.md) - Coding guidelines and examples
- [GitHub Discussions](https://github.com/yourusername/annabo/discussions) - Community help

---

## 📜 Code of Conduct

### Our Standards

- **Be respectful** - Treat everyone with dignity and respect
- **Be inclusive** - Welcome contributors from all backgrounds
- **Be constructive** - Provide helpful, constructive feedback
- **Be collaborative** - Work together for the common good

### Unacceptable Behavior

- **Harassment** - Bullying, intimidation, or discrimination
- **Trolling** - Deliberately disruptive behavior
- **Spam** - Unwanted promotional content
- **Inappropriate content** - Offensive or inappropriate material

### Enforcement

- **Warnings** - First violations result in warnings
- **Temporary bans** - Repeated violations may result in temporary bans
- **Permanent bans** - Severe or repeated violations may result in permanent bans

---

## 🎉 Thank You!

Thank you for contributing to AnnaBo! Your contributions help make TouchBar customization better for everyone.

### Quick Links

- [GitHub Repository](https://github.com/yourusername/annabo)
- [Issues](https://github.com/yourusername/annabo/issues)
- [Discussions](https://github.com/yourusername/annabo/discussions)
- [Wiki](https://github.com/yourusername/annabo/wiki)

### Stay Connected

- **Star the repository** - Show your support
- **Watch for updates** - Stay informed about new features
- **Share with others** - Help grow the community
- **Provide feedback** - Help us improve

---

*Happy coding! 🚀*

*This contributing guide is based on best practices from the open source community and adapted specifically for AnnaBo.*
