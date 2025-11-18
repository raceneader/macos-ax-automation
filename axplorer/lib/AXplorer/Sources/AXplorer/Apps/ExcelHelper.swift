import Foundation
import ApplicationServices
import Yams

/// Helper functions for processing Excel-specific accessibility elements
public class ExcelHelper {
    /// Flattens Excel  elements in a YAML hierarchy by removing certain attributes
    /// - Parameter yamlString: YAML string containing Excel cell elements
    /// - Returns: Processed YAML string with flattened elements cells, or empty string if processing fails
    public static func flattenElement(_ yamlString: String) -> String {
        // Parse YAML string
        do {
            guard var yamlDict = try Yams.load(yaml: yamlString) as? [String: Any] else {
                print("Failed to parse YAML into a dictionary")
                return ""
            }

            // Flattens cell Elements
            _flattenCell(&yamlDict)
            
            // Flattens the other types
            _flattenElement(&yamlDict)
            
            // Convert back to YAML string
            return (try? Yams.dump(object: yamlDict)) ?? ""
        } catch {
            print("Error processing YAML: \(error)")
            return ""
        }
    }

    /// Flattens Excel cell elements in a YAML hierarchy by merging child attributes into parents.
    /// - Parameter yamlString: YAML string containing Excel cell elements
    /// - Returns: Processed YAML string with flattened Excel cells, or empty string if processing fails
    public static func flattenCell(_ yamlString: String) -> String {
        // Parse YAML string
        do {
            guard var yamlDict = try Yams.load(yaml: yamlString) as? [String: Any] else {
                print("Failed to parse YAML into a dictionary")
                return ""
            }
            
            // Process the dictionary
            _flattenCell(&yamlDict)
            
            // Convert back to YAML string
            return (try? Yams.dump(object: yamlDict)) ?? ""
        } catch {
            print("Error processing YAML: \(error)")
            return ""
        }
    }
    
    private static func _flattenCell(_ element: inout [String: Any], _ foundCell: Bool = false) {
        // If the element has attributes and matches the cell criteria, process it
        if var attributes = element["attributes"] as? [String: Any],
           (foundCell || (attributes[kAXRoleAttribute] as? String == "AXCell" &&
                          attributes[kAXRoleDescriptionAttribute] as? String == "cell")) {
            // Check for children and iterate over them
            if let children = element["children"] as? [String: [String: Any]] {
                for (_, var child) in children {
                    _flattenCell(&child, true) // Recursively process child elements
                    
                    // Merge the child's attributes into the parent
                    if let childAttributes = child["attributes"] as? [String: Any] {
                        if let axDescription = childAttributes[kAXDescriptionAttribute] as? String {
                            attributes[kAXDescriptionAttribute] = axDescription
                        }
                        if var axRoleDescription = childAttributes[kAXRoleDescriptionAttribute] as? String {
                            if axRoleDescription == "text entry area" {
                                axRoleDescription = "cell"
                            }
                            attributes[kAXRoleDescriptionAttribute] = axRoleDescription
                        }
                        if let axValue = childAttributes[kAXValueAttribute] {
                            attributes[kAXValueAttribute] = axValue
                        }
                    }
                    // Store the updated attributes back into `element["attributes"]`
                    element["attributes"] = attributes
                }
            }

            if !foundCell { // top level only
                // Ensure `AXDescription` is included in `Description`
                let roleDescription = attributes[kAXRoleDescriptionAttribute] as? String ?? ""
                let axDescription = attributes[kAXDescriptionAttribute] as? String ?? ""
                
                // Remove punctuation from `Description`
                let descriptionText = [axDescription]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ") // Ensures space only if both values exist
                    .components(separatedBy: CharacterSet.punctuationCharacters) // Remove punctuation
                    .joined() // Rejoin without punctuation
                    .trimmingCharacters(in: .whitespaces) // Removes leading/trailing spaces
                    // Construct attributes dynamically

                let cleaned_roleDescription = roleDescription
                    .components(separatedBy: CharacterSet.punctuationCharacters)
                    .joined()
                
                // Only add "AXValue" if it exists
                if let axValue = attributes["AXValue"] {
                    element["value"] = axValue
                }
                
                element[cleaned_roleDescription] = descriptionText
                // super compact
                element.removeValue(forKey: kAXRoleDescriptionAttribute)
                element.removeValue(forKey: "attributes")
            }
            // Remove children
            element.removeValue(forKey: "children")
        } else {
            // If the current element is not a cell, recursively process all dictionaries or arrays
            for (key, value) in element {
                if var dictValue = value as? [String: Any] {
                    _flattenCell(&dictValue) // Process nested dictionaries
                    element[key] = dictValue
                } else if var arrayValue = value as? [[String: Any]] {
                    for i in 0..<arrayValue.count {
                        _flattenCell(&arrayValue[i]) // Process elements in arrays
                    }
                    element[key] = arrayValue
                }
            }
        }
    }
    
