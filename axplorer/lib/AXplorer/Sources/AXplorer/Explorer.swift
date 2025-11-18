import Cocoa
import ApplicationServices
import Foundation

/// Enumeration representing different contexts for UI elements.
public enum ElementContext: String {
    case appContext = "App"     // Main application context
    case mainContext = "Main"     // Main application context
    case focusContext = "Focus"   // Focused UI element context
    case menuContext = "Menu"     // Menu bar context
    case queryContext = "Query"   // Queryable element context
}

/// A utility class for exploring and interacting with macOS application accessibility elements.
public class AccessExplorer {
    /// The application name
    private var appName: String
    
    /// The root accessibility element of the application.
    private var appElement: AXUIElement
    
    /// A dictionary storing UI elements grouped by context.
    private var elementAccessStore: [String: [Int: AXUIElement]] = [:]
    
    /// The current index for element storage. Reserved indices are below 100.
    private var currentIndex: Int = 100
    
    /**
     Initializes the AccessExplorer with the given application name.
     
     - Parameter appName: The name of the application to interact with.
     - Returns: An instance of `AccessExplorer` if the application is found; otherwise, `nil`.
     */
    public init?(appName: String) {
        guard let appElement = getApplicationElement(for: appName) else {
            print("Error: Unable to find application with name '\(appName)'.")
            return nil
        }
        self.appName = appName
        self.appElement = appElement
    }

    /**
     Retrieves a YAML representation of the application's the application top level window hierarchy.
     
     The method also stores the `elementMap` for the main window in the `elementAccessStore`.
     This allows the stored elements to be later retrieved by `getQueryElementYAML` or interacted with using `performAction`.
     
     - Returns: A YAML string representing the main window hierarchy, or `nil` if the main window cannot be retrieved.
     */
    public func getAppYAML(maxDepth: Int = 5) -> String? {        
        let (yamlWindowOut, elementMap) = convertHierarchyToYAML(appElement, maxDepth: maxDepth)
        
        // Store the element map for future use by getQueryElementYAML and performAction
        storeElement(context: .appContext, elementMap: elementMap)
        
        return yamlWindowOut
    }

    /**
     Retrieves a YAML representation of the application's main window hierarchy.
     
     The method also stores the `elementMap` for the main window in the `elementAccessStore`.
     This allows the stored elements to be later retrieved by `getQueryElementYAML` or interacted with using `performAction`.
     
     - Returns: A YAML string representing the main window hierarchy, or `nil` if the main window cannot be retrieved.
     */
    public func getMainWindowYAML(maxDepth: Int = 5) -> String? {
        guard let mainWindow = getMainWindow(for: appElement) else {
            print("Error: Unable to retrieve the main window.")
            return nil
        }
        
        let (yamlWindowOut, elementMap) = convertHierarchyToYAML(mainWindow, maxDepth: maxDepth)
        
        // Store the element map for future use by getQueryElementYAML and performAction
        storeElement(context: .mainContext, elementMap: elementMap)
        
        return yamlWindowOut
    }

    /**
     Retrieves a YAML representation of the application's focused window hierarchy.
     
     The method also stores the `elementMap` for the focused window in the `elementAccessStore`.
     This allows the stored elements to be later retrieved by `getQueryElementYAML` or interacted with using `performAction`.
     
     - Returns: A YAML string representing the main window hierarchy, or `nil` if the main window cannot be retrieved.
     */
    public func getFocusedWindowYAML(maxDepth: Int = 5) -> String? {
        guard let focusedWindow = getFocusedWindow(for: appElement) else {
            print("Error: Unable to retrieve the focus window.")
            return nil
        }
        
        let (yamlWindowOut, elementMap) = convertHierarchyToYAML(focusedWindow, maxDepth: maxDepth)
        
        // Store the element map for future use by getQueryElementYAML and performAction
        storeElement(context: .mainContext, elementMap: elementMap)
        
        return yamlWindowOut
    }
    
    /**
     Retrieves a YAML representation of the application's menu bar hierarchy.
     
     The method also stores the `elementMap` for the menu bar in the `elementAccessStore`.
     This allows the stored elements to be later retrieved by `getQueryElementYAML` or interacted with using `performAction`.
     
     - Returns: A YAML string representing the menu bar hierarchy, or `nil` if the menu bar cannot be retrieved.
     */
    public func getMenuBarYAML(maxDepth: Int = 5) -> String? {
        guard let menuBar = getMenuBar(for: appElement) else {
            print("Error: Unable to retrieve the menu bar.")
            return nil
        }
        
        let (yamlWindowOut, elementMap) = convertHierarchyToYAML(menuBar, maxDepth: maxDepth)
        
        // Store the element map for future use by getQueryElementYAML and performAction
        storeElement(context: .menuContext, elementMap: elementMap)
        
        return yamlWindowOut
    }
    
    /**
     Retrieves a YAML representation of a specific queryable UI element.
     
     This method retrieves the element from the `elementAccessStore` and processes its hierarchy into YAML format.
     It also updates the `elementMap` for the queried context, enabling further interactions with `performAction`.
     
     - Parameters:
       - context: The context of the UI element.
       - idx: The index of the element in the context.
     - Returns: A YAML string representing the element hierarchy, or `nil` if the element cannot be found.
     */
    public func getQueryElementYAML(context: ElementContext, idx: Int, maxDepth: Int = 5) -> String? {
        guard let element = getElement(context: context, index: idx) else {
            print("Error: Element not found.")
            return nil
        }
        
        let (yamlWindowOut, elementMap) = convertHierarchyToYAML(element, maxDepth: maxDepth)
        
        // Store the updated element map for future use by performAction
        storeElement(context: ElementContext.queryContext, elementMap: elementMap)
        
        return yamlWindowOut
    }
    
