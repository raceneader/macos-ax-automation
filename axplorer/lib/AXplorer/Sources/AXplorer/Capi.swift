//
//  Capi.swift
//  access_test_sw
//
//  Created by Nasahn Reader on 1/16/25.
//

/// This file provides C-compatible wrapper functions for the AXplorer accessibility framework.
/// It enables interoperability between Swift accessibility functionality and C-based clients,
/// handling memory management, type conversions, and safe access to the underlying Swift objects.
/// The API is organized into several functional areas:
/// - Application management (raising, launching)
/// - Explorer lifecycle (creation, destruction)
/// - YAML hierarchy generation (app, window, menu bar)
/// - Element actions and attribute manipulation
/// - Mouse actions (clicks, scrolling, dragging)
/// - YAML processing utilities

import AppKit
import Cocoa
import ApplicationServices
import Foundation

// MARK: - Mouse Location Struct

/// C-compatible struct to return mouse coordinates
public struct MousePoint {
    public var x: Double
    public var y: Double
}

// MARK: - Application Management

/// Raises (brings to front) an application with the specified name.
/// - Parameter appName: A C string containing the name of the application to raise
/// - Returns: 1 if successful, 0 if failed
@_cdecl("raiseApplication")
public func raiseApplication(appName: UnsafePointer<CChar>) -> Int32 {
    let appNameString = String(cString: appName)
    let result: Bool = raiseApplication(appName: appNameString)
    return result ? 1 : 0 // Convert Bool to Int32
}

/// Launches an application with the specified name.
/// - Parameter appName: A C string containing the name of the application to launch
/// - Returns: 1 if successful, 0 if failed
@_cdecl("launchApplication")
public func launchApplication(appName: UnsafePointer<CChar>) -> Int32 {
    let appNameString = String(cString: appName)
    let result = launchApplication(appName: appNameString)
    return result ? 1 : 0
}

// MARK: - Explorer Lifecycle

/// Creates a new AccessExplorer instance for the specified application.
/// - Parameter appName: A C string containing the name of the target application
/// - Returns: An unmanaged pointer to the created AccessExplorer instance, or nil if creation failed
/// - Note: The returned pointer must be freed using destroyAccessExplorer to prevent memory leaks
@_cdecl("createAccessExplorer")
public func createAccessExplorer(appName: UnsafePointer<CChar>) -> UnsafeMutableRawPointer? {
    let appNameString = String(cString: appName)
    guard let explorer = AccessExplorer(appName: appNameString) else { return nil }
    return UnsafeMutableRawPointer(Unmanaged.passRetained(explorer).toOpaque())
}

/// Destroys an AccessExplorer instance and frees its associated memory.
/// - Parameter context: The explorer context pointer to destroy
/// - Note: This function should be called when the explorer is no longer needed to prevent memory leaks
@_cdecl("destroyAccessExplorer")
public func destroyAccessExplorer(context: UnsafeMutableRawPointer?) {
    guard let context = context else { return }
    Unmanaged<AccessExplorer>.fromOpaque(context).release()
}

// MARK: - YAML Generation

/// Retrieves the YAML representation of the application's accessibility hierarchy.
/// - Parameters:
///   - context: The explorer context pointer obtained from createAccessExplorer
///   - maxDepth: Maximum depth to traverse in the accessibility hierarchy
/// - Returns: A C string containing the YAML representation, or nil if failed
/// - Note: The returned string must be freed by the caller
@_cdecl("getAppYAML")
public func getAppYAML(context: UnsafeMutableRawPointer?, maxDepth: Int) -> UnsafePointer<CChar>? {
    guard let context = context else { return nil }
    let explorer = Unmanaged<AccessExplorer>.fromOpaque(context).takeUnretainedValue()
    guard let yaml = explorer.getAppYAML(maxDepth: maxDepth) else { return nil }
    return UnsafePointer(strdup(yaml))
}

