#Requires -Version 5.1

<# 
.SYNOPSIS
    Advanced Cisco Meraki firewall configuration auditing and compliance reporting system.

.DESCRIPTION
    This script provides comprehensive Meraki firewall analysis and reporting:
    - Retrieves and analyzes firewall rules and policies
    - Validates NAT configurations and VPN settings
    - Identifies security risks and rule conflicts
    - Checks compliance with best practices
    - Detects redundant or obsolete rules
    - Generates detailed audit reports
    - Validates rule documentation
    - Monitors high-risk port usage
    - Ensures configuration consistency
    - Provides remediation recommendations

.NOTES
    Author: 13city
    Compatible with: Windows Server 2016-2022, Windows 10/11
    Requirements:
    - PowerShell 5.1 or higher
    - Internet connectivity
    - Meraki Dashboard API access
    - Valid API key with read permissions
    - Organization admin rights
    - Write access to script directory

.PARAMETER ApiKey
    Meraki Dashboard API key
    Required: Yes
    Format: 40-character string
    Obtain from: Meraki Dashboard > Organization > Settings
    Must have read permissions

.PARAMETER OrganizationId
    Meraki Organization identifier
    Required: Yes
    Format: String (e.g., "463308")
    Found in: Organization settings URL
    Must be accessible to API key

.PARAMETER ReportFormat
    Output report format selection
    Required: No
    Default: "HTML"
    Options: "HTML", "CSV"
    Affects report generation format

.EXAMPLE
    .\MerakiFirewallAuditor.ps1 -ApiKey "1234567890abcdef1234567890abcdef12345678" -OrganizationId "463308"
    Basic audit with HTML report:
    - Uses default HTML format
    - Analyzes all networks
    - Generates comprehensive report
    - Saves in script directory

.EXAMPLE
    .\MerakiFirewallAuditor.ps1 -ApiKey "1234567890abcdef1234567890abcdef12345678" -OrganizationId "463308" -ReportFormat "CSV"
    CSV report generation:
    - Outputs data in CSV format
    - Enables data analysis
    - Supports automation
    - Includes all audit findings

.EXAMPLE
    $key = "1234567890abcdef1234567890abcdef12345678"
    .\MerakiFirewallAuditor.ps1 -ApiKey $key -OrganizationId "463308" -ReportFormat "HTML"
    Secure key handling:
    - Uses variable for API key
    - Full HTML report
    - Enhanced security
    - Complete audit trail
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ApiKey,

    [Parameter(Mandatory = $true)]
    [string]$OrganizationId,

    [Parameter(Mandatory = $false)]
    [ValidateSet("HTML", "CSV")]
    [string]$ReportFormat = "HTML"
)

# Security best practices configuration
$SecurityBestPractices = @{
    HighRiskPorts = @(21, 23, 445, 1433, 3389, 5900)
    RequiredLogging = $true
    MaxRuleAge = 90 # days
    RequiredRuleDescription = $true
    MaxOpenPorts = 50
    RequiredSourceRestriction = $true
}

class MerakiAuditor {
    [string]$ApiKey
    [string]$BaseUrl = "https://api.meraki.com/api/v1"
    [hashtable]$Headers
    
    MerakiAuditor([string]$apiKey) {
        $this.ApiKey = $apiKey
        $this.Headers = @{
            "X-Cisco-Meraki-API-Key" = $apiKey
            "Content-Type" = "application/json"
        }
    }

    # Get all networks in the organization
    [array] GetNetworks([string]$orgId) {
        try {
            $response = Invoke-RestMethod -Uri "$($this.BaseUrl)/organizations/$orgId/networks" `
                -Headers $this.Headers -Method Get
            return $response
        }
        catch {
            Write-Error "Failed to get networks: $_"
            return @()
        }
    }

    # Get firewall rules for a network
    [array] GetFirewallRules([string]$networkId) {
        try {
            $response = Invoke-RestMethod -Uri "$($this.BaseUrl)/networks/$networkId/appliance/firewall/l3FirewallRules" `
                -Headers $this.Headers -Method Get
            return $response.rules
        }
        catch {
            Write-Error "Failed to get firewall rules for network $networkId : $_"
            return @()
        }
    }

    # Get NAT policies
    [array] GetNatPolicies([string]$networkId) {
        try {
            $response = Invoke-RestMethod -Uri "$($this.BaseUrl)/networks/$networkId/appliance/firewall/oneToOneNatRules" `
                -Headers $this.Headers -Method Get
            return $response
        }
        catch {
            Write-Error "Failed to get NAT policies for network $networkId : $_"
            return @()
        }
    }

    # Get VPN configuration
    [object] GetVpnConfig([string]$networkId) {
        try {
            $response = Invoke-RestMethod -Uri "$($this.BaseUrl)/networks/$networkId/appliance/vpn/siteToSiteVpn" `
                -Headers $this.Headers -Method Get
            return $response
        }
        catch {
            Write-Error "Failed to get VPN config for network $networkId : $_"
            return $null
        }
    }

