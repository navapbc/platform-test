---
name: Image Scan Template
about: Describes any findings in a Docker image scanned by the image-scan action
# Will create an issue where the title is like the following format
# Image Scan Findings April 2025 - APP_NAME
# If this issue title already exists, the workflow will update this issue
title: Image Scan Findings {{ date | date('MMMM YYYY') }} - {{ env.APP_NAME }}
# Auto adds these labels on issue creation, the image_scan_findings and API Guild
# label are required for Github project automation to put the issue in the right
# board view
labels: dependencies, image_scan_findings, API Guild
assignees: ""
---

#  Image Scan

## Background

This issue is auto-created by the image-scans.yml workflow. It will update with any findings when the daily run is triggered as long as this issue is open and in the same month. If this issue is closed, or the workflow runs in a new month, it will open a new issue for any findings.

{{ env.IMAGE_FINDINGS }}

## Image Scan Link

[Click here to review logs from workflow run if needed]({{ env.WORKFLOW_LINK }})