    /**
     Performs an action on a specific UI element.
     
     This method retrieves the target element from the `elementAccessStore` and executes the specified action.
     
     - Parameters:
       - context: The context of the UI element.
       - elementId: The identifier of the element within the context.
       - action: The action to perform, as a string.
     - Returns: `true` if the action is performed successfully; otherwise, `false`.
     */
    public func performAction(context: ElementContext, elementId: Int, action: String) -> Bool {
        guard let element = getElement(context: context, index: elementId) else {
            print("Error: Element not found for context \(context.rawValue) and ID \(elementId).")
            return false
        }
        
        let actionResult = AXUIElementPerformAction(element, action as CFString)
        if actionResult == .success {
            return true
        } else {
            print("Error: Failed to perform action '\(action)' on element '\(actionResult)'.")
            return false
        }
    }
    
    func isCellEditable(cell: AXUIElement) -> Bool {
        var isSettable = DarwinBoolean(false) // Initialize the DarwinBoolean variable
        let result = AXUIElementIsAttributeSettable(cell, kAXValueAttribute as CFString, &isSettable)
        if result == .success {
            return isSettable.boolValue // Convert DarwinBoolean to Bool
        } else {
            print("Error: Unable to check if cell is editable. Result: \(result)")
            return false
        }
    }
    
    /**
     Sets an attribute value for a specific UI element.

     - Parameters:
       - context: The context of the UI element.
       - elementId: The identifier of the element within the context.
       - attribute: The name of the attribute to set.
       - value: The value to set for the attribute. Supports String, Bool, and Number.
     - Returns: `true` if the attribute is set successfully; otherwise, `false`.
     */
    public func setAttributeValue(
        context: ElementContext,
        elementId: Int,
        attribute: String,
        value: Any
    ) -> Bool {
        guard let element = getElement(context: context, index: elementId) else {
            print("Error: Element not found for context \(context.rawValue) and ID \(elementId).")
            return false
        }

        // Convert value to CFTypeRef
        var cfValue: CFTypeRef
        if let stringValue = value as? String {
            cfValue = stringValue as CFString
        } else if let boolValue = value as? Bool {
            cfValue = boolValue ? kCFBooleanTrue : kCFBooleanFalse
        } else if let numberValue = value as? NSNumber {
            cfValue = numberValue
        } else if let arrayValue = value as? [Any] {
            let cfArray = arrayValue.map { item -> CFTypeRef in
                if let stringItem = item as? String {
                    return stringItem as CFString
                } else if let numberItem = item as? NSNumber {
                    return numberItem
                } else if let boolItem = item as? Bool {
                    return boolItem ? kCFBooleanTrue : kCFBooleanFalse
                } else {
                    print("Warning: Unsupported item type '\(type(of: item))' in array. Ignoring.")
                    return "" as CFString // Placeholder for unsupported types
                }
            } as CFArray
            cfValue = cfArray
        } else {
            print("Error: Unsupported value type '\(type(of: value))'.")
            return false
        }

        // Attempt to set the attribute value
        let result = AXUIElementSetAttributeValue(element, attribute as CFString, cfValue)
        if result == .success {
            return true
        } else {
            return false
        }
    }
    
    // MARK: - Private Methods
    /**
     Stores a map of elements in the specified context.
     
     This is used internally by `getMainWindowYAML`, `getMenuBarYAML`, and `getQueryElementYAML` to allow
     stored elements to be accessed by `getQueryElementYAML` and `performAction`.
     
     - Parameters:
       - context: The context in which to store the elements.
       - elementMap: A dictionary of element indices and their corresponding accessibility elements.
     */
    private func storeElement(context: ElementContext, elementMap: [Int: AXUIElement]) {
        elementAccessStore[context.rawValue] = elementMap
    }
    
    /**
     Retrieves a stored UI element by context and index.
     
     This is used internally to fetch elements for `getQueryElementYAML` and `performAction`.
     
     - Parameters:
       - context: The context of the element.
       - index: The index of the element in the context.
     - Returns: The accessibility element if found; otherwise, `nil`.
     */
    public func getElement(context: ElementContext, index: Int) -> AXUIElement? {
        return elementAccessStore[context.rawValue]?[index]
    }
    
    /**
     Gets a YAML representation of the UI element at the current mouse cursor position.
     
     This method uses AXUIElementCopyElementAtPosition to find the element under the mouse cursor,
     then converts it to a YAML representation using convertHierarchyToYAML.

     It stores the element within the "query" context
     
     - Parameter maxDepth: Maximum depth to traverse in the accessibility hierarchy (default: 2)
     - Returns: A YAML string representing the element at the mouse position, or nil if no element is found
     */
    public func getElementAtMousePositionYAML(maxDepth: Int = 2) -> String? {
        // Get current mouse location
        guard let mouseLocation = ActionHelper.getMouseLocation() else {
            print("Error: Unable to get mouse location.")
            return nil
        }
        
        // Create a mutable pointer for the result
        var element: AXUIElement?
        
        // Call AXUIElementCopyElementAtPosition with the application element
        let result = AXUIElementCopyElementAtPosition(appElement, Float(mouseLocation.x), Float(mouseLocation.y), &element)
        
        if result == .success, let foundElement = element {
            // Convert the element to YAML
            let (yamlString, elementMap) = convertHierarchyToYAML(foundElement, maxDepth: maxDepth)
            
            // Store the element map for future use
            storeElement(context: .queryContext, elementMap: elementMap)
            
            return yamlString
        } else {
            print("Error: Failed to get element at position (\(mouseLocation.x), \(mouseLocation.y)). Result: \(result)")
            return nil
        }
    }
}
