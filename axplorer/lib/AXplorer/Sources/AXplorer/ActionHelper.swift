//
//  ActionHelper.swift
//  AXplorer
//
//  Created by Nasahn Reader on 1/21/25.
//

import CoreGraphics
import AppKit

/// Direction for scroll actions
enum ScrollDirection {
    case up
    case down
}

/// Helper functions for performing mouse and keyboard actions
enum ActionHelper {
    /// Maps special keys to their CGKeyCode values
    private static let specialKeyMap: [String: CGKeyCode] = [
        "\n": 36, "return": 36, "enter": 36, "\t": 48, "tab": 48, "delete": 51, "escape": 53, 
        "capslock": 57, "right": 124, "left": 123, "down": 125, "up": 126,
        "home": 115, "end": 119, "pageup": 116, "pagedown": 121,
        "space": 49
    ]
    
    /// Maps modifier key names to their CGEventFlags
    private static let modifierFlags: [String: CGEventFlags] = [
        "command": .maskCommand,
        "shift": .maskShift,
        "option": .maskAlternate,
        "control": .maskControl,
        "function": .maskSecondaryFn
    ]
    /// Moves the mouse cursor to a specified position with natural-looking movement
    /// - Parameter position: The target CGPoint coordinates where the cursor should move to
    /// - Returns: The final position of the mouse after movement, or nil if movement failed
    static func moveMouseTo(position: CGPoint) -> CGPoint? {
        guard let mainScreen = NSScreen.main else { return nil }
        let source = CGEventSource(stateID: .hidSystemState)
        let screenHeight = mainScreen.frame.height // Get the screen height
        var startPos = NSEvent.mouseLocation
        startPos.y = screenHeight - startPos.y // Flip the y-coordinate
        
        // Calculate distance and number of steps
        let distance = hypot(position.x - startPos.x, position.y - startPos.y)
        let steps = max(Int(distance / 10), 1) // One step per 10 pixels, minimum 1 step
        
        // Generate interpolation points with slight randomization
        for i in 1...steps {
            let progress = Double(i) / Double(steps)
            
            // Smooth easing using sine function for natural acceleration/deceleration
            let easedProgress = sin(progress * .pi / 2)
            
            // Calculate intermediate position with slight random deviation
            let x = startPos.x + (position.x - startPos.x) * easedProgress + Double.random(in: -2...2)
            let y = startPos.y + (position.y - startPos.y) * easedProgress + Double.random(in: -2...2)
            
            let intermediatePos = CGPoint(x: x, y: y)
            if let event = CGEvent(mouseEventSource: source, mouseType: .mouseMoved, 
                                 mouseCursorPosition: intermediatePos, mouseButton: .left) {
                event.post(tap: CGEventTapLocation.cghidEventTap)
            }
            
            // Random small delay between movements (10-20ms)
            usleep(UInt32.random(in: 10000...20000))
        }
        
        // Final movement to exact target position
        if let finalEvent = CGEvent(mouseEventSource: source, mouseType: .mouseMoved, 
                                   mouseCursorPosition: position, mouseButton: .left) {
            finalEvent.post(tap: CGEventTapLocation.cghidEventTap)
        }
        
        // Return the final position
        return getMouseLocation()
    }

    /// Performs a left mouse click at the specified position
    /// - Parameter position: The CGPoint where the click should occur
    static func leftClick() {
        guard let mainScreen = NSScreen.main else { return }
        let source = CGEventSource(stateID: .hidSystemState)
        let screenHeight = mainScreen.frame.height // Get the screen height
        var currentPos = NSEvent.mouseLocation
        currentPos.y = screenHeight - currentPos.y // Flip the y-coordinate
        
        
        // Mouse down
        if let clickDown = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, 
                                  mouseCursorPosition: currentPos, mouseButton: .left) {
            clickDown.setIntegerValueField(CGEventField.mouseEventClickState, value: Int64(1))
            clickDown.post(tap: CGEventTapLocation.cghidEventTap)
        }
        
        // Small random delay between down and up (50-150ms)
        usleep(UInt32.random(in: 50000...150000))
        
