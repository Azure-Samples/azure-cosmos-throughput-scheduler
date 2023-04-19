# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Open json file with details on resources to scale up
$json = (Get-Content ".\ScaleUpTrigger\resources.json" -Raw) | ConvertFrom-Json


foreach($item in $json.resources){

    $resourceGroupName = $item.resourceGroupName
    $accountName = $item.accountName
    $api = $item.api #nosql, cassandra, gremlin, mongodb, table
    $throughputType = $item.throughputType #manual, autoscale
    $resourceName = $item.resourceName
    $throughput = $item.throughput
    
    # Store database and container level names in an array. 
    $resourceArray = $resourceName.split("/")

    # When array.count -eq 2, it's dedicated throughput versus shared.
    if($resourceArray.Count -eq 2){
        $isDedicatedThroughput = $true
    }
    else {
        $isDedicatedThroughput = $false
    }

    Write-Host "Updating throughput on resource....."
    Write-Host "ResourceGroup = $resourceGroupName"
    Write-Host "Account = $accountName"
    Write-Host "Api = $api"
    Write-Host "Throughput Type = $throughputType"
    Write-Host "Resource Name = $resourceName"
    Write-Host "Throughput = $throughput"

    switch($api){
        "nosql"{
            if($isDedicatedThroughput){ #container level throughput

                # Ensure throughput is not set below the Minimum Throughput for the resource.
                $minThroughput = Get-AzCosmosDBSqlContainerThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -DatabaseName $resourceArray[0] -Name $resourceArray[1] | Select-Object -ExpandProperty MinimumThroughput

                if($minThroughput as [Int32] -gt $throughput as [Int32])
                {
                    Write-Host "Cannot set throughput to $throughput RU/s, below minimum throughput, setting to minimum allowed throughput, $minThroughput RU/s"
                    $throughput = $minThroughput -as [Int32]
                }

                # Set the Throughput
                if($throughputType -eq "manual"){
                    Update-AzCosmosDBSqlContainerThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -DatabaseName $resourceArray[0] -Name $resourceArray[1] -Throughput $throughput

                }
                else {
                    Update-AzCosmosDBSqlContainerThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -DatabaseName $resourceArray[0] -Name $resourceArray[1] -AutoscaleMaxThroughput $throughput
                }
            }
            else{ #database level throughput

                # Ensure throughput is not set below the Minimum Throughput for the resource.
                $minThroughput = Get-AzCosmosDBSqlDatabaseThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -Name $resourceArray[0] | Select-Object -ExpandProperty MinimumThroughput

                if($minThroughput as [Int32] -gt $throughput as [Int32])
                {
                    Write-Host "Cannot set throughput to $throughput RU/s, below minimum throughput, setting to minimum allowed throughput, $minThroughput RU/s"
                    $throughput = $minThroughput -as [Int32]
                }
                
                # Set the Throughput
                if($throughputType -eq "manual"){
                    Update-AzCosmosDBSqlDatabaseThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -Name $resourceArray[0] -Throughput $throughput
                }
                else {
                    Update-AzCosmosDBSqlDatabaseThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -Name $resourceArray[0] -AutoscaleMaxThroughput $throughput
                }
            }
        }
        "mongodb"{
            if($isDedicatedThroughput){ #collection level throughput

                # Ensure throughput is not set below the Minimum Throughput for the resource.
                $minThroughput = Get-AzCosmosDBMongoDBCollectionThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -DatabaseName $resourceArray[0] -Name $resourceArray[1] | Select-Object -ExpandProperty MinimumThroughput

                if($minThroughput as [Int32] -gt $throughput as [Int32])
                {
                    Write-Host "Cannot set throughput to $throughput RU/s, below minimum throughput, setting to minimum allowed throughput, $minThroughput RU/s"
                    $throughput = $minThroughput -as [Int32]
                }

                # Set the Throughput
                if($throughputType -eq "manual"){
                    Update-AzCosmosDBMongoDBCollectionThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -DatabaseName $resourceArray[0] -Name $resourceArray[1] -Throughput $throughput

                }
                else {
                    Update-AzCosmosDBMongoDBCollectionThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -DatabaseName $resourceArray[0] -Name $resourceArray[1] -AutoscaleMaxThroughput $throughput
                }
            }
            else{ #database level throughput

                # Ensure throughput is not set below the Minimum Throughput for the resource.
                $minThroughput = Get-AzCosmosDBMongoDBDatabaseThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -Name $resourceArray[0] | Select-Object -ExpandProperty MinimumThroughput

                if($minThroughput as [Int32] -gt $throughput as [Int32])
                {
                    Write-Host "Cannot set throughput to $throughput RU/s, below minimum throughput, setting to minimum allowed throughput, $minThroughput RU/s"
                    $throughput = $minThroughput -as [Int32]
                }
                
                # Set the Throughput
                if($throughputType -eq "manual"){
                    Update-AzCosmosDBMongoDBDatabaseThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -Name $resourceArray[0] -Throughput $throughput
                }
                else {
                    Update-AzCosmosDBMongoDBDatabaseThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -Name $resourceArray[0] -AutoscaleMaxThroughput $throughput
                }
            }
        }
        "cassandra"{
            if($isDedicatedThroughput){ #table level throughput

                # Ensure throughput is not set below the Minimum Throughput for the resource.
                $minThroughput = Get-AzCosmosDBCassandraTableThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -KeyspaceName $resourceArray[0] -Name $resourceArray[1] | Select-Object -ExpandProperty MinimumThroughput

                if($minThroughput as [Int32] -gt $throughput as [Int32])
                {
                    Write-Host "Cannot set throughput to $throughput RU/s, below minimum throughput, setting to minimum allowed throughput, $minThroughput RU/s"
                    $throughput = $minThroughput -as [Int32]
                }

                # Set the Throughput
                if($throughputType -eq "manual"){
                    Update-AzCosmosDBCassandraTableThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -KeyspaceName $resourceArray[0] -Name $resourceArray[1] -Throughput $throughput

                }
                else {
                    Update-AzCosmosDBCassandraTableThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -KeyspaceName $resourceArray[0] -Name $resourceArray[1] -AutoscaleMaxThroughput $throughput
                }
            }
            else{ #keyspace level throughput

                # Ensure throughput is not set below the Minimum Throughput for the resource.
                $minThroughput = Get-AzCosmosDBCassandraKeyspaceThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -Name $resourceArray[0] | Select-Object -ExpandProperty MinimumThroughput

                if($minThroughput as [Int32] -gt $throughput as [Int32])
                {
                    Write-Host "Cannot set throughput to $throughput RU/s, below minimum throughput, setting to minimum allowed throughput, $minThroughput RU/s"
                    $throughput = $minThroughput -as [Int32]
                }
                
                # Set the Throughput
                if($throughputType -eq "manual"){
                    Update-AzCosmosDBCassandraKeyspaceThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -Name $resourceArray[0] -Throughput $throughput
                }
                else {
                    Update-AzCosmosDBCassandraKeyspaceThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -Name $resourceArray[0] -AutoscaleMaxThroughput $throughput
                }
            }
        }
        "gremlin"{
            if($isDedicatedThroughput){ #graph level throughput

                # Ensure throughput is not set below the Minimum Throughput for the resource.
                $minThroughput = Get-AzCosmosDBGremlinGraphThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -DatabaseName $resourceArray[0] -Name $resourceArray[1] | Select-Object -ExpandProperty MinimumThroughput

                if($minThroughput as [Int32] -gt $throughput as [Int32])
                {
                    Write-Host "Cannot set throughput to $throughput RU/s, below minimum throughput, setting to minimum allowed throughput, $minThroughput RU/s"
                    $throughput = $minThroughput -as [Int32]
                }

                # Set the Throughput
                if($throughputType -eq "manual"){
                    Update-AzCosmosDBGremlinGraphThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -DatabaseName $resourceArray[0] -Name $resourceArray[1] -Throughput $throughput

                }
                else {
                    Update-AzCosmosDBGremlinGraphThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -DatabaseName $resourceArray[0] -Name $resourceArray[1] -AutoscaleMaxThroughput $throughput
                }
            }
            else{ #database level throughput

                # Ensure throughput is not set below the Minimum Throughput for the resource.
                $minThroughput = Get-AzCosmosDBGremlinDatabaseThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -Name $resourceArray[0] | Select-Object -ExpandProperty MinimumThroughput

                if($minThroughput as [Int32] -gt $throughput as [Int32])
                {
                    Write-Host "Cannot set throughput to $throughput RU/s, below minimum throughput, setting to minimum allowed throughput, $minThroughput RU/s"
                    $throughput = $minThroughput -as [Int32]
                }
                
                # Set the Throughput
                if($throughputType -eq "manual"){
                    Update-AzCosmosDBGremlinDatabaseThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -Name $resourceArray[0] -Throughput $throughput
                }
                else {
                    Update-AzCosmosDBGremlinDatabaseThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -Name $resourceArray[0] -AutoscaleMaxThroughput $throughput
                }
            }
        }
        "table"{
            #table level throughput

            # Ensure throughput is not set below the Minimum Throughput for the resource.
            $minThroughput = Get-AzCosmosDBTableThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -Name $resourceArray[0] | Select-Object -ExpandProperty MinimumThroughput

            if($minThroughput as [Int32] -gt $throughput as [Int32])
            {
                Write-Host "Cannot set throughput to $throughput RU/s, below minimum throughput, setting to minimum allowed throughput, $minThroughput RU/s"
                $throughput = $minThroughput -as [Int32]
            }
            
            # Set the Throughput
            if($throughputType -eq "manual"){
                Update-AzCosmosDBTableThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -Name $resourceArray[0] -Throughput $throughput
            }
            else {
                Update-AzCosmosDBTableThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -Name $resourceArray[0] -AutoscaleMaxThroughput $throughput
            }
        }
    }

    Write-Host "Throughput set on resource $resourceName in account $accountName using $throughputType throughput to $throughput RU/s`n`n"

}

# Write an information log with the current time.
Write-Host "Cosmos DB ScaleUpTrigger ran! TIME: $currentUTCtime"
