using module '..\core\MonitoringEngine.ps1'

class TeamsMonitor {
    [MonitoringEngine]$Engine
    [int]$CheckInterval
    [hashtable]$LastMetrics
    [datetime]$LastCheck

    TeamsMonitor([MonitoringEngine]$engine) {
        $this.Engine = $engine
        $this.CheckInterval = $engine.Config.monitoring.intervals.teams
        $this.LastMetrics = @{}
        $this.LastCheck = [datetime]::MinValue
    }

    [void]CheckMeetingQuality() {
        try {
            # Get meeting quality data for the last hour
            $startTime = (Get-Date).AddHours(-1)
            $endTime = Get-Date
            
            $callRecords = Get-CsTeamsUserCallRecord -StartTime $startTime -EndTime $endTime
            
            # Group issues by type
            $audioIssues = $callRecords | Where-Object { $_.AudioQuality -ne 'Good' }
            $videoIssues = $callRecords | Where-Object { $_.VideoQuality -ne 'Good' }
            $screenIssues = $callRecords | Where-Object { $_.ScreenShareQuality -ne 'Good' }

            # Check for audio quality issues
            if ($audioIssues) {
                $context = @{
                    IssueCount = $audioIssues.Count
                    TimeWindow = "Last hour"
                    AffectedUsers = $audioIssues | Select-Object UserId, AudioQuality, NetworkQuality
                }

                $description = @"
Audio quality issues detected in Teams meetings

Number of affected calls: $($context.IssueCount)
Time period: $($context.TimeWindow)

Sample of affected users:
$(($context.AffectedUsers | Select-Object -First 5 | ForEach-Object {
    "- User: $($_.UserId)`n  Audio: $($_.AudioQuality)`n  Network: $($_.NetworkQuality)"
}) -join "`n")

Common causes:
1. Network bandwidth constraints
2. Audio device problems
3. Client configuration issues
4. Service degradation
5. Firewall/proxy interference

Investigation steps:
1. Review network metrics
2. Check client versions
3. Verify audio devices
4. Test network paths
5. Review QoS settings

PowerShell commands:
``````
Get-CsTeamsNetworkAssessment
Get-CsTeamsClientConfiguration
Get-CsTeamsQoSPolicy
``````
"@

                $this.Engine.QueueAlert(
                    'Teams',
                    'high',
                    'Teams Audio Quality Issues Detected',
                    $description,
                    $context
                )
            }

            # Check for video quality issues
            if ($videoIssues) {
                $context = @{
                    IssueCount = $videoIssues.Count
                    TimeWindow = "Last hour"
                    AffectedUsers = $videoIssues | Select-Object UserId, VideoQuality, NetworkQuality
                }

                $description = @"
Video quality issues detected in Teams meetings

Number of affected calls: $($context.IssueCount)
Time period: $($context.TimeWindow)

Sample of affected users:
$(($context.AffectedUsers | Select-Object -First 5 | ForEach-Object {
    "- User: $($_.UserId)`n  Video: $($_.VideoQuality)`n  Network: $($_.NetworkQuality)"
}) -join "`n")

Troubleshooting steps:
1. Check bandwidth utilization
2. Review video device settings
3. Verify client performance
4. Test network capacity
5. Check QoS policies

PowerShell commands:
``````
Get-CsTeamsVideoConfiguration
Get-CsTeamsMediaConfiguration
Test-CsTeamsConnection -UserPrincipalName user@domain.com
``````
"@

                $this.Engine.QueueAlert(
                    'Teams',
                    'high',
                    'Teams Video Quality Issues Detected',
                    $description,
                    $context
                )
            }
        }
        catch {
            Write-Error "Error checking meeting quality: $_"
        }
    }

