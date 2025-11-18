//
//  access.swift
//  access_test_sw
//
//  Created by Nasahn Reader on 1/14/25.
//
import Cocoa
import ApplicationServices
import Yams
import AppKit


let elementDebugMode = false

private func convertNumber(_ number: Double) -> Any {
    return (number == floor(number)) ? Int(number) : number
}

private func getChildren(of element: AXUIElement) -> [AXUIElement]? {
    var children: CFTypeRef?
    
    // Try to retrieve children using AXChildrenInNavigationOrder
    var result = AXUIElementCopyAttributeValue(element, "AXChildrenInNavigationOrder" as CFString, &children)
    
    // Fallback to AXChildren if the first attempt fails
    if result != .success {
        result = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &children)
    }
    
    // Check for success and cast to array
    if result == .success, let childrenArray = children as? [AXUIElement] {
        return childrenArray
    }
    
    return nil
}

private func actionsAsStrings(for element: AXUIElement) -> [String] {
    var names: CFArray?
    let error = AXUIElementCopyActionNames(element, &names)
    
    if error == .noValue || error == .attributeUnsupported {
        return []
    }
    
    guard error == .success else {
        return []
    }
    
    if let namesArray = names as? [AnyObject] as? [String] {
        return namesArray
    } else {
        return []
    }
}

