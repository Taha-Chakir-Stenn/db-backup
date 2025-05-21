# Login
Connect-AzAccount

# Set variables
$sourceSubscriptionId = "06512459-9f85-4800-a92b-d333fa1b2ad2" # superenvironment0test-envs
$storageSubscriptionId = "2c59dd5f-a222-476d-ba56-3e0c009af644" # decommissioned0live
$sqlRg = "superenvironment-test-envs"
$serverName = "superenvironment0test-envs"
$storageAccount = "decommissioned0live"
$container = "aws"
$storageRg = "Decommissioned-RG"

# Timestamp
$timestamp = (Get-Date).ToString("yyyy-MM-dd")

# Switch to the storage subscription
Set-AzContext -SubscriptionId $storageSubscriptionId

# Get storage key
$storageKey = (Get-AzStorageAccountKey -ResourceGroupName $storageRg -Name $storageAccount)[0].Value

# Switch to the SQL server subscription
Set-AzContext -SubscriptionId $sourceSubscriptionId

# Get databases, excluding 'master' and 'paused'
$databases = Get-AzSqlDatabase -ServerName $serverName -ResourceGroupName $sqlRg | Where-Object {
    $_.DatabaseName -ne "master" -and $_.Status -eq "Online"
}

# Export each DB
foreach ($db in $databases) {
    $dbName = $db.DatabaseName
    $bacpacName = "${dbName}_$timestamp.bacpac"
    $storageUri = "https://$storageAccount.blob.core.windows.net/$container/test/$timestamp/$bacpacName"

    Write-Host "🔄 Exporting $dbName to $storageUri"

    New-AzSqlDatabaseExport `
        -ResourceGroupName $sqlRg `
        -ServerName $serverName `
        -DatabaseName $dbName `
        -StorageKeyType "StorageAccessKey" `
        -StorageKey $storageKey `
        -StorageUri $storageUri `
        -AuthenticationType "AdPassword" `
        -AdministratorLogin "<your-AAD-username>" `
        -AdministratorLoginPassword (Read-Host -AsSecureString "Enter Azure AD password")
}
