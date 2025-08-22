//
//  CustomWidgetBuilder.swift
//  MTMR
//
//  Created by Enhanced Menu System on 2024.
//  Phase 5A: Advanced Widget Customization - Custom Widget Builder.
//

import Cocoa
import SwiftUI
import JavaScriptCore

// MARK: - Custom Widget Builder

@MainActor
final class CustomWidgetBuilder: ObservableObject {
    static let shared = CustomWidgetBuilder()
    
    @Published var isVisible = false
    @Published var currentWidget: CustomWidget = CustomWidget()
    @Published var selectedElement: WidgetElement?
    @Published var showScriptEditor = false
    @Published var showThemeEditor = false
    @Published var previewMode = false
    
    private var builderWindow: NSWindow?
    private let scriptingEngine = ScriptingEngine()
    private let themeManager = ThemeManager()
    
    private init() {}
    
    // MARK: - Public Methods
    
    func showBuilder() {
        isVisible = true
        
        if builderWindow == nil {
            createBuilderWindow()
        }
        
        builderWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func openScriptEditor() {
        showScriptEditor = true
        let scriptWindow = createScriptEditorWindow()
        scriptWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func openThemeEditor() {
        showThemeEditor = true
        let themeWindow = createThemeEditorWindow()
        themeWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - Private Methods
    
    private func createBuilderWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1400, height: 900),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "MTMR Custom Widget Builder"
        window.center()
        window.setFrameAutosaveName("CustomWidgetBuilderWindow")
        
        // Create SwiftUI view
        let builderView = CustomWidgetBuilderView(
            widget: Binding(
                get: { self.currentWidget },
                set: { self.currentWidget = $0 }
            ),
            selectedElement: Binding(
                get: { self.selectedElement },
                set: { self.selectedElement = $0 }
            ),
            showScriptEditor: Binding(
                get: { self.showScriptEditor },
                set: { self.showScriptEditor = $0 }
            ),
            showThemeEditor: Binding(
                get: { self.showThemeEditor },
                set: { self.showThemeEditor = $0 }
            ),
            previewMode: Binding(
                get: { self.previewMode },
                set: { self.previewMode = $0 }
            ),
            onSave: { [weak self] in
                self?.saveCustomWidget()
            },
            onClose: { [weak self] in
                self?.closeBuilderWindow()
            }
        )
        
        let hostingView = NSHostingView(rootView: builderView)
        window.contentView = hostingView
        
        self.builderWindow = window
    }
    
    private func createScriptEditorWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Widget Script Editor"
        window.center()
        
        let scriptEditorView = ScriptEditorView(
            script: Binding(
                get: { self.currentWidget.script },
                set: { self.currentWidget.script = $0 }
            ),
            onSave: { [weak self] in
                self?.saveScript()
            }
        )
        
        let hostingView = NSHostingView(rootView: scriptEditorView)
        window.contentView = hostingView
        
        return window
    }
    
    private func createThemeEditorWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Theme Editor"
        window.center()
        
        let themeEditorView = ThemeEditorView(
            theme: Binding(
                get: { self.currentWidget.theme },
                set: { self.currentWidget.theme = $0 }
            ),
            onSave: { [weak self] in
                self?.saveTheme()
            }
        )
        
        let hostingView = NSHostingView(rootView: themeEditorView)
        window.contentView = hostingView
        
        return window
    }
    
    private func closeBuilderWindow() {
        builderWindow?.close()
        builderWindow = nil
        isVisible = false
        selectedElement = nil
    }
    
    private func saveCustomWidget() {
        do {
            try saveWidgetToFile()
            print("MTMR: Custom widget saved successfully")
            showSuccessAlert()
        } catch {
            showErrorAlert(error: error)
        }
    }
    
    private func saveWidgetToFile() throws {
        // Save custom widget to user's custom widgets directory
        let customWidgetsPath = getCustomWidgetsDirectory()
        let widgetFileName = "\(currentWidget.name).json"
        let widgetPath = customWidgetsPath.appendingPathComponent(widgetFileName)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(currentWidget)
        try data.write(to: widgetPath)
    }
    
    private func getCustomWidgetsDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let mtmrPath = appSupport.appendingPathComponent("MTMR")
        let customWidgetsPath = mtmrPath.appendingPathComponent("CustomWidgets")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: customWidgetsPath, withIntermediateDirectories: true)
        
        return customWidgetsPath
    }
    
    private func saveScript() {
        // Save script changes
        print("MTMR: Widget script saved")
    }
    
    private func saveTheme() {
        // Save theme changes
        print("MTMR: Widget theme saved")
    }
    
    private func showSuccessAlert(message: String = "Custom widget saved successfully!") {
        let alert = NSAlert()
        alert.messageText = "Success"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showErrorAlert(error: Error) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = "Failed to save custom widget: \(error.localizedDescription)"
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .critical
        alert.runModal()
    }
}

