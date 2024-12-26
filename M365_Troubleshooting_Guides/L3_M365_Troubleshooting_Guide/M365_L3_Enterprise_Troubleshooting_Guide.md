# Microsoft 365 L3 Enterprise Troubleshooting Guide
## Version 1.0 - Enterprise Support Level

## Table of Contents
1. [Enterprise Architecture Troubleshooting](#enterprise-architecture-troubleshooting)
2. [Complex Hybrid Scenarios](#complex-hybrid-scenarios)
3. [Advanced Identity Federation](#advanced-identity-federation)
4. [Cross-Forest Exchange Issues](#cross-forest-exchange-issues)
5. [Enterprise SharePoint Architecture](#enterprise-sharepoint-architecture)
6. [Teams Enterprise Voice](#teams-enterprise-voice)
7. [Advanced Security Incidents](#advanced-security-incidents)
8. [Performance at Scale](#performance-at-scale)
9. [Custom Solutions](#custom-solutions)
10. [Disaster Recovery](#disaster-recovery)

---

## Enterprise Architecture Troubleshooting

### Complex Network Topology Issues

#### Problem: Multi-Region Performance Degradation with ExpressRoute
**Root Cause Analysis:**
1. BGP route analysis:
```powershell
# Get detailed BGP routing table
$routes = Get-AzExpressRouteCircuitRouteTable -ResourceGroupName "ERResourceGroup" `
    -ExpressRouteCircuitName "MainCircuit" -PeeringType AzurePrivatePeering
$routes | Where-Object { $_.LocalAddress -like "10.*" } | Select-Object Network, NextHop, Path
```

2. Network path analysis:
```powershell
# Custom function for advanced path analysis
function Test-M365NetworkPath {
    param(
        [string]$TargetEndpoint,
        [string]$SourceRegion
    )
    
    $results = @()
    foreach($hop in (Test-NetConnection -TraceRoute $TargetEndpoint).TraceRoute) {
        $results += [PSCustomObject]@{
            Hop = $hop
            Latency = (Test-Connection $hop -Count 1).ResponseTime
            ASPath = (Get-BGPPath $hop).ASPath
        }
    }
    return $results
}
```

**Advanced Solutions:**

1. Implement Regional Traffic Management:
```powershell
# Configure regional traffic policies
$policy = @{
    Name = "RegionalTrafficPolicy"
    Priority = 1
    Rules = @(
        @{
            Region = "WestEurope"
            PreferredCircuit = "WE-Circuit"
            Backup = "NE-Circuit"
        },
        @{
            Region = "NorthEurope"
            PreferredCircuit = "NE-Circuit"
            Backup = "WE-Circuit"
        }
    )
}

Set-AzExpressRouteTrafficPolicy @policy
```

2. Advanced Route Optimization:
```powershell
# Implement custom route optimization
$optimizedRoutes = @{
    "10.0.0.0/16" = @{
        NextHop = "192.168.1.1"
        Weight = 100
        PreferredPath = "Direct"
    }
    "172.16.0.0/12" = @{
        NextHop = "192.168.1.2"
        Weight = 200
        PreferredPath = "Backup"
    }
}

foreach($route in $optimizedRoutes.Keys) {
    Add-AzExpressRouteCircuitRouteConfig -ResourceGroupName "ERResourceGroup" `
        -CircuitName "MainCircuit" `
        -PeeringType AzurePrivatePeering `
        -AddressPrefix $route `
        -NextHopIP $optimizedRoutes[$route].NextHop `
        -Weight $optimizedRoutes[$route].Weight
}
```

*Why this works:* Implements intelligent route distribution across multiple ExpressRoute circuits while maintaining optimal path selection based on network conditions and regional preferences.

### Multi-Forest Authentication Chain Issues

#### Problem: Token Acquisition Failures in Complex Forest Trusts
**Advanced Diagnosis:**
1. Analyze authentication paths:
```powershell
# Custom function to trace authentication path
function Trace-AuthenticationPath {
    param(
        [string]$UserPrincipal,
        [string]$TargetResource
    )
    
    $authPath = @()
    $currentDomain = (Get-ADUser $UserPrincipal).Domain
    
    while($currentDomain) {
        $trustInfo = Get-ADTrust -Filter {Target -eq $currentDomain}
        $authPath += [PSCustomObject]@{
            Domain = $currentDomain
            TrustType = $trustInfo.TrustType
            TrustDirection = $trustInfo.TrustDirection
            TrustAttributes = $trustInfo.TrustAttributes
        }
        $currentDomain = $trustInfo.TargetName
    }
    
    return $authPath
}
```

2. Token lifetime analysis:
```powershell
# Analyze token lifetime across trust boundaries
function Analyze-TokenLifetime {
    param(
        [string]$UserPrincipal
    )
    
    $tokenInfo = @()
    $domains = (Get-ADForest).Domains
    
    foreach($domain in $domains) {
        $tokenInfo += [PSCustomObject]@{
            Domain = $domain
            TokenLifetime = (Get-ADDomainController -Domain $domain).TokenLifetime
            KerberosPolicy = Get-ADDomainController -Domain $domain | 
                Select-Object MaxTicketAge, MaxServiceAge, MaxClockSkew
        }
    }
    
    return $tokenInfo
}
```

**Advanced Solutions:**

1. Implement Cross-Forest Token Optimization:
```powershell
# Configure optimal token settings across forests
$forests = Get-ADForest
foreach($forest in $forests.Domains) {
    Set-ADDomainController -Identity $forest -TokenLifetime 600
    Set-ADDomainController -Identity $forest -MaxTicketAge 10
    
    # Configure selective authentication
    $trustSettings = @{
        SourceDomain = $forest
        TargetDomain = "target.forest.com"
        TrustType = "Forest"
        SelectiveAuthentication = $true
        FilteredAttributeSet = @("mail", "proxyAddresses", "userPrincipalName")
    }
    
    Set-ADTrust @trustSettings
}
```

2. Implement Advanced Trust Monitoring:
```powershell
# Create trust monitoring solution
$monitoringConfig = @{
    IntervalMinutes = 5
    Targets = @(
        "forest1.com",
        "forest2.com"
    )
    Thresholds = @{
        TokenAcquisitionTime = 2000  # milliseconds
        TrustValidationTime = 1000   # milliseconds
        MaxClockSkew = 300           # seconds
    }
}

# Monitor trust health
function Monitor-ForestTrustHealth {
    param($config)
    
    while($true) {
        foreach($target in $config.Targets) {
            $health = Test-ForestTrust -Target $target
            if($health.TokenAcquisitionTime -gt $config.Thresholds.TokenAcquisitionTime) {
                Write-Warning "Token acquisition time exceeded threshold for $target"
                Invoke-TrustRepair -Target $target
            }
        }
        Start-Sleep -Minutes $config.IntervalMinutes
    }
}
```

*Why this works:* Implements comprehensive trust monitoring and automatic remediation while optimizing token lifetimes and trust relationships for complex forest topologies.

## Cross-Forest Exchange Issues

### Complex Mail Flow Problems

#### Problem: Mail Loop Detection in Multi-Forest Exchange Environment
**Advanced Diagnosis:**
1. Analyze transport servers:
```powershell
# Custom function to analyze mail flow across forests
function Analyze-CrossForestMailFlow {
    param(
        [string]$MessageID,
        [datetime]$StartTime,
        [datetime]$EndTime
    )
    
    $forests = Get-ADForest | Select-Object -ExpandProperty Domains
    $mailFlowData = @()
    
    foreach($forest in $forests) {
        $transportLogs = Get-TransportService -Identity $forest |
            Get-MessageTrackingLog -MessageId $MessageID -Start $StartTime -End $EndTime
        
        $mailFlowData += $transportLogs | Select-Object @{
            Name = "Forest"; Expression = {$forest}
        }, Timestamp, EventId, Source, Recipients, RecipientStatus
    }
    
    return $mailFlowData | Sort-Object Timestamp
}
```

2. Connector configuration analysis:
```powershell
# Analyze send connectors across forests
function Analyze-SendConnectors {
    $forests = Get-ADForest | Select-Object -ExpandProperty Domains
    $connectorData = @()
    
    foreach($forest in $forests) {
        $connectors = Get-SendConnector -Forest $forest
        foreach($connector in $connectors) {
            $connectorData += [PSCustomObject]@{
                Forest = $forest
                ConnectorName = $connector.Name
                AddressSpaces = $connector.AddressSpaces
                SourceTransportServers = $connector.SourceTransportServers
                MaxMessageSize = $connector.MaxMessageSize
                Enabled = $connector.Enabled
            }
        }
    }
    
    return $connectorData
}
```

**Advanced Solutions:**

1. Implement Advanced Mail Flow Controls:
```powershell
# Configure advanced mail flow controls
$mailFlowConfig = @{
    MaxHops = 15
    MaxRecipients = 1000
    MaxMessageSize = 150MB
    EnableLoopDetection = $true
    LoopDetectionHeaders = @(
        "X-MS-Exchange-Forest-Path",
        "X-MS-Exchange-Organization-Path"
    )
}

# Apply configuration to all transport servers
Get-TransportService | ForEach-Object {
    Set-TransportService -Identity $_.Identity `
        -MaxHopCount $mailFlowConfig.MaxHops `
        -MaxRecipients $mailFlowConfig.MaxRecipients `
        -MaxMessageSize $mailFlowConfig.MaxMessageSize
        
    # Custom loop detection
    Add-TransportRule -Name "Cross-Forest-Loop-Detection" `
        -Priority 0 `
        -HeaderMatchesMessageHeader "X-MS-Exchange-Forest-Path" `
        -HeaderMatchesPatterns ".*$($_.Forest).*" `
        -RejectMessageReasonText "Potential mail loop detected"
}
```

2. Implement Cross-Forest Mail Flow Monitoring:
```powershell
# Create mail flow monitoring solution
$monitoringConfig = @{
    IntervalMinutes = 5
    Thresholds = @{
        QueueLength = 1000
        DeliveryLatency = 300  # seconds
        LoopDetectionCount = 5
    }
    AlertRecipients = @("admin@contoso.com")
}

function Monitor-CrossForestMailFlow {
    param($config)
    
    while($true) {
        $forests = Get-ADForest | Select-Object -ExpandProperty Domains
        foreach($forest in $forests) {
            $queues = Get-Queue -Forest $forest
            $highQueues = $queues | Where-Object {
                $_.MessageCount -gt $config.Thresholds.QueueLength
            }
            
            if($highQueues) {
                $alert = @{
                    To = $config.AlertRecipients
                    Subject = "High Queue Alert - $forest"
                    Body = "Queue length threshold exceeded:`n" +
                           ($highQueues | Format-Table | Out-String)
                }
                Send-MailMessage @alert
            }
        }
        Start-Sleep -Minutes $config.IntervalMinutes
    }
}
```

*Why this works:* Implements comprehensive mail flow monitoring and control mechanisms while preventing mail loops through advanced header tracking and forest path detection.

## Enterprise SharePoint Architecture

### Complex Content Migration Issues

#### Problem: Large-Scale Content Migration Failures with Custom Solutions
**Advanced Diagnosis:**
1. Analyze migration bottlenecks:
```powershell
# Custom function to analyze migration performance
function Analyze-MigrationPerformance {
    param(
        [string]$JobID,
        [datetime]$StartTime,
        [datetime]$EndTime
    )
    
    $metrics = @()
    $logs = Get-SPOMigrationJobStatus -JobId $JobID
    
    foreach($log in $logs) {
        $metrics += [PSCustomObject]@{
            Timestamp = $log.Timestamp
            ItemsProcessed = $log.ItemsProcessed
            BytesProcessed = $log.BytesProcessed
            FailedItems = $log.FailedItems
            Throughput = $log.BytesProcessed / 
                        ($log.Timestamp - $StartTime).TotalSeconds
        }
    }
    
    return $metrics
}
```

2. Content database analysis:
```powershell
# Analyze content database health
function Analyze-ContentDB {
    param(
        [string]$SiteUrl
    )
    
    $dbHealth = @()
    $site = Get-SPOSite $SiteUrl -Detailed
    
    $dbHealth += [PSCustomObject]@{
        DatabaseName = $site.ContentDatabase
        Size = $site.StorageUsageCurrent
        QuotaWarning = $site.StorageQuotaWarning
        LockIssue = $site.LockIssue
        CompatibilityLevel = $site.CompatibilityLevel
    }
    
    return $dbHealth
}
```

**Advanced Solutions:**

1. Implement Intelligent Migration Throttling:
```powershell
# Configure adaptive migration throttling
$throttlingConfig = @{
    MaxConcurrentMigrations = 5
    MaxItemsPerBatch = 1000
    MaxBytesPerBatch = 100MB
    RetryCount = 3
    RetryWaitTime = 300  # seconds
    TimeWindow = @{
        Start = "18:00"
        End = "06:00"
    }
}

function Start-ThrottledMigration {
    param(
        $Config,
        $Items
    )
    
    $batches = Split-MigrationBatches -Items $Items `
        -MaxItems $Config.MaxItemsPerBatch `
        -MaxBytes $Config.MaxBytesPerBatch
        
    foreach($batch in $batches) {
        $currentTime = Get-Date
        if($currentTime.TimeOfDay -ge $Config.TimeWindow.Start -and 
           $currentTime.TimeOfDay -le $Config.TimeWindow.End) {
            
            $activeMigrations = Get-SPOMigrationJob | 
                Where-Object {$_.State -eq "InProgress"}
                
            if($activeMigrations.Count -lt $Config.MaxConcurrentMigrations) {
                Start-SPOMigrationJob -Batch $batch
            }
        }
    }
}
```

2. Implement Advanced Error Handling:
```powershell
# Create comprehensive error handling system
$errorHandlers = @{
    "ItemNotFound" = {
        param($item)
        Write-Log "Item not found: $($item.Path)"
        Add-ToRetryQueue $item
    }
    "AccessDenied" = {
        param($item)
        $permissions = Get-ItemPermissions $item
        if(-not $permissions) {
            Grant-MinimumPermissions $item
            Add-ToRetryQueue $item
        }
    }
    "QuotaExceeded" = {
        param($site)
        $newQuota = $site.StorageQuota * 1.2
        Set-SPOSite -Identity $site.Url -StorageQuota $newQuota
        Resume-MigrationJob -Identity $site.MigrationJobId
    }
}

function Handle-MigrationError {
    param(
        $Error,
        $Context
    )
    
    $handler = $errorHandlers[$Error.Category]
    if($handler) {
        & $handler $Context
        return $true
    }
    
    # Default error handling
    Write-Log "Unhandled error: $($Error.Message)"
    return $false
}
```

*Why this works:* Implements intelligent throttling and comprehensive error handling while maintaining data integrity and optimizing migration performance.

## Teams Enterprise Voice

### Complex Call Queue Routing Issues

#### Problem: Call Routing Failures in Multi-Site Deployments
**Advanced Diagnosis:**
1. Analyze call routing patterns:
```powershell
# Custom function to analyze call routing
function Analyze-CallRouting {
    param(
        [string]$CallQueueId,
        [datetime]$StartTime,
        [datetime]$EndTime
    )
    
    $routingData = @()
    $calls = Get-CsCallQueueCalls -Identity $CallQueueId `
        -StartTime $StartTime -EndTime $EndTime
        
    foreach($call in $calls) {
        $routingData += [PSCustomObject]@{
            CallId = $call.CallId
            StartTime = $call.StartTime
            Duration = $call.Duration
            RoutingPath = $call.RoutingPath
            AgentResponses = $call.AgentResponses
            Outcome = $call.Outcome
            WaitTime = $call.WaitTime
        }
    }
    
    return $routingData
}
```

2. SBC configuration analysis:
```powershell
# Analyze SBC health and configuration
function Analyze-SBCHealth {
    $sbcs = Get-CsOnlinePSTNGateway
    $sbcHealth = @()
    
    foreach($sbc in $sbcs) {
        $health = Test-CsOnlinePSTNOutboundCall -Identity $sbc.Identity
        $sbcHealth += [PSCustomObject]@{
            Identity = $sbc.Identity
            MediaRelayRoutingLocationOverride = $sbc.MediaRelayRoutingLocationOverride
            FailoverTimeSeconds = $sbc.FailoverTimeSeconds
            ForwardCallHistory = $sbc.ForwardCallHistory
            ForwardPai = $sbc.ForwardPai
            SendSipOptions = $sbc.SendSipOptions
            MaxConcurrentSessions = $sbc.MaxConcurrentSessions
            Enabled = $sbc.Enabled
            TestResult = $health.Success
        }
    }
    
    return $sbcHealth
}
```

**Advanced Solutions:**

1. Implement Advanced Call Routing Logic:
```powershell
# Configure advanced call routing
$routingConfig = @{
    PrimaryQueue = "Sales-Primary"
    BackupQueue = "Sales-Backup"
    OverflowQueue = "Sales-Overflow"
    Thresholds = @{
        WaitTime = 120  # seconds
        QueueLength = 10
        AgentAvailability = 0.2  # 20% minimum available agents
    }
    RoutingRules = @(
        @{
            Condition = "BusinessHours"
            Action = "PrimaryQueue"
        },
        @{
            Condition = "AfterHours"
            Action = "BackupQueue"
        },
        @{
            Condition = "Emergency"
            Action = "OverflowQueue"
        }
    )
}

# Apply routing configuration
function Set-AdvancedCallRouting {
    param($config)
    
    foreach($rule in $config.RoutingRules) {
        New-CsTeamsCallRoutingPolicy -Identity $rule.Condition `
            -AllowPSTNReRouting $true `
            -AllowVoicemail $true
            
        Set-CsTeamsCallQueue -Identity $config[$rule.Action] `
            -RoutingMethod RoundRobin `
            -AllowOptOut $true `
            -ConferenceMode $true
    }
}
```

2. Implement Real-Time Monitoring:
```powershell
# Create call quality monitoring solution
$monitoringConfig = @{
    IntervalSeconds = 30
    Metrics = @(
        "ActiveCalls",
        "WaitingCalls",
        "AbandonedCalls",
        "AverageWaitTime",
        "ServiceLevel"
    )
    Thresholds = @{
        MaxWaitTime = 180  # seconds
        MaxQueueLength = 15
        MinServiceLevel = 0.8  # 80%
    }
}

function Monitor-CallQueueHealth {
    param($config)
    
    while($true) {
        $queues = Get-CsCallQueue
        foreach($queue in $queues) {
            $metrics = Get-CsCallQueueStatistics -Identity $queue.Identity
            
            if($metrics.AverageWaitTime -gt $config.Thresholds.MaxWaitTime) {
                Invoke-OverflowRouting -Queue $queue
            }
            
            if($metrics.ServiceLevel -lt $config.Thresholds.MinServiceLevel) {
                Add-EmergencyAgents -Queue $queue
            }
        }
        
        Start-Sleep -Seconds $config.IntervalSeconds
    }
}
```

*Why this works:* Implements intelligent call routing with real-time monitoring and automatic remediation while maintaining service levels and call quality.

## Advanced Security Incidents

### Complex Security Breach Investigation

#### Problem: Advanced Persistent Threat (APT) Activity Detection
**Advanced Diagnosis:**
1. Analyze authentication patterns:
```powershell
# Custom function to detect anomalous authentication
function Analyze-AuthenticationPatterns {
    param(
        [datetime]$StartTime,
        [datetime]$EndTime
    )
    
    $authData = @()
    $logs = Get-AzureADAuditSignInLogs -StartTime $StartTime -EndTime $EndTime
    
    foreach($log in $logs) {
        $authData += [PSCustomObject]@{
            Timestamp = $log.CreatedDateTime
            User = $log.UserPrincipalName
            Location = $log.Location
            IPAddress = $log.IpAddress
            DeviceDetail = $log.DeviceDetail
            RiskLevel = $log.RiskLevel
            RiskState = $log.RiskState
            RiskDetail = $log.RiskDetail
            ConditionalAccessStatus = $log.ConditionalAccessStatus
        }
    }
    
    return $authData
}
```

2. Analyze data exfiltration patterns:
```powershell
# Analyze potential data exfiltration
function Analyze-DataExfiltration {
    param(
        [datetime]$StartTime,
        [datetime]$EndTime
    )
    
    $activities = @()
    $logs = Get-AuditLog -StartTime $StartTime -EndTime $EndTime
    
    foreach($log in $logs) {
        if($log.Operations -match "FileDownloaded|FileCopied|FileShared") {
            $activities += [PSCustomObject]@{
                Timestamp = $log.CreationTime
                User = $log.UserIds
                Operation = $log.Operations
                ItemType = $log.ItemType
                SourceFileName = $log.SourceFileName
                SourceRelativeUrl = $log.SourceRelativeUrl
                ClientIP = $log.ClientIP
                UserAgent = $log.UserAgent
            }
        }
    }
    
    return $activities
}
```

**Advanced Solutions:**

1. Implement Advanced Threat Detection:
```powershell
# Configure advanced threat detection
$threatConfig = @{
    AuthenticationThresholds = @{
        MaxFailedAttempts = 5
        TimeWindow = 300  # seconds
        UnknownLocationLogins = 3
        RiskThreshold = "Medium"
    }
    DataExfiltrationThresholds = @{
        MaxDownloads = 100
        TimeWindow = 3600  # seconds
        SensitiveDataTypes = @(
            "CreditCardNumber",
            "SSN",
            "BankAccountNumber"
        )
    }
}

function Start-ThreatDetection {
    param($config)
    
    # Configure authentication monitoring
    New-AzureADRiskDetectionPolicy -Name "Advanced-Auth-Policy" `
        -RiskLevel $config.AuthenticationThresholds.RiskThreshold `
        -NotifyUsers $true `
        -BlockAccess $true
        
    # Configure DLP monitoring
    $dlpRule = New-DlpComplianceRule -Name "Data-Exfiltration-Rule" `
        -Policy "DLP-Policy" `
        -ContentContainsSensitiveInformation $config.DataExfiltrationThresholds.SensitiveDataTypes `
        -AccessScope NotInOrganization `
        -BlockAccess $true
        
    # Configure adaptive response
    New-AzureADConditionalAccessPolicy -Name "Adaptive-Response" `
        -State Enabled `
        -Conditions @{
            SignInRiskLevels = @("High")
            UserRiskLevels = @("High")
        } `
        -GrantControls @{
            RequireAuthentication = $true
            RequireMFA = $true
        }
}
```

2. Implement Incident Response Automation:
```powershell
# Create incident response automation
$responseConfig = @{
    IsolationCriteria = @{
        RiskLevel = "High"
        FailedAuthAttempts = 10
        UnusualActivity = $true
    }
    NotificationRecipients = @(
        "security@contoso.com",
        "incident-response@contoso.com"
    )
    AutomatedActions = @{
        BlockUser = $true
        RevokeTokens = $true
        EnableMFA = $true
        IsolateDevice = $true
    }
}

function Start-IncidentResponse {
    param(
        $Incident,
        $Config
    )
    
    if(Test-IncidentSeverity $Incident $Config.IsolationCriteria) {
        # Isolate affected resources
        $affectedUser = $Incident.AffectedEntity
        
        # Block user access
        if($Config.AutomatedActions.BlockUser) {
            Set-AzureADUser -ObjectId $affectedUser.ObjectId -AccountEnabled $false
        }
        
        # Revoke active sessions
        if($Config.AutomatedActions.RevokeTokens) {
            Revoke-AzureADUserAllRefreshToken -ObjectId $affectedUser.ObjectId
        }
        
        # Enable MFA
        if($Config.AutomatedActions.EnableMFA) {
            $mfaRequirement = @{
                State = "Enabled"
                RememberDevice = $false
            }
            Set-MsolUser -UserPrincipalName $affectedUser.UserPrincipalName `
                -StrongAuthenticationRequirements $mfaRequirement
        }
        
        # Notify security team
        $notification = @{
            To = $Config.NotificationRecipients
            Subject = "Security Incident - High Severity"
            Body = "Incident Details:`n" +
                   ($Incident | ConvertTo-Json)
        }
        Send-MailMessage @notification
    }
}
```

*Why this works:* Implements comprehensive threat detection and automated incident response while maintaining security posture and minimizing impact.

## Performance at Scale

### Large-Scale Performance Degradation

#### Problem: System-Wide Performance Issues in Large Tenant
**Advanced Diagnosis:**
1. Analyze system-wide metrics:
```powershell
# Custom function to analyze tenant-wide performance
function Analyze-TenantPerformance {
    param(
        [datetime]$StartTime,
        [datetime]$EndTime
    )
    
    $metrics = @()
    $services = @(
        "Exchange",
        "SharePoint",
        "Teams",
        "OneDrive"
    )
    
    foreach($service in $services) {
        $serviceMetrics = Get-ServiceHealth -Service $service `
            -StartTime $StartTime -EndTime $EndTime
            
        $metrics += [PSCustomObject]@{
            Service = $service
            ResponseTime = $serviceMetrics.ResponseTime
            Availability = $serviceMetrics.Availability
            ErrorRate = $serviceMetrics.ErrorRate
            Throughput = $serviceMetrics.Throughput
            ActiveUsers = $serviceMetrics.ActiveUsers
        }
    }
    
    return $metrics
}
```

2. Resource utilization analysis:
```powershell
# Analyze resource utilization across services
function Analyze-ResourceUtilization {
    $resources = @()
    $quotas = Get-Tenant | Select-Object ResourceQuotas
    
    foreach($quota in $quotas.ResourceQuotas) {
        $usage = Get-TenantResourceUsage -ResourceType $quota.ResourceType
        
        $resources += [PSCustomObject]@{
            ResourceType = $quota.ResourceType
            Allocated = $quota.Allocated
            Used = $usage.Used
            Available = $quota.Allocated - $usage.Used
            UtilizationPercentage = ($usage.Used / $quota.Allocated) * 100
        }
    }
    
    return $resources
}
```

**Advanced Solutions:**

1. Implement Resource Optimization:
```powershell
# Configure resource optimization
$optimizationConfig = @{
    Thresholds = @{
        CPUUtilization = 80
        MemoryUtilization = 85
        StorageUtilization = 90
        NetworkUtilization = 75
    }
    OptimizationRules = @(
        @{
            Condition = "HighCPU"
            Action = "ScaleOut"
            Parameters = @{
                ScaleFactor = 1.5
                CooldownPeriod = 300  # seconds
            }
        },
        @{
            Condition = "HighMemory"
            Action = "OptimizeCache"
            Parameters = @{
                CacheReduction = 0.2
                MinimumCache = "1GB"
            }
        }
    )
}

function Start-ResourceOptimization {
    param($config)
    
    foreach($rule in $config.OptimizationRules) {
        switch($rule.Condition) {
            "HighCPU" {
                $currentLoad = Get-CPUUtilization
                if($currentLoad -gt $config.Thresholds.CPUUtilization) {
                    # Scale out resources
                    $newCapacity = $currentCapacity * $rule.Parameters.ScaleFactor
                    Set-TenantCapacity -Type "Compute" -Value $newCapacity
                }
            }
            "HighMemory" {
                $currentMemory = Get-MemoryUtilization
                if($currentMemory -gt $config.Thresholds.MemoryUtilization) {
                    # Optimize memory usage
                    Optimize-TenantMemory -ReductionFactor $rule.Parameters.CacheReduction `
                        -MinimumCache $rule.Parameters.MinimumCache
                }
            }
        }
    }
}
```

2. Implement Performance Monitoring and Alerting:
```powershell
# Create comprehensive monitoring solution
$monitoringConfig = @{
    IntervalMinutes = 5
    MetricsToMonitor = @(
        "ResponseTime",
        "Throughput",
        "ErrorRate",
        "ActiveConnections",
        "QueueLength"
    )
    Thresholds = @{
        ResponseTime = 2000  # milliseconds
        ErrorRate = 0.05     # 5%
        QueueLength = 1000
    }
    AlertRecipients = @(
        "operations@contoso.com",
        "monitoring@contoso.com"
    )
}

function Start-PerformanceMonitoring {
    param($config)
    
    while($true) {
        $metrics = Get-TenantPerformanceMetrics
        
        foreach($metric in $metrics) {
            if($metric.ResponseTime -gt $config.Thresholds.ResponseTime) {
                $alert = @{
                    To = $config.AlertRecipients
                    Subject = "High Response Time Alert"
                    Body = "Response time threshold exceeded for $($metric.Service)`n" +
                           "Current: $($metric.ResponseTime)ms`n" +
                           "Threshold: $($config.Thresholds.ResponseTime)ms"
                }
                Send-MailMessage @alert
            }
            
            if($metric.ErrorRate -gt $config.Thresholds.ErrorRate) {
                Start-ErrorInvestigation -Service $metric.Service
            }
        }
        
        Start-Sleep -Minutes $config.IntervalMinutes
    }
}
```

*Why this works:* Implements proactive performance monitoring with automated alerts and remediation while maintaining service health across the tenant.

## Custom Solutions

### Complex Integration Issues

#### Problem: Custom Application Integration Failures
**Advanced Diagnosis:**
1. Analyze application dependencies:
```powershell
# Custom function to analyze app dependencies
function Analyze-AppDependencies {
    param(
        [string]$AppId,
        [datetime]$StartTime,
        [datetime]$EndTime
    )
    
    $dependencies = @()
    $logs = Get-AzureADApplicationLog -AppId $AppId -StartTime $StartTime -EndTime $EndTime
    
    foreach($log in $logs) {
        $dependencies += [PSCustomObject]@{
            Timestamp = $log.Timestamp
            DependencyType = $log.DependencyType
            TargetService = $log.TargetService
            ResponseTime = $log.ResponseTime
            StatusCode = $log.StatusCode
            ErrorDetails = $log.ErrorDetails
        }
    }
    
    return $dependencies | Group-Object DependencyType | 
        Select-Object Name, Count, @{
            Name = 'AvgResponseTime'
            Expression = {($_.Group | Measure-Object ResponseTime -Average).Average}
        }
}
```

2. Permission analysis:
```powershell
# Analyze application permissions
function Analyze-AppPermissions {
    param(
        [string]$AppId
    )
    
    $app = Get-AzureADApplication -ObjectId $AppId
    $servicePrincipal = Get-AzureADServicePrincipal -ObjectId $app.ObjectId
    
    $permissions = @()
    
    # Delegated permissions
    $oauth2Permissions = $servicePrincipal.Oauth2Permissions
    foreach($permission in $oauth2Permissions) {
        $permissions += [PSCustomObject]@{
            Type = "Delegated"
            Name = $permission.Value
            AdminConsent = $permission.AdminConsentRequired
            UserConsent = $permission.UserConsentRequired
        }
    }
    
    # Application permissions
    $appRoles = $servicePrincipal.AppRoles
    foreach($role in $appRoles) {
        $permissions += [PSCustomObject]@{
            Type = "Application"
            Name = $role.Value
            AdminConsent = $true
            UserConsent = $false
        }
    }
    
    return $permissions
}
```

**Advanced Solutions:**

1. Implement Dependency Health Checks:
```powershell
# Configure dependency health monitoring
$healthConfig = @{
    Endpoints = @(
        @{
            Name = "GraphAPI"
            Url = "https://graph.microsoft.com/v1.0/$metadata"
            Method = "GET"
            ExpectedStatus = 200
        },
        @{
            Name = "SharePointAPI"
            Url = "https://{tenant}.sharepoint.com/_api/web"
            Method = "GET"
            ExpectedStatus = 200
        }
    )
    Headers = @{
        "Accept" = "application/json"
        "Content-Type" = "application/json"
    }
    RetryCount = 3
    RetryDelay = 5  # seconds
}

function Test-DependencyHealth {
    param($config)
    
    $results = @()
    foreach($endpoint in $config.Endpoints) {
        $attempt = 0
        $success = $false
        
        while(-not $success -and $attempt -lt $config.RetryCount) {
            try {
                $response = Invoke-WebRequest -Uri $endpoint.Url `
                    -Method $endpoint.Method `
                    -Headers $config.Headers
                    
                $success = $response.StatusCode -eq $endpoint.ExpectedStatus
                
                $results += [PSCustomObject]@{
                    Endpoint = $endpoint.Name
                    Status = if($success) {"Healthy"} else {"Unhealthy"}
                    ResponseTime = $response.TimeToResponse
                    StatusCode = $response.StatusCode
                }
            }
            catch {
                $attempt++
                if($attempt -lt $config.RetryCount) {
                    Start-Sleep -Seconds $config.RetryDelay
                }
            }
        }
    }
    
    return $results
}
```

2. Implement Advanced Error Recovery:
```powershell
# Create error recovery system
$recoveryConfig = @{
    MaxRetries = 5
    BackoffMultiplier = 2
    InitialDelay = 1  # seconds
    RecoveryStrategies = @{
        "TokenExpired" = {
            param($context)
            $newToken = Get-NewAccessToken -Resource $context.Resource
            Update-TokenCache -Token $newToken
            return $true
        }
        "QuotaExceeded" = {
            param($context)
            $currentQuota = Get-ResourceQuota -Resource $context.Resource
            if($currentQuota.CanIncrease) {
                Set-ResourceQuota -Resource $context.Resource `
                    -NewQuota ($currentQuota.Current * 1.5)
                return $true
            }
            return $false
        }
        "ServiceUnavailable" = {
            param($context)
            $backup = Get-BackupEndpoint -Service $context.Service
            if($backup) {
                Update-ServiceEndpoint -Service $context.Service -Endpoint $backup
                return $true
            }
            return $false
        }
    }
}

function Start-ErrorRecovery {
    param(
        $Error,
        $Context,
        $Config
    )
    
    $strategy = $Config.RecoveryStrategies[$Error.Category]
    if($strategy) {
        $delay = $Config.InitialDelay
        $attempt = 0
        
        while($attempt -lt $Config.MaxRetries) {
            if(& $strategy $Context) {
                return $true
            }
            
            $attempt++
            $delay *= $Config.BackoffMultiplier
            Start-Sleep -Seconds $delay
        }
    }
    
    return $false
}
```

*Why this works:* Implements comprehensive dependency monitoring and intelligent error recovery while maintaining application reliability.

## Disaster Recovery

### Complex Service Recovery

#### Problem: Multi-Service Failure Recovery
**Advanced Diagnosis:**
1. Service dependency mapping:
```powershell
# Map service dependencies
function Map-ServiceDependencies {
    $services = Get-M365Service
    $dependencies = @{}
    
    foreach($service in $services) {
        $deps = Get-ServiceDependency -Identity $service.Identity
        $dependencies[$service.Identity] = @{
            UpstreamDependencies = $deps.Upstream
            DownstreamDependencies = $deps.Downstream
            CriticalPath = $deps.CriticalPath
            RecoveryPriority = $deps.RecoveryPriority
        }
    }
    
    return $dependencies
}
```

2. Impact analysis:
```powershell
# Analyze service impact
function Analyze-ServiceImpact {
    param(
        [string[]]$AffectedServices
    )
    
    $impact = @{
        DirectlyAffected = @()
        Downstream = @()
        BusinessImpact = @()
    }
    
    foreach($service in $AffectedServices) {
        $deps = Get-ServiceDependency -Identity $service
        
        $impact.DirectlyAffected += $service
        $impact.Downstream += $deps.DownstreamDependencies
        
        $businessProcesses = Get-BusinessProcess -DependsOn $service
        $impact.BusinessImpact += $businessProcesses
    }
    
    return $impact
}
```

**Advanced Solutions:**

1. Implement Service Recovery Orchestration:
```powershell
# Configure recovery orchestration
$recoveryConfig = @{
    Phases = @(
        @{
            Name = "Assessment"
            Actions = @(
                "ValidateInfrastructure",
                "CheckDataIntegrity",
                "EvaluateCapacity"
            )
        },
        @{
            Name = "Preparation"
            Actions = @(
                "AllocateResources",
                "PrepareBackupSystems",
                "NotifyStakeholders"
            )
        },
        @{
            Name = "Recovery"
            Actions = @(
                "RestoreServices",
                "ValidateIntegration",
                "VerifyFunctionality"
            )
        }
    )
    ValidationChecks = @{
        Infrastructure = @(
            "NetworkConnectivity",
            "DNSResolution",
            "CertificateValidity"
        )
        Data = @(
            "DatabaseConsistency",
            "ReplicationStatus",
            "BackupIntegrity"
        )
        Integration = @(
            "AuthenticationFlow",
            "APIConnectivity",
            "DataSync"
        )
    }
}

function Start-ServiceRecovery {
    param(
        $AffectedServices,
        $Config
    )
    
    foreach($phase in $Config.Phases) {
        Write-Log "Starting recovery phase: $($phase.Name)"
        
        foreach($action in $phase.Actions) {
            $result = Invoke-RecoveryAction -Action $action -Services $AffectedServices
            
            if(-not $result.Success) {
                Write-Log "Recovery action failed: $action"
                if($result.Critical) {
                    throw "Critical recovery failure in phase $($phase.Name)"
                }
            }
        }
        
        $validation = Test-PhaseCompletion -Phase $phase.Name
        if(-not $validation.Success) {
            Write-Log "Phase validation failed: $($phase.Name)"
            Invoke-RollbackProcedure -Phase $phase.Name
        }
    }
}
```

2. Implement Business Continuity Management:
```powershell
# Configure business continuity
$continuityConfig = @{
    FailoverThresholds = @{
        ServiceHealth = 0.6  # 60% health
        DataIntegrity = 0.9  # 90% integrity
        UserImpact = 0.4    # 40% users affected
    }
    FailoverTargets = @{
        Primary = "Region1"
        Secondary = "Region2"
        Tertiary = "Region3"
    }
    RecoveryTimeObjective = 240  # minutes
    RecoveryPointObjective = 15  # minutes
}

function Start-BusinessContinuity {
    param(
        $Incident,
        $Config
    )
    
    # Assess incident severity
    $severity = Get-IncidentSeverity -Incident $Incident
    
    if($severity.HealthScore -lt $Config.FailoverThresholds.ServiceHealth) {
        # Initiate failover
        $target = Get-OptimalFailoverTarget -Config $Config.FailoverTargets
        
        $failover = Start-ServiceFailover -Target $target -Services $Incident.AffectedServices
        
        if($failover.Success) {
            # Update DNS and routing
            Update-ServiceEndpoints -Target $target
            
            # Verify failover
            $verification = Test-FailoverSuccess -Target $target
            if($verification.Success) {
                Write-Log "Failover completed successfully to $target"
            }
            else {
                Write-Log "Failover verification failed"
                Start-FailoverRollback
            }
        }
    }
    else {
        # Monitor and prepare for potential escalation
        Start-ContinuousMonitoring -Incident $Incident
    }
}
```

*Why this works:* Implements comprehensive disaster recovery with intelligent service orchestration while maintaining business continuity and data integrity.

---

## Best Practices for L3 Support

1. **Advanced Troubleshooting Methodology**
   - Systematic problem decomposition
   - Root cause analysis techniques
   - Impact assessment frameworks
   - Service dependency mapping

2. **Documentation Requirements**
   - Detailed technical documentation
   - Solution architecture diagrams
   - Recovery procedures
   - Lessons learned repository

3. **Incident Management**
   - Severity classification matrix
   - Escalation procedures
   - Communication templates
   - Stakeholder management

4. **Knowledge Transfer**
   - Technical deep dives
   - Case study development
   - Best practice documentation
   - Training material creation

---

## Additional Resources

- Microsoft 365 Service Health: https://admin.microsoft.com/Adminportal/Home#/servicehealth
- Microsoft 365 Network Connectivity Test: https://connectivity.office.com
- Azure AD Connect Health: https://docs.microsoft.com/azure/active-directory/hybrid/whatis-azure-ad-connect
- Exchange Online Remote Connectivity Analyzer: https://testconnectivity.microsoft.com
- Microsoft Teams Network Assessment Tool: https://www.microsoft.com/download/details.aspx?id=53885

---

*Note: This guide is intended for L3 support personnel with deep technical expertise in Microsoft 365 services, advanced PowerShell scripting, and enterprise architecture. Always test solutions in a non-production environment first and maintain proper change control procedures.*
