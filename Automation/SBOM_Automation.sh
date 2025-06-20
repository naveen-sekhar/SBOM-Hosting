#!/bin/bash

# === Function: Check & Update Syft ===
check_update_syft() {
  if ! command -v syft >/dev/null 2>&1; then
    echo "❌ Syft is not installed. Please install Syft first."
    exit 1
  fi
  echo "🔍 Syft current version: $(syft version)"
  echo "⬆️ Updating Syft to latest version..."
  curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sudo sh -s -- -b /usr/local/bin
  echo "✅ Syft updated to: $(syft version)"
}

# === Function: Check & Update Grype ===
check_update_grype() {
  if ! command -v grype >/dev/null 2>&1; then
    echo "❌ Grype is not installed. Please install Grype first."
    exit 1
  fi
  echo "🔍 Grype current version: $(grype version)"
  echo "⬆️ Updating Grype to latest version..."
  curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sudo sh -s -- -b /usr/local/bin
  echo "✅ Grype updated to: $(grype version)"
}

# === Function: Path Compatibility ===
realpath_fallback() {
  [[ "$1" = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

# === Function: SBOM & Vulnerability Analysis ===
run_sbom_analysis() {
  read -p "Enter path to application folder OR Docker image name: " TARGET
  read -p "Enter path where output should be saved: " OUTPUT_DIR

  # Normalize Output Directory
  if command -v realpath >/dev/null 2>&1; then
    OUTPUT_DIR=$(realpath "$OUTPUT_DIR")
  else
    OUTPUT_DIR=$(realpath_fallback "$OUTPUT_DIR")
  fi

  mkdir -p "$OUTPUT_DIR"
  cd "$OUTPUT_DIR" || exit

  # Check if input is Docker image or directory
  if docker image inspect "$TARGET" > /dev/null 2>&1; then
    SCAN_MODE="image"
  else
    if command -v realpath >/dev/null 2>&1; then
      TARGET=$(realpath "$TARGET")
    else
      TARGET=$(realpath_fallback "$TARGET")
    fi
    if [[ ! -d "$TARGET" ]]; then
      echo "❌ Error: Directory '$TARGET' does not exist."
      exit 1
    fi
    SCAN_MODE="dir"
  fi

  echo "🟡 Scanning mode: $SCAN_MODE"
  echo "📦 Target: $TARGET"
  echo "💾 Output: $OUTPUT_DIR"

  # === HTML Template (html.tmpl) ===
  cat > html.tmpl << 'EOF'
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <title>Vulnerability Report</title>

    <!-- Template Metadata-->
    <meta name="author" content="grype">
    <meta name="version" content="1.0.0">

    <!-- Source DataTables.js and its dependencies -->
    <!-- Styling: DataTables | Packages: Jquery | Core: DataTables | Extensions: Buttons, HTML5 Export, JSZip, PDFmake, Responsive -->
    <link href="https://cdn.datatables.net/v/dt/jq-3.7.0/jszip-3.10.1/dt-2.3.0/b-3.2.3/b-html5-3.2.3/r-3.0.4/datatables.min.css" rel="stylesheet" integrity="sha384-i3FrIG8iE4wl9Hmwo+yL2xgtj0L+/QgCSGfIAJbuoowqsGIdhIpg9ax2eizUyCZw" crossorigin="anonymous">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.2.7/pdfmake.min.js" integrity="sha384-VFQrHzqBh5qiJIU0uGU5CIW3+OWpdGGJM9LBnGbuIH2mkICcFZ7lPd/AAtI7SNf7" crossorigin="anonymous"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.2.7/vfs_fonts.js" integrity="sha384-/RlQG9uf0M2vcTw3CX7fbqgbj/h8wKxw7C3zu9/GxcBPRKOEcESxaxufwRXqzq6n" crossorigin="anonymous"></script>
    <script src="https://cdn.datatables.net/v/dt/jq-3.7.0/jszip-3.10.1/dt-2.3.0/b-3.2.3/b-html5-3.2.3/r-3.0.4/datatables.min.js" integrity="sha384-uD0xNCd/C2vKjG5NDZ8BdHFubelfW0p6XH+6n7crJnbQcPP6aUw5MJ3WfEZFz3bA" crossorigin="anonymous"></script>
    
    <!-- Include Devicon (for specific tech icons) - Using @latest -->
    <link rel="stylesheet" type='text/css' href="https://cdn.jsdelivr.net/gh/devicons/devicon@2.16.0/devicon.min.css" /> 
    
    <!-- Preload SVG icons used in CSS -->
    <link rel="preload" href="https://api.iconify.design/noto:package.svg" as="image">
    <link rel="preload" href="https://api.iconify.design/file-icons:alpine-linux.svg" as="image">
    <link rel="preload" href="https://api.iconify.design/vscode-icons:file-type-excel.svg" as="image">
    <link rel="preload" href="https://api.iconify.design/vscode-icons:file-type-pdf2.svg" as="image">

    <!-- Font Awesome for search icon -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.7.2/css/all.min.css" integrity="sha512-Evv84Mr4kqVGRNSgIGL/F/aIDqQb7xQ2vcrdIwxfjThSH8CSR7PBEakCr51Ck+w+/U6swU2Im1vVX0SVk9ABhg==" crossorigin="anonymous" referrerpolicy="no-referrer" />
    
    <!-- CSS Variables for Theming -->
    <style>
        /* Root variables for light theme */
        :root {
            --bg-color: #f4f4f4;
            --text-color: #333;
            --container-bg: #fff;
            --container-shadow: rgba(0, 0, 0, 0.1);
            --header-bg: #e8f0fe;
            --header-text: #495057;
            --severity-box-text: rgba(255, 255, 255, 0.9);
            --severity-box-shadow-hover: rgba(0, 0, 0, 0.2);
            --input-border-color: #ccc;
            --input-bg-color: #fff;
            --input-text-color: #333;
            --button-bg: #007bff;
            --button-hover-bg: #0056b3;
            --button-text: white;
            --table-border: #ddd;
            --table-header-bg: #d1dff0;
            --table-header-text: #333;
            --table-row-hover-bg: #f5f5f5;
            --link-color: #007bff;
            --link-visited-color: #551a8b;
            --pill-text: white;
        }

        /* Dark theme variables */
        @media (prefers-color-scheme: dark) {
            :root {
                --bg-color: #1a1a1a;
                --text-color: #e0e0e0;
                --container-bg: #2c2c2c;
                --container-shadow: rgba(255, 255, 255, 0.1);
                --header-bg: #3a3a3a;
                --header-text: #c0c0c0;
                --severity-box-text: rgba(255, 255, 255, 0.9);
                --severity-box-shadow-hover: rgba(255, 255, 255, 0.2);
                --input-border-color: #555;
                --input-bg-color: #3a3a3a;
                --input-text-color: #e0e0e0;
                --button-bg: #0d6efd;
                --button-hover-bg: #0b5ed7;
                --button-text: white;
                --table-border: #444;
                --table-header-bg: #4a4a4a;
                --table-header-text: #e0e0e0;
                --table-row-hover-bg: #3f3f3f;
                --link-color: #58a6ff;
                --link-visited-color: #9d8eee;
                --pill-text: white;
            }

            /* DataTables dark mode adjustments */
            .dataTables_wrapper .dataTables_length select,
            .dataTables_wrapper .dt-search input,
            .dataTables_wrapper .dataTables_info,
            .dataTables_wrapper .dataTables_paginate .paginate_button {
                color: var(--text-color) !important;
            }

            .dataTables_wrapper .dataTables_paginate .paginate_button.disabled {
                color: #666 !important;
            }

            .dataTables_wrapper .dataTables_paginate .paginate_button:hover {
                 background-color: var(--table-row-hover-bg);
                 border-color: var(--table-border);
                 color: var(--text-color) !important;
            }

            /* Dark mode table link colors */
            #vulnerabilityTable a {
                color: var(--link-color);
            }
            #vulnerabilityTable a:visited {
                 color: var(--link-visited-color);
             }
        }
    </style>
    <!-- Page & Main Container -->
    <style>
        /* Base page styling */
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: flex-start;
            background-color: var(--bg-color);
            color: var(--text-color);
        }

        /* Main container styling */
        .main-container {
            width: 90%;
            max-width: 1200px;
            background-color: var(--container-bg);
            padding: 20px;
            box-shadow: 0 4px 8px var(--container-shadow);
            border-radius: 10px;
            margin: 20px;
        }

        /* Global link styling */
        a {
            color: var(--link-color);
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
        a:visited {
            color: var(--link-visited-color);
        }
    </style>
    <!-- Header Container -->
    <style>
        /* Header container styling */
        .heading {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 10px;
            margin-bottom: 20px;
            border-radius: 5px;
            background-color: var(--header-bg);
            color: var(--header-text);
        }

        /* Left and right sections of header */
        .heading-left,
        .heading-right {
            display: flex;
            flex-direction: column;
            align-items: flex-start;
        }

        /* Right section specific styling */
        .heading-right {
            align-items: flex-end;
            padding-right: 20px;
            color: var(--header-text);
        }

        /* Logo image styling */
        .heading-right img {
            width: 70px;
            height: auto;
        }

        /* Left section text styling */
        .heading-left h1,
        .heading-left p {
            padding-left: 20px;
            margin: 4px 0;
        }

        /* Report details grid layout */
        .heading-left dl.report-details {
            padding-left: 20px;
            margin: 4px 0;
            display: grid;
            grid-template-columns: auto 1fr;
            gap: 2px 10px;
            align-items: baseline;
        }

        /* Definition term styling */
        .heading-left dt {
            grid-column: 1;
            font-weight: bold;
            text-align: left;
        }

        /* Definition description styling */
        .heading-left dd {
            grid-column: 2;
            margin: 0;
            text-align: left;
            word-break: break-all;
        }
    </style>
    <!-- Severity Information Container -->
    <style>
        /* Severity info container styling */
        .severity-info {
            display: flex;
            justify-content: space-around;
            align-items: center;
            padding: 10px;
            background-color: var(--header-bg);
            color: var(--header-text);
            margin-bottom: 20px;
            border-radius: 5px;
        }

        /* Individual severity box styling */
        .severity-box {
            flex-grow: 1;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            align-items: center;
            text-align: center;
            padding: 20px;
            margin: 5px;
            border-radius: 5px;
            cursor: pointer;
            position: relative;
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }

        /* Severity title styling */
        .severity-title {
            font-size: 0.8em;
            position: absolute;
            bottom: 10px;
            width: 100%;
            color: var(--severity-box-text);
        }

        /* Severity count styling */
        .severity-count {
            font-size: 3em;
            margin-bottom: 20px;
            color: #fff;
        }

        /* Active severity box styling */
        .severity-box.active {
            border: 2px solid #007bff;
        }

        /* Severity color definitions */
        #critical {
            background-color: #d9534f;
        }

        #high {
            background-color: #f0ad4e;
        }

        #medium {
            background-color: #5bc0de;
        }

        #low {
            background-color: #5cb85c;
        }

        #unknown {
            background-color: #777;
        }

        /* Severity box hover effects */
        .severity-box:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 20px var(--severity-box-shadow-hover);
        }
    </style>
    <!-- Table Control & Datatables Wrapper -->
    <style>
        /* DataTables wrapper styling */
        .dataTables_wrapper {
            display: flex;
            justify-content: space-between;
            align-items: center;
            background-color: var(--header-bg);
            color: var(--header-text);
            margin-bottom: 10px;
            border-radius: 5px;
            transition: background-color 0.3s ease, color 0.3s ease;
        }

        /* Button group styling */
        .dt-buttons {
            order: 2;
            flex-grow: 1;
            display: flex;
            justify-content: flex-end;
            gap: 10px;
            padding-right: 10px;
        }

        /* DataTables button styling */
        .dt-button {
            background-color: var(--button-bg) !important;
            color: white !important;
            border: none !important;
            border-radius: 5px !important;
            padding: 0 !important;
            width: 36px !important;
            height: 36px !important;
            font-size: 16px !important;
            display: flex !important;
            align-items: center !important;
            justify-content: center !important;
            text-align: center;
            cursor: pointer;
            margin-left: 5px !important;
            box-shadow: 0 2px 5px rgba(0,0,0,0.2);
            transition: background-color 0.2s ease;
            overflow: hidden;
        }

        /* Button hover state */
        .dt-button:hover {
            background-color: var(--button-hover-bg) !important;
            box-shadow: 0 4px 8px rgba(0,0,0,0.3);
        }

        /* Icon-only button styling */
        .dt-button.buttons-pdf,
        .dt-button.buttons-excel {
            background-color: transparent !important;
            border: none !important;
            box-shadow: none !important;
        }

        /* Icon-only button hover state */
        .dt-button.buttons-pdf:hover,
        .dt-button.buttons-excel:hover {
            background-color: rgba(0, 0, 0, 0.1) !important;
            box-shadow: none !important;
        }

        /* Icon sizing */
        .dt-button.buttons-pdf .vscode-icons--file-type-pdf2,
        .dt-button.buttons-excel .vscode-icons--file-type-excel {
            width: 32px;
            height: 32px;
        }

        /* Child row details styling */
        .child-row-details {
            padding: 10px;
            margin-left: 25px;
            background-color: var(--container-bg);
            color: var(--text-color);
            border-top: 1px solid var(--table-border);
            margin-top: -1px;
            white-space: normal !important;
        }
        .child-row-details b {
            font-weight: bold;
        }
        .child-row-details ul {
            list-style-type: disc;
            padding-left: 20px;
            margin-top: 5px;
            margin-bottom: 10px;
        }

        /* === Search Bar === */

        /* Search box container */
        .dataTables_wrapper .dt-search {
            position: relative;
        }

        /* Search input styling */
        .dataTables_wrapper .dt-search .dt-input {
            height: 36px;
            width: 36px;
            border-style: none;
            padding: 5px 10px;
            font-size: 14px;
            letter-spacing: 1px;
            outline: none;
            border-radius: 18px;
            transition: all 0.5s ease-in-out;
            background-color: var(--button-bg);
            padding-left: 10px;
            padding-right: 30px;
            color: var(--button-text);
            vertical-align: middle;
            cursor: pointer;
        }

        /* Search input placeholder styling */
        .dataTables_wrapper .dt-search .dt-input::placeholder {
            color: var(--text-color);
            opacity: 0.7;
        }

        /* Dark mode placeholder adjustments */
        @media (prefers-color-scheme: dark) {
            .dataTables_wrapper .dt-search .dt-input::placeholder {
                color: var(--text-color);
                opacity: 0.7;
            }
            .dataTables_wrapper .dt-search .dt-input:focus {
                background-color: var(--input-bg-color);
                color: var(--input-text-color);
            }
        }

        /* Search input focus state */
        .dataTables_wrapper .dt-search .dt-input:focus {
            width: 250px;
            border-radius: 5px;
            background-color: var(--input-bg-color);
            border: 1px solid var(--input-border-color);
            color: var(--input-text-color);
            cursor: text;
        }

        /* Search icon container */
        .dataTables_wrapper .dt-search > label {
            position: absolute;
            right: 0.1em;
            top: 0;
            height: 36px;
            width: 36px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--button-text);
            font-size: 14px;
            cursor: pointer;
            pointer-events: none;
            z-index: 2;
            transition: color 0.3s ease-in-out;
        }

        /* Search icon styling */
        .dataTables_wrapper .dt-search > label::before {
                font-family: "Font Awesome 6 Free";
                font-weight: 900;
                content: "\f002";
        }

        /* Search icon focus state */
        .dataTables_wrapper .dt-search .dt-input:focus + label {
            color: var(--text-color);
        }

        /* Hide label text */
        .dataTables_wrapper .dt-search > label span {
            display: none;
        }
    </style>
    <!-- Table Container -->
    <style>
        /* Table container styling */
        .data-table {
            background-color: var(--header-bg);
            color: var(--header-text);
            padding: 20px;
            border-radius: 5px;
            overflow-x: auto;
            transition: background-color 0.3s ease, color 0.3s ease;
        }

        /* Table base styling */
        table.display {
            width: 100%;
            border-collapse: collapse;
            color: var(--text-color);
        }

        /* Table cell styling */
        th,
        td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid var(--table-border);
        }

        /* Table header styling */
        th {
            background-color: var(--table-header-bg);
            font-weight: bold;
            color: var(--table-header-text);
        }

        /* Table row hover state */
        tr:hover {
            background-color: var(--table-row-hover-bg);
        }

        /* Table link styling */
        table.display a {
             color: var(--link-color);
        }

        table.display a:visited {
             color: var(--link-visited-color);
        }

        /* Fixed-in column styling */
        .fixed-in ul {
            list-style-type: none;
            padding: 0;
            margin: 0;
        }

        .fixed-in li {
            padding: 0;
            margin: 0;
        }
    </style>
    <!-- Severity Coloring -->
    <style>
        /* Severity pill base styling */
        .severity-pill,
        .child-row-details .severity-pill {
            display: inline-block; 
            padding: 5px 10px;
            border-radius: 15px;
            color: var(--pill-text);
            text-align: center;
        }

        /* Severity color definitions */
        .critical,
        .child-row-details .critical {
            background-color: #d9534f;
        }

        .high,
        .child-row-details .high {
            background-color: #f0ad4e;
        }

        .medium,
        .child-row-details .medium {
            background-color: #5bc0de;
        }

        .low,
        .child-row-details .low {
            background-color: #5cb85c;
        }

        .unknown,
        .child-row-details .unknown {
            background-color: #777;
        }
    </style>
    <!-- State Coloring -->
    <style>
        /* State pill base styling */
        .state-pill,
        .child-row-details .state-pill {
            display: inline-block;
            padding: 5px 10px;
            border-radius: 15px;
            color: var(--pill-text);
            text-align: center;
            white-space: nowrap;
        }

        /* State color definitions */
        .fixed,
        .child-row-details .fixed {
            background-color: #d9534f;
        }

        .not-fixed,
        .child-row-details .not-fixed {
            background-color: #f0ad4e;
        }

        .unknown,
        .child-row-details .unknown {
            background-color: #6c757d;
        }

        .wont-fix,
        .child-row-details .wont-fix {
            background-color: #5cb85c;
        }
    </style>

    <!-- Package Type Icon Styling -->
    <style>
        /* Package type cell container */
        .pkg-type-cell {
            display: flex;
            align-items: center;
            gap: 6px;
        }

        /* Icon base styling */
        .pkg-type-cell i,
        .pkg-type-cell .icon-span {
            font-size: 1.2em;
            width: 1.2em;
            text-align: center;
            color: #555;
            flex-shrink: 0;
        }

        /* Package icon fallback */
        .iconify-noto--package {
            display: inline-block;
            width: 1.2em;
            height: 1.2em;
            vertical-align: middle;
            background-color: transparent;
            background-repeat: no-repeat;
            background-size: contain;
            background-position: center;
            background-image: url('https://api.iconify.design/noto:package.svg');
        }

        /* Alpine Linux icon */
        .iconify-file-icons--alpine-linux {
            display: inline-block;
            width: 1.2em;
            height: 1.2em;
            background-color: #0d597f;
            mask-image: url('https://api.iconify.design/file-icons:alpine-linux.svg');
            mask-size: contain;
            mask-repeat: no-repeat;
            mask-position: center;
        }

        /* Excel icon */
        .vscode-icons--file-type-excel {
            display: inline-block;
            width: 20px;
            height: 20px;
            vertical-align: middle;
            background-color: transparent;
            background-repeat: no-repeat;
            background-size: contain;
            background-position: center;
            background-image: url('https://api.iconify.design/vscode-icons:file-type-excel.svg');
        }

        /* PDF icon */
        .vscode-icons--file-type-pdf2 {
            display: inline-block;
            width: 1em;
            height: 1em;
            vertical-align: middle;
            background-color: transparent;
            background-repeat: no-repeat;
            background-size: contain;
            background-position: center;
            background-image: url('https://api.iconify.design/vscode-icons:file-type-pdf2.svg');
        }
    </style>

