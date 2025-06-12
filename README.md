# SBOM Automation Using Syft & Vulnerability Analysis using Grype 

This project offers an end-to-end workflow for creating Software Bill of Materials (SBOMs) and running automated vulnerability scans on installed enterprise software — binaries, source directories, Docker containers, and live systems. It accommodates various SBOM formats, integrates with major vulnerability databases (NVD, Vulners), and outputs in-depth human-readable reports.

## 🚀 Project Overview

The growing complexity of enterprise software demands a systematic way to understand and manage its components. This project aims to:

- Generate SBOMs in SPDX and CycloneDX formats
- Automatically identify dependencies and components in source code or binaries
- Scan for known vulnerabilities (CVEs) using trusted databases
- Support bulk and individual software scans (applications, Docker images, etc.)
- Create HTML and JSON reports for visualizing and auditing

## 📦 Features

- ✅ SBOM generation in SPDX and CycloneDX
- ✅ Vulnerability scanning using Grype, Syft, and APIs (NVD, Vulners)
- ✅ Docker image analysis with SBOM + CVE lookup
- ✅ HTML, JSON, and terminal report outputs
- ✅ Support for GUI-based and CLI-based applications
- ✅ Automation scripts for end-to-end analysis

## 🧰 Tech Stack

- **Languages**: Python, Bash, HTML, CSS, JS 
- **Tools**: 
  - [Syft](https://github.com/anchore/syft) – for SBOM generation
  - [Grype](https://github.com/anchore/grype) – for vulnerability scanning

## 📁 Output Folder Structure

```

SBOM-Vulnerability-Analysis/
├── html.tmpl            # Contains the template for the report.html page
├── report.html          # Visual representation of the vulnerability analysis in a html page(Generated using grype)
├── report.txt           # Contains the CVE ids and their details in the text document
├── sbom_cyclonedx.json  # CycloneDX Format 
└── sbom_spdx.json       # SPDX Format

````

## 📌 Prerequisites

Install the required tools - Syft and Grype:

```bash
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sudo sh -s -- -b /usr/local/bin
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sudo sh -s -- -b /usr/local/bin
```

## ⚙️ How to Use

### 1. Clone into you local system

```bash
git clone https://github.com/naveen-sekhar/SBOM-Hosting.git
```

### 2. Change the directory

```bash
cd SBOM-HOSTING/Automation
```

### 3. Give file executable permissions

```bash
chmod +x SBOM_Automation.sh
```
* If you need comparison for trivy
```bash
chmod +x SBOM_syft_trivy_Automation.sh
``` 

### 4. Run the File 

```bash
./SBOM_Automation
```

## 🧪 Sample Targets Analyzed

* LibreOffice
* GIMP
* Tux Typing
* VLC Media Player
* Docker Image: `nginx:latest`
* Python Flask Application
* DVWA Vulnerable App (Docker)

### 📊 Sample Report

> Available in deploy branch inside the ['Tested_Comparison_Files'](https://github.com/naveen-sekhar/SBOM-Hosting/tree/deploy/Tested_Comparison_Files) Folder

Includes:

* Vulnerability counts by severity
* CVE details (CVSS score, description)
* Affected packages and versions
* SBOM component statistics

## 📌 Future Enhancements

* Integration with GitHub Security Advisories
* Real-time dashboard using Streamlit
* CI/CD integration for DevSecOps pipelines
* SBOM diffing and historical tracking

## 🧑‍💻 Authors

* \[Naveen Sekhar] – SBOM Automation & Vulnerability Analysis

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## 📬 Contact

For questions, feel free to raise an issue or email at: `e0223006@sriher.edu.in`

---

> *Secure your software, one component at a time.*
