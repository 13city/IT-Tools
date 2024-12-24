using module '..\core\MonitoringEngine.ps1'

class ExchangeMonitor {
    [MonitoringEngine]$Engine
    [int]$CheckInterval
    [hashtable]$LastMetrics
    [datetime]$LastCheck

    ExchangeMonitor([MonitoringEngine]$engine) {
        $this.Engine = $engine
        $this.CheckInterval = $engine.Config.monitoring.intervals.exchangeOnline
        $this.LastMetrics = @{}
        $this.LastCheck = [datetime]::MinValue
    }

    [void]CheckMailFlow() {
        try {
            # Check transport queues
            $queues = Get-TransportService | Get-Queue
            $queueSize = ($queues | Measure-Object MessageCount -Sum).Sum

            if ($queueSize -gt $this.Engine.Config.monitoring.thresholds.mailQueueSize) {
                $context = @{
                    QueueSize = $queueSize
                    QueueDetails = $queues | Where-Object {$_.MessageCount -gt 0} | Select-Object Identity, MessageCount, Status
                    Threshold = $this.Engine.Config.monitoring.thresholds.mailQueueSize
                }

                $guidance = $this.Engine.GenerateGuidance('MailFlow')
                
                $description = @"
Mail queue size ($queueSize) exceeds threshold ($($this.Engine.Config.monitoring.thresholds.mailQueueSize))

Affected Queues:
$(($context.QueueDetails | ForEach-Object { "- $($_.Identity): $($_.MessageCount) messages ($($_.Status))" }) -join "`n")

Resolution Steps:
$($guidance.steps -join "`n")

Required Permissions:
$($guidance.permissions -join "`n")

Useful Commands:
``````
$($guidance.commands -join "`n")
``````
"@

                $this.Engine.QueueAlert(
                    'Exchange Online',
                    'high',
                    'Mail Queue Buildup Detected',
                    $description,
                    $context
                )
            }

            # Check for NDR patterns
            $startTime = (Get-Date).AddHours(-1)
            $ndrMessages = Get-MessageTrace -StartDate $startTime -EndDate (Get-Date) |
                Where-Object { $_.Status -eq 'Failed' }
            
            $ndrCount = ($ndrMessages | Measure-Object).Count
            if ($ndrCount -gt 50) { # Threshold for NDR spike
                $ndrPatterns = $ndrMessages | Group-Object -Property RecipientAddress |
                    Sort-Object Count -Descending | Select-Object -First 5

                $context = @{
                    NDRCount = $ndrCount
                    TimeWindow = "1 hour"
                    TopPatterns = $ndrPatterns
                }

                $description = @"
High number of NDRs detected ($ndrCount in the last hour)

Top affected recipients:
$(($ndrPatterns | ForEach-Object { "- $($_.Name): $($_.Count) failures" }) -join "`n")

Please investigate potential causes:
1. Invalid recipient addresses
2. Mail flow rule conflicts
3. Connector configuration issues
4. External domain DNS problems
5. Anti-spam policy blocks

Run message trace for detailed analysis:
Get-MessageTrace -StartDate '$($startTime.ToString('yyyy-MM-dd HH:mm:ss'))' -Status Failed | Export-Csv -Path 'NDR_Analysis.csv'
"@

                $this.Engine.QueueAlert(
                    'Exchange Online',
                    'high',
                    'NDR Pattern Detected',
                    $description,
                    $context
                )
            }
        }
        catch {
            Write-Error "Error checking mail flow: $_"
        }
    }