</head>
{{/* Initialize counters */}}
{{- $CountCritical := 0 }}
{{- $CountHigh := 0 }}
{{- $CountMedium := 0 }}
{{- $CountLow := 0}}
{{- $CountUnknown := 0 }}

{{/* Create a list */}}
{{- $FilteredMatches := list }}

{{/* Loop through all vulns limit output and set count*/}}
{{- range $vuln := .Matches }}
    {{/* Use this filter to exclude severity if needed */}}
    {{- if or (eq $vuln.Vulnerability.Severity "Critical") (eq $vuln.Vulnerability.Severity "High") (eq $vuln.Vulnerability.Severity "Medium") (eq $vuln.Vulnerability.Severity "Low") (eq $vuln.Vulnerability.Severity "Unknown") }}
        {{- $FilteredMatches = append $FilteredMatches $vuln }}
        {{- if eq $vuln.Vulnerability.Severity "Critical" }}
            {{- $CountCritical = add $CountCritical 1 }}
        {{- else if eq $vuln.Vulnerability.Severity "High" }}
            {{- $CountHigh = add $CountHigh 1 }}
        {{- else if eq $vuln.Vulnerability.Severity "Medium" }}
            {{- $CountMedium = add $CountMedium 1 }}
        {{- else if eq $vuln.Vulnerability.Severity "Low" }}
            {{- $CountLow = add $CountLow 1 }}
        {{- else }}
            {{- $CountUnknown = add $CountUnknown 1 }}
        {{- end }}
    {{- end }}
{{- end }}

