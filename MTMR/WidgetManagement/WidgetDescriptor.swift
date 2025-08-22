//
//  WidgetDescriptor.swift
//  MTMR
//
//  Created by Enhanced Menu System on 2024.
//  Type-safe widget description and configuration system.
//

import Cocoa
import SwiftUI

// MARK: - Widget Descriptor

struct WidgetDescriptor: Identifiable, Codable, Sendable {
    let id = UUID()
    let identifier: String
    let name: String
    let description: String
    let category: WidgetCategory
    let icon: String
    let configurationSchema: ConfigurationSchema
    
    // Computed properties
    var systemIcon: NSImage? {
        NSImage(systemSymbolName: icon, accessibilityDescription: name)
    }
    
    var previewImage: NSImage? {
        // Generate preview image based on widget type
        return NSImage(systemSymbolName: icon, accessibilityDescription: name)?
            .resized(to: NSSize(width: 64, height: 32))
    }
}

// MARK: - Widget Category

enum WidgetCategory: String, CaseIterable, Codable, Sendable {
    case systemControls = "System Controls"
    case productivity = "Productivity"
    case systemInfo = "System Info"
    case mediaApps = "Media & Apps"
    case custom = "Custom"
    
    var icon: String {
        switch self {
        case .systemControls: return "gear"
        case .productivity: return "briefcase"
        case .systemInfo: return "chart.bar"
        case .mediaApps: return "play.rectangle"
        case .custom: return "wrench.and.screwdriver"
        }
    }
    
    var description: String {
        switch self {
        case .systemControls: return "Essential system controls and shortcuts"
        case .productivity: return "Tools to enhance your productivity"
        case .systemInfo: return "System monitoring and information"
        case .mediaApps: return "Media controls and app launchers"
        case .custom: return "Custom scripts and advanced widgets"
        }
    }
}

// MARK: - Configuration Schema

enum ConfigurationSchema: Codable, Sendable {
    case simple([ConfigurationField])
    case advanced([ConfigurationField])
    case group([ConfigurationField])
}

enum ConfigurationField: Codable, Sendable {
    // Basic fields
    case title(String)
    case textField(String, defaultValue: String = "")
    case numberField(String, defaultValue: Double = 0, range: ClosedRange<Double>? = nil)
    case toggle(String, defaultValue: Bool = false)
    case slider(String, range: ClosedRange<Double>, step: Double = 0.1)
    
    // Advanced fields
    case dropdown(String, options: [String])
    case segmentedControl(String, options: [String])
    case colorPicker(String, defaultValue: NSColor = .systemBlue)
    case imagePicker(String)
    case filePicker(String, allowedTypes: [String] = [])
    case appPicker(String)
    case locationPicker(String)
    
    // Layout fields
    case layout(LayoutType)
    case spacing(Double)
    case alignment(AlignmentType)
    
    // Code editors
    case codeEditor(String, language: CodeLanguage)
    
    var displayName: String {
        switch self {
        case .title(let name): return name
        case .textField(let name, _): return name
        case .numberField(let name, _, _): return name
        case .toggle(let name, _): return name
        case .slider(let name, _, _): return name
        case .dropdown(let name, _): return name
        case .segmentedControl(let name, _): return name
        case .colorPicker(let name, _): return name
        case .imagePicker(let name): return name
        case .filePicker(let name, _): return name
        case .appPicker(let name): return name
        case .locationPicker(let name): return name
        case .layout(_): return "Layout"
        case .spacing(_): return "Spacing"
        case .alignment(_): return "Alignment"
        case .codeEditor(let name, _): return name
        }
    }
}

enum LayoutType: String, Codable, Sendable {
    case horizontal
    case vertical
    case grid
}

enum AlignmentType: String, Codable, Sendable {
    case left
    case center
    case right
    case leading
    case trailing
}

enum CodeLanguage: String, Codable, Sendable {
    case applescript
    case shell
    case python
    case javascript
}

// MARK: - Touch Bar Configuration

struct TouchBarConfiguration: Codable, Sendable {
    var widgets: [WidgetConfiguration]
    let layout: LayoutConfiguration
    let globalSettings: GlobalSettings
    
    init(widgets: [WidgetConfiguration] = [], layout: LayoutConfiguration = LayoutConfiguration(), globalSettings: GlobalSettings = GlobalSettings()) {
        self.widgets = widgets
        self.layout = layout
        self.globalSettings = globalSettings
    }
}

struct WidgetConfiguration: Identifiable, Codable, Sendable {
    let id: UUID
    let descriptor: WidgetDescriptor
    var configuration: [String: AnyCodable]
    var position: Int
    
    init(id: UUID = UUID(), descriptor: WidgetDescriptor, configuration: [String: Any], position: Int) {
        self.id = id
        self.descriptor = descriptor
        self.configuration = configuration.mapValues { AnyCodable($0) }
        self.position = position
    }
}

struct LayoutConfiguration: Codable, Sendable {
    let spacing: Double
    let padding: EdgeInsets
    let alignment: AlignmentType
    
    init(spacing: Double = 4.0, padding: EdgeInsets = EdgeInsets(), alignment: AlignmentType = .center) {
        self.spacing = spacing
        self.padding = padding
        self.alignment = alignment
    }
}

struct EdgeInsets: Codable, Sendable {
    let top: Double
    let leading: Double
    let bottom: Double
    let trailing: Double
    
    init(top: Double = 0, leading: Double = 0, bottom: Double = 0, trailing: Double = 0) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }
}

struct GlobalSettings: Codable, Sendable {
    let hapticFeedback: Bool
    let showControlStrip: Bool
    let multitouchGestures: Bool
    let blacklistedApps: [String]
    
    init(hapticFeedback: Bool = true, showControlStrip: Bool = true, multitouchGestures: Bool = false, blacklistedApps: [String] = []) {
        self.hapticFeedback = hapticFeedback
        self.showControlStrip = showControlStrip
        self.multitouchGestures = multitouchGestures
        self.blacklistedApps = blacklistedApps
    }
}

// MARK: - AnyCodable Helper

struct AnyCodable: Codable, Sendable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictionaryValue = try? container.decode([String: AnyCodable].self) {
            value = dictionaryValue.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictionaryValue as [String: Any]:
            try container.encode(dictionaryValue.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - Extensions

extension NSImage {
    func resized(to size: NSSize) -> NSImage {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        defer { newImage.unlockFocus() }
        
        let rect = NSRect(origin: .zero, size: size)
        draw(in: rect, from: NSRect(origin: .zero, size: self.size), operation: .sourceOver, fraction: 1.0)
        
        return newImage
    }
}

extension NSColor: @retroactive Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let colorString = try container.decode(String.self)
        
        // Simple color decoding - in a real implementation, you'd want more robust color handling
        switch colorString {
        case "systemBlue": self = .systemBlue
        case "systemRed": self = .systemRed
        case "systemGreen": self = .systemGreen
        case "systemYellow": self = .systemYellow
        case "systemOrange": self = .systemOrange
        case "systemPurple": self = .systemPurple
        default: self = .systemBlue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        // Simple color encoding - in a real implementation, you'd want more robust color handling
        let colorString: String
        switch self {
        case .systemBlue: colorString = "systemBlue"
        case .systemRed: colorString = "systemRed"
        case .systemGreen: colorString = "systemGreen"
        case .systemYellow: colorString = "systemYellow"
        case .systemOrange: colorString = "systemOrange"
        case .systemPurple: colorString = "systemPurple"
        default: colorString = "systemBlue"
        }
        
        try container.encode(colorString)
    }
}