        // Mouse up
        if let clickUp = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, 
                                mouseCursorPosition: currentPos, mouseButton: .left) {
            clickUp.setIntegerValueField(CGEventField.mouseEventClickState, value: Int64(1))
            clickUp.post(tap: CGEventTapLocation.cghidEventTap)
        }
    }


    /// Performs a right mouse click at the current cursor position
    static func rightClick() {
        guard let mainScreen = NSScreen.main else { return }
        let source = CGEventSource(stateID: .hidSystemState)
        let screenHeight = mainScreen.frame.height // Get the screen height
        var currentPos = NSEvent.mouseLocation
        currentPos.y = screenHeight - currentPos.y // Flip the y-coordinate
        
        
        // Mouse down
        if let clickDown = CGEvent(mouseEventSource: source, mouseType: .rightMouseDown, 
                                  mouseCursorPosition: currentPos, mouseButton: .right) {
            clickDown.setIntegerValueField(CGEventField.mouseEventClickState, value: Int64(1))
            clickDown.post(tap: CGEventTapLocation.cghidEventTap)
        }
        
        // Small random delay between down and up (50-150ms)
        usleep(UInt32.random(in: 50000...150000))
        
        // Mouse up
        if let clickUp = CGEvent(mouseEventSource: source, mouseType: .rightMouseUp, 
                                mouseCursorPosition: currentPos, mouseButton: .right) {
            clickUp.setIntegerValueField(CGEventField.mouseEventClickState, value: Int64(1))
            clickUp.post(tap: CGEventTapLocation.cghidEventTap)
        }
    }
    
    /// Performs a double left click at the current cursor position
    static func doubleLeftClick() {
        guard let mainScreen = NSScreen.main else { return }
        let source = CGEventSource(stateID: .hidSystemState)
        let screenHeight = mainScreen.frame.height
        var currentPos = NSEvent.mouseLocation
        currentPos.y = screenHeight - currentPos.y
        print("Double click position: \(currentPos)")
        
        // First click
        if let clickDown = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, 
                                  mouseCursorPosition: currentPos, mouseButton: .left) {
            clickDown.setIntegerValueField(CGEventField.mouseEventClickState, value: Int64(1))
            clickDown.post(tap: CGEventTapLocation.cghidEventTap)
        }
        
        usleep(UInt32.random(in: 50000...150000))
        
        if let clickUp = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, 
                                mouseCursorPosition: currentPos, mouseButton: .left) {
            clickUp.setIntegerValueField(CGEventField.mouseEventClickState, value: Int64(1))
            clickUp.post(tap: CGEventTapLocation.cghidEventTap)
        }
        
        // Wait between clicks (200-300ms)
        usleep(UInt32.random(in: 200000...300000))
        
        // Second click with click state 2
        if let clickDown = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, 
                                  mouseCursorPosition: currentPos, mouseButton: .left) {
            clickDown.setIntegerValueField(CGEventField.mouseEventClickState, value: Int64(2))
            clickDown.post(tap: CGEventTapLocation.cghidEventTap)
        }
        
        usleep(UInt32.random(in: 50000...150000))
        
        if let clickUp = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, 
                                mouseCursorPosition: currentPos, mouseButton: .left) {
            clickUp.setIntegerValueField(CGEventField.mouseEventClickState, value: Int64(2))
            clickUp.post(tap: CGEventTapLocation.cghidEventTap)
        }
    }
    
    /// Performs a left mouse drag from current position to target point
    /// - Parameter to: Ending point for the 
    
    static func leftDrag(to: CGPoint) {
        guard let mainScreen = NSScreen.main else { return }
        let source = CGEventSource(stateID: .hidSystemState)
        let screenHeight = mainScreen.frame.height // Get the screen height
        var currentPos = NSEvent.mouseLocation
        currentPos.y = screenHeight - currentPos.y // Flip the y-coordinate
        
        // Mouse down at current position
        if let mouseDown = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, 
                                  mouseCursorPosition: currentPos, mouseButton: .left) {
            mouseDown.post(tap: CGEventTapLocation.cghidEventTap)
        }
        
        // Small delay after mouse down (50-150ms)
        usleep(UInt32.random(in: 50000...150000))
        
        // Move to destination while holding button
        if let mouseDrag = CGEvent(mouseEventSource: source, mouseType: .leftMouseDragged, 
                                  mouseCursorPosition: to, mouseButton: .left) {
            mouseDrag.post(tap: CGEventTapLocation.cghidEventTap)
        }
        
        // Small delay before release (50-150ms)
        usleep(UInt32.random(in: 50000...150000))
        
        // Release at destination
        if let mouseUp = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, 
                                mouseCursorPosition: to, mouseButton: .left) {
            mouseUp.post(tap: CGEventTapLocation.cghidEventTap)
        }
    }
    
    /// Performs a smooth scroll action with natural easing
    /// - Parameters:
    ///   - distance: The scroll distance in pixels (default: 800)
    ///   - direction: The direction to scroll (up or down)
    static func scroll(distance: CGFloat = 800, direction: ScrollDirection) {
        let source = CGEventSource(stateID: .hidSystemState)
        let scrollAmount = direction == .up ? distance : -distance
        let steps = max(Int(abs(distance) / 25), 1) // 25 pixels per step
        
        // Generate smooth scrolling with easing
        for i in 1...steps {
            let progress = Double(i) / Double(steps)
            
            // Smooth easing using sine function
            let easedProgress = sin(progress * .pi / 2)
            
            // Calculate scroll amount for this step with slight randomization
            let stepAmount = (scrollAmount / CGFloat(steps)) * CGFloat(easedProgress)
            let randomizedAmount = stepAmount + CGFloat.random(in: -1...1)
            
            if let event = CGEvent(scrollWheelEvent2Source: source,
                                 units: .pixel,
                                 wheelCount: 1,
                                 wheel1: Int32(randomizedAmount),
                                 wheel2: 0,
                                 wheel3: 0) {
                event.post(tap: CGEventTapLocation.cghidEventTap)
            }
            
            // Random small delay between scrolls (5-10ms)
            usleep(UInt32.random(in: 5000...10000))
        }
    }
    
    /// Simulates pressing a key using UTF-8 input or key code
    /// - Parameter key: The key to press (can be a character or special key name)
    static func keyPress(key: String) {
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Handle special keys
        if let keyCode = specialKeyMap[key.lowercased()] {
            if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) {
                keyDown.post(tap: .cghidEventTap)
            }
            
            keyPressDelay()
            
            if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
                keyUp.post(tap: .cghidEventTap)
            }
            return
        }
        
        // For regular characters, use simple string input
        if let char = key.first {
            if let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
                let str = String(char)
                event.keyboardSetUnicodeString(stringLength: str.utf16.count, unicodeString: Array(str.utf16))
                event.post(tap: .cghidEventTap)
            }
            
            keyPressDelay()
            
            if let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
                event.post(tap: .cghidEventTap)
            }
        }
    }
    
    /// Simulates pressing a key with modifier keys held down
    /// - Parameters:
    ///   - key: The key to press (can be a character or special key name)
    ///   - modifiers: Array of modifier key names (e.g., ["command", "shift"])
    static func pressKeyWithModifiers(key: String, modifiers: [String]) {
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Set new flags for our modified key press
        let modifierFlags = getModifierFlags(modifiers)
        
        // Handle special keys
        if let keyCode = specialKeyMap[key.lowercased()] {
            if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) {
                keyDown.flags = modifierFlags
                keyDown.post(tap: .cghidEventTap)
            }
            
            keyPressDelay()
            
            if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
                keyUp.flags = modifierFlags
                keyUp.post(tap: .cghidEventTap)
            }
        }
        // For regular characters, use simple string input with modifiers
        else if let char = key.first {
            if let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
                event.flags = modifierFlags
                let str = String(char)
                event.keyboardSetUnicodeString(stringLength: str.utf16.count, unicodeString: Array(str.utf16))
                event.post(tap: .cghidEventTap)
            }
            
            keyPressDelay()
            
            if let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
                event.flags = modifierFlags
                event.post(tap: .cghidEventTap)
            }
        }
        
        // Read current flags state
        if let checkEvent = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
            print("Current system flags state: \(checkEvent.flags)")
        }
    }
    
    /// Types a Unicode character directly, handling characters beyond the BMP
    /// - Parameter char: The character to type
    static func unicodeKeyPress(char: Character) {
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Convert character to UTF-16 code units
        let utf16 = String(char).utf16
        let codeUnits = Array(utf16)
        
        // Type each UTF-16 code unit
        for codeUnit in codeUnits {
            if let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
                event.keyboardSetUnicodeString(stringLength: 1, unicodeString: [codeUnit])
                event.post(tap: .cghidEventTap)
            }
            
            keyPressDelay()
            
            // Key up event
            if let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
                event.post(tap: .cghidEventTap)
            }
            
            // Small delay between code units if there are multiple
            if codeUnits.count > 1 {
                usleep(UInt32.random(in: 10000...20000))
            }
        }
    }
    
    /// Types a string of text with natural timing
    /// - Parameter text: The text to type
    static func typeText(text: String) {
        for char in text {
            switch char {
            case "\n", "\r":  // Return/newline
                keyPress(key: "return")
            case "\t":        // Tab
                keyPress(key: "tab")
            default:
                // Use Unicode input for all other characters
                unicodeKeyPress(char: char)
            }
            
            // Random delay between characters (10-20ms)
            usleep(UInt32.random(in: 10000...20000))
        }
    }
    
    /// Gets the CGEventFlags for a list of modifier key names
    /// - Parameter modifierNames: Array of modifier key names (e.g., ["command", "shift"])
    /// - Returns: Combined CGEventFlags for the specified modifiers
    static func getModifierFlags(_ modifierNames: [String]) -> CGEventFlags {
        var flags = CGEventFlags()
        for name in modifierNames {
            if let flag = modifierFlags[name.lowercased()] {
                flags.insert(flag)
            }
        }
        return flags
    }
    
    /// Gets the CGKeyCode for a special key name
    /// - Parameter key: The name of the special key (e.g., "return", "tab")
    /// - Returns: The corresponding CGKeyCode, or nil if not found
    static func getKeyCode(_ key: String) -> CGKeyCode? {
        return specialKeyMap[key.lowercased()]
    }

    static func keyPressDelay() {
        // Small delay between press and release (20-50ms)
        usleep(UInt32.random(in: 20000...50000))        
    }

    static func getMouseLocation() -> NSPoint? {
        guard let mainScreen = NSScreen.main else { return nil }
        let screenHeight = mainScreen.frame.height // Get the screen height
        var pos = NSEvent.mouseLocation
        pos.y = screenHeight - pos.y // Flip the y-coordinate
        return pos
    }
}