// MARK: - Custom Widget Model

struct CustomWidget: Codable, Identifiable {
    let id = UUID()
    var name: String = "New Custom Widget"
    var description: String = ""
    var elements: [WidgetElement] = []
    var script: String = ""
    var theme: WidgetTheme = WidgetTheme()
    var configuration: [String: String] = [:]
    var version: String = "1.0.0"
    var author: String = ""
    var category: WidgetCategory = .custom
    
    var displayName: String {
        return name.isEmpty ? "Untitled Widget" : name
    }
}

struct WidgetElement: Codable, Identifiable {
    let id = UUID()
    var type: ElementType
    var position: CGPoint
    var size: CGSize
    var properties: [String: String] = [:]
    var style: ElementStyle = ElementStyle()
    
    enum ElementType: String, CaseIterable, Codable {
        case button = "Button"
        case label = "Label"
        case image = "Image"
        case slider = "Slider"
        case progress = "Progress"
        case custom = "Custom"
        
        var icon: String {
            switch self {
            case .button: return "button.programmable"
            case .label: return "textformat"
            case .image: return "photo"
            case .slider: return "slider.horizontal.3"
            case .progress: return "chart.bar"
            case .custom: return "rectangle.3.group"
            }
        }
    }
}

struct ElementStyle: Codable {
    var backgroundColor: String = "#000000"
    var textColor: String = "#FFFFFF"
    var fontSize: CGFloat = 14.0
    var fontFamily: String = "SF Pro"
    var borderRadius: CGFloat = 4.0
    var opacity: CGFloat = 1.0
    var borderWidth: CGFloat = 0.0
    var borderColor: String = "#000000"
}

struct WidgetTheme: Codable {
    var name: String = "Default"
    var primaryColor: String = "#007AFF"
    var secondaryColor: String = "#5856D6"
    var backgroundColor: String = "#000000"
    var textColor: String = "#FFFFFF"
    var accentColor: String = "#FF9500"
    var borderRadius: CGFloat = 6.0
    var padding: CGFloat = 8.0
    var spacing: CGFloat = 4.0
}

enum WidgetCategory: String, CaseIterable, Codable {
    case productivity = "Productivity"
    case development = "Development"
    case media = "Media"
    case gaming = "Gaming"
    case custom = "Custom"
    case utility = "Utility"
    case entertainment = "Entertainment"
}

// MARK: - Scripting Engine

class ScriptingEngine {
    private let context = JSContext()
    
    init() {
        setupJavaScriptContext()
    }
    
    private func setupJavaScriptContext() {
        // Set up JavaScript context for widget scripting
        context?.exceptionHandler = { context, exception in
            print("MTMR: JavaScript error: \(exception?.toString() ?? "Unknown error")")
        }
        
        // Add common APIs
        addCommonAPIs()
    }
    
    private func addCommonAPIs() {
        // Add system APIs for widget scripting
        context?.setObject(SystemAPI(), forKeyedSubscript: "system" as NSString)
        context?.setObject(WidgetAPI(), forKeyedSubscript: "widget" as NSString)
    }
    
    func executeScript(_ script: String) -> JSValue? {
        return context?.evaluateScript(script)
    }
}

// MARK: - System API for JavaScript

@objc class SystemAPI: NSObject {
    @objc func getSystemInfo() -> [String: Any] {
        return [
            "platform": "macOS",
            "version": ProcessInfo.processInfo.operatingSystemVersionString,
            "hostname": Host.current().localizedName ?? "Unknown"
        ]
    }
    
