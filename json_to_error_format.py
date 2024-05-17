import json
import sys

def preprocess_file(filename):
    # Read the file and skip the first line if it's invalid
    with open(filename, 'r') as file:
        lines = file.readlines()
    
    # Check if the first line is None or empty and skip it if so
    first_line = lines[0].strip()
    if first_line.lower() == 'none' or first_line == '':
        lines = lines[1:]
    
    # Combine the remaining lines and return as a single string
    return ''.join(lines)

def transform_to_rdjsonl(lint_output, dbt_project_dir):
    rdjsonl_lines = []
    for result in lint_output:
        for violation in result['violations']:
            start_line_no = violation.get('start_line_no')
            start_line_pos = violation.get('start_line_pos')
            
            if start_line_no is None:
                # Handle the case where start_line_no is None
                start_line_no = 0  # Or choose an appropriate default
            
            rdjsonl_line = {
                "message": violation['description'],
                "location": {
                    "path": f"{dbt_project_dir}/{result['filepath']}",
                    "range": {
                        "start": {
                            "line": start_line_no,
                            "column": start_line_pos
                        }
                    }
                },
                "severity": "ERROR"
            }
            rdjsonl_lines.append(rdjsonl_line)
    return rdjsonl_lines

def main():
    if len(sys.argv) != 3:
        print("Usage: python convert_to_rdjsonl.py <filename>")
        sys.exit(1)
    
    filename = sys.argv[1]
    dbt_project_dir = sys.argv[2]
    json_content = preprocess_file(filename)
    lint_output = json.loads(json_content)
    rdjsonl_output = transform_to_rdjsonl(lint_output)
    
    # Print the transformed output in rdjsonl format
    for entry in rdjsonl_output:
        print(json.dumps(entry))

if __name__ == "__main__":
    main()
