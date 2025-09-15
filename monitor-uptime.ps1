# monitor-uptime.ps1

# Slack Webhook URL (replace with your actual URL)
$slackWebhookUrl = "https://hooks.slack.com/services/XXXXXXXXXXXXX/XXXXXXXXXXXXXXX"

# Server you want to ping (replace with your server's IP or hostname)
$server = "1.2.3.4"
# $server = "8.8.8.8"  # Google's DNS as an example

# File to track the last known status
$statusFile = "$PSScriptRoot\server-status.txt"

# Ensure status file exists, if not create it with "UP"
if (-Not (Test-Path $statusFile)) {
    "UP" | Out-File $statusFile
}

try {
    # Ping the server
    $ping = Test-Connection -ComputerName $server -Count 2 -Quiet

    # Read last known status
    $lastStatus = Get-Content $statusFile

    if ($ping) {
        Write-Output "Server is UP"
        
        # Send notification only if it was previously down
        if ($lastStatus -eq "DOWN") {
            $message = @{ text = "✅ Server is back UP!" } | ConvertTo-Json
            Invoke-RestMethod -Uri $slackWebhookUrl -Method Post -Body $message -ContentType 'application/json'
        }

        # Update the status file
        "UP" | Out-File $statusFile
    }
    else {
        Write-Output "Server is DOWN"

        # Send notification only if it was previously up
        if ($lastStatus -eq "UP") {
            $message = @{ text = "⚠️ Server is DOWN!" } | ConvertTo-Json
            Invoke-RestMethod -Uri $slackWebhookUrl -Method Post -Body $message -ContentType 'application/json'
        }

        # Update the status file
        "DOWN" | Out-File $statusFile
    }
}
catch {
    # Handle unexpected errors gracefully
    Write-Output "An error occurred: $_"
    $message = @{ text = "⚠️ Error occurred while checking the server: $_" } | ConvertTo-Json
    Invoke-RestMethod -Uri $slackWebhookUrl -Method Post -Body $message -ContentType 'application/json'
}
