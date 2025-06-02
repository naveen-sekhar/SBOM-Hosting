import json
import os

def load_cyclonedx_sbom(file_path):
    with open(file_path, 'r') as f:
        data = json.load(f)
    components = data.get("components", [])
    result = {}
    for comp in components:
        raw_name = comp.get("name", "Unknown")
        clean_name = os.path.basename(raw_name)  # Extract just the file name
        result[clean_name] = comp.get("version", "Unknown")
    return result

def compare_sboms(syft_sbom, trivy_sbom):
    table = []
    all_packages = set(syft_sbom.keys()).union(set(trivy_sbom.keys()))
    for pkg in sorted(all_packages):
        syft_ver = syft_sbom.get(pkg, "Not Found")
        trivy_ver = trivy_sbom.get(pkg, "Not Found")
        if syft_ver == trivy_ver and syft_ver != "Not Found":
            note = "✅ Match"
            color = "#d4edda"
        elif trivy_ver == "Not Found":
            note = "⚠️ Missing in Trivy"
            color = "#fff3cd"
        elif syft_ver == "Not Found":
            note = "⚠️ Missing in Syft"
            color = "#fff3cd"
        else:
            note = "❌ Version Mismatch"
            color = "#f8d7da"
        table.append((pkg, syft_ver, trivy_ver, note, color))
    return table

def export_to_html(table, filename="CycloneDX_SBOM_comparison_report_GIMP.html"):
    html = """<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>CycloneDX SBOM Comparison Report</title>
    <style>
        body { font-family: Arial, sans-serif; padding: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ccc; padding: 10px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h2>CycloneDX Comparison Report</h2>
    <table>
        <tr>
            <th>Package</th>
            <th>Syft Version</th>
            <th>Trivy Version</th>
            <th>Notes</th>
        </tr>
    """
    for pkg, syft_ver, trivy_ver, note, color in table:
        html += f"""
        <tr style="background-color: {color};">
            <td>{pkg}</td>
            <td>{syft_ver}</td>
            <td>{trivy_ver}</td>
            <td>{note}</td>
        </tr>
        """
    html += """
    </table>
</body>
</html>"""
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(html)
    print(f"\n✅ HTML report saved as: {filename}")

# File paths
syft_file = "syft-cyclonedx-gimp.json"
trivy_file = "trivy-cyclonedx-gimp.json"

# Load, compare, and export
syft_data = load_cyclonedx_sbom(syft_file)
trivy_data = load_cyclonedx_sbom(trivy_file)
comparison = compare_sboms(syft_data, trivy_data)
export_to_html(comparison)
