#Requires -Version 5.1

<#
.SYNOPSIS
    Audits SonicWALL firewall configurations and generates compliance reports.

.DESCRIPTION
    This script connects to SonicWALL firewall API to:
    - Retrieve access rules, NAT policies, and VPN configurations
    - Identify redundant or conflicting rules
    - Check against security best practices
    - Generate HTML/CSV reports for review

.PARAMETER Hostname
    The hostname or IP address of the SonicWALL device

.PARAMETER Username
    Username for SonicWALL API authentication

.PARAMETER Password
    Password for SonicWALL API authentication

.PARAMETER ReportFormat
    The format of the output report (HTML or CSV)

.EXAMPLE
    .\SonicWallFirewallAuditor.ps1 -Hostname "192.168.1.1" -Username "admin" -Password "password" -ReportFormat "HTML"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Hostname,

    [Parameter(Mandatory = $true)]
    [string]$Username,

    [Parameter(Mandatory = $true)]
    [string]$Password,

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
    ZoneRestrictions = @{
        WAN = "Restricted"
        DMZ = "Controlled"
        LAN = "Standard"
    }
}

class SonicWallAuditor {
    [string]$BaseUrl
    [string]$Token
    [hashtable]$Headers
    
    SonicWallAuditor([string]$hostname) {
        $this.BaseUrl = "https://$hostname/api/sonicos"
    }

    # Authenticate and get session token
    [bool] Authenticate([string]$username, [string]$password) {
        try {
            $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($username):$($password)"))
            $headers = @{
                "Authorization" = "Basic $auth"
                "Content-Type" = "application/json"
            }

            $response = Invoke-RestMethod -Uri "$($this.BaseUrl)/auth" -Headers $headers -Method Post
            $this.Token = $response.data.token
            $this.Headers = @{
                "Authorization" = "Bearer $($this.Token)"
                "Content-Type" = "application/json"
            }
            
            return $true
        }
        catch {
            Write-Error "Authentication failed: $_"
            return $false
        }
    }

    # Get access rules
    [array] GetAccessRules() {
        try {
            $response = Invoke-RestMethod -Uri "$($this.BaseUrl)/access-rules/ipv4" `
                -Headers $this.Headers -Method Get
            return $response.access_rules
        }
        catch {
            Write-Error "Failed to get access rules: $_"
            return @()
        }
    }

    # Get NAT policies
    [array] GetNatPolicies() {
        try {
            $response = Invoke-RestMethod -Uri "$($this.BaseUrl)/nat-policies" `
                -Headers $this.Headers -Method Get
            return $response.nat_policies
        }
        catch {
            Write-Error "Failed to get NAT policies: $_"
            return @()
        }
    }

    # Get VPN configurations
    [array] GetVpnConfig() {
        try {
            $response = Invoke-RestMethod -Uri "$($this.BaseUrl)/vpn/policies" `
                -Headers $this.Headers -Method Get
            return $response.vpn_policies
        }
        catch {
            Write-Error "Failed to get VPN configurations: $_"
            return @()
        }
    }

    # Analyze rules for security issues
    [array] AnalyzeRules([array]$rules) {
        $issues = @()
        $portMappings = @{}
        $zoneMatrix = @{}

        foreach ($rule in $rules) {
            # Check source zone restrictions
            if ($rule.from.zone -eq "WAN" -and $rule.action -eq "allow") {
                $issues += [PSCustomObject]@{
                    Type = "Security Risk"
                    Rule = $rule.name
                    Issue = "Rule allows unrestricted WAN access"
                    Severity = "High"
                }
            }

            # Check for any rule without source restriction
            if ($rule.source.address -eq "any") {
                $issues += [PSCustomObject]@{
                    Type = "Security Risk"
                    Rule = $rule.name
                    Issue = "Rule allows unrestricted source access"
                    Severity = "High"
                }
            }

            # Check for high-risk ports
            $ports = $rule.service.ports -split ","
            foreach ($port in $ports) {
                if ($port -in $script:SecurityBestPractices.HighRiskPorts) {
                    $issues += [PSCustomObject]@{
                        Type = "Security Risk"
                        Rule = $rule.name
                        Issue = "Rule allows access to high-risk port $port"
                        Severity = "High"
                    }
                }
            }

            # Check for rule conflicts
            $zoneKey = "$($rule.from.zone)->$($rule.to.zone)"
            foreach ($port in $ports) {
                $portKey = "$zoneKey`:$port"
                if ($portMappings.ContainsKey($portKey)) {
                    $issues += [PSCustomObject]@{
                        Type = "Conflict"
                        Rule = $rule.name
                        Issue = "Port $port already defined in rule '$($portMappings[$portKey])' for same zone path"
                        Severity = "Medium"
                    }
                }
                else {
                    $portMappings[$portKey] = $rule.name
                }
            }

            # Check for missing descriptions
            if ([string]::IsNullOrWhiteSpace($rule.description)) {
                $issues += [PSCustomObject]@{
                    Type = "Documentation"
                    Rule = $rule.name
                    Issue = "Missing rule description"
                    Severity = "Low"
                }
            }

            # Check for disabled rules
            if (-not $rule.enabled) {
                $issues += [PSCustomObject]@{
                    Type = "Maintenance"
                    Rule = $rule.name
                    Issue = "Disabled rule should be removed if not needed"
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
    <title>SonicWALL Firewall Audit Report</title>
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
    <h1>SonicWALL Firewall Audit Report</h1>
    <div class="summary">
        <h2>Configuration Summary</h2>
        <ul>
            <li>Total Access Rules: $($ConfigSummary.TotalRules)</li>
            <li>Total NAT Policies: $($ConfigSummary.TotalNatPolicies)</li>
            <li>VPN Configurations: $($ConfigSummary.VpnConfigs)</li>
            <li>High Severity Issues: $($Issues.Where({$_.Severity -eq 'High'}).Count)</li>
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
        Item = "Total Access Rules"
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
    $csvData += [PSCustomObject]@{
        Type = "Summary"
        Item = "High Severity Issues"
        Value = $Issues.Where({$_.Severity -eq 'High'}).Count
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
    Write-Host "Starting SonicWALL firewall audit..." -ForegroundColor Cyan
    
    # Initialize auditor and authenticate
    $auditor = [SonicWallAuditor]::new($Hostname)
    if (-not $auditor.Authenticate($Username, $Password)) {
        throw "Failed to authenticate with SonicWALL device"
    }
    
    $allIssues = @()
    $configSummary = @{
        TotalRules = 0
        TotalNatPolicies = 0
        VpnConfigs = 0
    }
    
    # Get and analyze access rules
    Write-Host "Retrieving access rules..." -ForegroundColor Yellow
    $rules = $auditor.GetAccessRules()
    $configSummary.TotalRules = $rules.Count
    $ruleIssues = $auditor.AnalyzeRules($rules)
    $allIssues += $ruleIssues
    
    # Get NAT policies
    Write-Host "Retrieving NAT policies..." -ForegroundColor Yellow
    $natPolicies = $auditor.GetNatPolicies()
    $configSummary.TotalNatPolicies = $natPolicies.Count
    
    # Get VPN configurations
    Write-Host "Retrieving VPN configurations..." -ForegroundColor Yellow
    $vpnConfigs = $auditor.GetVpnConfig()
    $configSummary.VpnConfigs = $vpnConfigs.Count
    
    # Generate report
    $reportPath = Join-Path $PSScriptRoot "SonicWallAudit_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    
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
