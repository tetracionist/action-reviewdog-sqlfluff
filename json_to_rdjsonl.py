import json
import argparse


def preprocess_file(filename):
    # Read the file and skip the first line if it's invalid
    with open(filename, "r") as file:
        lines = file.readlines()

    # Check if the first line is None or empty and skip it if so
    first_line = lines[0].strip()
    if first_line.lower() == "none" or first_line == "":
        lines = lines[1:]

    # Combine the remaining lines and return as a single string
    return "".join(lines)


def transform_to_rdjsonl(lint_output, dbt_project_dir):
    rdjsonl_lines = []
    for result in lint_output:
        for violation in result["violations"]:
            rdjsonl_line = {
                "message": violation["description"],
                "location": {
                    "path": f"{dbt_project_dir}/{result['filepath']}",
                    "range": {
                        "start": {
                            "line": violation["start_line_no"],
                            "column": violation["start_line_pos"],
                        },
                        "end": {
                            "line": violation["end_line_no"],
                            "column": violation["end_line_pos"],
                        },
                    },
                },
                "suggestions": [
                        {
                            "range": {
                                "start": {
                                    "line": fix["start_line_no"],
                                    "column": fix["start_line_pos"],
                                },
                                "end": {
                                    "line": fix["end_line_no"],
                                    "column": fix["end_line_pos"],
                                },
                            },
                            "text": fix["edit"],
                        }
                        for fix in violation.get("fixes", [])
                    ],
                "severity": "ERROR",
            }
            rdjsonl_lines.append(rdjsonl_line)
    return rdjsonl_lines

def merge_consecutive_suggestions(suggestions):
    merged_suggestions = []
    current_range = None
    current_text = ""

    for suggestion in suggestions:
        if current_range is None:
            # Initialize current range and text with the first suggestion
            current_range = suggestion["range"]
            current_text = suggestion["text"]
        elif suggestion["text"] == current_text:
            # Extend the current range if the text is the same as the previous suggestion
            current_range["end"] = suggestion["range"]["end"]
        else:
            # Append the merged suggestion and reset current range and text
            merged_suggestions.append({
                "range": current_range,
                "text": current_text
            })
            current_range = suggestion["range"]
            current_text = suggestion["text"]

    # Append the last merged suggestion
    if current_range is not None:
        merged_suggestions.append({
            "range": current_range,
            "text": current_text
        })

    return merged_suggestions


def main():
    parser = argparse.ArgumentParser(
        description="Convert SQL lint output to rdjsonl format"
    )
    parser.add_argument(
        "--filename",
        help="Path to the JSON lint output file",
        default="lint_output.json",
        required=False,
    )
    parser.add_argument(
        "--dbt_project_dir", help="Path to the DBT project directory", required=True
    )
    args = parser.parse_args()

    json_content = preprocess_file(args.filename)
    lint_output = json.loads(json_content)
    rdjsonl_output = transform_to_rdjsonl(lint_output, args.dbt_project_dir)

    for rdjsonl_entry in rdjsonl_output:
        suggestions = rdjsonl_entry["suggestions"]
        merged_suggestions = merge_consecutive_suggestions(suggestions)
        if merged_suggestions:
            rdjsonl_entry["suggestions"] = merged_suggestions[:1]
    


    with open("violations.rdjsonl", "w") as outfile:
        for entry in rdjsonl_output:
            json.dump(entry, outfile)
            outfile.write("\n")


if __name__ == "__main__":
    main()