<body>
    <div class="main-container">
        <div class="heading">
            <div class="heading-left">
                <h1 class="report-title">Vulnerability Report</h1>
                <dl class="report-details">
                    <dt>Name:</dt>
                    <dd id="nameValue"> {{- if eq (.Source.Type) "image" -}} {{.Source.Target.UserInput}}
                        {{- else if eq (.Source.Type) "directory" -}} {{.Source.Target}}
                        {{- else if eq (.Source.Type) "file" -}} {{.Source.Target}}
                        {{- else -}} unknown
                        {{- end -}}</dd>

                    <dt>Type:</dt>
                    <dd id="typeValue">{{ .Source.Type }}</dd>

                    {{- /* Conditionally add ImageID (Checksum) for images */ -}}
                    {{- if eq .Source.Type "image" -}}
                    {{- with .Source.Target.ID -}}
                    <dt>Checksum:</dt>
                    <dd id="checksumValue">{{ . }}</dd>
                    {{- end -}}
                    {{- end -}}

                    <dt>Date:</dt>
                    <dd>
                        <span id="dateElement">{{.Descriptor.Timestamp}}</span>
                        <span id="prettyDateElement" style="display: none;"></span>
                    </dd>
                </dl>
            </div>
            <div class="heading-right">
                <img src="https://user-images.githubusercontent.com/5199289/136855393-d0a9eef9-ccf1-4e2b-9d7c-7aad16a567e5.png"
                    alt="Grype Logo">
            </div>
        </div>
        <div class="severity-info">
            <div class="severity-box" id="critical">
                <div class="severity-title">Critical</div>
                <div class="severity-count" id="criticalCount">{{ $CountCritical }}</div>
            </div>
            <div class="severity-box" id="high">
                <div class="severity-title">High</div>
                <div class="severity-count" id="highCount">{{ $CountHigh }}</div>
            </div>
            <div class="severity-box" id="medium">
                <div class="severity-title">Medium</div>
                <div class="severity-count" id="mediumCount">{{ $CountMedium }}</div>
            </div>
            <div class="severity-box" id="low">
                <div class="severity-title">Low</div>
                <div class="severity-count" id="lowCount">{{ $CountLow }}</div>
            </div>
            <div class="severity-box" id="unknown">
                <div class="severity-title">Unknown</div>
                <div class="severity-count" id="unknownCount">{{ $CountUnknown }}</div>
            </div>
        </div>
        <div class="data-table">
            <table id="vulnerabilityTable" class="display nowrap" style="width:100%">
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>Version</th>
                        <th>Type</th>
                        <th>Vulnerability</th>
                        <th>Severity</th>
                        <th>State</th>
                        <th>Fixed In</th>
                        <th>Description</th>
                        <th>Related URLs</th>
                        <th>PURL</th>
                    </tr>
                </thead>
                <tbody>
                    {{- range $FilteredMatches }}
                    <tr>
                        <td>{{.Artifact.Name}}</td>
                        <td>{{.Artifact.Version}}</td>
                        <td>{{.Artifact.Type}}</td>
                        <td>
                            <a href="{{.Vulnerability.DataSource}}">{{.Vulnerability.ID}}</a>
                        </td>
                        <td>{{.Vulnerability.Severity}}</td>
                        <td>{{.Vulnerability.Fix.State}}</td>
                        <td>
                            {{- if .Vulnerability.Fix.Versions }}
                            <ul>
                                {{- range .Vulnerability.Fix.Versions }}
                                <li>{{ . }}</li>
                                {{- end }}
                            </ul>
                            {{- else }}
                            N/A
                            {{- end }}
                        </td>
                        <td>{{html .Vulnerability.Description}}</td>
                        <td>{{ toJson .Vulnerability.URLs }}</td>
                        <td>{{ .Artifact.PURL }}</td>
                    </tr>
                    {{- end }}
                </tbody>
            </table>
        </div>
    </div>
    <script>

    // ================================================
    // DataTables Core Logic & Callbacks
    // ================================================

    /**
     * Initializes the main DataTable instance (#vulnerabilityTable) with configuration
     * for responsiveness, buttons (PDF, Excel), dynamic page length calculation,
     * column definitions, severity filtering, and other display settings.
     */
    function initDataTable() {
        // Target the table element
        const tableElement = $('#vulnerabilityTable');
        
        // Destroy existing DataTable instance if it exists, to prevent reinitialization errors
        if ($.fn.dataTable.isDataTable(tableElement)) {
            tableElement.DataTable().destroy();
        }

        const table = tableElement.DataTable({
            // Responsive Extension Configuration
            responsive: {
                details: {
                    type: 'inline',
                    // Use the custom renderer function for child row content
                    renderer: renderChildRowDetailsDt
                }
            },
            // DOM Structure Definition (Controls placement)
            // B: Buttons, f: Filter input, t: Table, i: Info, p: Pagination
            // Custom wrappers for styling/control: dataTables_wrapper, dataTables_control
            dom: '<"dataTables_wrapper"Bf>t<"dataTables_control"ip>',

            // Language Configuration
            language: {
                search: "", // Hide the default "Search:" label
                searchPlaceholder: "Search vulnerabilities..." // Set custom placeholder
            },

            // Initial Sorting Order (Sort by Name column, ascending)
            order: [[0, 'asc']],

            // Column Definitions (retrieved from helper function)
            columnDefs: getColumnDefsDt(),

            // Callback after table initialization is complete
            initComplete: function(settings, json) {
                // Calculate and set initial page length based on viewport height
                setDynamicPageLengthDt(this.api());
            },

            // Callback after each table draw (including pagination, filtering, sorting)
            drawCallback: function (settings) {
                const api = this.api();
                const pageInfo = api.page.info();

                // Target the specific wrapper for pagination controls
                const controlsWrapper = $(api.table().container()).find('.dataTables_control');

                // Hide pagination controls if there's only one page
                if (controlsWrapper.length) { // Ensure wrapper exists
                     controlsWrapper.toggle(pageInfo.pages > 1);
                }
            },

            // Buttons Configuration (Export functionality)
            buttons: [
                {
                    extend: 'pdfHtml5',
                    text: '<span class="vscode-icons--file-type-pdf2"></span>', // Use Iconify span
                    titleAttr: 'Export to PDF',                   // Tooltip
                    title: function () { return getReportMetadata().title; },
                    messageTop: function () { return getReportMetadata().message; },
                    filename: function () {
                        return `vulnerability-report-${getReportMetadata().safeName}`;
                    },
                    exportOptions: {
                        // Specify columns to include by name (more robust than index)
                        // Excludes control, Description, PURL, Related URLs from PDF
                        columns: [
                            'Name:name',
                            'Version:name',
                            'Type:name',
                            'Vulnerability:name',
                            'Severity:name',
                            'State:name',
                            'Fixed In:name'
                        ]
                    },
                    customize: function (doc) {
                        // PDF customization: left-align content, adjust widths
                        doc.styles.tableHeader.alignment = 'left';
                        doc.defaultStyle.alignment = 'left';
                        // Relative widths: Name, Vuln, FixedIn get more space
                        doc.content[doc.content.length - 1].table.widths = ['*', 'auto', 'auto', '*', 'auto', 'auto', '*'];
                    }
                },
                {
                    extend: 'excelHtml5',
                    text: '<span class="vscode-icons--file-type-excel"></span>', // Use Iconify span
                    titleAttr: 'Export to Excel',                    // Tooltip
                    title: function () { return getReportMetadata().title; },
                    messageTop: function () { return getReportMetadata().message; },
                    filename: function () {
                        return `vulnerability-report-${getReportMetadata().safeName}`;
                    },
                    exportOptions: {
                        // Specify columns to include by name for Excel
                        // Includes PURL and Related URLs in Excel export
                         columns: [
                            'Name:name',
                            'Version:name',
                            'Type:name',
                            'Vulnerability:name',
                            'Severity:name', 
                            'State:name',
                            'Fixed In:name',
                            'Related URLs:name',
                            'PURL:name'
                        ]
                    }
                }
            ]
        });

        // Setup the click handlers for the severity filter boxes
        initSeverityFilteringDt(table);

        // --- Resize Listener for Dynamic Page Length ---
        // Create a debounced version of the page length calculation
         const dtInstance = table; // Reference the table instance
         const debouncedPageLengthHandler = debounce(function() {
             // Ensure the DataTable instance still exists before calculating
             if ($.fn.dataTable.isDataTable(tableElement)) {
                setDynamicPageLengthDt(dtInstance);
             }
        }, 250); // Delay execution by 250ms after the last resize event

        // Attach the debounced handler to the window resize event
        window.addEventListener('resize', debouncedPageLengthHandler);
    }

    /**
     * Defines the column configurations for the DataTables instance.
     * Specifies properties like name, target index, visibility, searchability,
     * rendering functions, cell creation callbacks, and responsive priority.
     *
     * @returns {Array<object>} An array of DataTables column definition objects.
     */
    function getColumnDefsDt() {
        return [
            // Column 0: Name
            {
                name: 'Name',
                targets: 0,
                searchable: true,
                responsivePriority: 1
            },
            // Column 1: Version
            {
                name: 'Version',
                targets: 1,
                searchable: true,
                responsivePriority: 5
            },
            // Column 2: Type
            {
                name: 'Type',
                targets: 2,
                render: function (data, type, row) { return data; },
                createdCell: function (td, cellData, rowData, row, col) {
                    $(td).html(formatTypeCell(cellData));
                },
                searchable: false,
                responsivePriority: 6
            },
            // Column 3: Vulnerability ID
            {
                name: 'Vulnerability',
                targets: 3,
                searchable: true,
                responsivePriority: 2
            },
            // Column 4: Severity
            {
                name: 'Severity',
                targets: 4,
                // Render raw data; formatting is handled by createdCell and renderChildRowDetails
                render: function (data, type, row) { return data; },
                // Apply pill formatting using helper function after cell is created
                createdCell: function (td, cellData, rowData, row, col) {
                    $(td).html(formatPill(cellData, 'severity'));
                },
                searchable: true,
                responsivePriority: 3
            },
            // Column 5: State
            {
                name: 'State',
                targets: 5,
                 // Render raw data
                render: function (data, type, row) { return data; },
                 // Apply pill formatting using helper function after cell is created
                createdCell: function (td, cellData, rowData, row, col) {
                    $(td).html(formatPill(cellData, 'state'));
                },
                searchable: true,
                responsivePriority: 4
            },
            // Column 7: Fixed In Version(s)
            {
                name: 'Fixed In',
                targets: 6,
                 // Add class to apply styling
                createdCell: function (td, cellData, rowData, row, col) {
                    $(td).addClass('fixed-in');
                },
                searchable: true,
                responsivePriority: 7
            },
             // --- Columns initially hidden, shown in child row by default ---
             // They are excluded from responsivity using className: 'none'
            {
                name: 'Description',
                targets: 7,
                searchable: true,
                className: 'none', // Tell Responsive to hide this column initially
            },
            {
                name: 'Related URLs',
                targets: 8,
                searchable: false,
                className: 'none', // Tell Responsive to hide this column initially
            },
            {
                name: 'PURL',
                targets: 9,
                searchable: false,
                className: 'none', // Tell Responsive to hide this column initially
            },
        ];
    }

    /**
     * Custom renderer function for DataTables Responsive extension.
     * Generates the HTML content for the child row displayed when a row collapses.
     * It iterates through the columns marked as 'hidden' by Responsive for the
     * current row and formats their data appropriately (using helpers like
     * formatPill and formatUrlList) before combining them into a single HTML block.
     *
     * @param {DataTables.Api} api - The DataTables API instance.
     * @param {number} rowIndex - The index of the row being rendered.
     * @param {Array<object>} columns - An array of column objects provided by Responsive,
     *                                  indicating which columns are hidden ({columnIndex, title, hidden}).
     * @returns {string|false} The HTML string for the child row content, or false if no content is generated.
     */
    function renderChildRowDetailsDt( api, rowIndex, columns ) {
        // We will get data cell-by-cell using the correct API.
        let finalHtml = '';

        // Iterate through the column information provided by the Responsive extension
        columns.forEach(function(col) {
            // Only process columns that are currently hidden by Responsive for this specific row
            if (col.hidden) {
                const index = col.columnIndex; // Original index of the column (0-based)
                const title = col.title;       // Column title (from <thead> or columnDefs name)
                
                // --- Use api.cell(rowIndex, columnIndex).data() for robust data retrieval ---
                const data = api.cell(rowIndex, index).data();
                
                let contentHtml = ''; // HTML for this specific column's content

                // Apply specific formatting based on the original column index
                switch (index) {
                    case 2: // Type
                        contentHtml = formatTypeCell(data);
                        break;
                    case 4: // Severity
                        contentHtml = formatPill(data, 'severity');
                        break;
                    case 5: // State
                        contentHtml = formatPill(data, 'state');
                        break;
                     case 7: // Description
                         // Ensure data exists before trying to format
                         contentHtml = data ? String(data) : ''; 
                         break;
                    case 8: // Related URLs
                        contentHtml = formatUrlList(data); // formatUrlList handles empty/invalid data
                        break;
                    default:
                         // Check if data exists and is not null/undefined before displaying
                         if (data !== null && data !== undefined) {
                             contentHtml = String(data); // Convert to string just in case
                         }
                         break;
                }

                // Add the formatted content to the final HTML, wrapped in a div with a title
                // Only add if contentHtml was actually generated (e.g., empty URLs or null data won't add a section)
                if (contentHtml) {
                    finalHtml += `<div class="child-row-details"><b>${title}</b><br>${contentHtml}</div>`;
                }
            }
        });

        // Return the generated HTML (if any content was added), otherwise false
        // Returning false tells Responsive not to show a child row if there's nothing to display
        return finalHtml ? finalHtml : false;
    }

    /**
     * Attaches click handlers to the severity overview boxes.
     * Clicking a box adds/removes its severity from the active filter set.
     * Updates the DataTable to show rows matching *any* of the selected severities.
     * Highlights the active severity boxes.
     *
     * @param {DataTables.Api} table - The DataTables API instance.
     */
    function initSeverityFilteringDt(table) {
        let activeSeverityFilters = []; // Use an array to track multiple selections
        const severityBoxes = $('.severity-box'); // Cache selector

        severityBoxes.on('click', function () {
            const clickedBox = $(this);
            const severity = clickedBox.find('.severity-title').text().trim();
            const severityIndex = activeSeverityFilters.indexOf(severity);

            // Toggle severity in the active filter list
            if (severityIndex > -1) {
                // Severity is currently active, remove it
                activeSeverityFilters.splice(severityIndex, 1);
                clickedBox.removeClass('active');
            } else {
                // Severity is not active, add it
                activeSeverityFilters.push(severity);
                clickedBox.addClass('active');
            }

            // Clear any global search and previous column searches
            table.search('').columns().search('');

            // Apply the combined severity filter to column 5 (Severity)
            if (activeSeverityFilters.length > 0) {
                // Create a regex string like "^Critical$|^High$|^Medium$"
                // This ensures exact matches for each selected severity
                const filterRegex = activeSeverityFilters.map(sev => `^${sev}$`).join('|');
                table.column(4).search(filterRegex, true, false); // Enable regex, disable smart search
            } else {
                // If no filters are active, clear the specific column search
                table.column(4).search('');
            }
            
            // Redraw the table to apply the filter changes
            table.draw();
        });
    }

    /**
     * Calculates the optimal number of rows to display in the DataTable based on
     * available viewport height and sets the table's page length accordingly.
     * It subtracts the height of the table header, pagination controls, and a
     * fixed buffer from the total viewport height to determine the space available
     * for table rows. Ensures at least one row is shown if space permits.
     *
     * @param {DataTables.Api} table - The DataTables API instance for the table.
     */
    function setDynamicPageLengthDt(table) {
        try {
            const tableWrapper = table.table().container();
            const tableBody = table.table().body();
            const controls = $(tableWrapper).find('.dataTables_control')[0];

            // If the table is not visible, don't calculate the page length
            if (!tableWrapper || !tableBody || !tableBody.rows.length) {
                return;
            }

            const firstRow = tableBody.rows[0];
            const rowHeight = firstRow.offsetHeight;

            // If the row height is not valid, don't calculate the page length
            if (!rowHeight || rowHeight <= 0) {
                return;
            }

            // Measure heights and positions
            const controlsHeight = controls ? $(controls).outerHeight(true) : 0; // Height of pagination controls
            const tableBodyTopOffset = tableBody.getBoundingClientRect().top; // Vertical position of the tbody relative to viewport
            const verticalBuffer = 60; // Pixels to leave empty below the table for aesthetics

            // Calculate available height for rows
            const availableHeight = window.innerHeight - tableBodyTopOffset - controlsHeight - verticalBuffer;

            // If there's not enough available height, don't calculate the page length
            if (availableHeight <= 0) {
                return;
            }

            // Calculate how many rows fit and ensure at least 1
            const calculatedNumberOfRows = Math.floor(availableHeight / rowHeight);
            const numberOfRowsToShow = Math.max(1, calculatedNumberOfRows);

            // Apply the new page length only if it has changed
            const currentPageLength = table.page.len();
            if (currentPageLength !== numberOfRowsToShow) {
                table.page.len(numberOfRowsToShow).draw(false);
            }

        } catch (error) {
            console.error("Error calculating page length:", error);
        }
    }

    // ================================================
    // UI Formatting & Utility Helpers
    // ================================================

    /**
     * Formats the original ISO timestamp from the #dateElement into a human-readable
     * format (e.g., "Monday, January 1, 2024 at 12:00 PM") and displays it in
     * the #prettyDateElement, hiding the original element.
     */
    function renderFormattedTimestamp() {
        const originalDateElement = document.getElementById("dateElement");
        const prettyDateElement = document.getElementById("prettyDateElement");

        // Ensure both elements exist
        if (!originalDateElement || !prettyDateElement) {
            console.error("prettyTimestamp: Date elements not found.");
            return;
        }

        const dateString = originalDateElement.textContent;
        if (!dateString) {
            console.warn("prettyTimestamp: Original date string is empty.");
            // Optionally hide the pretty date element or show 'N/A'
            prettyDateElement.textContent = 'N/A';
            prettyDateElement.style.display = '';
            originalDateElement.style.display = 'none';
            return;
        }

        try {
            const date = new Date(dateString);

            // Check for invalid date
            if (isNaN(date.getTime())) {
                console.warn("prettyTimestamp: Invalid date string:", dateString);
                prettyDateElement.textContent = 'Invalid Date';
                prettyDateElement.style.display = '';
                originalDateElement.style.display = 'none';
                return;
            }

            // Format date to a more human-readable form
            const formattedDate = date.toLocaleDateString("en-US", {
                weekday: "long",
                year: "numeric",
                month: "long",
                day: "numeric",
            });

            const formattedTime = date.toLocaleTimeString("en-US", {
                hour: "2-digit",
                minute: "2-digit",
                hour12: true,
            });

            // Update the content of the pretty date element
            prettyDateElement.textContent = `${formattedDate} at ${formattedTime}`;

            // Hide the original and show the pretty one
            originalDateElement.style.display = 'none';
            prettyDateElement.style.display = ''; // Reset to default (inline)

        } catch (error) {
             console.error("prettyTimestamp: Error formatting date:", error);
             prettyDateElement.textContent = 'Error'; // Indicate an error occurred
             prettyDateElement.style.display = '';
             originalDateElement.style.display = 'none';
        }
    }

    /**
     * Extracts report metadata (title, name, type, checksum, date) from DOM elements.
     * Formats the data for use in report exports (PDF, Excel messageTop) and
     * generates a sanitized version of the name for use in filenames.
     *
     * @returns {object} An object containing report metadata:
     *                   { title: string, message: string, name: string, safeName: string }
     */
    function getReportMetadata() {
        // Query elements safely
        const titleElem = document.querySelector('.report-title');
        const nameElem = document.getElementById('nameValue');
        const typeElem = document.getElementById('typeValue');
        const checksumElem = document.getElementById('checksumValue');
        const dateElem = document.getElementById('prettyDateElement');

        // Extract text content with fallbacks
        const title = titleElem ? titleElem.textContent.trim() : 'Vulnerability Report';
        const name = nameElem ? nameElem.textContent.trim() : 'N/A';
        const type = typeElem ? typeElem.textContent.trim() : 'N/A';
        const checksum = checksumElem ? checksumElem.textContent.trim() : 'N/A';
        const dateText = dateElem ? dateElem.textContent.trim() : 'N/A';

        // Sanitize the name for use as a filename (allow letters, numbers, ., _, -)
        const safeName = name.replace(/[^a-z0-9._-]+/gi, '_').replace(/_+/g, '_');

        // Construct the message string for export headers
        let message = `Name: ${name}\n`;
        message += `Type: ${type}\n`;
        if (checksumElem && checksum !== 'N/A') {
            message += `Checksum: ${checksum}\n`;
        }
        message += `Date: ${dateText}\n\n`;

        return {
            title,    // Report title
            message,  // Formatted multi-line message for export header
            name,     // Original name
            safeName  // Sanitized name for filename
        };
    }

    /**
     * Generates HTML for a styled "pill" element used to display Severity or State.
     * Applies appropriate CSS classes based on the data value and type.
     *
     * @param {string} data - The data value (e.g., "Critical", "fixed").
     * @param {string} type - The type of pill ('severity' or 'state').
     * @returns {string} HTML string for the styled span element.
     */
    function formatPill(data, type) {
        // Define mappings from data values to CSS classes
        const severityClasses = {'Critical': 'critical','High': 'high','Medium': 'medium','Low': 'low','Unknown': 'unknown'};
        const stateClasses = {'fixed': 'fixed','not-fixed': 'not-fixed','unknown': 'unknown','wont-fix': 'wont-fix'};

        let baseClass = '';
        let specificClass = '';
        let text = data || 'Unknown'; // Use 'Unknown' as default text if data is falsy

        // Determine base class and specific class based on type
        if (type === 'severity') {
            baseClass = 'severity-pill';
            // Use provided data, fallback to 'Unknown' class if data is not in map
            specificClass = severityClasses[data] || 'unknown';
        } else if (type === 'state') {
            baseClass = 'state-pill';
             // Normalize state data to lower case for matching, fallback to 'unknown' class
            specificClass = stateClasses[String(data).toLowerCase()] || 'unknown';
        } else {
            // If type is unknown, return the raw text without formatting
             console.warn(`formatPill: Unknown type "${type}" for data "${data}"`);
            return text;
        }

        // Construct and return the HTML span element
        // Use text content that was determined (might be 'Unknown')
        return `<span class="${baseClass} ${specificClass}">${text}</span>`;
    }

    /**
     * Parses a JSON string containing an array of URLs and formats them
     * into an HTML unordered list (<ul>). Handles potential JSON parsing errors.
     * URLs starting with 'http' are made into clickable links. Other strings
     * are displayed as plain text list items.
     *
     * @param {string} data - A JSON string representing an array of URLs/strings, or null/undefined.
     * @returns {string} An HTML string containing the <ul> list, or an empty string if no valid URLs are found or parsing fails.
     */
    function formatUrlList(data) {
        let urls = [];
        // Safely parse the JSON data
        try {
            // Only attempt parsing if data is a non-empty string
            if (data && typeof data === 'string') {
                urls = JSON.parse(data);
            }
        } catch (error) {
            console.error("Failed to parse Related URLs JSON:", data, error);
            urls = []; // Ensure urls is an array on error
        }

        let listHtml = '';
        // Ensure urls is an array before proceeding
        if (Array.isArray(urls) && urls.length > 0) {
            listHtml += '<ul>';
            urls.forEach(url => {
                // Check if the item is a valid, non-empty string
                if (url && typeof url === 'string') {
                     // Check if it looks like a clickable URL
                    if (url.startsWith('http://') || url.startsWith('https://')) {
                        // Create a link, escaping URL for safety (though usually fine here)
                        // Add rel="noopener noreferrer" for security when using target="_blank"
                        listHtml += `<li><a href="${url}" target="_blank" rel="noopener noreferrer">${url}</a></li>`;
                    } else {
                        // Display other strings as plain text list items
                        listHtml += `<li>${url}</li>`;
                    }
                }
            });
            listHtml += '</ul>';
        }
        return listHtml;
    }

    /**
     * Returns a function, that, as long as it continues to be invoked, will not
     * be triggered. The function will be called after it stops being called for
     * N milliseconds. If `immediate` is passed, trigger the function on the
     * leading edge, instead of the trailing.
     *
     * @param {Function} func - The function to debounce.
     * @param {number} wait - The number of milliseconds to delay.
     * @param {boolean} [immediate=false] - Trigger the function on the leading edge.
     * @returns {Function} The debounced function.
     */
    function debounce(func, wait, immediate = false) {
        let timeout;

        return function executedFunction() {
            const context = this;
            const args = arguments;

            const later = function() {
                timeout = null;
                if (!immediate) {
                    func.apply(context, args);
                }
            };

            const callNow = immediate && !timeout;

            clearTimeout(timeout);
            timeout = setTimeout(later, wait);

            if (callNow) {
                func.apply(context, args);
            }
        };
    };

    /**
    * Icon mapping for different package types.
    * Uses Devicon classes where available, otherwise a fallback span.
    */
    const packageTypeIcons = {
        'alpm': { type: 'icon', class: 'devicon-archlinux-plain colored' },
        'apk': { type: 'fallback', class: 'iconify-file-icons--alpine-linux' },
        'cocoapods': { type: 'icon', class: 'devicon-apple-original colored' },
        'composer': { type: 'icon', class: 'devicon-composer-line colored' },
        'conan': { type: 'icon', class: 'devicon-cplusplus-plain' },
        'deb': { type: 'icon', class: 'devicon-debian-plain colored' },
        'dotnet': { type: 'icon', class: 'devicon-dotnetcore-plain colored' },
        'gem': { type: 'icon', class: 'devicon-ruby-plain colored' },
        'go-module': { type: 'icon', class: 'devicon-go-original-wordmark colored' },
        'haskell': { type: 'icon', class: 'devicon-haskell-plain colored' },
        'hex': { type: 'icon', class: 'devicon-elixir-plain colored' },
        'java': { type: 'icon', class: 'devicon-java-plain colored' },
        'jenkins-plugin': { type: 'icon', class: 'devicon-jenkins-line' },
        'linux-kernel-module': { type: 'icon', class: 'devicon-linux-plain colored' },
        'lua': { type: 'icon', class: 'devicon-lua-plain colored' },
        'npm': { type: 'icon', class: 'devicon-npm-original-wordmark colored' },
        'nix': { type: 'icon', class: 'devicon-nixos-plain colored' },
        'portage': { type: 'icon', class: 'devicon-gentoo-plain colored' },
        'pub': { type: 'icon', class: 'devicon-dart-plain colored' },
        'python': { type: 'icon', class: 'devicon-python-plain colored' },
        'rpm': { type: 'icon', class: 'devicon-redhat-plain colored' },
        'rust-crate': { type: 'icon', class: 'devicon-rust-plain colored' },
        'swift': { type: 'icon', class: 'devicon-swift-plain colored' },
        'wordpress-plugin': { type: 'icon', class: 'devicon-wordpress-plain colored' },
        'github-action': { type: 'icon', class: 'devicon-github-original colored' },
        'binary': { type: 'fallback', class: 'iconify-noto--package' },
        'buildroot': { type: 'fallback', class: 'iconify-noto--package' },
        'graalvm-native-image': { type: 'fallback', class: 'iconify-noto--package' },
        'kb': { type: 'icon', class: 'devicon-windows11-original colored' },
        // Fallback for unknown types will be handled in formatTypeCell
    };

    /**
     * Generates HTML for a package type cell, including an icon.
     *
     * @param {string} data - The package type string (e.g., "java", "npm").
     * @returns {string} HTML string for the formatted cell content.
     */
    function formatTypeCell(data) {
        const typeKey = data ? String(data).toLowerCase() : 'unknown'; // Normalize key
        const iconInfo = packageTypeIcons[typeKey];
        const fallbackInfo = { type: 'fallback', class: 'noto--package' };
        const chosenInfo = iconInfo || fallbackInfo;

        let iconHtml = '';
        if (chosenInfo.type === 'icon') {
            iconHtml = `<i class="${chosenInfo.class}"></i>`;
        } else { // fallback
            iconHtml = `<span class="icon-span ${chosenInfo.class}"></span>`;
        }

        return `<span class="pkg-type-cell">${iconHtml}<span>${data}</span></span>`;
    }

    // ================================================
    // Main Execution
    // ================================================

    document.addEventListener("DOMContentLoaded", function () {
        // 1. Update the browser page title dynamically using report name
        const headerInfo = getReportMetadata();
        if (headerInfo && headerInfo.safeName && headerInfo.safeName !== 'N_A') {
            document.title = `Vulnerability Report (${headerInfo.safeName})`;
        } else {
            document.title = `Vulnerability Report`;
        }

        // 2. Format the timestamp in the header
        renderFormattedTimestamp();

        // 3. Initialize the main DataTable
        initDataTable();
        
    });



    </script>