/// Retrieves the YAML representation of the application's main window hierarchy.
/// - Parameters:
///   - context: The explorer context pointer obtained from createAccessExplorer
///   - maxDepth: Maximum depth to traverse in the accessibility hierarchy
/// - Returns: A C string containing the YAML representation, or nil if failed
/// - Note: The returned string must be freed by the caller
@_cdecl("getMainWindowYAML")
public func getMainWindowYAML(context: UnsafeMutableRawPointer?, maxDepth: Int) -> UnsafePointer<CChar>? {
    guard let context = context else { return nil }
    let explorer = Unmanaged<AccessExplorer>.fromOpaque(context).takeUnretainedValue()
    guard let yaml = explorer.getMainWindowYAML(maxDepth: maxDepth) else { return nil }
    return UnsafePointer(strdup(yaml))
}

/// Retrieves the YAML representation of the application's focused window hierarchy.
/// - Parameters:
///   - context: The explorer context pointer obtained from createAccessExplorer
///   - maxDepth: Maximum depth to traverse in the accessibility hierarchy
/// - Returns: A C string containing the YAML representation, or nil if failed
/// - Note: The returned string must be freed by the caller
@_cdecl("getFocusedWindowYAML")
public func getFocusedWindowYAML(context: UnsafeMutableRawPointer?, maxDepth: Int) -> UnsafePointer<CChar>? {
    guard let context = context else { return nil }
    let explorer = Unmanaged<AccessExplorer>.fromOpaque(context).takeUnretainedValue()
    guard let yaml = explorer.getFocusedWindowYAML(maxDepth: maxDepth) else { return nil }
    return UnsafePointer(strdup(yaml))
}

/// Retrieves the YAML representation of the application's menu bar hierarchy.
/// - Parameters:
///   - context: The explorer context pointer obtained from createAccessExplorer
///   - maxDepth: Maximum depth to traverse in the accessibility hierarchy
/// - Returns: A C string containing the YAML representation, or nil if failed
/// - Note: The returned string must be freed by the caller
@_cdecl("getMenuBarYAML")
public func getMenuBarYAML(context: UnsafeMutableRawPointer?, maxDepth: Int) -> UnsafePointer<CChar>? {
    guard let context = context else { return nil }
    let explorer = Unmanaged<AccessExplorer>.fromOpaque(context).takeUnretainedValue()
    guard let yaml = explorer.getMenuBarYAML(maxDepth: maxDepth) else { return nil }
    return UnsafePointer(strdup(yaml))
}

/// Retrieves the YAML representation of a specific element in the accessibility hierarchy.
/// - Parameters:
///   - context: The explorer context pointer obtained from createAccessExplorer
///   - contextType: A C string specifying the context type (e.g., "app", "window", "menubar")
///   - idx: The index of the element to query
///   - maxDepth: Maximum depth to traverse in the accessibility hierarchy
/// - Returns: A C string containing the YAML representation, or nil if failed
/// - Note: The returned string must be freed by the caller

/// Retrieves the YAML representation of the UI element at the current mouse cursor position.
/// - Parameters:
///   - context: The explorer context pointer obtained from createAccessExplorer
///   - maxDepth: Maximum depth to traverse in the accessibility hierarchy (default: 2)
/// - Returns: A C string containing the YAML representation, or nil if failed
/// - Note: The returned string must be freed by the caller
@_cdecl("getElementAtMousePositionYAML")
public func getElementAtMousePositionYAML(
    context: UnsafeMutableRawPointer?,
    maxDepth: Int32
) -> UnsafePointer<CChar>? {
    guard let context = context else { return nil }
    let explorer = Unmanaged<AccessExplorer>.fromOpaque(context).takeUnretainedValue()
    guard let yaml = explorer.getElementAtMousePositionYAML(maxDepth: Int(maxDepth)) else { return nil }
    return UnsafePointer(strdup(yaml))
}

@_cdecl("getQueryElementYAML")
public func getQueryElementYAML(
    context: UnsafeMutableRawPointer?,
    contextType: UnsafePointer<CChar>,
    idx: Int,
    maxDepth: Int
) -> UnsafePointer<CChar>? {
    guard let context = context else { return nil }
    let explorer = Unmanaged<AccessExplorer>.fromOpaque(context).takeUnretainedValue()
    let contextString = String(cString: contextType)
    guard let elementContext = ElementContext(rawValue: contextString) else {
        print("Error: Invalid context type '\(contextString)'.")
        return nil
    }
    guard let yaml = explorer.getQueryElementYAML(context: elementContext, idx: idx, maxDepth: maxDepth) else {
        return nil
    }
    return UnsafePointer(strdup(yaml))
}

