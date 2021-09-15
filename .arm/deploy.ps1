
Param (
    [string] $ResourceGroup = 'cosmosscale-c2c',
    [string] $Location = 'centralus',
    [string] $File = './environment.bicep',
    [string] $Account,
    $parameters = $null
)

if ($Account) {
    az account set -s $Account
}

if ($null -eq $parameters) {
    $parameters = @{}
}

$parameters = $parameters | ConvertTo-Json -Compress
$parameters = $parameters -Replace '"','\"'

# Create resource group
az group create -g $ResourceGroup --location $Location

# Create deployment
az deployment group create `
    -f $File `
    -g $ResourceGroup `
    --parameters $parameters `
    | ConvertFrom-Json

[Console]::ResetColor()