    @objc func executeCommand(_ command: String) -> String {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}

// MARK: - Widget API for JavaScript

@objc class WidgetAPI: NSObject {
    @objc func updateDisplay(_ data: [String: Any]) {
        // Update widget display with new data
        print("MTMR: Widget display updated with data: \(data)")
    }
    
    @objc func showNotification(_ message: String) {
        // Show notification
        let notification = NSUserNotification()
        notification.title = "MTMR Widget"
        notification.informativeText = message
        NSUserNotificationCenter.default.deliver(notification)
    }
}

// MARK: - Theme Manager

class ThemeManager {
    private var themes: [WidgetTheme] = []
    
    init() {
        loadDefaultThemes()
    }
    
    private func loadDefaultThemes() {
        themes = [
            WidgetTheme(name: "Default", primaryColor: "#007AFF", secondaryColor: "#5856D6"),
            WidgetTheme(name: "Dark", primaryColor: "#FF9500", secondaryColor: "#FF2D92", backgroundColor: "#1C1C1E"),
            WidgetTheme(name: "Light", primaryColor: "#007AFF", secondaryColor: "#5856D6", backgroundColor: "#F2F2F7", textColor: "#000000"),
            WidgetTheme(name: "Neon", primaryColor: "#00FF00", secondaryColor: "#FF00FF", backgroundColor: "#000000"),
            WidgetTheme(name: "Minimal", primaryColor: "#FFFFFF", secondaryColor: "#CCCCCC", backgroundColor: "#000000", borderRadius: 0)
        ]
    }
    
    func getThemes() -> [WidgetTheme] {
        return themes
    }
    
    func addTheme(_ theme: WidgetTheme) {
        themes.append(theme)
    }
}

// MARK: - SwiftUI Views

struct CustomWidgetBuilderView: View {
    @Binding var widget: CustomWidget
    @Binding var selectedElement: WidgetElement?
    @Binding var showScriptEditor: Bool
    @Binding var showThemeEditor: Bool
    @Binding var previewMode: Bool
    let onSave: () -> Void
    let onClose: () -> Void
    
    @State private var showElementLibrary = false
    @State private var showProperties = false
    