// MARK: - Element Actions

/// Performs an accessibility action on a specific element.
/// - Parameters:
///   - context: The explorer context pointer obtained from createAccessExplorer
///   - contextType: A C string specifying the context type (e.g., "app", "window", "menubar")
///   - elementId: The identifier of the element to perform the action on
///   - action: A C string specifying the action to perform (e.g., "press", "increment")
/// - Returns: true if the action was performed successfully, false otherwise
@_cdecl("performAction")
public func performAction(
    context: UnsafeMutableRawPointer?,
    contextType: UnsafePointer<CChar>,
    elementId: Int,
    action: UnsafePointer<CChar>
) -> Bool {
    guard let context = context else { return false }
    let explorer = Unmanaged<AccessExplorer>.fromOpaque(context).takeUnretainedValue()
    let contextString = String(cString: contextType)
    let actionString = String(cString: action)
    guard let elementContext = ElementContext(rawValue: contextString) else {
        print("Error: Invalid context type '\(contextString)'.")
        return false
    }
    return explorer.performAction(context: elementContext, elementId: elementId, action: actionString)
}

/// Sets the value of an accessibility attribute for a specific element.
/// - Parameters:
///   - context: The explorer context pointer obtained from createAccessExplorer
///   - contextType: A C string specifying the context type (e.g., "app", "window", "menubar")
///   - elementId: The identifier of the element to modify
///   - attribute: A C string specifying the attribute to modify
///   - value: A pointer to the new value
///   - valueType: A C string specifying the type of value ("String", "Bool", or "Number")
/// - Returns: true if the attribute was set successfully, false otherwise
@_cdecl("setAttributeValue")
public func setAttributeValue(
    context: UnsafeMutableRawPointer?,
    contextType: UnsafePointer<CChar>,
    elementId: Int,
    attribute: UnsafePointer<CChar>,
    value: UnsafeRawPointer?,
    valueType: UnsafePointer<CChar>
) -> Bool {
    guard let context = context, let value = value else { return false }

    let explorer = Unmanaged<AccessExplorer>.fromOpaque(context).takeUnretainedValue()
    let contextString = String(cString: contextType)
    let attributeString = String(cString: attribute)
    let valueTypeString = String(cString: valueType)

    guard let elementContext = ElementContext(rawValue: contextString) else {
        print("Error: Invalid context type '\(contextString)'.")
        return false
    }

    // Copy the value based on the specified type
    let convertedValue: Any
    if valueTypeString == "String" {
        convertedValue = String(cString: value.assumingMemoryBound(to: CChar.self))
    } else if valueTypeString == "Bool" {
        convertedValue = value.load(as: Bool.self)
    } else if valueTypeString == "Number" {
        let numberValue = value.load(as: Double.self) // Assuming NSNumber is represented as a Double
        convertedValue = NSNumber(value: numberValue)
    } else {
        print("Error: Unsupported value type '\(valueTypeString)'.")
        return false
    }

    return explorer.setAttributeValue(context: elementContext, elementId: elementId, attribute: attributeString, value: convertedValue)
}


/// Moves the mouse cursor to the specified position of an element.
/// - Parameters:
///   - context: The explorer context pointer obtained from createAccessExplorer
///   - contextType: A C string specifying the context type (e.g., "app", "window", "menubar")
///   - elementId: The identifier of the element to move to
///   - position: A C string specifying the position ("center" or "bottomRight")
/// - Returns: true if the mouse was moved successfully, false otherwise
@_cdecl("moveToElement")
public func moveToElement(
    context: UnsafeMutableRawPointer?,
    contextType: UnsafePointer<CChar>,
    elementId: Int,
    position: UnsafePointer<CChar>
) -> Bool {
    guard let context = context else { return false }
    let explorer = Unmanaged<AccessExplorer>.fromOpaque(context).takeUnretainedValue()
    let contextString = String(cString: contextType)
    guard let elementContext = ElementContext(rawValue: contextString) else {
        print("Error: Invalid context type '\(contextString)'.")
        return false
    }
    let positionString = String(cString: position)
    let elementPosition = positionString == "bottomRight" ? ElementPosition.bottomRight : ElementPosition.center
    return Action.moveToElement(explorer: explorer, context: elementContext, elementId: elementId, position: elementPosition)
}