private func getAttributes(
    of element: AXUIElement,
    counter: inout Int,
    elementMap: inout [Int: AXUIElement],
    visitedElements: inout Set<AXUIElement>,
    depth: Int = 0,
    maxDepth: Int = 5) -> [String: Any] {
    var attributesDictionary: [String: Any] = [:]
    var attributesToFetch: CFArray?
    
    let result = AXUIElementCopyAttributeNames(element, &attributesToFetch)
    if result == .success, let attributes = attributesToFetch as? [String] {
        let mandatoryAttributes = ["AXTitle", "AXLabel", "AXRole", "AXSubRole", "AXDescription", "AXValue", "AXHelp"]
        let unwantedAttributes = ["AXChildren", "AXVisibleChildren", "AXChildrenInNavigationOrder", "AXSelectedChildren", "AXTopLevelUIElement", "AXParent"]

        let filteredAttributes = attributes.filter { !unwantedAttributes.contains($0) }
        let mergedAttributes = mandatoryAttributes + filteredAttributes.filter { !mandatoryAttributes.contains($0) }

        for attribute in mergedAttributes {
            var value: AnyObject?
            let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
            
            if error == .success, let value = value {
                let typeID = CFGetTypeID(value)
                switch typeID {
                case AXValueGetTypeID():
                    let axValue = value as! AXValue
                    let type = AXValueGetType(axValue)
                    switch type {
                    case .cgPoint:
                        var point = CGPoint.zero
                        if AXValueGetValue(axValue, type, &point) {
                            let pointDict: [String: Any] = [
                                "x": convertNumber(point.x),
                                "y": convertNumber(point.y)
                            ]
                            // Assuming you serialize this dictionary to YAML later
                            attributesDictionary[attribute] = pointDict
                        }
                    case .cgRect:
                        var rect = CGRect.zero
                        if AXValueGetValue(axValue, type, &rect) {
                            let rectDict: [String: Any] = [
                                "x": convertNumber(rect.origin.x),
                                "y": convertNumber(rect.origin.y),
                                "width": convertNumber(rect.size.width),
                                "height": convertNumber(rect.size.height)
                            ]
                            // Assuming you serialize this dictionary to YAML later
                            attributesDictionary[attribute] = rectDict
                        }
                    case .cgSize:
                        var size = CGSize.zero
                        if AXValueGetValue(axValue, type, &size) {
                            let sizeDict: [String: Any] = [
                                "width": convertNumber(size.width),
                                "height": convertNumber(size.height)
                            ]
                            attributesDictionary[attribute] = sizeDict
                        }
                    case .cfRange:
                        var range = CFRange()
                        if AXValueGetValue(axValue, type, &range) {
                            let rangeDict: [String: Any] = [
                                "location": range.location,
                                "length": range.length
                            ]
                            attributesDictionary[attribute] = rangeDict
                        }
                    default:
                        attributesDictionary[attribute] = "[Unsupported AXValue]"
                    }
                case CFStringGetTypeID():
                    let stringValue = value as! String
                    if !stringValue.isEmpty {
                        attributesDictionary[attribute] = stringValue
                    }

                case CFNumberGetTypeID():
                    attributesDictionary[attribute] = convertNumber(value as! Double)

                case CFBooleanGetTypeID():
                    attributesDictionary[attribute] = value as! Bool

                case CFArrayGetTypeID():
                    if let array = value as? [Any] {
                        var set_attr = true
                        let elArray: [Any] = array.compactMap { item -> Any? in
                            if CFGetTypeID(item as CFTypeRef) == AXUIElementGetTypeID() {
                                let info = collectElementInfo(
                                    item as! AXUIElement,
                                    counter: &counter,
                                    elementMap: &elementMap,
                                    visitedElements: &visitedElements,
                                    depth: depth + 1,
                                    maxDepth: maxDepth
                                )
                                return info.isEmpty ? nil : info
                            } else {
                                set_attr = false
                                let attributes = getAttributes(
                                    of: item as! AXUIElement,
                                    counter: &counter,
                                    elementMap: &elementMap,
                                    visitedElements: &visitedElements,
                                    depth: depth + 1,
                                    maxDepth: maxDepth
                                )
                                return attributes.isEmpty ? nil : attributes
                            }
                        }
                        if set_attr, !elArray.isEmpty {
                            attributesDictionary[attribute] = elArray
                        }
                    } else {
                        attributesDictionary[attribute] = "[Unsupported CFArray]"
                    }

                case CFDictionaryGetTypeID():
                    if let dictionary = value as? [AnyHashable: Any] {
                        var set_attr = true
                        let processedDictionary = dictionary.compactMapValues { item -> Any? in
                            if CFGetTypeID(item as CFTypeRef) == AXUIElementGetTypeID() {
                                let info = collectElementInfo(
                                    item as! AXUIElement,
                                    counter: &counter,
                                    elementMap: &elementMap,
                                    visitedElements: &visitedElements,
                                    depth: depth + 1,
                                    maxDepth: maxDepth
                                )
                                return info.isEmpty ? nil : info // Return nil for empty dictionaries
                            } else {
                                set_attr = false
                                let attributes = getAttributes(
                                    of: item as! AXUIElement,
                                    counter: &counter,
                                    elementMap: &elementMap,
                                    visitedElements: &visitedElements,
                                    depth: depth + 1,
                                    maxDepth: maxDepth
                                )
                                return attributes.isEmpty ? nil : attributes // Return nil for empty dictionaries
                            }
                        }
                        if set_attr, !processedDictionary.isEmpty {
                            attributesDictionary[attribute] = processedDictionary
                        }

                    } else {
                        attributesDictionary[attribute] = "[Unsupported CFDictionary]"
                    }
                case CFURLGetTypeID():
                    if let url = value as? URL {
                        attributesDictionary[attribute] = url
                    } else {
                        print("Failed to retrieve CFURL for attribute: \(attribute)")
                        attributesDictionary[attribute] = "[Failed CFURL]"
                    }
                case AXUIElementGetTypeID():
                    let childInfo = collectElementInfo(
                        value as! AXUIElement,
                        counter: &counter,
                        elementMap: &elementMap,
                        visitedElements: &visitedElements,
                        depth: depth + 1,
                        maxDepth: maxDepth
                    )
                    if !childInfo.isEmpty {
                        attributesDictionary[attribute] = childInfo
                    }
                    
                default:
                    attributesDictionary[attribute] = "[Unsupported CFTypeID: \(typeID)]"
                }
            }
        }
    }
    
    let actions = actionsAsStrings(for: element)
        if !actions.isEmpty {
            attributesDictionary["AvailableActions"] = actions
        }
    
    return attributesDictionary
}

private func generateUniqueID(counter: inout Int) -> Int {
    counter += 1
    return counter
}

