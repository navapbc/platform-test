import json
import os

from github import create_markdown as create_github_markdown


def parse_trivy():
    scan_results = {}

    file_location = os.environ.get("TRIVY_RESULTS_FILE", "trivy.json")
    if not os.path.exists(file_location):
        print("ERROR: Trivy file not found!")
        return scan_results

    with open(file_location) as findings:
        findings = json.load(findings)
        for result in findings["Results"]:
            # If there are vulnerabilities in the result
            if "Vulnerabilities" in result:
                package_name = result["Target"]
                # For handling if the vulnerability is in the poetry venv. We don't
                # need to see the path to the vulnerability, just what the package is
                # Custom cleaning can be done here to make the output cleaner
                # For example, removing the path to the poetry venv from the package name. Uncomment and modify as needed.
                # package_name = package_name.replace(
                #     "app/.venv/lib/python3.11/site-packages/", ""
                # )

                if package_name not in scan_results:
                    scan_results[package_name] = []
                for line in result["Vulnerabilities"]:
                    scan_results[package_name].append(
                        {
                            "id": line["VulnerabilityID"],
                            "severity": line["Severity"],
                            "status": line["Status"],
                            "cause": f"Current version: {line['InstalledVersion']}, fixed version(s): {line['FixedVersion']}",
                            # Handles if there's markdown in the description, we want to pull the description before markdown
                            "description": line["Description"].split("##")[0],
                        }
                    )
    return scan_results


def parse_anchore():
    scan_results = {}

    file_location = os.environ.get("ANCHORE_RESULTS_FILE", "anchore.json")
    if not os.path.exists(file_location):
        print("ERROR: Anchore file not found!")
        return scan_results

    with open(file_location) as findings:
        findings = json.load(findings)
        for result in findings["matches"]:
            package_name = result["artifact"]["name"]
            if package_name not in scan_results:
                scan_results[package_name] = []
            for line in result["matchDetails"]:
                # The description can sometimes be missing, so we need to handle it
                description = "Finding has no description"
                if "description" in result["vulnerability"]:
                    description = result["vulnerability"]["description"]

                scan_results[package_name].append(
                    {
                        "id": line["found"]["vulnerabilityID"],
                        "severity": result["vulnerability"]["severity"],
                        "status": result["vulnerability"]["fix"]["state"],
                        "cause": f"Current version: {result['artifact']['version']}, fixed version(s): {result['vulnerability']['fix']['versions']}",
                        "description": description,
                    }
                )

    return scan_results


def parse_hadolint():
    scan_results = {}

    file_location = os.environ.get("HADOLINT_RESULTS_FILE", "hadolint.json")
    if not os.path.exists(file_location):
        print("ERROR: Hadolint file not found!")
        return scan_results

    # Possible finding levels from the hadolint results
    finding_levels = ["ignore", "style", "info", "warning", "error"]
    # What level you want to alert on
    alert_level = os.environ.get("HADOLINT_THRESHOLD", "warning")
    # Remove alerting up to the level you want to alert at
    alert_levels = finding_levels[finding_levels.index(alert_level) :]

    with open(file_location) as findings:
        findings = json.load(findings)
        package_name = f"Dockerfile: {os.getenv('DOCKERFILE')}"
        scan_results = {
            # Hadolint only scans Dockerfiles, so it is the only source
            package_name: [],
        }
        for result in findings:
            # Only set findings based on if it is in the alerting levels
            if result["level"] in alert_levels:
                issue = {
                    "id": result["code"],
                    "severity": result["level"],
                    # The status is not compliant to the hadolint scan
                    "status": "Not compliant",
                    "cause": f"Line location: {result['line']}",
                    "description": result["message"],
                }
                scan_results[package_name].append(issue)
        # If we don't have any findings, we want to return an empty dict
        if not scan_results[package_name]:
            return {}
    return scan_results


if __name__ == "__main__":
    image_findings = {
        "Trivy": parse_trivy(),
        "Anchore": parse_anchore(),
        "Hadolint": parse_hadolint(),
    }

    with open("parsed_results.json", "w") as output:
        json.dump(image_findings, output)

    # Creates markdown files for the results. The github markdown file is created by default 
    # for displaying the workflow summary. If there are other formats defined in the environment variable FINDINGS_FORMAT, 
    # then it will create them as well
    create_github_markdown(image_findings, "github_markdown.md")

    markdown_format = os.environ.get("FINDINGS_FORMAT", "github_markdown").lower()
    if markdown_format == "github_markdown":
        create_github_markdown(image_findings, "markdown.md")
    # elif markdown_format != "some_other_format":
    #     run_that_function_here(image_findings)
