class MonitoringEngine {
    [string]$ConfigPath
    [hashtable]$Config
    [System.Collections.Generic.List[PSCustomObject]]$AlertQueue
    [bool]$IsRunning

    MonitoringEngine([string]$configPath) {
        $this.ConfigPath = $configPath
        $this.AlertQueue = [System.Collections.Generic.List[PSCustomObject]]::new()
        $this.LoadConfig()
        $this.InitializeAuth()
    }

    [void]LoadConfig() {
        try {
            $this.Config = Get-Content -Path $this.ConfigPath -Raw | ConvertFrom-Json -AsHashtable
            Write-Host "Configuration loaded successfully"
        }
        catch {
            throw "Failed to load configuration: $_"
        }
    }

    [void]InitializeAuth() {
        try {
            Connect-MgGraph -ClientId $this.Config.authentication.clientId `
                          -TenantId $this.Config.authentication.tenantId `
                          -CertificateThumbprint $this.Config.authentication.certificateThumbprint
            
            Write-Host "Successfully authenticated with Microsoft Graph"
            
            # Connect to Exchange Online PowerShell
            Connect-ExchangeOnline -CertificateThumbprint $this.Config.authentication.certificateThumbprint `
                                 -AppId $this.Config.authentication.clientId `
                                 -Organization "$($this.Config.authentication.tenantId).onmicrosoft.com" `
                                 -ShowBanner:$false
            
            Write-Host "Successfully connected to Exchange Online"
        }
        catch {
            throw "Authentication failed: $_"
        }
    }

    [void]QueueAlert([string]$service, [string]$severity, [string]$title, [string]$description, [hashtable]$context) {
        $alert = [PSCustomObject]@{
            Timestamp = (Get-Date).ToUniversalTime()
            Service = $service
            Severity = $severity
            Title = $title
            Description = $description
            Context = $context
            CorrelationId = [guid]::NewGuid().ToString()
        }

        # Check for duplicate alerts within suppression period
        $suppressionPeriod = (Get-Date).AddSeconds(-$this.Config.alerting.suppressionPeriod)
        $duplicateAlert = $this.AlertQueue | Where-Object {
            $_.Service -eq $service -and 
            $_.Title -eq $title -and 
            $_.Timestamp -gt $suppressionPeriod
        }

        if (-not $duplicateAlert) {
            $this.AlertQueue.Add($alert)
            $this.ProcessAlert($alert)
        }
    }

    [void]ProcessAlert($alert) {
        # Format Slack message
        $slackMessage = @{
            channel = $this.Config.slack.channels[$alert.Severity]
            attachments = @(
                @{
                    color = switch ($alert.Severity) {
                        'critical' { '#FF0000' }
                        'high' { '#FFA500' }
                        'medium' { '#FFFF00' }
                        'low' { '#00FF00' }
                    }
                    blocks = @(
                        @{
                            type = "header"
                            text = @{
                                type = "plain_text"
                                text = "🚨 $($alert.Title)"
                            }
                        }
                        @{
                            type = "section"
                            text = @{
                                type = "mrkdwn"
                                text = $alert.Description
                            }
                        }
                        @{
                            type = "section"
                            fields = @(
                                @{
                                    type = "mrkdwn"
                                    text = "*Service:*\n$($alert.Service)"
                                }
                                @{
                                    type = "mrkdwn"
                                    text = "*Severity:*\n$($alert.Severity.ToUpper())"
                                }
                                @{
                                    type = "mrkdwn"
                                    text = "*Time (UTC):*\n$($alert.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))"
                                }
                                @{
                                    type = "mrkdwn"
                                    text = "*Correlation ID:*\n$($alert.CorrelationId)"
                                }
                            )
                        }
                    )
                }
            )
        }

        # Add mentions for critical/high severity
        if ($this.Config.slack.mentionRoles[$alert.Severity]) {
            $mentions = $this.Config.slack.mentionRoles[$alert.Severity] -join ' '
            $slackMessage.text = $mentions
        }

        # Send to Slack
        try {
            $body = $slackMessage | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Uri $this.Config.slack.webhookUrl -Method Post -Body $body -ContentType 'application/json'
        }
        catch {
            Write-Error "Failed to send Slack alert: $_"
        }
    }

    [void]Start() {
        $this.IsRunning = $true
        Write-Host "Monitoring engine started"
        
        while ($this.IsRunning) {
            try {
                # Process alert queue
                while ($this.AlertQueue.Count -gt 0) {
                    $alert = $this.AlertQueue[0]
                    $this.ProcessAlert($alert)
                    $this.AlertQueue.RemoveAt(0)
                }

                # Rate limiting check
                Start-Sleep -Seconds 1
            }
            catch {
                Write-Error "Error in monitoring loop: $_"
            }
        }
    }

    [void]Stop() {
        $this.IsRunning = $false
        Write-Host "Monitoring engine stopped"
    }

    [hashtable]GenerateGuidance([string]$problemType) {
        $guidance = @{
            steps = @()
            permissions = @()
            tools = @()
            commands = @()
            references = @()
        }

        switch ($problemType) {
            'MailFlow' {
                $guidance.steps = @(
                    "1. Check message trace for affected messages",
                    "2. Review transport queue status",
                    "3. Verify connector health",
                    "4. Check for transport rules conflicts",
                    "5. Review anti-spam policies"
                )
                $guidance.permissions = @(
                    "Exchange Admin",
                    "Security Admin"
                )
                $guidance.tools = @(
                    "Exchange Admin Center > Mail Flow > Message Trace",
                    "Exchange Admin Center > Mail Flow > Queues"
                )
                $guidance.commands = @(
                    "Get-TransportService | Get-Queue",
                    "Get-MessageTrace -StartDate (Get-Date).AddHours(-1)",
                    "Get-TransportRule | Where-Object {$_.State -eq 'Enabled'}"
                )
            }
            'MailboxStorage' {
                $guidance.steps = @(
                    "1. Review mailbox statistics",
                    "2. Check retention policies",
                    "3. Verify archive status",
                    "4. Review folder statistics",
                    "5. Check for large items"
                )
                $guidance.permissions = @(
                    "Exchange Admin"
                )
                $guidance.tools = @(
                    "Exchange Admin Center > Recipients > Mailboxes",
                    "Security & Compliance Center > Information Governance"
                )
                $guidance.commands = @(
                    "Get-MailboxStatistics",
                    "Get-MailboxFolderStatistics",
                    "Get-RetentionPolicy"
                )
            }
            # Add more problem types as needed
        }

        return $guidance
    }
}