private func collectElementInfo(
    _ element: AXUIElement,
    counter: inout Int,
    elementMap: inout [Int: AXUIElement],
    visitedElements: inout Set<AXUIElement>,
    depth: Int = 0,
    maxDepth: Int = 5
) -> [String: Any] {
    guard depth <= maxDepth, !visitedElements.contains(element) else { return [:] }
    
    // Mark the element as visited
    visitedElements.insert(element)
    
    // Generate a unique ID for the current element
    let numericID = generateUniqueID(counter: &counter)
    let uniqueID = "element\(numericID)"
    
    // Store the element in the flat map
    elementMap[numericID] = element
    
    // Create element info dictionary with uniqueID as the key
    var elementDict: [String: Any] = [
        "attributes": getAttributes(of: element, counter: &counter, elementMap: &elementMap, visitedElements: &visitedElements, depth: depth, maxDepth: maxDepth),
//        "aid": numericID  // Assign ID to every element
    ]
    
    // Add children if they exist
    if let children = getChildren(of: element) {
        var childrenDict: [String: [String: Any]] = [:]
        
        for child in children {
            if let childInfo = collectElementInfo(child, counter: &counter, elementMap: &elementMap, visitedElements: &visitedElements, depth: depth + 1, maxDepth: maxDepth) as? [String: [String: Any]],
               let (childID, childData) = childInfo.first {
                childrenDict[childID] = childData
            }
        }
        
        if !childrenDict.isEmpty {
            elementDict["children"] = childrenDict
        }
    }
    
    return [uniqueID: elementDict]
}

func convertHierarchyToYAML(_ rootElement: AXUIElement, maxDepth: Int = 5) -> (yaml: String, elementMap: [Int: AXUIElement]) {
    var elementMap: [Int: AXUIElement] = [:] // keeps an ID to element map for future use by actions
    var visitedElements: Set<AXUIElement> = [] // to prevent graph cycles
    var counter: Int = 0

    let hierarchyInfo = collectElementInfo(rootElement, counter: &counter, elementMap: &elementMap, visitedElements: &visitedElements, depth: 0, maxDepth: maxDepth)
    
    do {
        let yamlString = try Yams.dump(object: hierarchyInfo)
        return (yaml: yamlString, elementMap: elementMap)
    } catch {
        print("Error converting to YAML: \(error)")
        return (yaml: "", elementMap: elementMap)
    }
}

// Function to get and print all window names using kAXWindowsAttribute
func getAllWindows(for appElement: AXUIElement) {
    var appWindows: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &appWindows)

    guard result == .success, let windowsArray = appWindows as! CFArray? else {
        print("Failed to retrieve windows or no windows available.")
        return
    }

    let windows = windowsArray as NSArray as! [AXUIElement]
    print("All Windows:")
    for (index, window) in windows.enumerated() {
        var windowTitle: CFTypeRef?
        let titleResult = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &windowTitle)

        if titleResult == .success, let title = windowTitle as? String {
            print("  \(index + 1): \(title)")
        } else {
            print("  \(index + 1): Untitled Window")
        }
    }
}

// Function to get and print the name of AXMainWindow
func getMainWindow(for appElement: AXUIElement) -> AXUIElement? {
    var mainWindow: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(appElement, kAXMainWindowAttribute as CFString, &mainWindow)

    guard result == .success, let window = mainWindow as! AXUIElement? else {
        print("Failed to retrieve the main window.")
        return nil
    }
    
    return window
}

// Function to get and print the name of AXFocusedWindow
func getFocusedWindow(for appElement: AXUIElement) -> AXUIElement? {
    var focusedWindow: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)

    guard result == .success, let window = focusedWindow as! AXUIElement? else {
        print("Failed to retrieve the focused window.")
        return nil
    }
    
    return window
}

func getMenuBar(for appElement: AXUIElement) -> AXUIElement? {
    
    var menuBar: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(appElement, kAXMenuBarAttribute as CFString, &menuBar)

    guard result == .success, let menu = menuBar as! AXUIElement? else {
        print("Failed to retrieve the menu bar.")
        return nil
    }

    return menu
}

