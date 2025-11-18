import XCTest
import Yams
@testable import AXplorer

class AppHelperTests: XCTestCase {

    func testFlattenedDescription() {
        var yamlDict: [String: Any] = [
            kAXRoleAttribute as String: "Button",
            kAXRoleDescriptionAttribute as String: "Pressable",
            kAXTitleAttribute as String: "Submit!",
            kAXHelpAttribute as String: "Click to submit. Submit Now!",
            kAXIdentifierAttribute as String: "submit_button_123",
            kAXLabelValueAttribute as String: "Submit?"
        ]
        
        let expectedOutput = "button pressable submit click to now submitbutton123"
        let output = AppHelper.getFlattenedDescription(from: &yamlDict)
        
        XCTAssertEqual(output, expectedOutput, "Flattened description did not match expected output.")
        
        // Ensure AX attributes are removed from yamlDict
        XCTAssertFalse(yamlDict.keys.contains(kAXRoleAttribute as String), "AXRole was not removed from dictionary")
        XCTAssertFalse(yamlDict.keys.contains(kAXRoleDescriptionAttribute as String), "AXRoleDescription was not removed from dictionary")
        XCTAssertFalse(yamlDict.keys.contains(kAXTitleAttribute as String), "AXTitle was not removed from dictionary")
        XCTAssertFalse(yamlDict.keys.contains(kAXHelpAttribute as String), "AXHelp was not removed from dictionary")
        XCTAssertFalse(yamlDict.keys.contains(kAXIdentifierAttribute as String), "AXIdentifier was not removed from dictionary")
        XCTAssertFalse(yamlDict.keys.contains(kAXLabelValueAttribute as String), "AXLabel was not removed from dictionary")
    }

    func testFlattenedDescriptionWithMissingAttributes() {
        var yamlDict: [String: Any] = [
            kAXRoleAttribute as String: "Button",
            kAXTitleAttribute as String: "Submit!"
        ]
        
        let expectedOutput = "button submit"
        let output = AppHelper.getFlattenedDescription(from: &yamlDict)
        
        XCTAssertEqual(output, expectedOutput, "Flattened description did not match expected output when some attributes are missing.")
        
        // Ensure the processed attributes are removed
        XCTAssertFalse(yamlDict.keys.contains(kAXRoleAttribute as String), "AXRole was not removed from dictionary")
        XCTAssertFalse(yamlDict.keys.contains(kAXTitleAttribute as String), "AXTitle was not removed from dictionary")
    }

    func testFlattenedDescriptionWithPunctuation() {
        var yamlDict: [String: Any] = [
            kAXRoleAttribute as String: "TextField",
            kAXTitleAttribute as String: "Enter name:",
            kAXHelpAttribute as String: "Type your name, then press Enter.",
            kAXIdentifierAttribute as String: "input-name"
        ]
        
        let expectedOutput = "textfield enter name type your then press inputname"
        let output = AppHelper.getFlattenedDescription(from: &yamlDict)
        
        XCTAssertEqual(output, expectedOutput, "Flattened description did not remove punctuation correctly.")
        
        // Ensure processed attributes are removed
        XCTAssertFalse(yamlDict.keys.contains(kAXRoleAttribute as String))
        XCTAssertFalse(yamlDict.keys.contains(kAXTitleAttribute as String))
        XCTAssertFalse(yamlDict.keys.contains(kAXHelpAttribute as String))
        XCTAssertFalse(yamlDict.keys.contains(kAXIdentifierAttribute as String))
    }

    func testFlattenedDescriptionWithDuplicateWords() {
        var yamlDict: [String: Any] = [
            kAXRoleAttribute as String: "Button",
            kAXRoleDescriptionAttribute as String: "button",
            kAXTitleAttribute as String: "Submit",
            kAXHelpAttribute as String: "submit submit Click to send",
            kAXIdentifierAttribute as String: "submit_button",
            kAXLabelValueAttribute as String: "Submit"
        ]
        
        let expectedOutput = "button submit click to send submitbutton"
        let output = AppHelper.getFlattenedDescription(from: &yamlDict)
        
        XCTAssertEqual(output, expectedOutput, "Flattened description did not correctly remove duplicate words.")
        
        // Ensure attributes are removed
        XCTAssertFalse(yamlDict.keys.contains(kAXRoleAttribute as String))
        XCTAssertFalse(yamlDict.keys.contains(kAXRoleDescriptionAttribute as String))
        XCTAssertFalse(yamlDict.keys.contains(kAXTitleAttribute as String))
        XCTAssertFalse(yamlDict.keys.contains(kAXHelpAttribute as String))
        XCTAssertFalse(yamlDict.keys.contains(kAXIdentifierAttribute as String))
        XCTAssertFalse(yamlDict.keys.contains(kAXLabelValueAttribute as String))
    }
}