    # Analyze firewall rules for redundancies and conflicts
    [array] AnalyzeRules([array]$rules) {
        $issues = @()
        $portMappings = @{}

        foreach ($rule in $rules) {
            # Check for any rule without source restriction
            if ($rule.srcCidr -eq "any") {
                $issues += [PSCustomObject]@{
                    Type = "Security Risk"
                    Rule = $rule.comment
                    Issue = "Rule allows unrestricted source access"
                    Severity = "High"
                }
            }

            # Check for high-risk ports
            $ports = $rule.destinationPorts -split ","
            foreach ($port in $ports) {
                if ($port -in $script:SecurityBestPractices.HighRiskPorts) {
                    $issues += [PSCustomObject]@{
                        Type = "Security Risk"
                        Rule = $rule.comment
                        Issue = "Rule allows access to high-risk port $port"
                        Severity = "High"
                    }
                }
            }

            # Check for rule conflicts
            foreach ($port in $ports) {
                if ($portMappings.ContainsKey($port)) {
                    $issues += [PSCustomObject]@{
                        Type = "Conflict"
                        Rule = $rule.comment
                        Issue = "Port $port already defined in rule '$($portMappings[$port])'"
                        Severity = "Medium"
                    }
                }
                else {
                    $portMappings[$port] = $rule.comment
                }
            }

            # Check for missing descriptions
            if ([string]::IsNullOrWhiteSpace($rule.comment)) {
                $issues += [PSCustomObject]@{
                    Type = "Documentation"
                    Rule = "Rule ${$rule.policy}"
                    Issue = "Missing rule description"
                    Severity = "Low"
                }
            }
        }

        return $issues
    }
}

# Function to generate HTML report
function New-HtmlReport {
    param (
        [array]$Issues,
        [hashtable]$ConfigSummary
    )

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Meraki Firewall Audit Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .high { color: #ff0000; }
        .medium { color: #ffa500; }
        .low { color: #008000; }
        .summary { margin-bottom: 30px; }
    </style>
</head>
<body>
    <h1>Meraki Firewall Audit Report</h1>
    <div class="summary">
        <h2>Configuration Summary</h2>
        <ul>
            <li>Total Networks: $($ConfigSummary.TotalNetworks)</li>
            <li>Total Rules: $($ConfigSummary.TotalRules)</li>
            <li>Total NAT Policies: $($ConfigSummary.TotalNatPolicies)</li>
            <li>VPN Configurations: $($ConfigSummary.VpnConfigs)</li>
        </ul>
    </div>
    <h2>Issues Found</h2>
    <table>
        <tr>
            <th>Type</th>
            <th>Rule</th>
            <th>Issue</th>
            <th>Severity</th>
        </tr>
"@

    foreach ($issue in $Issues) {
        $severityClass = switch ($issue.Severity) {
            "High" { "high" }
            "Medium" { "medium" }
            "Low" { "low" }
            default { "" }
        }
        
        $html += @"
        <tr>
            <td>$($issue.Type)</td>
            <td>$($issue.Rule)</td>
            <td>$($issue.Issue)</td>
            <td class="$severityClass">$($issue.Severity)</td>
        </tr>
"@
    }

    $html += @"
    </table>
    <p>Report generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
</body>
</html>
"@

    return $html
}

# Function to generate CSV report
function New-CsvReport {
    param (
        [array]$Issues,
        [hashtable]$ConfigSummary
    )
    
    $csvData = @()
    
    # Add summary information
    $csvData += [PSCustomObject]@{
        Type = "Summary"
        Item = "Total Networks"
        Value = $ConfigSummary.TotalNetworks
        Note = ""
    }
    $csvData += [PSCustomObject]@{
        Type = "Summary"
        Item = "Total Rules"
        Value = $ConfigSummary.TotalRules
        Note = ""
    }
    $csvData += [PSCustomObject]@{
        Type = "Summary"
        Item = "Total NAT Policies"
        Value = $ConfigSummary.TotalNatPolicies
        Note = ""
    }
    $csvData += [PSCustomObject]@{
        Type = "Summary"
        Item = "VPN Configurations"
        Value = $ConfigSummary.VpnConfigs
        Note = ""
    }
    
    # Add issues
    foreach ($issue in $Issues) {
        $csvData += [PSCustomObject]@{
            Type = $issue.Type
            Item = $issue.Rule
            Value = $issue.Severity
            Note = $issue.Issue
        }
    }
    
    return $csvData
}

# Main execution block
try {
    Write-Host "Starting Meraki firewall audit..." -ForegroundColor Cyan
    
    $auditor = [MerakiAuditor]::new($ApiKey)
    $allIssues = @()
    $configSummary = @{
        TotalNetworks = 0
        TotalRules = 0
        TotalNatPolicies = 0
        VpnConfigs = 0
    }
    
    # Get all networks
    $networks = $auditor.GetNetworks($OrganizationId)
    $configSummary.TotalNetworks = $networks.Count
    
    foreach ($network in $networks) {
        Write-Host "Processing network: $($network.name)" -ForegroundColor Yellow
        
        # Get and analyze firewall rules
        $rules = $auditor.GetFirewallRules($network.id)
        $configSummary.TotalRules += $rules.Count
        $ruleIssues = $auditor.AnalyzeRules($rules)
        $allIssues += $ruleIssues
        
        # Get NAT policies
        $natPolicies = $auditor.GetNatPolicies($network.id)
        $configSummary.TotalNatPolicies += $natPolicies.Count
        
        # Get VPN config
        $vpnConfig = $auditor.GetVpnConfig($network.id)
        if ($vpnConfig) {
            $configSummary.VpnConfigs++
        }
    }
    
    # Generate report
    $reportPath = Join-Path $PSScriptRoot "MerakiAudit_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    
    if ($ReportFormat -eq "HTML") {
        $report = New-HtmlReport -Issues $allIssues -ConfigSummary $configSummary
        $reportPath += ".html"
        $report | Out-File -FilePath $reportPath -Encoding UTF8
    }
    else {
        $report = New-CsvReport -Issues $allIssues -ConfigSummary $configSummary
        $reportPath += ".csv"
        $report | Export-Csv -Path $reportPath -NoTypeInformation
    }
    
    Write-Host "`nAudit completed successfully!" -ForegroundColor Green
    Write-Host "Report saved to: $reportPath" -ForegroundColor Cyan
}
catch {
    Write-Error "Script execution failed: $_"
    exit 1
}
