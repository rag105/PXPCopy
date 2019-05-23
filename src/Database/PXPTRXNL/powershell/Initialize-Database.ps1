param(
    [string] $sa_password = $env:sa_password,
    [string] $data_path = $env:data_path,
    [string] $TargetServerName = $env:server_name,
    [string] $TargetDatabaseName = $env:database_name,
    [string] $TargetUser = 'sa',
    [string] $TargetPassword = $env:sa_password
)
$VerbosePreference = "Continue"

Write-Verbose "data_path: $data_path"
Write-Verbose "TargetServerName: $TargetServerName"
Write-Verbose "TargetDatabaseName: $TargetDatabaseName"
Write-Verbose "TargetUser: $TargetUser"

if ($TargetServerName -eq '.\SQLEXPRESS') {

	Write-Verbose "Creating Local: $TargetServerName"
    # start the service
    Write-Verbose 'Starting SQL Server'
    Start-Service MSSQL`$SQLEXPRESS

    if ($sa_password -ne "_") {
        Write-Verbose 'Changing SA login credentials'
        $sqlcmd = "ALTER LOGIN sa with password='$sa_password'; ALTER LOGIN sa ENABLE;"
        Invoke-SqlCmd -Query $sqlcmd -ServerInstance ".\SQLEXPRESS" 
    }

    $mdfPath = "$data_path\PXPTRXNL_Primary.mdf"
    $ldfPath = "$data_path\PXPTRXNL_Primary.ldf"

    # attach data files if they exist: 
    if ((Test-Path $mdfPath) -eq $true) {
        $sqlcmd = "IF DB_ID('PXPTRXNL') IS NULL BEGIN CREATE DATABASE PXPTRXNL ON (FILENAME = N'$mdfPath')"
        if ((Test-Path $ldfPath) -eq $true) {
            $sqlcmd = "$sqlcmd, (FILENAME = N'$ldfPath')"
        }
        $sqlcmd = "$sqlcmd FOR ATTACH; END"
        Write-Verbose 'Data files exist - will attach and upgrade database'
        Invoke-Sqlcmd -Query $sqlcmd -ServerInstance ".\SQLEXPRESS"
    }
    else {
        Write-Verbose 'No data files - will create new database'
    }
}

# deploy or upgrade the database:
$SqlPackagePath = 'C:\Program Files\Microsoft SQL Server\140\DAC\bin\SqlPackage.exe'
& $SqlPackagePath  `
    /sf:PXPTRXNL.dacpac `
    /a:Script /op:deploy.sql /p:CommentOutSetVarDeclarations=true `
    /TargetServerName:$TargetServerName /TargetDatabaseName:$TargetDatabaseName `
    /TargetUser:$TargetUser /TargetPassword:$TargetPassword 

if ($TargetServerName -eq '.\SQLEXPRESS') {
	Write-Verbose "Deploying to Local: $TargetServerName"
    $SqlCmdVars = "DatabaseName=$TargetDatabaseName", "DefaultFilePrefix=$TargetDatabaseName", "DefaultDataPath=$data_path\", "DefaultLogPath=$data_path\"  
    Invoke-Sqlcmd -InputFile deploy.sql -Variable $SqlCmdVars -Verbose

    Write-Verbose "Deployed PXPTRXNL database, data files at: $data_path"

    $lastCheck = (Get-Date).AddSeconds(-2) 
    while ($true) { 
        Get-EventLog -LogName Application -Source "MSSQL*" -After $lastCheck | Select-Object TimeGenerated, EntryType, Message	 
        $lastCheck = Get-Date 
        Start-Sleep -Seconds 2 
    }
}
else {
	Write-Verbose "Deploying to Remote: $TargetServerName"
    $SqlCmdVars = "DatabaseName=$TargetDatabaseName", "DefaultFilePrefix=$TargetDatabaseName", "DefaultDataPath=$data_path\", "DefaultLogPath=$data_path\"  
	Write-Verbose "SqlCmdVars: $SqlCmdVars"
    Invoke-Sqlcmd -ServerInstance $TargetServerName -User $TargetUser -Password $TargetPassword -InputFile deploy.sql -Variable $SqlCmdVars -Verbose | Out-File -FilePath "C:\TestSqlCmd.rpt"

    Write-Verbose "Deployed PXPTRXNL database, data files at: $data_path"
}
