def clean_json_format(json_string : str):
    if json_string.startswith("```json\n"):
        json_string = json_string[8:]  # Remove opening delimiter
    if json_string.endswith("\n```"):
        json_string = json_string[:-4]  # Remove closing delimiter
    return json_string