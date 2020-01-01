# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Open json file with details on resources to scale up
$json = (Get-Content ".\ScaleupTrigger\scale.json" -Raw) | ConvertFrom-Json


foreach($item in $json.resources)
{
    $resourceGroup = $item.resourceGroup
    $account = $item.account
    $resourceName = $item.resourceName
    $throughput = $item.throughput

    # Determine if shared or dedicated throughput resource
    $isDedicatedThroughput = Select-String -Pattern "/" -InputObject $resourceName | Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Index

    # Set the -ResourceType based upon $api
    $api = Get-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
        -ApiVersion "2019-08-01" -ResourceGroupName $resourceGroup `
        -Name $account | Select-Object -ExpandProperty Properties | Select-Object -ExpandProperty EnabledApiTypes

    Write-Host "ResourceGroup = $resourceGroup"
    Write-Host "Account = $account"
    Write-Host "Api = $api"
    Write-Host "ResourceName = $resourceName"
    Write-Host "Throughput = $throughput"

    switch($api)
    {
        "Sql"
        {
            if($isDedicatedThroughput){
                $resourceType = "Microsoft.DocumentDb/databaseAccounts/sqlDatabases/containers/throughputSettings"
            }
            else {
                $resourceType = "Microsoft.DocumentDb/databaseAccounts/sqlDatabases/throughputSettings"
            }
        }
        "Cassandra"
        {
            if($isDedicatedThroughput){
                $resourceType = "Microsoft.DocumentDb/databaseAccounts/cassandraKeyspaces/tables/throughputSettings"
            }
            else{
                $resourceType = "Microsoft.DocumentDb/databaseAccounts/cassandraKeyspaces/throughputSettings"
            }
        }
        "MongoDB"
        {
            if($isDedicatedThroughput){
                $resourceType = "Microsoft.DocumentDb/databaseAccounts/mongodbDatabases/collections/throughputSettings"
            }
            else{
                $resourceType = "Microsoft.DocumentDb/databaseAccounts/mongodbDatabases/throughputSettings"
            }
        }
        "Gremlin, Sql"
        {
            if($isDedicatedThroughput){
                $resourceType = "Microsoft.DocumentDb/databaseAccounts/gremlinDatabases/graphs/throughputSettings"
            }
            else{
                $resourceType = "Microsoft.DocumentDb/databaseAccounts/gremlinDatabases/throughputSettings"
            }
        }
        "Table, Sql"
        {
            $resourceType = "Microsoft.DocumentDb/databaseAccounts/tables/throughputSettings"
        }
    }

    # Set the -Name for the resource
    $name = $account + "/" + $resourceName + "/default"

    # Ensure throughput is not set below the Minimum Throughput for the resource.
    $minThroughput = Get-AzResource -ResourceType $resourceType `
    -ApiVersion "2019-08-01" -ResourceGroupName $resourceGroup `
    -Name $name | Select-Object -ExpandProperty Properties | Select-Object -ExpandProperty Resource | Select-Object -ExpandProperty minimumThroughput

    if($minThroughput -gt $throughput)
    {
        Write-Host "Cannot reduce throughput to $throughput RU/s, reducing to minimum allowed throughput, $minThroughput RU/s"
        $throughput = $minThroughput -as [Int32]
    }

    # Set the throughput property and value for the resource
    $properties = @{
        "resource"=@{"throughput"=$throughput}
    }

    # Set the Throughput
    Set-AzResource -ResourceType $resourceType `
        -ApiVersion "2019-08-01" -ResourceGroupName $resourceGroup `
        -Name $name -PropertyObject $properties -Force

    Write-Host "Scale up throughput on resource: " + $name + " to " + $throughput + "RU/s"

    # Write an information log with the current time.
    Write-Host "Cosmos DB ScaleUpTrigger ran! TIME: $currentUTCtime"

}