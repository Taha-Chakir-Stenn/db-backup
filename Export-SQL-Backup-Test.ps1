Connect-AzAccount

# Get Storage Key from 'Live' subscription ---
Set-AzContext -SubscriptionId "2c59dd5f-a222-476d-ba56-3e0c009af644"
$storageAccount = "decommissioned0live"
$storageContainer = "aws"
$storageResourceGroup = "Decommissioned-RG"
$storageKey = (Get-AzStorageAccountKey -ResourceGroupName $storageResourceGroup -Name $storageAccount)[0].Value
$subFolder = "Test" # Subfolder in the blob storage
# Switch to SQL server's subscription ---
Set-AzContext -SubscriptionId "06512459-9f85-4800-a92b-d333fa1b2ad2"
$sqlServerName = "superenvironment0test-envs"
$sqlResourceGroup = "superenvironment-test-envs"
$sqlAdmin = "sql_administrator"
$sqlPassword = Read-Host -AsSecureString "Enter SQL administrator password"

# Get databases 
$databases = Get-AzSqlDatabase -ServerName $sqlServerName -ResourceGroupName $sqlResourceGroup | Where-Object { $_.DatabaseName -ne "master" }

# Timestamped folder for BACPACs
$timestamp = (Get-Date).ToString("yyyy-MM-dd")

# Export each database
foreach ($db in $databases) {
    $dbName = $db.DatabaseName
    $bacpacName = "$dbName.bacpac"
    $storageUri = "https://$storageAccount.blob.core.windows.net/$storageContainer/$subFolder/$timestamp/$bacpacName" #I put Live in the path to distiguish between environments.

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
