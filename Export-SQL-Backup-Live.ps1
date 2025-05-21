Connect-AzAccount

# Get Storage Key from 'Live' subscription ---
Set-AzContext -SubscriptionId "2c59dd5f-a222-476d-ba56-3e0c009af644"
$storageAccount = "decommissioned0live"
$storageContainer = "aws"
$storageResourceGroup = "Decommissioned-RG"
$storageKey = (Get-AzStorageAccountKey -ResourceGroupName $storageResourceGroup -Name $storageAccount)[0].Value

# Switch to SQL server's subscription ---
Set-AzContext -SubscriptionId "c3885f45-6172-4386-a8a3-8bcc83a96b8e"
$sqlServerName = "superenvironment0live"
$sqlResourceGroup = "superenvironment-live"
$sqlAdmin = "sql_administrator"
$sqlPassword = Read-Host -AsSecureString "Enter SQL administrator password"

# Get databases 
$databases = Get-AzSqlDatabase -ServerName $serverName -ResourceGroupName $sqlRg | Where-Object {
    $_.DatabaseName -ne "master" -and $_.Status -eq "Online"
}
# Timestamped folder for BACPACs
$timestamp = (Get-Date).ToString("yyyy-MM-dd")

# Export each database
foreach ($db in $databases) {
    $dbName = $db.DatabaseName
    $bacpacName = "$dbName.bacpac"
    $storageUri = "https://$storageAccount.blob.core.windows.net/$storageContainer/live/$timestamp/$bacpacName" #I put Live in the path to distiguish between environments.

    Write-Host "Exporting $dbName to $storageUri..."

    $export = New-AzSqlDatabaseExport `
        -ResourceGroupName $sqlResourceGroup `
        -ServerName $sqlServerName `
        -DatabaseName $dbName `
        -StorageKeyType "StorageAccessKey" `
        -StorageKey $storageKey `
        -StorageUri $storageUri `
        -AdministratorLogin $sqlAdmin `
        -AdministratorLoginPassword $sqlPassword `
        -AuthenticationType "Sql"

    Write-Host "Started export for $dbName."
    Write-Host "To check status: Get-AzSqlDatabaseImportExportStatus -OperationStatusLink '$($export.OperationStatusLink)'"
    Write-Host ""
}