    [void]CheckTeamHealth() {
        try {
            # Get all teams
            $teams = Get-Team
            
            foreach ($team in $teams) {
                # Check storage usage
                $storageUsage = Get-TeamStorageUsage -GroupId $team.GroupId
                $usedPercentage = ($storageUsage.Used / $storageUsage.Total) * 100

                if ($usedPercentage -gt $this.Engine.Config.monitoring.thresholds.storageWarning) {
                    $context = @{
                        TeamName = $team.DisplayName
                        UsedStorage = "$([math]::Round($storageUsage.Used / 1GB, 2)) GB"
                        TotalStorage = "$([math]::Round($storageUsage.Total / 1GB, 2)) GB"
                        UsedPercentage = $usedPercentage
                    }

                    $description = @"
Storage warning for team: $($team.DisplayName)
- Used: $($context.UsedStorage)
- Total: $($context.TotalStorage)
- Usage: $($usedPercentage.ToString('0.00'))%

Impact:
1. File sharing limitations
2. Collaboration constraints
3. Potential service disruption

Recommended actions:
1. Review large files
2. Archive old content
3. Check retention policies
4. Review storage allocation
5. Plan cleanup activities

PowerShell commands:
``````
Get-TeamFileReport -GroupId "$($team.GroupId)"
Get-TeamRetentionPolicy -GroupId "$($team.GroupId)"
``````
"@

                    $this.Engine.QueueAlert(
                        'Teams',
                        ($usedPercentage -gt $this.Engine.Config.monitoring.thresholds.storageCritical ? 'critical' : 'high'),
                        'Team Storage Warning',
                        $description,
                        $context
                    )
                }

                # Check app issues
                $apps = Get-TeamsApp -TeamId $team.GroupId
                $failedApps = $apps | Where-Object { $_.Status -ne 'Enabled' }

                if ($failedApps) {
                    $context = @{
                        TeamName = $team.DisplayName
                        FailedApps = $failedApps | Select-Object DisplayName, Status
                    }

                    $description = @"
App issues detected in team: $($team.DisplayName)

Affected apps:
$(($context.FailedApps | ForEach-Object { "- $($_.DisplayName): $($_.Status)" }) -join "`n")

Impact:
1. Workflow disruption
2. Feature unavailability
3. User experience degradation

Resolution steps:
1. Check app permissions
2. Verify licensing
3. Review app policies
4. Test app reinstallation
5. Check for updates

PowerShell commands:
``````
Get-TeamsAppPermissionPolicy
Get-TeamsAppSetupPolicy
Get-TeamsAppInstallation -TeamId "$($team.GroupId)"
``````
"@

                    $this.Engine.QueueAlert(
                        'Teams',
                        'high',
                        'Teams App Issues Detected',
                        $description,
                        $context
                    )
                }

                # Check guest access issues
                $guestSettings = Get-TeamGuestSettings -GroupId $team.GroupId
                $guestMembers = Get-TeamUser -GroupId $team.GroupId -Role Guest
                
                if ($guestSettings.AllowGuestAccess -and -not $guestMembers) {
                    $context = @{
                        TeamName = $team.DisplayName
                        GuestSettings = $guestSettings
                    }

                    $description = @"
Guest access configuration issue detected in team: $($team.DisplayName)

Current settings:
- Guest access enabled: Yes
- No guest members present
- Potential configuration drift

Security implications:
1. Unused guest access
2. Security policy compliance
3. Access control review needed

Recommended actions:
1. Review guest access requirements
2. Verify guest invitation process
3. Check external sharing policies
4. Document guest access justification
5. Update security policies

PowerShell commands:
``````
Get-TeamExternalAccess -GroupId "$($team.GroupId)"
Get-TeamSharingPolicy -GroupId "$($team.GroupId)"
``````
"@

                    $this.Engine.QueueAlert(
                        'Teams',
                        'medium',
                        'Teams Guest Access Configuration Issue',
                        $description,
                        $context
                    )
                }
            }
        }
        catch {
            Write-Error "Error checking team health: $_"
        }
    }

    [void]RunChecks() {
        if ((Get-Date) -lt $this.LastCheck.AddSeconds($this.CheckInterval)) {
            return
        }

        $this.CheckMeetingQuality()
        $this.CheckTeamHealth()
        
        $this.LastCheck = Get-Date
    }
}