// MARK: - Mouse Actions

/// Gets the current mouse cursor position
/// - Parameters:
///   - x: Pointer to store the x coordinate
///   - y: Pointer to store the y coordinate
/// - Returns: true if coordinates were retrieved successfully, false otherwise
@_cdecl("getMouseLocation")
public func getMouseLocation(x: UnsafeMutablePointer<Double>, y: UnsafeMutablePointer<Double>) -> Bool {
    guard let location = ActionHelper.getMouseLocation() else { return false }
    x.pointee = Double(location.x)
    y.pointee = Double(location.y)
    return true
}

/// Performs a left mouse button click at the current cursor position.
/// - Returns: true if the click was performed successfully, false otherwise
@_cdecl("leftClick")
public func leftClick() -> Bool {
    return Action.performLeftClick()
}

/// Performs a right mouse button click at the current cursor position.
/// - Returns: true if the click was performed successfully, false otherwise
@_cdecl("rightClick")
public func rightClick() -> Bool {
    return Action.performRightClick()
}

/// Performs a double-click with the left mouse button at the current cursor position.
/// - Returns: true if the double-click was performed successfully, false otherwise
@_cdecl("doubleLeftClick")
public func doubleLeftClick() -> Bool {
    return Action.performDoubleLeftClick()
}

/// Performs a scroll up action with the specified distance.
/// - Parameter distance: The distance to scroll in points (default: 800)
/// - Returns: true if the scroll was performed successfully, false otherwise
@_cdecl("scrollUp")
public func scrollUp(distance: Double = 800) -> Bool {
    return Action.performScrollUp(distance: CGFloat(distance))
}

/// Performs a scroll down action with the specified distance.
/// - Parameter distance: The distance to scroll in points (default: 800)
/// - Returns: true if the scroll was performed successfully, false otherwise
@_cdecl("scrollDown")
public func scrollDown(distance: Double) -> Bool {
    return Action.performScrollDown(distance: CGFloat(distance))
}

@_cdecl("typeText")
public func typeText(_ text: UnsafePointer<UniChar>) -> Bool {
    // Determine the length of the null-terminated UTF-16 string
    var length = 0
    while text[length] != 0 {
        length += 1
    }
    
    // Convert the UTF-16 pointer to a Swift String
    let swiftText = String(utf16CodeUnits: text, count: length)
    
    return Action.typeText(swiftText)
}

@_cdecl("pressKey")
public func pressKey(_ key: UnsafePointer<CChar>) -> Bool {
    let keyString = String(cString: key)
    return Action.pressKey(keyString)
}

@_cdecl("pressKeyCombo")
public func pressKeyCombo(_ key: UnsafePointer<CChar>, _ modifiers: UnsafePointer<UnsafePointer<CChar>>, _ count: Int32) -> Bool {
    let keyString = String(cString: key)
    var modifierList: [String] = []
    
    // Convert C string array to Swift string array
    for i in 0..<Int(count) {
        let modifier = String(cString: modifiers[i])
        modifierList.append(modifier)
    }
    
    return Action.pressKeyCombo(keyString, modifiers: modifierList)
}

/// Performs a drag operation with the left mouse button to the specified coordinates.
/// - Parameters:
///   - toX: The target X coordinate
///   - toY: The target Y coordinate
/// - Returns: true if the drag was performed successfully, false otherwise
/// - Note: This function assumes the mouse button is already pressed at the starting position.
///         Use this for dragging from the current mouse position to absolute screen coordinates.
@_cdecl("leftDrag")
public func leftDrag(toX: Double, toY: Double) -> Bool {
    let to = CGPoint(x: toX, y: toY)
    return Action.performLeftDrag(to: to)
}

