#!/usr/bin/env python3

from axplorer.macos.action import type_text, press_key, press_key_combo
import time

def demonstrate_text_input():
    print("1. Basic text input (using type_text):")
    type_text("Hello, World!")
    time.sleep(2)
    
    print("\n2. Special characters and symbols (using type_text):")
    type_text("©®™€£¥§¶†‡")  # Unicode symbols
    time.sleep(2)
    
    print("\n3. Emojis (using type_text):")
    type_text("👋🌍✨")  # Emojis
    time.sleep(2)
    
    print("\n4. Mixed text with control characters (using type_text):")
    type_text("Line 1\nLine 2\tTabbed textHello,\nLine 3")  # Newlines and tabs
    time.sleep(2)

def demonstrate_keyboard_actions():
    print("\nKeyboard actions:")
    
    print("\n1. Special keys (using press_key):")
    press_key("\t")      # Tab key
    time.sleep(0.5)
    press_key("\n")   # Return key
    time.sleep(0.5)
    press_key(" ")    # Space key
    time.sleep(0.5)
    
    print("\n2. Navigation keys (using press_key):")
    press_key("left")     # Left arrow
    time.sleep(0.5)
    press_key("right")    # Right arrow
    time.sleep(0.5)
    press_key("up")       # Up arrow
    time.sleep(0.5)
    press_key("down")     # Down arrow
    time.sleep(0.5)
    
    print("\n3. Keyboard shortcuts (using press_key_combo):")
    press_key_combo("a", ["command"])  # Select all
    time.sleep(0.5)
    press_key_combo("c", ["command"])  # Copy
    time.sleep(0.5)
    press_key_combo("v", ["command"])  # Paste
    time.sleep(0.5)

if __name__ == "__main__":
    demonstrate_text_input()
    demonstrate_keyboard_actions()
