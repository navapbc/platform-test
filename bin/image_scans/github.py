import json
import os


def create_markdown(payload: dict, filename: str) -> None:
    # Handles printing out what app these findings are for
    app_name = os.getenv("APP_NAME")

    with open(filename, "w") as output:
        output.write(f"## {app_name}\n\n")

        for key, findings in payload.items():
            # Handles skipping if the findings are empty
            if not findings:
                continue
            # Shows the top level key as a header
            output.write(f"### {key}\n")
            for source in findings:
                output.write("<details>\n")
                output.write(f"<summary>{source}</summary>\n\n")
                for vulnerability in findings[source]:
                    # Handles setting the emoji based on severity
                    emoji = ""
                    if vulnerability["severity"].lower() == "critical":
                        emoji = ":rotating_light: :rotating_light: :rotating_light:"
                    if vulnerability["severity"].lower() in ["high", "error"]:
                        emoji = ":rotating_light:"
                    elif vulnerability["severity"].lower() in ["medium", "warning"]:
                        emoji = ":warning:"

                    output.write(
                        f"#### {emoji} {vulnerability['severity']}: {vulnerability['id']} - {vulnerability['status']}\n"
                    )
                    output.write(f"Cause - {vulnerability['cause']}\n")
                    output.write(f"Description - {vulnerability['description']}\n\n")
                output.write("</details>\n\n")
            output.write("\n\n")
    return