/// Performs a drag operation from the current mouse position to the center of a specific element.
/// - Parameters:
///   - context: The explorer context pointer obtained from createAccessExplorer
///   - contextType: A C string specifying the context type (e.g., "app", "window", "menubar")
///   - elementId: The identifier of the target element
/// - Returns: true if the drag was performed successfully, false otherwise
@_cdecl("dragToElement")
public func dragToElement(
    context: UnsafeMutableRawPointer?,
    contextType: UnsafePointer<CChar>,
    elementId: Int
) -> Bool {
    guard let context = context else { return false }
    let explorer = Unmanaged<AccessExplorer>.fromOpaque(context).takeUnretainedValue()
    let contextString = String(cString: contextType)
    guard let elementContext = ElementContext(rawValue: contextString) else {
        print("Error: Invalid context type '\(contextString)'.")
        return false
    }
    return Action.dragToElement(explorer: explorer, context: elementContext, elementId: elementId)
}

// MARK: - YAML Processing

/// Filters a YAML string to include only specified keys.
/// - Parameters:
///   - yamlCString: A C string containing the YAML to filter
///   - keys: An array of C strings specifying the keys to keep
///   - keyCount: The number of keys in the array
/// - Returns: A C string containing the filtered YAML, or nil if failed
/// - Note: The returned string must be freed by the caller
/// Filters nodes from a YAML string based on a key or key-value pair.
/// - Parameters:
///   - yamlCString: A C string containing the YAML to filter
///   - key: A C string specifying the key to match
///   - value: Optional C string specifying the value to match (can be nil)
/// - Returns: A C string containing the filtered YAML, or nil if failed
/// - Note: The returned string must be freed by the caller
@_cdecl("filterYAMLNodes")
public func filterYAMLNodes(
    yamlCString: UnsafePointer<CChar>,
    key: UnsafePointer<CChar>,
    value: UnsafePointer<CChar>?
) -> UnsafePointer<CChar>? {
    // Convert C strings to Swift Strings
    let yamlString = String(cString: yamlCString)
    let keyString = String(cString: key)
    let valueString = value.map { String(cString: $0) }
    
    if yamlString.isEmpty {
        print("Invalid YAML input string")
        return nil
    }
    
    // Call the Swift filterYAMLNodes function
    guard let filteredYAML = filterYAMLNodes(from: yamlString, key: keyString, value: valueString) else {
        return nil
    }
    
    return UnsafePointer(strdup(filteredYAML))
}

@_cdecl("filterYAML")
public func filterYAML(
    yamlCString: UnsafePointer<CChar>,
    keys: UnsafePointer<UnsafePointer<CChar>>,
    keyCount: Int
) -> UnsafePointer<CChar>? {
    // Convert C string to Swift String
    let yamlString = String(cString: yamlCString)
    if yamlString.isEmpty {
        print("Invalid YAML input string")
        return nil
    }
    
    // Convert C array of strings to Swift Set<String>
    let keysArray = (0..<keyCount).compactMap { index -> String? in
        String(cString: keys[index])
    }
    let keysToFilter = Set(keysArray)
    
    // Call the Swift filterYAMLKeys function
    guard let filteredYAML = filterYAMLKeys(from: yamlString, keysToFilter: keysToFilter) else {
        return nil
    }

    return UnsafePointer(strdup(filteredYAML))
}

// MARK: - Excel Operations

/// Flattens Excel cell elements in a YAML hierarchy by merging child attributes into parents.
/// - Parameter yamlCString: A C string containing the YAML to process
/// - Returns: A C string containing the processed YAML with flattened Excel cells, or nil if failed
/// - Note: The returned string must be freed by the caller
@_cdecl("flattenExcelCells")
public func flattenExcelCells(yamlCString: UnsafePointer<CChar>) -> UnsafePointer<CChar>? {
    let yamlString = String(cString: yamlCString)
    let result = ExcelHelper.flattenElement(yamlString)
    if result.isEmpty {
        return nil
    }
    return UnsafePointer(strdup(result))
}
