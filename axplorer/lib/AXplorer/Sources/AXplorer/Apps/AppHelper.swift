import Foundation
import ApplicationServices
import Yams

public class AppHelper {
    /// Retrieves accessibility attributes from a YAML dictionary and returns a flattened description string.
    /// - Parameter yamlDict: A dictionary parsed from a YAML file
    /// - Returns: A flattened string with accessibility attributes, without punctuation and duplicate words
    public static func getFlattenedDescription(from yamlDict: inout [String: Any]) -> String {
        // Extract and remove AX attributes from the dictionary
        let role = yamlDict.removeValue(forKey: kAXRoleAttribute as String) as? String
        let roleDescription = yamlDict.removeValue(forKey: kAXRoleDescriptionAttribute as String) as? String
        let title = yamlDict.removeValue(forKey: kAXTitleAttribute as String) as? String
        let help = yamlDict.removeValue(forKey: kAXHelpAttribute as String) as? String
        let identifier = yamlDict.removeValue(forKey: kAXIdentifierAttribute as String) as? String
        let label = yamlDict.removeValue(forKey: kAXLabelValueAttribute as String) as? String

        return flattenDescription(role: role, roleDescription: roleDescription, title: title, help: help, identifier: identifier, label: label)
    }

    /// Private function to flatten accessibility attributes into a single string without punctuation and duplicates
    private static func flattenDescription(role: String?, roleDescription: String?, title: String?, help: String?, identifier: String?, label: String?) -> String {
        let attributes = [role, roleDescription, title, help, identifier, label]
        
        // Step 1: Remove nils and join into one string
        let rawString = attributes
            .compactMap { $0 }
            .joined(separator: " ")

        // Step 2: Remove punctuation
        let cleanedString = rawString.components(separatedBy: CharacterSet.punctuationCharacters)
            .joined()

        // Step 3: Split into words, normalize case, and remove duplicates while preserving order
        var seenWords = Set<String>()
        let uniqueWords = cleanedString
            .lowercased() // Normalize case for comparison
            .components(separatedBy: CharacterSet.whitespacesAndNewlines) // Split into words
            .filter { !$0.isEmpty && seenWords.insert($0).inserted } // Remove duplicates while preserving order

        // Step 4: Rejoin words into a single string
        return uniqueWords.joined(separator: " ")
    }
}