    [void]CheckMailboxHealth() {
        try {
            # Get all mailboxes
            $mailboxes = Get-Mailbox -ResultSize Unlimited
            
            foreach ($mailbox in $mailboxes) {
                $stats = Get-MailboxStatistics $mailbox.Identity
                
                # Check storage thresholds
                $usedPercentage = ($stats.TotalItemSize.Value.ToBytes() / 
                    $mailbox.ProhibitSendReceiveQuota.Value.ToBytes()) * 100

                if ($usedPercentage -gt $this.Engine.Config.monitoring.thresholds.storageCritical) {
                    $context = @{
                        Mailbox = $mailbox.UserPrincipalName
                        UsedSpace = $stats.TotalItemSize.Value
                        TotalQuota = $mailbox.ProhibitSendReceiveQuota.Value
                        UsedPercentage = $usedPercentage
                    }

                    $guidance = $this.Engine.GenerateGuidance('MailboxStorage')

                    $description = @"
Mailbox storage critical for $($mailbox.UserPrincipalName)
- Used: $($stats.TotalItemSize)
- Quota: $($mailbox.ProhibitSendReceiveQuota)
- Usage: $($usedPercentage.ToString('0.00'))%

Resolution Steps:
$($guidance.steps -join "`n")

Required Permissions:
$($guidance.permissions -join "`n")

Useful Commands:
``````
$($guidance.commands -join "`n")
``````
"@

                    $this.Engine.QueueAlert(
                        'Exchange Online',
                        'critical',
                        'Mailbox Storage Critical',
                        $description,
                        $context
                    )
                }

                # Check for corruption indicators
                $folderStats = Get-MailboxFolderStatistics $mailbox.Identity
                $corruptionIndicators = $folderStats | Where-Object {
                    $_.ItemsInFolder -eq 0 -and $_.FolderSize -gt 0
                }

                if ($corruptionIndicators) {
                    $context = @{
                        Mailbox = $mailbox.UserPrincipalName
                        CorruptFolders = $corruptionIndicators | Select-Object FolderPath, FolderSize
                    }

                    $description = @"
Potential corruption detected in mailbox $($mailbox.UserPrincipalName)

Affected folders:
$(($context.CorruptFolders | ForEach-Object { "- $($_.FolderPath): $($_.FolderSize)" }) -join "`n")

Recommended actions:
1. Run New-MailboxRepairRequest for the affected mailbox
2. Monitor repair request progress
3. Check for missing items after repair
4. Consider running content index repair if needed

Command to repair:
New-MailboxRepairRequest -Mailbox "$($mailbox.UserPrincipalName)" -CorruptionType SearchFolder,AggregateCounts,ProvisionedFolder
"@

                    $this.Engine.QueueAlert(
                        'Exchange Online',
                        'high',
                        'Potential Mailbox Corruption',
                        $description,
                        $context
                    )
                }
            }
        }
        catch {
            Write-Error "Error checking mailbox health: $_"
        }
    }

    [void]CheckComplianceStatus() {
        try {
            # Check retention policy application
            $retentionPolicies = Get-RetentionPolicy
            foreach ($policy in $retentionPolicies) {
                $tags = $policy | Get-RetentionPolicyTag
                $inactiveTags = $tags | Where-Object { -not $_.RetentionEnabled }

                if ($inactiveTags) {
                    $context = @{
                        Policy = $policy.Name
                        InactiveTags = $inactiveTags | Select-Object Name, Type
                    }

                    $description = @"
Inactive retention tags detected in policy $($policy.Name)

Affected tags:
$(($context.InactiveTags | ForEach-Object { "- $($_.Name) ($($_.Type))" }) -join "`n")

Impact:
- Data retention may not be properly enforced
- Compliance requirements might be violated
- Legal hold effectiveness could be compromised

Required Actions:
1. Review retention policy configuration
2. Enable inactive tags or update policy
3. Verify retention settings are aligned with compliance requirements
4. Check for any policy conflicts
"@

                    $this.Engine.QueueAlert(
                        'Exchange Online',
                        'high',
                        'Retention Policy Configuration Issue',
                        $description,
                        $context
                    )
                }
            }

            # Check for hold breaches
            $holds = Get-Mailbox -ResultSize Unlimited | Where-Object { $_.LitigationHoldEnabled -eq $true }
            foreach ($hold in $holds) {
                $holdStats = Get-MailboxStatistics $hold.Identity
                if ($holdStats.ItemCount -lt ($this.LastMetrics["$($hold.Identity)_HoldItems"] ?? 0)) {
                    $context = @{
                        Mailbox = $hold.UserPrincipalName
                        CurrentItems = $holdStats.ItemCount
                        PreviousItems = $this.LastMetrics["$($hold.Identity)_HoldItems"]
                        Difference = $this.LastMetrics["$($hold.Identity)_HoldItems"] - $holdStats.ItemCount
                    }

                    $description = @"
Potential hold breach detected for $($hold.UserPrincipalName)
- Current item count: $($holdStats.ItemCount)
- Previous item count: $($this.LastMetrics["$($hold.Identity)_HoldItems"])
- Items potentially removed: $($context.Difference)

Critical Actions Required:
1. Immediately investigate item deletions
2. Review audit logs for deletion events
3. Check hold configuration status
4. Document findings for compliance team
5. Consider legal team notification

Audit command:
Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-1) -EndDate (Get-Date) -UserIds $($hold.UserPrincipalName) -Operations HardDelete,SoftDelete
"@

                    $this.Engine.QueueAlert(
                        'Exchange Online',
                        'critical',
                        'Potential Legal Hold Breach',
                        $description,
                        $context
                    )
                }

                # Update metrics
                $this.LastMetrics["$($hold.Identity)_HoldItems"] = $holdStats.ItemCount
            }
        }
        catch {
            Write-Error "Error checking compliance status: $_"
        }
    }

    [void]RunChecks() {
        if ((Get-Date) -lt $this.LastCheck.AddSeconds($this.CheckInterval)) {
            return
        }

        $this.CheckMailFlow()
        $this.CheckMailboxHealth()
        $this.CheckComplianceStatus()
        
        $this.LastCheck = Get-Date
    }
}
