using module '..\core\MonitoringEngine.ps1'

class SharePointMonitor {
    [MonitoringEngine]$Engine
    [int]$CheckInterval
    [hashtable]$LastMetrics
    [datetime]$LastCheck

    SharePointMonitor([MonitoringEngine]$engine) {
        $this.Engine = $engine
        $this.CheckInterval = $engine.Config.monitoring.intervals.sharePoint
        $this.LastMetrics = @{}
        $this.LastCheck = [datetime]::MinValue
    }

    [void]CheckSiteHealth() {
        try {
            # Get all site collections
            $sites = Get-MgSite -All
            
            foreach ($site in $sites) {
                # Check storage usage
                $storageUsedGB = $site.Storage.Used / 1GB
                $storageQuotaGB = $site.Storage.Quota / 1GB
                $usedPercentage = ($site.Storage.Used / $site.Storage.Quota) * 100

                if ($usedPercentage -gt $this.Engine.Config.monitoring.thresholds.storageWarning) {
                    $context = @{
                        SiteUrl = $site.WebUrl
                        UsedStorage = "$($storageUsedGB.ToString('0.00')) GB"
                        TotalQuota = "$($storageQuotaGB.ToString('0.00')) GB"
                        UsedPercentage = $usedPercentage
                    }

                    $description = @"
Storage warning for site: $($site.WebUrl)
- Used: $($context.UsedStorage)
- Quota: $($context.TotalQuota)
- Usage: $($usedPercentage.ToString('0.00'))%

Recommended actions:
1. Review site storage analytics
2. Identify large files and libraries
3. Check version history settings
4. Review retention policies
5. Consider quota adjustment if needed

PowerShell commands for investigation:
``````
Get-PnPStorageReport -Url "$($site.WebUrl)"
Get-PnPList | Sort-Object -Property Size -Descending | Select-Object Title, ItemCount, Size
Get-PnPFile -List "Documents" -Limit 100 | Sort-Object Length -Descending | Select-Object Name, Length, TimeLastModified
``````
"@

                    $this.Engine.QueueAlert(
                        'SharePoint Online',
                        ($usedPercentage -gt $this.Engine.Config.monitoring.thresholds.storageCritical ? 'critical' : 'high'),
                        'Site Storage Warning',
                        $description,
                        $context
                    )
                }

                # Check for permission issues
                try {
                    $sitePermissions = Get-MgSitePermission -SiteId $site.Id
                    $brokenInheritance = $sitePermissions | Where-Object { -not $_.HasUniqueRoleAssignments }

                    if ($brokenInheritance) {
                        $context = @{
                            SiteUrl = $site.WebUrl
                            BrokenPermissions = $brokenInheritance | Select-Object Id, DisplayName
                        }

                        $description = @"
Permission inheritance broken for site: $($site.WebUrl)

Affected items:
$(($context.BrokenPermissions | ForEach-Object { "- $($_.DisplayName)" }) -join "`n")

Security implications:
1. Inconsistent access controls
2. Potential unauthorized access
3. Difficult permission management
4. Compliance risk

Recommended actions:
1. Review broken permission inheritance
2. Verify business justification
3. Document exceptions
4. Consider resetting inheritance where appropriate
5. Update governance policies

Investigation commands:
``````
Get-PnPWeb -Includes HasUniqueRoleAssignments
Get-PnPList | Where-Object {$_.HasUniqueRoleAssignments} | Select-Object Title
Get-PnPGroup | Select-Object Title, Owner, Users
``````
"@

                        $this.Engine.QueueAlert(
                            'SharePoint Online',
                            'medium',
                            'Permission Inheritance Issues Detected',
                            $description,
                            $context
                        )
                    }
                }
                catch {
                    Write-Error "Error checking site permissions for $($site.WebUrl): $_"
                }

                # Check for workflow failures
                try {
                    $flows = Get-MgSiteWorkflowSubscription -SiteId $site.Id
                    foreach ($flow in $flows) {
                        $runs = Get-MgSiteWorkflowSubscriptionRun -SiteId $site.Id -SubscriptionId $flow.Id
                        $failedRuns = $runs | Where-Object { $_.Status -eq 'Failed' }

                        if ($failedRuns.Count -gt 5) { # Alert if more than 5 failures
                            $context = @{
                                SiteUrl = $site.WebUrl
                                FlowName = $flow.Name
                                FailureCount = $failedRuns.Count
                                RecentFailures = $failedRuns | Select-Object -First 5 | Select-Object StartTime, Error
                            }

                            $description = @"
Multiple workflow failures detected for site: $($site.WebUrl)
Flow: $($flow.Name)
Failed runs: $($failedRuns.Count)

Recent failures:
$(($context.RecentFailures | ForEach-Object { "- $($_.StartTime): $($_.Error)" }) -join "`n")

Impact:
1. Business process disruption
2. Data processing delays
3. User experience degradation

Troubleshooting steps:
1. Review flow configuration
2. Check connection status
3. Verify permissions
4. Review error patterns
5. Test flow triggers
"@

                            $this.Engine.QueueAlert(
                                'SharePoint Online',
                                'high',
                                'Workflow Failures Detected',
                                $description,
                                $context
                            )
                        }
                    }
                }
                catch {
                    Write-Error "Error checking workflows for $($site.WebUrl): $_"
                }

                # Check search health
                try {
                    $searchHealth = Get-PnPSearchHealth -SiteUrl $site.WebUrl
                    if ($searchHealth.CrawlStatus -ne 'Success' -or $searchHealth.IndexStatus -ne 'Active') {
                        $context = @{
                            SiteUrl = $site.WebUrl
                            CrawlStatus = $searchHealth.CrawlStatus
                            IndexStatus = $searchHealth.IndexStatus
                            LastCrawlTime = $searchHealth.LastCrawlTime
                        }

                        $description = @"
Search issues detected for site: $($site.WebUrl)
- Crawl Status: $($searchHealth.CrawlStatus)
- Index Status: $($searchHealth.IndexStatus)
- Last Crawl: $($searchHealth.LastCrawlTime)

Impact:
1. Content discoverability affected
2. Search results incomplete
3. User productivity impact

Resolution steps:
1. Verify search service status
2. Check crawl schedule
3. Review crawl logs
4. Verify content sources
5. Test search functionality

PowerShell commands:
``````
Get-PnPSearchConfiguration
Get-PnPSearchCrawlLog
Start-PnPSearchCrawl
``````
"@

                        $this.Engine.QueueAlert(
                            'SharePoint Online',
                            'high',
                            'Search Health Issues',
                            $description,
                            $context
                        )
                    }
                }
                catch {
                    Write-Error "Error checking search health for $($site.WebUrl): $_"
                }
            }
        }
        catch {
            Write-Error "Error in CheckSiteHealth: $_"
        }
    }

    [void]RunChecks() {
        if ((Get-Date) -lt $this.LastCheck.AddSeconds($this.CheckInterval)) {
            return
        }

        $this.CheckSiteHealth()
        
        $this.LastCheck = Get-Date
    }
}