// Core Swift function with optional debugging
func getApplicationElement(for appName: String) -> AXUIElement? {
    // Run the main run loop in common mode to ensure `runningApplications` is up-to-date
    RunLoop.current.run(mode: .default, before: Date())
    // Locate the running applications
    let runningApps = NSWorkspace.shared.runningApplications
    let debug = false
    
    // Debug: Print all running applications
    if debug {
        print("Running Applications:")
        for app in runningApps {
            let appName = app.localizedName ?? "Unknown App"
            print("- \(appName) (PID: \(app.processIdentifier))")
        }
    }
    
    // Find the application by its localized name
    guard let app = runningApps.first(where: { $0.localizedName == appName }) else {
        print("\(appName) is not running.")
        return nil
    }
    
    // Return the AXUIElement for the application
    return AXUIElementCreateApplication(app.processIdentifier)
}


func raiseApplication(appName: String) -> Bool {
    let workspace = NSWorkspace.shared
    
    // Check if the app is already running
    if let runningApp = workspace.runningApplications.first(where: { $0.localizedName == appName }) {
        // Bring the app to the foreground
        if runningApp.activate(options: []) {
            return true // Success: App activated
        } else {
            print("Failed to activate application '\(appName)'")
            return false // Failure: Activation failed
        }
    }
    return false // Failure: App not running
}

// Launch an application by its human-readable name and wait for it to finish launching
func launchApplication(appName: String, timeout: TimeInterval = 10) -> Bool {
    // Get the application URL by manually searching the filesystem
    guard let appURL = urlForApplication(withName: appName) else {
        print("Application '\(appName)' not found.")
        return false // Failure: App not found
    }

    let workspace = NSWorkspace.shared
    let configuration = NSWorkspace.OpenConfiguration()
    let semaphore = DispatchSemaphore(value: 0) // To synchronize
    var launchSuccessful = false

    workspace.openApplication(at: appURL, configuration: configuration) { (application, error) in
        if let error = error {
            print("Failed to launch application: \(error)")
        } else if let application = application {
            print("Successfully launched application: \(application)")
            launchSuccessful = true
        }
        semaphore.signal() // Signal that the task is complete
    }

    // Wait with a timeout to avoid indefinite blocking
    let result = semaphore.wait(timeout: .now() + timeout)
    if result == .timedOut {
        print("Launching application timed out.")
    }

    return launchSuccessful
}

// Manually find the application URL by its human-readable name
func urlForApplication(withName appName: String) -> URL? {
    let fileManager = FileManager.default
    let applicationsDirectories = [
        "/Applications",
        "/System/Applications",
        "/Applications/Utilities"
    ]

    for directory in applicationsDirectories {
        let appPath = "\(directory)/\(appName).app"
        if fileManager.fileExists(atPath: appPath) {
            return URL(fileURLWithPath: appPath)
        }
    }

    print("Application '\(appName)' not found in default locations.")
    return nil
}

/// Filters out specific YAML keys from a given YAML string.
/// - Parameters:
///   - yamlString: The original YAML string.
///   - keysToFilter: A set of keys to be removed.
/// - Returns: A new YAML string with the specified keys removed, or nil if parsing fails.
func filterYAMLKeys(from yamlString: String, keysToFilter: Set<String>) -> String? {
    do {
        // Parse the YAML string into a dictionary - note: Yams converts numeric keys to strings
        guard let yamlObject = try Yams.load(yaml: yamlString) as? [String: Any] else {
            print("Failed to parse YAML into a dictionary")
            return nil
        }
        
        // Recursively filter the dictionary
        let filteredDict = filterKeys(in: yamlObject, keysToFilter: keysToFilter)
        
        // Serialize the filtered dictionary back to a YAML string
        let newYamlString = try Yams.dump(object: filteredDict)
        return newYamlString
    } catch {
        print("Error processing YAML: \(error)")
        return nil
    }
}

