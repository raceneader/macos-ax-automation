import Foundation
import CoreGraphics
import ApplicationServices
import AppKit
import Accessibility

/// Specifies where to move the mouse relative to an element
enum ElementPosition {
    case center
    case bottomRight
}

/// Provides functionality for performing mouse and keyboard actions on accessibility elements
struct Action {
    /// Moves the mouse to the specified position of an element
    /// - Parameters:
    ///   - explorer: The AccessExplorer instance
    ///   - context: The context of the element (e.g., main, menu, etc.)
    ///   - elementId: The ID of the element to move to
    ///   - position: Where to move relative to the element (default: center)
    /// - Returns: True if mouse movement was successful, false otherwise
    static func moveToElement(explorer: AccessExplorer, context: ElementContext, elementId: Int, position: ElementPosition = .center) -> Bool {
        guard let element = explorer.getElement(context: context, index: elementId) else {
            print("Error: Element not found")
            return false
        }
        
        if let coordinates = getElementCoordinates(element) {
            let targetPoint = position == .center ?
                calculateCenter(x: coordinates.x, y: coordinates.y, width: coordinates.width, height: coordinates.height) :
                calculateBottomRight(x: coordinates.x, y: coordinates.y, width: coordinates.width, height: coordinates.height)
            if let finalPosition = ActionHelper.moveMouseTo(position: targetPoint) {
                // Validate position is within reasonable tolerance (5 pixels)
                let tolerance: CGFloat = 5.0
                let distance = hypot(finalPosition.x - targetPoint.x, 
                                   finalPosition.y - targetPoint.y)
                
                if distance <= tolerance {
                    return true
                } else {
                    print("Warning: Mouse movement not precise enough. Target: \(targetPoint), Actual: \(finalPosition), Distance: \(distance)")
                    return false
                }
            }
            return false
        }
        
        print("Error: No position information found for element")
        return false
    }
    
    
    /// Performs a left mouse click at the current cursor position
    /// - Returns: True if the click was performed successfully
    static func performLeftClick() -> Bool {
        ActionHelper.leftClick()
        return true
    }
    
    /// Performs a right mouse click at the current cursor position
    /// - Returns: True if the click was performed successfully
    static func performRightClick() -> Bool {
        ActionHelper.rightClick()
        return true
    }
    
    /// Performs a double left click at the current cursor position
    /// - Returns: True if the click was performed successfully
    static func performDoubleLeftClick() -> Bool {
        ActionHelper.doubleLeftClick()
        return true
    }
    
    /// Performs a scroll up action with natural easing
    /// - Parameter distance: The scroll distance in pixels (default: 800)
    /// - Returns: True if the scroll was performed successfully
    static func performScrollUp(distance: CGFloat = 800) -> Bool {
        ActionHelper.scroll(distance: distance, direction: .up)
        return true
    }
    
    /// Performs a scroll down action with natural easing
    /// - Parameter distance: The scroll distance in pixels (default: 800)
    /// - Returns: True if the scroll was performed successfully
    static func performScrollDown(distance: CGFloat = 800) -> Bool {
        ActionHelper.scroll(distance: distance, direction: .down)
        return true
    }
    
    /// Performs a left mouse drag from current position to target point
    /// - Parameter to: The target point to drag to
    /// - Returns: True if the drag was performed successfully
    static func performLeftDrag(to: CGPoint) -> Bool {
        ActionHelper.leftDrag(to: to)
        return true
    }
    
    /// Performs a left mouse drag from current position to the center of the specified element
    /// - Parameters:
    ///   - explorer: The AccessExplorer instance
    ///   - context: The context of the element (e.g., main, menu, etc.)
    ///   - elementId: The ID of the element to drag to
    /// - Returns: True if the drag was performed successfully
    static func dragToElement(explorer: AccessExplorer, context: ElementContext, elementId: Int) -> Bool {
        guard let element = explorer.getElement(context: context, index: elementId) else {
            print("Error: Element not found")
            return false
        }
        
        if let coordinates = getElementCoordinates(element) {
            let centerPoint = calculateCenter(
                x: coordinates.x,
                y: coordinates.y,
                width: coordinates.width,
                height: coordinates.height
            )
            // Perform the drag operation
            ActionHelper.leftDrag(to: centerPoint)
            
            // Validate final position
            if let finalPosition = ActionHelper.getMouseLocation() {
                // Validate position is within reasonable tolerance (5 pixels)
                let tolerance: CGFloat = 5.0
                let distance = hypot(finalPosition.x - centerPoint.x, 
                                   finalPosition.y - centerPoint.y)
                
                if distance <= tolerance {
                    return true
                } else {
                    print("Warning: Drag movement not precise enough. Target: \(centerPoint), Actual: \(finalPosition), Distance: \(distance)")
                    return false
                }
            }
            return false
        }
        
        print("Error: No position information found for element")
        return false
    }
    
