import XCTest
@testable import AXplorer

final class ExcelTests: XCTestCase {
    func testFlattenExcelCell() {
        // Test case with a simple Excel cell
        let input = """
        element1:
          attributes:
            AXRole: AXCell
            AXRoleDescription: cell
          children:
            child1:
              attributes:
                AXDescription: Cell A1
                AXValue: 42
        """
        
        let expected = """
        element1:
            cell: Cell A1
            value: 42
        """
        
        let result = ExcelHelper.flattenElement(input)
        XCTAssertFalse(result.isEmpty, "Result should not be empty")
        
        // Normalize whitespace for comparison
        let normalizedResult = result.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
        let normalizedExpected = expected.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
        
        XCTAssertEqual(normalizedResult, normalizedExpected, "Flattened cell structure should match expected output")
    }
    
    func testFlattenExcelCell2() {
        let input = """
    element346:
        aid: 346
        attributes:
          AXFocused: false
          AXRole: AXCell
          AXRoleDescription: cell
          AXSelected: false
          AvailableActions:
          - AXShowMenu
        children:
          element347:
            aid: 347
            attributes:
              AXEnabled: true
              AXFocused: false
              AXOrientation: AXUnknownOrientation
              AXRole: AXGroup
              AXValue: IncomeExpenseTotal5000
              AvailableActions:
              - AXShowMenu
            children:
              element348:
                aid: 348
                attributes:
                  AXDescription: C1
                  AXFocused: false
                  AXRole: AXTextArea
                  AXRoleDescription: text entry
                    area
                  AXValue: IncomeExpenseTotal5000
                  AvailableActions:
                  - AXShowMenu
    """
        let expected = """
        element346:
          aid: 346
          cell: C1
          value: IncomeExpenseTotal5000
        """
        let result = ExcelHelper.flattenElement(input)
        XCTAssertFalse(result.isEmpty, "Result should not be empty")
        
        // Normalize whitespace for comparison
        let normalizedResult = result.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
        let normalizedExpected = expected.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
        
        XCTAssertEqual(normalizedResult, normalizedExpected, "Flattened cell structure should match expected output")
    }
    
    func testFlattenNonExcelCell() {
        // Test case with a non-Excel cell (should remain unchanged)
        let input = """
        element1:
          attributes:
            AXRoleDescription: button
          children:
            child1:
              attributes:
                AXDescription: Click me
        """
        
        let result = ExcelHelper.flattenElement(input)
        XCTAssertFalse(result.isEmpty, "Result should not be empty")
        
        // Normalize whitespace for comparison
        let normalizedResult = result.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
        let normalizedInput = input.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
        
        XCTAssertEqual(normalizedResult, normalizedInput, "Non-Excel cell should remain unchanged")
    }
    
    func testFlattenInvalidYAML() {
        // Test case with invalid YAML
        let input = "invalid: yaml: :"
        let result = ExcelHelper.flattenElement(input)
        XCTAssertTrue(result.isEmpty, "Result should be empty for invalid YAML")
    }
    
    func testFlattenEmptyInput() {
        // Test case with empty input
        let result = ExcelHelper.flattenElement("")
        XCTAssertTrue(result.isEmpty, "Result should be empty for empty input")
    }
    
    func testFlattenNestedExcelCell() {
        // Test case with Excel cell nested inside non-Excel element
        let input = """
        element1:
          attributes:
            AXRole: AXGroup
            AXRoleDescription: group
          children:
            child1:
              attributes:
                AXRole: AXCell
                AXRoleDescription: cell
              children:
                grandchild1:
                  attributes:
                    AXDescription: Cell B2
                    AXValue: 123
        """
        
        let expected = """
        element1:
              attributes:
                AXRoleDescription: group
              children:
                child1:
                    cell: Cell B2
                    value: 123
        """
        
        let result = ExcelHelper.flattenElement(input)
        XCTAssertFalse(result.isEmpty, "Result should not be empty")
        
        // Normalize whitespace for comparison
        let normalizedResult = result.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
        let normalizedExpected = expected.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
        
        XCTAssertEqual(normalizedResult, normalizedExpected, "Nested Excel cell should be flattened while parent remains unchanged")
    }
}