    /// Recursively processes an accessibility element dictionary, opportunistically removing kAXRoleAttribute and kAXSubroleAttribute
    ///  if kAXRoleDescriptionAttribute exists
    /// - Complexity: O(n), where n is the total number of keys and nested elements in `element`.
    private static func _flattenElement(_ element: inout [String: Any]) {
        if var attributes = element["attributes"] as? [String: Any] {
            if attributes.keys.contains(kAXRoleDescriptionAttribute as String) {
                // Remove kAXSubroleAttribute and kAXRoleAttribute if they exist
                
                attributes.removeValue(forKey: kAXSubroleAttribute)
                attributes.removeValue(forKey: kAXRoleAttribute)
                attributes.removeValue(forKey: kAXEnabledAttribute)
                // Check if AXTitle contains all of AXHelp, or vice versa
                if let axTitle = attributes[kAXTitleAttribute as String] as? String,
                   let axHelp = attributes[kAXHelpAttribute as String] as? String {
                    
                    if axTitle.contains(axHelp) || axHelp.contains("For more options") {
                        attributes.removeValue(forKey: kAXHelpAttribute)
                    }
                    
                    
                }

                if var availableActions = attributes["AvailableActions"] as? [String] {
                    // Remove "ShowMenu"
                    availableActions = availableActions.filter { $0 != "AXShowMenu" }
                    
                    // Update the dictionary
                    attributes["AvailableActions"] = availableActions
                }
//                // Extract relevant attributes in specified order
//                let orderedKeys = [kAXTitleAttribute, kAXIdentifierAttribute, kAXDescriptionAttribute, kAXRoleDescriptionAttribute]
//                
//                var descriptionList: [String] = []
//                var seenValues = Set<String>()
//
//                for key in orderedKeys {
//                    if let value = attributes[key] as? String, !value.isEmpty {
//                        if !seenValues.contains(value) {  // Ensure no exact duplicates
//                            seenValues.insert(value)
//                            descriptionList.append(value)
//                        }
//                    }
//                }
//
//                // **Remove redundant substrings**: If a string is fully contained within another, remove it
//                var filteredDescriptions: [String] = []
//                for desc in descriptionList {
//                    if !filteredDescriptions.contains(where: { $0.contains(desc) && $0 != desc }) {
//                        filteredDescriptions.append(desc)
//                    }
//                }
//
//                // Create a combined, unique description in the correct order
//                if !filteredDescriptions.isEmpty {
//                    let finalDescription = filteredDescriptions.joined(separator: " ")
//                        .replacingOccurrences(of: "\n", with: " ")  // Remove newlines
//                        .replacingOccurrences(of: ",", with: " | ")  // Replace commas to avoid YAML quoting
//                        .replacingOccurrences(of: ":", with: "- ")  // Replace commas to avoid YAML quoting
//                        .trimmingCharacters(in: .whitespacesAndNewlines)  // Trim spaces
//
//                    element["description"] = finalDescription
//                }
//                
//                // **Remove the original attributes now that they've been merged into "Description"**
//                for key in orderedKeys {
//                    attributes.removeValue(forKey: key)
//                }
//                
//                if let axHelp = attributes[kAXHelpAttribute] as? String {
//                    attributes.removeValue(forKey: kAXHelpAttribute)
//                    element["help"] = axHelp
//                }
                
                if !attributes.isEmpty {
                    element["attributes"] = attributes // Store the modified attributes back
                } else {
                    element.removeValue(forKey: "attributes")
                }
            }
        }

        // Iterate through all keys and process nested dictionaries/arrays
        for (key, value) in element {
            if var dictValue = value as? [String: Any] {
                _flattenElement(&dictValue) // Process nested dictionary
                element[key] = dictValue
            } else if var arrayValue = value as? [[String: Any]] {
                for i in 0..<arrayValue.count {
                    _flattenElement(&arrayValue[i]) // Process each dictionary in the array
                }
                element[key] = arrayValue
            }
        }
    }
}
