# SBOM Automation Using Syft & Vulnerability Analysis using Grype 
Here's a detailed and professional `README.md` for your **SBOM Generation and Vulnerability Analysis for Existing Enterprise Software** GitHub repository:

---

```markdown
# SBOM Generation and Vulnerability Analysis

This project provides a comprehensive workflow for generating Software Bill of Materials (SBOMs) and performing automated vulnerability analysis on existing enterprise software — including binaries, source folders, Docker images, and live systems. It supports multiple SBOM formats, integrates with leading vulnerability databases (NVD, Vulners), and produces detailed human-readable reports.

## 🚀 Project Overview

The growing complexity of enterprise software demands a systematic way to understand and manage its components. This project aims to:

- Generate SBOMs in SPDX and CycloneDX formats
- Automatically identify dependencies and components in source code or binaries
- Scan for known vulnerabilities (CVEs) using trusted databases
- Support bulk and individual software scans (applications, Docker images, etc.)
- Create HTML and JSON reports for visibility and auditing

## 📦 Features

- ✅ SBOM generation in SPDX and CycloneDX
- ✅ Vulnerability scanning using Grype, Syft, and APIs (NVD, Vulners)
- ✅ Docker image analysis with SBOM + CVE lookup
- ✅ HTML, JSON, and terminal report outputs
- ✅ Support for GUI-based and CLI-based applications
- ✅ Automation scripts for end-to-end analysis

## 🧰 Tech Stack

- **Languages**: Python, Bash
- **Tools**: 
  - [Syft](https://github.com/anchore/syft) – for SBOM generation
  - [Grype](https://github.com/anchore/grype) – for vulnerability scanning
  - [CycloneDX CLI](https://github.com/CycloneDX/cyclonedx-cli) – for SBOM validation
- **APIs**: NVD, Vulners
- **Platforms**: Linux (Ubuntu/Kali), Windows (via WSL), Docker

## 📁 Folder Structure

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

Install required tools:
```bash
sudo apt install jq curl docker.io -y
pip install -r requirements.txt
````

Install Syft and Grype:

```bash
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
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

* \[Your Name] – SBOM Automation & Vulnerability Analysis
* \[Other Contributors, if any]

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## 📬 Contact

For questions, feel free to raise an issue or email at: `your.email@example.com`

---

> *Secure your software, one component at a time.*

```

---

Let me know if you'd like this tailored for a private repo, include contribution guidelines, or need the matching `requirements.txt`.
```