/// Recursively filters keys from a dictionary or array.
/// - Parameters:
///   - object: The input object (dictionary or array).
///   - keysToFilter: A set of keys to remove.
/// - Returns: A new object with the specified keys removed.
/// Filters YAML nodes based on a key or key-value pair, removing matching nodes and their children.
/// - Parameters:
///   - yamlString: The original YAML string.
///   - key: The key to match.
///   - value: Optional value to match along with the key.
/// - Returns: A new YAML string with matching nodes removed, or nil if parsing fails.
func filterYAMLNodes(from yamlString: String, key: String, value: Any? = nil) -> String? {
    do {
        // Parse the YAML string into a dictionary - note: Yams converts numeric keys to strings
        guard let yamlObject = try Yams.load(yaml: yamlString) as? [String: Any] else {
            print("Failed to parse YAML into a dictionary")
            return nil
        }
        
        // Recursively filter the dictionary
        let filteredDict = filterNodes(in: yamlObject, key: key, value: value)
        
        // Serialize the filtered dictionary back to a YAML string
        let newYamlString = try Yams.dump(object: filteredDict)
        return newYamlString
    } catch {
        print("Error processing YAML: \(error)")
        return nil
    }
}

/// Recursively filters nodes from a dictionary or array based on key or key-value pair.
/// - Parameters:
///   - object: The input object (dictionary or array).
///   - key: The key to match.
///   - value: Optional value to match along with the key.
/// - Returns: A new object with matching nodes removed.
private func filterNodes(in object: Any, key: String, value: Any?) -> Any {
    // Handle both string and numeric keys
    if let dictionary = object as? [String: Any] {
        // Check direct properties first
        if dictionary[key] != nil {
            if let targetValue = value {
                if let nodeValue = dictionary[key], String(describing: nodeValue) == String(describing: targetValue) {
                    return [:] // Remove this node and its children
                }
            } else {
                // If only key provided and it exists in direct properties, remove this node
                return [:]
            }
        }
        
        // Then check attributes
        if let attributes = dictionary["attributes"] as? [String: Any] {
            if attributes[key] != nil {
                if let targetValue = value {
                    if let attrValue = attributes[key], String(describing: attrValue) == String(describing: targetValue) {
                        return [:] // Remove this node and its children
                    }
                } else {
                    // If only key provided and it exists in attributes, remove this node
                    return [:]
                }
            }
        }
        
        // If we didn't find a match in attributes, process children
        var filteredDict = [String: Any]()
        for (dictKey, dictValue) in dictionary {
            let filteredValue = filterNodes(in: dictValue, key: key, value: value)
            
            // Only include non-empty results
            if let dictResult = filteredValue as? [String: Any], !dictResult.isEmpty {
                filteredDict[dictKey] = filteredValue
            } else if let arrayResult = filteredValue as? [Any], !arrayResult.isEmpty {
                filteredDict[dictKey] = filteredValue
            } else if !(filteredValue is [String: Any]) && !(filteredValue is [Any]) {
                filteredDict[dictKey] = filteredValue
            }
        }
        
        return filteredDict
        
    } else if let array = object as? [Any] {
        // Filter each element in the array
        let filteredArray = array.compactMap { element -> Any? in
            let filtered = filterNodes(in: element, key: key, value: value)
            
            // Only include non-empty results
            if let dictResult = filtered as? [String: Any], dictResult.isEmpty {
                return nil
            }
            if let arrayResult = filtered as? [Any], arrayResult.isEmpty {
                return nil
            }
            return filtered
        }
        
        return filteredArray
    }
    
    // For non-dictionary, non-array types, return the value as-is
    return object
}

private func filterKeys(in object: Any, keysToFilter: Set<String>) -> Any {
    if let dictionary = object as? [String: Any] {
        var filteredDict = [String: Any]()
        
        for (key, value) in dictionary {
            // Skip keys that should be filtered out
            if keysToFilter.contains(key) {
                continue
            }
            
            // Recursively filter nested dictionaries or arrays
            filteredDict[key] = filterKeys(in: value, keysToFilter: keysToFilter)
        }
        
        return filteredDict
    } else if let array = object as? [Any] {
        // Recursively filter elements within arrays
        return array.map { filterKeys(in: $0, keysToFilter: keysToFilter) }
    } else {
        // For non-dictionary, non-array types, return the value as-is
        return object
    }
}
