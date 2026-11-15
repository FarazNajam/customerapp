
$ErrorActionPreference = "Stop"

# CustomerApp configuration
$SqlServer   = "p-auea-customerapp-sqlserver.database.windows.net"
$Database    = "p-auea-customerapp-db"
$AppIdentity = "p-auea-customerapp-api"
$TenantId    = "84dcd724-5abd-41f1-bb78-f5d9dc799506"

Write-Host "`n=== CustomerApp SQL Identity Configuration ===" -ForegroundColor Cyan

# --------------------------------------------------
# 1. Authenticate to Azure SQL using Azure CLI
# --------------------------------------------------

Write-Host "`nObtaining Azure SQL access token..." -ForegroundColor Cyan

$accessToken = az account get-access-token `
    --resource https://database.windows.net/ `
    --query accessToken `
    --output tsv 2>$null

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($accessToken)) {

    Write-Host "Interactive authentication required. Signing in..." -ForegroundColor Yellow

    az login `
        --tenant $TenantId `
        --scope https://database.windows.net//.default

    if ($LASTEXITCODE -ne 0) {
        throw "Azure login failed."
    }

    Write-Host "Retrying Azure SQL token request..." -ForegroundColor Cyan

    $accessToken = az account get-access-token `
        --resource https://database.windows.net/ `
        --query accessToken `
        --output tsv

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($accessToken)) {
        throw "Could not obtain an Azure SQL access token."
    }
}

Write-Host "Azure SQL access token obtained successfully." -ForegroundColor Green

# --------------------------------------------------
# 2. Retrieve API Managed Identity Principal ID
# --------------------------------------------------

Write-Host "`nRetrieving API Managed Identity Principal ID..." -ForegroundColor Cyan

$principalId = terraform output -raw api_managed_identity_principal_id

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($principalId)) {
    throw "Could not retrieve API Managed Identity Principal ID from Terraform."
}

$principalId = $principalId.Trim()

Write-Host "API identity: $AppIdentity" -ForegroundColor Green
Write-Host "Principal ID: $principalId" -ForegroundColor Green

# --------------------------------------------------
# 3. Construct SQL script
# --------------------------------------------------

Write-Host "`nPreparing SQL database permissions..." -ForegroundColor Cyan

$query = @"
IF DATABASE_PRINCIPAL_ID(N'$AppIdentity') IS NULL
BEGIN
    CREATE USER [$AppIdentity]
    FROM EXTERNAL PROVIDER
    WITH OBJECT_ID = '$principalId';

    PRINT 'Database user created.';
END
ELSE
BEGIN
    PRINT 'Database user already exists.';
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members rm
    INNER JOIN sys.database_principals rolep
        ON rm.role_principal_id = rolep.principal_id
    INNER JOIN sys.database_principals memberp
        ON rm.member_principal_id = memberp.principal_id
    WHERE rolep.name = 'db_datareader'
      AND memberp.name = '$AppIdentity'
)
BEGIN
    ALTER ROLE db_datareader ADD MEMBER [$AppIdentity];
    PRINT 'db_datareader assigned.';
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members rm
    INNER JOIN sys.database_principals rolep
        ON rm.role_principal_id = rolep.principal_id
    INNER JOIN sys.database_principals memberp
        ON rm.member_principal_id = memberp.principal_id
    WHERE rolep.name = 'db_datawriter'
      AND memberp.name = '$AppIdentity'
)
BEGIN
    ALTER ROLE db_datawriter ADD MEMBER [$AppIdentity];
    PRINT 'db_datawriter assigned.';
END;

PRINT 'Database permissions configured.';
"@

Write-Host "`nSQL query prepared successfully." -ForegroundColor Green

# --------------------------------------------------
# 4. Execute SQL script
# --------------------------------------------------

Write-Host "`nConnecting to Azure SQL..." -ForegroundColor Cyan

Invoke-Sqlcmd `
    -ServerInstance $SqlServer `
    -Database $Database `
    -AccessToken $accessToken `
    -Query $query `
    -ErrorAction Stop

Write-Host "`nSQL configuration executed." -ForegroundColor Green

# --------------------------------------------------
# 5. Verify database user and permissions
# --------------------------------------------------

Write-Host "`nVerifying database permissions..." -ForegroundColor Cyan

$verifyQuery = @"
SELECT
    dp.name AS DatabaseUser,
    dp.type_desc AS PrincipalType,
    rp.name AS DatabaseRole
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members drm
    ON dp.principal_id = drm.member_principal_id
LEFT JOIN sys.database_principals rp
    ON drm.role_principal_id = rp.principal_id
WHERE dp.name = '$AppIdentity'
ORDER BY rp.name;
"@

$verification = Invoke-Sqlcmd `
    -ServerInstance $SqlServer `
    -Database $Database `
    -AccessToken $accessToken `
    -Query $verifyQuery `
    -ErrorAction Stop

if (-not $verification) {
    throw "Verification failed: database user was not found."
}

$verification | Format-Table -AutoSize

$roles = @($verification | ForEach-Object { $_.DatabaseRole })

if ($roles -notcontains "db_datareader" -or
    $roles -notcontains "db_datawriter") {
    throw "Verification failed: expected database roles are missing."
}

Write-Host "`nCustomerApp SQL identity configuration completed successfully." -ForegroundColor Green

# --------------------------------------------------
# 6. Clear access token from memory
# --------------------------------------------------

$accessToken = $null
