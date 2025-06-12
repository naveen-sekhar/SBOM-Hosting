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
├── applications/              # Target software directories or binaries
├── docker\_images/             # Scripts and tools for Docker image analysis
├── reports/                   # HTML and JSON reports generated
├── scripts/                   # Core automation scripts
│   ├── generate\_sbom.py
│   ├── validate\_sbom.py
│   ├── scan\_with\_grype.py
│   ├── generate\_report.py
│   └── bulk\_cve\_lookup.py
├── README.md
└── requirements.txt

````

## 📌 Prerequisites

Install the required tools - Syft and Grype:

```bash
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sudo sh -s -- -b /usr/local/bin
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sudo sh -s -- -b /usr/local/bin
```

## ⚙️ How to Use

### 1. Generate SBOM

```bash
python scripts/generate_sbom.py /path/to/software
```

### 2. Validate SBOM

```bash
python scripts/validate_sbom.py /path/to/sbom.spdx.json
```

### 3. Perform Vulnerability Scan

```bash
python scripts/scan_with_grype.py /path/to/sbom.spdx.json
```

### 4. Generate HTML Report

```bash
python scripts/generate_report.py --input reports/vulnerabilities.json --output reports/final_report.html
```

### 5. Bulk CVE Lookup (NVD & Vulners)

```bash
streamlit run scripts/bulk_cve_lookup.py
```

## 🧪 Sample Targets Analyzed

* LibreOffice
* GIMP
* Tux Typing
* VLC Media Player
* Docker Image: `nginx:latest`
* Python Flask Application
* DVWA Vulnerable App (Docker)

## 📊 Sample Report

> Available in `reports/final_report.html`

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
* 
## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## 📬 Contact

For questions, feel free to raise an issue or email at: `e0223006@sriher.edu.in`

---

> *Secure your software, one component at a time.*
