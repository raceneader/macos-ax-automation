#!/usr/bin/env python3
from axplorer.common.yaml import filter_yaml_by_key_value

def test_filter_yaml():
    # Test YAML content
    yaml_content = """
- name: Button1
  role: AXCell
  value: 123
- name: Button2
  role: AXButton
  value: 456
"""
    
    # Test filtering by role=AXCell
    filtered = filter_yaml_by_key_value(yaml_content, 'role', 'AXCell')
    print("Original YAML:")
    print(yaml_content)
    print("\nFiltered YAML (excluding role=AXCell):")
    print(filtered)

if __name__ == "__main__":
    test_filter_yaml()