    // MARK: - Private Helper Functions
    
    /// Gets the position of an accessibility element
    /// - Parameter element: The accessibility element
    /// - Returns: The position as a CGPoint, or nil if not available
    private static func getPosition(_ element: AXUIElement) -> CGPoint? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &value)
        
        if result == .success, let value = value {
            let axValue = value as! AXValue
            var point = CGPoint.zero
            guard AXValueGetValue(axValue, .cgPoint, &point) else {
                return nil
            }
            return point
        }
        return nil
    }
    
    /// Gets the size of an accessibility element
    /// - Parameter element: The accessibility element
    /// - Returns: The size as a CGSize, or nil if not available
    private static func getSize(_ element: AXUIElement) -> CGSize? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &value)
        
        if result == .success, let value = value {
            let axValue = value as! AXValue
            var size = CGSize.zero
            guard AXValueGetValue(axValue, .cgSize, &size) else {
                return nil
            }
            return size
        }

        return nil
    }
    
    /// Gets the frame of an accessibility element
    /// - Parameter element: The accessibility element
    /// - Returns: The frame as a CGRect, or nil if not available
    private static func getFrame(_ element: AXUIElement) -> CGRect? {
        return getRect(element, "AXFrame")
    }
    
    /// Gets the rectangle in parent space of an accessibility element
    /// - Parameter element: The accessibility element
    /// - Returns: The rectangle as a CGRect, or nil if not available
    private static func getRectInParentSpace(_ element: AXUIElement) -> CGRect? {
        return getRect(element, "AXRectInParentSpace")
    }

    private static func getRect(_ element: AXUIElement, _ attribute: String) -> CGRect?
    {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)

        if result == .success, let value = value {
            let axValue = value as! AXValue
            var rect = CGRect.zero
            guard AXValueGetValue(axValue, .cgRect, &rect) else {
                return nil
            }
            return rect
        }

        return nil       
    }
    
    /// Gets the coordinates of an accessibility element by trying different methods
    /// - Parameter element: The accessibility element
    /// - Returns: Tuple of coordinates if found through any method, nil otherwise
    private static func getElementCoordinates(_ element: AXUIElement) -> (x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat)? {
        // Try AXPosition + AXSize first
        if let position = getPosition(element), let size = getSize(element) {
            return (position.x, position.y, size.width, size.height)
        }
        // Try AXFrame next
        if let frame = getFrame(element) {
            return (frame.origin.x, frame.origin.y, frame.size.width, frame.size.height)
        }
        // Finally try AXRectInParentSpace
        if let rect = getRectInParentSpace(element) {
            return (rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)
        }
        return nil
    }

    /// Calculates the center point given coordinates and dimensions
    /// - Parameters:
    ///   - x: The x coordinate
    ///   - y: The y coordinate
    ///   - width: The width
    ///   - height: The height
    /// - Returns: The center point
    private static func calculateCenter(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CGPoint {
        return CGPoint(
            x: x + width/2,
            y: y + height/2
        )
    }
    
    /// Calculates the bottom-right point given coordinates and dimensions
    /// - Parameters:
    ///   - x: The x coordinate
    ///   - y: The y coordinate
    ///   - width: The width
    ///   - height: The height
    /// - Returns: The bottom-right point
    private static func calculateBottomRight(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CGPoint {
        return CGPoint(
            x: x + width,
            y: y + height
        )
    }
    
    /// Types a string of text with natural timing between keystrokes
    /// - Parameter text: The text to type
    /// - Returns: True if successful, false otherwise
    static func typeText(_ text: String) -> Bool {
        ActionHelper.typeText(text: text)
        return true
    }
    
    /// Presses a single key
    /// - Parameter key: The key to press (e.g., "a", "return", "tab")
    /// - Returns: True if successful, false otherwise
    static func pressKey(_ key: String) -> Bool {
        if key.isEmpty {
            print("Error: Empty key name")
            return false
        }
        
        ActionHelper.keyPress(key: key)
        return true
    }
    
    /// Presses a key combination with modifier keys
    /// - Parameters:
    ///   - key: The main key to press (e.g., "c" for Command+C)
    ///   - modifiers: Array of modifier key names (e.g., ["command", "shift"])
    /// - Returns: True if successful, false otherwise
    static func pressKeyCombo(_ key: String, modifiers: [String]) -> Bool {
        if key.isEmpty {
            print("Error: Empty key name")
            return false
        }
        
        ActionHelper.pressKeyWithModifiers(key: key, modifiers: modifiers)
        return true
    }
}