</body>

</html>

EOF

  # === SBOM Generation ===
  echo "[1] Generating SPDX and CycloneDX SBOMs..."
  if [[ "$SCAN_MODE" == "image" ]]; then
    syft "$TARGET" -o spdx-json > sbom_spdx.json
    syft "$TARGET" -o cyclonedx-json > sbom_cyclonedx.json
  else
    syft dir:"$TARGET" -o spdx-json > sbom_spdx.json
    syft dir:"$TARGET" -o cyclonedx-json > sbom_cyclonedx.json
  fi

  # === Count Components ===
  echo "[2] Component Count:"
  echo -n "  SPDX Packages: "
  jq '.packages | length' sbom_spdx.json
  echo -n "  CycloneDX Components: "
  jq '.components | length' sbom_cyclonedx.json

  # === Grype Scan ===
  echo "[3] Scanning SBOM with Grype..."
  grype sbom:sbom_spdx.json -o template -t html.tmpl > report.html
  grype sbom:sbom_spdx.json -o table > report.txt

  echo "✅ Done!"
  echo "📄 HTML report: $OUTPUT_DIR/ report.html"
  echo "📄 Text report: $OUTPUT_DIR/ report.txt"
}

# === MAIN MENU ===
while true; do
  echo ""
  echo "===== SBOM & Vulnerability Scanner Menu ====="
  echo "1. Update Syft and Grype"
  echo "2. Start SBOM Generation & Analysis"
  echo "3. Open GitHub Profile (naveen-sekhar)"
  echo "4. Exit"
  read -p "Select an option [1-4]: " choice

  case "$choice" in
    1)
      check_update_syft
      check_update_grype
      ;;
    2)
      run_sbom_analysis
      ;;
    3)
      echo "🌐 Opening GitHub profile..."
      if command -v xdg-open >/dev/null; then
        xdg-open "https://github.com/naveen-sekhar"
      elif command -v open >/dev/null; then
        open "https://github.com/naveen-sekhar"
      else
        echo "❌ Cannot detect browser open command. Visit manually: https://github.com/naveen-sekhar"
      fi
      ;;
    4)
      echo "👋 Exiting... Goodbye!"
      exit 0
      ;;
    *)
      echo "⚠️ Invalid option. Please enter 1, 2, 3, or 4."
      ;;
  esac
done