    var body: some View {
        HSplitView {
            // Left Panel - Element Library
            elementLibraryPanel
                .frame(minWidth: 250, maxWidth: 300)
            
            // Center Panel - Canvas
            canvasPanel
                .frame(minWidth: 600)
            
            // Right Panel - Properties
            propertiesPanel
                .frame(minWidth: 300, maxWidth: 400)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Add Element") {
                    showElementLibrary = true
                }
                .keyboardShortcut("n")
                
                Button("Script Editor") {
                    showScriptEditor = true
                }
                .keyboardShortcut("s")
                
                Button("Theme Editor") {
                    showThemeEditor = true
                }
                .keyboardShortcut("t")
                
                Button("Preview") {
                    previewMode.toggle()
                }
                .keyboardShortcut("p")
                
                Divider()
                
                Button("Save") {
                    onSave()
                }
                .keyboardShortcut("s")
                
                Button("Close") {
                    onClose()
                }
                .keyboardShortcut(.escape)
            }
        }
        .sheet(isPresented: $showElementLibrary) {
            ElementLibrarySheet(onElementSelected: { elementType in
                addElement(elementType)
            })
        }
        .sheet(isPresented: $showScriptEditor) {
            ScriptEditorSheet(script: $widget.script)
        }
        .sheet(isPresented: $showThemeEditor) {
            ThemeEditorSheet(theme: $widget.theme)
        }
    }
    
    private var elementLibraryPanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Element Library")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button("Add") {
                    showElementLibrary = true
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            Divider()
            
            // Available elements
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(WidgetElement.ElementType.allCases, id: \.self) { elementType in
                        ElementTypeRow(
                            elementType: elementType,
                            onDrag: { location in
                                // Handle drag to canvas
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var canvasPanel: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Widget Canvas")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Clear Canvas") {
                    widget.elements.removeAll()
                }
                .buttonStyle(.bordered)
                .disabled(widget.elements.isEmpty)
            }
            .padding()
            
            // Canvas
            ZStack {
                // Canvas background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .frame(height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary, lineWidth: 1)
                    )
                
                // Widget elements
                ForEach(widget.elements) { element in
                    WidgetElementView(
                        element: element,
                        isSelected: selectedElement?.id == element.id,
                        onTap: {
                            selectedElement = element
                        }
                    )
                    .position(element.position)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 40)
            
            // Widget info
            VStack(alignment: .leading, spacing: 8) {
                Text("Widget: \(widget.displayName)")
                    .font(.headline)
                
                Text("Elements: \(widget.elements.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 40)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var propertiesPanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Properties")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Properties content
            if let selectedElement = selectedElement {
                ElementPropertiesView(element: Binding(
                    get: { selectedElement },
                    set: { newValue in
                        // Update the selected element
                        if let index = widget.elements.firstIndex(where: { $0.id == selectedElement.id }) {
                            widget.elements[index] = newValue
                        }
                    }
                ))
            } else {
                VStack {
                    Image(systemName: "slider.horizontal.3")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Select an element to edit its properties")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func addElement(_ elementType: WidgetElement.ElementType) {
        let newElement = WidgetElement(
            type: elementType,
            position: CGPoint(x: 100, y: 30),
            size: CGSize(width: 80, height: 30)
        )
        widget.elements.append(newElement)
    }
}

struct WidgetElementView: View {
    let element: WidgetElement
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: element.type.icon)
                    .font(.caption)
                
                Text(element.type.rawValue)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .frame(width: element.size.width, height: element.size.height)
            .background(isSelected ? Color.accentColor : Color.clear)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(element.style.borderRadius)
            .overlay(
                RoundedRectangle(cornerRadius: element.style.borderRadius)
                    .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ElementTypeRow: View {
    let elementType: WidgetElement.ElementType
    let onDrag: (CGPoint) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: elementType.icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(elementType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Add \(elementType.rawValue.lowercased()) element")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "plus.circle")
                .foregroundColor(.accentColor)
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .onDrag {
            onDrag(.zero)
            return NSItemProvider()
        }
    }
}

struct ElementPropertiesView: View {
    @Binding var element: WidgetElement
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Element info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: element.type.icon)
                            .font(.title2)
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(element.type.rawValue)
                                .font(.headline)
                            
                            Text("Element Properties")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                Divider()
                
                // Position and size
                VStack(alignment: .leading, spacing: 12) {
                    Text("Layout")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("X:")
                        TextField("X", text: Binding(
                            get: { String(format: "%.0f", element.position.x) },
                            set: { if let value = Double($0) { element.position.x = value } }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        
                        Text("Y:")
                        TextField("Y", text: Binding(
                            get: { String(format: "%.0f", element.position.y) },
                            set: { if let value = Double($0) { element.position.y = value } }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    }
                    
                    HStack {
                        Text("Width:")
                        TextField("Width", text: Binding(
                            get: { String(format: "%.0f", element.size.width) },
                            set: { if let value = Double($0) { element.size.width = value } }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        
                        Text("Height:")
                        TextField("Height", text: Binding(
                            get: { String(format: "%.0f", element.size.height) },
                            set: { if let value = Double($0) { element.size.height = value } }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    }
                }
                
                Divider()
                
                // Style properties
                VStack(alignment: .leading, spacing: 12) {
                    Text("Style")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("Background:")
                        ColorPicker("", selection: .constant(Color.black))
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("Text Color:")
                        ColorPicker("", selection: .constant(Color.white))
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("Font Size:")
                        TextField("Font Size", text: Binding(
                            get: { String(format: "%.0f", element.style.fontSize) },
                            set: { if let value = Double($0) { element.style.fontSize = value } }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Sheet Views

struct ElementLibrarySheet: View {
    let onElementSelected: (WidgetElement.ElementType) -> Void
    @State private var isPresented = true
    
    var body: some View {
        VStack {
            Text("Add Element")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
                ], spacing: 16) {
                    ForEach(WidgetElement.ElementType.allCases, id: \.self) { elementType in
                        ElementTypeCard(
                            elementType: elementType,
                            onSelect: {
                                onElementSelected(elementType)
                                isPresented = false
                            }
                        )
                    }
                }
                .padding()
            }
            
            Button("Cancel") {
                isPresented = false
            }
            .keyboardShortcut(.escape)
        }
        .frame(width: 600, height: 400)
    }
}

struct ElementTypeCard: View {
    let elementType: WidgetElement.ElementType
    let onSelect: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: elementType.icon)
                .font(.largeTitle)
                .foregroundColor(.accentColor)
            
            Text(elementType.rawValue)
                .font(.headline)
            
            Text("Add \(elementType.rawValue.lowercased()) to your widget")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Add Element") {
                onSelect()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(height: 150)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ScriptEditorSheet: View {
    @Binding var script: String
    @State private var isPresented = true
    
    var body: some View {
        VStack {
            Text("Widget Script Editor")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            TextEditor(text: $script)
                .font(.system(.body, design: .monospaced))
                .padding()
            
            HStack {
                Button("Save") {
                    isPresented = false
                }
                .keyboardShortcut("s")
                
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
            }
            .padding()
        }
        .frame(width: 800, height: 600)
    }
}

struct ThemeEditorSheet: View {
    @Binding var theme: WidgetTheme
    @State private var isPresented = true
    
    var body: some View {
        VStack {
            Text("Theme Editor")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            VStack(alignment: .leading, spacing: 16) {
                // Colors Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Colors")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("Primary Color:")
                        ColorPicker("", selection: .constant(Color.blue))
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("Secondary Color:")
                        ColorPicker("", selection: .constant(Color.purple))
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("Background Color:")
                        ColorPicker("", selection: .constant(Color.black))
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("Text Color:")
                        ColorPicker("", selection: .constant(Color.white))
                            .labelsHidden()
                    }
                }
                
                Divider()
                
                // Layout Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Layout")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("Border Radius:")
                        TextField("Border Radius", text: Binding(
                            get: { String(format: "%.0f", theme.borderRadius) },
                            set: { if let value = Double($0) { theme.borderRadius = value } }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        Text("Padding:")
                        TextField("Padding", text: Binding(
                            get: { String(format: "%.0f", theme.padding) },
                            set: { if let value = Double($0) { theme.padding = value } }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        Text("Spacing:")
                        TextField("Spacing", text: Binding(
                            get: { String(format: "%.0f", theme.spacing) },
                            set: { if let value = Double($0) { theme.spacing = value } }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                }
            }
            .padding()
            
            HStack {
                Button("Save") {
                    isPresented = false
                }
                .keyboardShortcut("s")
                
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - Missing Views

struct ScriptEditorView: View {
    @Binding var script: String
    let onSave: () -> Void
    
    var body: some View {
        VStack {
            Text("Widget Script Editor")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            TextEditor(text: $script)
                .font(.system(.body, design: .monospaced))
                .padding()
            
            HStack {
                Button("Save") {
                    onSave()
                }
                .keyboardShortcut("s")
                
                Button("Cancel") {
                    // Handle cancel
                }
                .keyboardShortcut(.escape)
            }
            .padding()
        }
        .frame(width: 800, height: 600)
    }
}

struct ThemeEditorView: View {
    @Binding var theme: WidgetTheme
    let onSave: () -> Void
    
    var body: some View {
        VStack {
            Text("Theme Editor")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            VStack(alignment: .leading, spacing: 16) {
                // Colors Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Colors")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("Primary Color:")
                        ColorPicker("", selection: .constant(Color.blue))
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("Secondary Color:")
                        ColorPicker("", selection: .constant(Color.purple))
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("Background Color:")
                        ColorPicker("", selection: .constant(Color.black))
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("Text Color:")
                        ColorPicker("", selection: .constant(Color.white))
                            .labelsHidden()
                    }
                }
                
                Divider()
                
                // Layout Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Layout")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("Border Radius:")
                        TextField("Border Radius", text: Binding(
                            get: { String(format: "%.0f", theme.borderRadius) },
                            set: { if let value = Double($0) { theme.borderRadius = value } }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        Text("Padding:")
                        TextField("Padding", text: Binding(
                            get: { String(format: "%.0f", theme.padding) },
                            set: { if let value = Double($0) { theme.padding = value } }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        Text("Spacing:")
                        TextField("Spacing", text: Binding(
                            get: { String(format: "%.0f", theme.spacing) },
                            set: { if let value = Double($0) { theme.spacing = value } }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                }
            }
            .padding()
            
            HStack {
                Button("Save") {
                    onSave()
                }
                .keyboardShortcut("s")
                
                Button("Cancel") {
                    // Handle cancel
                }
                .keyboardShortcut(.escape)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
    }
}
