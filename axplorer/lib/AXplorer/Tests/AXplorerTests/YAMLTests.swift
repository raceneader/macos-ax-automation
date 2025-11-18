import XCTest
@testable import AXplorer

final class YAMLTests: XCTestCase {
    // Test YAML string with a simple structure
    let simpleYAML = """
        element1:
          aid: 1
          attributes:
            name: Button1
            role: button
            position:
              x: 100
              y: 200
            size:
              width: 50
              height: 30
        """
    
    // Test YAML string with nested structure
    let nestedYAML = """
        element1:
          aid: 1
          attributes:
            name: 1
            role: button
            title: Click Me
          children:
            element2:
              aid: 2
              attributes:
                name: 2
                role: text
                title: Label
              children:
                element4:
                  aid: 4
                  attributes:
                    name: 4
                    role: remove
                    title: Me
                    uber: duber
            element3:
              aid: 3
              attributes:
                name: 3
                role: button
                title: Nested Button
                array:
                    - element5:
                          aid: 5
                          attributes:
                            name: 5
                            role: text
                            title: Nested Button
                          children:
                            element6:
                              aid: 6
                              attributes:
                                name: 6
                                role: text
                                title: Label
        """
    
    func testFilterYAMLKeys() throws {
        // Test filtering specific keys from simple YAML
        let keysToRemove = Set(["position", "size"])
        let filtered = try XCTUnwrap(filterYAMLKeys(from: simpleYAML, keysToFilter: keysToRemove))
        
        XCTAssertTrue(filtered.contains("name: Button1"))
        XCTAssertTrue(filtered.contains("role: button"))
        XCTAssertFalse(filtered.contains("position:"))
        XCTAssertFalse(filtered.contains("size:"))
    }
    
    func testFilterYAMLNodes() throws {
        let filtered = try XCTUnwrap(filterYAMLNodes(from: nestedYAML, key: "role", value: "text"))
        
        // remove all elements
        XCTAssertFalse(filtered.contains("aid: 2"))
        XCTAssertFalse(filtered.contains("aid: 4"))
        XCTAssertFalse(filtered.contains("aid: 5"))
        XCTAssertFalse(filtered.contains("aid: 6"))
        XCTAssertTrue(filtered.contains("aid: 3"))
        XCTAssertTrue(filtered.contains("aid: 1"))
    }

    func testFilterYAMLNodes2() throws {
        // Test filtering specific keys from simple YAML
        let filtered = try XCTUnwrap(filterYAMLNodes(from: simpleYAML, key: "aid", value: 1))
        
        // remove all elements
        XCTAssertFalse(filtered.contains("aid: 3"))
        XCTAssertFalse(filtered.contains("aid: 2"))
        XCTAssertFalse(filtered.contains("aid: 4"))
        XCTAssertFalse(filtered.contains("aid: 1"))
        XCTAssertFalse(filtered.contains("name: 1"))
    }
    
    func testFilterYAMLNodesKeyOnly() throws {
        let filtered = try XCTUnwrap(filterYAMLNodes(from: nestedYAML, key: "uber"))
        
        // When we filter nodes with 'role' key, those nodes and their children should be removed
        XCTAssertTrue(filtered.contains("aid: 3"))
        XCTAssertTrue(filtered.contains("aid: 2"))
        XCTAssertFalse(filtered.contains("aid: 4"))
        XCTAssertTrue(filtered.contains("aid: 1"))
    }
    
    func testInvalidInput() throws {
        // Test with empty input
        XCTAssertNil(filterYAMLKeys(from: "", keysToFilter: Set(["key"])), "Empty YAML string should return nil")
        
        // Test with invalid YAML
        XCTAssertNil(filterYAMLKeys(from: "invalid: yaml: : :", keysToFilter: Set(["key"])), "Invalid YAML should return nil")
        
        // Test with empty keys set
        let result = filterYAMLKeys(from: simpleYAML, keysToFilter: Set())
        XCTAssertNotNil(result, "Empty keysToFilter should return original YAML")
        if let yaml = result {
            XCTAssertTrue(yaml.contains("name: Button1"), "All content should remain when keysToFilter is empty")
        }
    }
}
