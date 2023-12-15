[CmdletBinding()]
param (
    [Parameter (Mandatory = $true)]
    [String] $SubscriptionId,

    [Parameter (Mandatory = $true)]
    [String] $WorkspaceName,

    [Parameter (Mandatory = $true)]
    [String] $PathToYamlFiles,

    [Parameter (Mandatory = $true)]
    [String] $ResourceGroupName

)

Clear-Host

$BackgroundColor    = "DarkGray"
$PrimaryColor       = "DarkRed"
$ForegroundColor    = "DarkGreen"
$HighlightColor     = "Magenta"

Write-Host "" -ForegroundColor $BackgroundColor
Write-Host "                                    ███████████▃▃" -ForegroundColor $BackgroundColor
Write-Host "                          █████  ███" -ForegroundColor $BackgroundColor -nonewline; Write-Host "░░░░░░░░░░░" -ForegroundColor $PrimaryColor -nonewline; Write-Host "██▀▀" -ForegroundColor $BackgroundColor
Write-Host "                      ████▒▒▒████" -ForegroundColor $BackgroundColor -nonewline; Write-Host "░░░░░░░░░░" -ForegroundColor $PrimaryColor -nonewline; Write-Host "████" -ForegroundColor $BackgroundColor
Write-Host "                    ██▒▒▒▒███" -ForegroundColor $BackgroundColor -nonewline; Write-Host "▒▒▒▒░░░░░░░" -ForegroundColor $PrimaryColor -nonewline; Write-Host "███" -ForegroundColor $BackgroundColor
Write-Host "                  ██▒▒████" -ForegroundColor $BackgroundColor -nonewline; Write-Host "▒▒▒▒▒▒▒▒▒░░░" -ForegroundColor $PrimaryColor -nonewline; Write-Host "██" -ForegroundColor $BackgroundColor
Write-Host "                   ███" -ForegroundColor $BackgroundColor -nonewline; Write-Host "▒▒▒▒▒▒▒▒▒▒▒▒▒░░░" -ForegroundColor $PrimaryColor -nonewline; Write-Host "██" -ForegroundColor $BackgroundColor
Write-Host "               ████" -ForegroundColor $BackgroundColor -nonewline; Write-Host "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░" -ForegroundColor $PrimaryColor -nonewline; Write-Host "██" -ForegroundColor $BackgroundColor
Write-Host "            ███" -ForegroundColor $BackgroundColor -nonewline; Write-Host "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░" -ForegroundColor $PrimaryColor -nonewline; Write-Host "██" -ForegroundColor $BackgroundColor
Write-Host "        ████" -ForegroundColor $BackgroundColor -nonewline; Write-Host "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░" -ForegroundColor $PrimaryColor -nonewline; Write-Host "█" -ForegroundColor $BackgroundColor
Write-Host "   ▃▃███" -ForegroundColor $BackgroundColor -nonewline; Write-Host "▓▓█▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" -ForegroundColor $PrimaryColor -nonewline; Write-Host "████" -ForegroundColor $BackgroundColor
Write-Host "    ██" -ForegroundColor $BackgroundColor -nonewline; Write-Host "▓▓██▓▓█▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" -ForegroundColor $PrimaryColor -nonewline; Write-Host "▓███▒▒██" -ForegroundColor $BackgroundColor
Write-Host "     ██" -ForegroundColor $BackgroundColor -nonewline; Write-Host "▓▓█▓█▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" -ForegroundColor $PrimaryColor -nonewline; Write-Host "████▓▓▓▒▒▒▒██" -ForegroundColor $BackgroundColor
Write-Host "       ██" -ForegroundColor $BackgroundColor -nonewline; Write-Host "▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" -ForegroundColor $PrimaryColor -nonewline; Write-Host "██▓▓▓▓▓▓▓▓▓▒▒██" -ForegroundColor $BackgroundColor
Write-Host "         █" -ForegroundColor $BackgroundColor -nonewline; Write-Host "▓█▓▓█▒▒▒▒▒▒▒▒▒▒" -ForegroundColor $PrimaryColor -nonewline; Write-Host "▓▓▓▓██▒▒▒▒▓▓▓▒▒▒▒▒▒██" -ForegroundColor $BackgroundColor
Write-Host "          ██" -ForegroundColor $BackgroundColor -nonewline; Write-Host "█▓█▓█▓▒▒▒▒▒" -ForegroundColor $PrimaryColor -nonewline; Write-Host "███░░ ░░██▒▒▒▓▓▓▓▓▓▒▒▒██" -ForegroundColor $BackgroundColor
Write-Host "           ██" -ForegroundColor $BackgroundColor -nonewline; Write-Host "▓█▓▓█▓█▒" -ForegroundColor $PrimaryColor -nonewline; Write-Host "██         ██▒▒▒▒▒▓▓▓▓▓▒▒██" -ForegroundColor $BackgroundColor
Write-Host "             █▓" -ForegroundColor $BackgroundColor -nonewline; Write-Host "█▓▓█▓" -ForegroundColor $PrimaryColor -nonewline; Write-Host "█░            █▓▒▒▒▒▒▓▓▓▒▒▒██" -ForegroundColor $BackgroundColor
Write-Host "          `$`$" -ForegroundColor $ForegroundColor -nonewline; Write-Host "   █" -ForegroundColor $BackgroundColor -NoNewLine; Write-Host "██" -ForegroundColor $PrimaryColor -nonewline; Write-Host "██               ▓█▒▒▒▒▒▒▒▒▒▒▒" -ForegroundColor $BackgroundColor -nonewline; Write-Host "██" -ForegroundColor $BackgroundColor
Write-Host "         /`$`$" -ForegroundColor $ForegroundColor -nonewline; Write-Host "    ▀▀        " -ForegroundColor $BackgroundColor -nonewline; Write-Host "/`$`$   /`$`$" -ForegroundColor $ForegroundColor -nonewline; Write-Host "  █" -ForegroundColor $BackgroundColor -nonewline; Write-Host "/`$`$" -ForegroundColor $ForegroundColor -NoNewline; Write-Host " ▒▒▒▒▒▒  " -ForegroundColor $BackgroundColor -NoNewline; Write-Host "/`$`$`$`$`$`$`$" -ForegroundColor $ForegroundColor
Write-Host "       /`$`$`$`$`$`$           | `$`$ /`$`$`$`$  | `$`$ " -ForegroundColor $ForegroundColor -NoNewline; Write-Host "  ▒▒▒ " -ForegroundColor $BackgroundColor -NoNewline; Write-Host " | `$`$__  `$`$" -ForegroundColor $ForegroundColor
Write-Host "      /`$`$__  `$`$  /`$`$`$`$`$`$ | `$`$|_  `$`$ /`$`$`$`$`$`$ " -ForegroundColor $ForegroundColor -NoNewline; Write-Host "  ▒▒" -ForegroundColor $BackgroundColor -NoNewline; Write-Host " | `$`$  \ `$`$" -ForegroundColor $ForegroundColor
Write-Host "     | `$`$  \__/ /`$`$__  `$`$| `$`$  | `$`$|_  `$`$_/      | `$`$`$`$`$`$`$/" -ForegroundColor $ForegroundColor
Write-Host "     |  `$`$`$`$`$`$ | `$`$  \ `$`$| `$`$  | `$`$  | `$`$ " -ForegroundColor $ForegroundColor -nonewline; Write-Host "▒█     " -ForegroundColor $BackgroundColor -nonewline; Write-Host "| `$`$__  `$`$" -ForegroundColor $ForegroundColor
Write-Host "      \____  `$`$| `$`$  | `$`$| `$`$  | `$`$  | `$`$ /`$`$" -ForegroundColor $ForegroundColor -nonewline; Write-Host "█   " -ForegroundColor $BackgroundColor -nonewline; Write-Host "| `$`$  \ `$`$" -ForegroundColor $ForegroundColor
Write-Host "      /`$`$  \ `$`$| `$`$`$`$`$`$`$/| `$`$ /`$`$`$`$`$`$|  `$`$`$`$/ " -ForegroundColor $ForegroundColor -nonewline; Write-Host "██" -ForegroundColor $BackgroundColor -nonewline; Write-Host " | `$`$ " -ForegroundColor $ForegroundColor -nonewline; Write-Host "▒" -ForegroundColor $BackgroundColor -nonewline; Write-Host "| `$`$" -ForegroundColor $ForegroundColor -nonewline; Write-Host "█" -ForegroundColor $BackgroundColor
Write-Host "     |  `$`$`$`$`$`$/| `$`$____/ |__/|______/ \___/   " -ForegroundColor $ForegroundColor -nonewline; Write-Host "██▒" -ForegroundColor $BackgroundColor -nonewline; Write-Host "|__/  |_ " -ForegroundColor $ForegroundColor -nonewline; Write-Host "▒▓█" -ForegroundColor $BackgroundColor -nonewline; Write-Host "" -ForegroundColor $ForegroundColor
Write-Host "      \_  `$`$_/ | `$`$                             " -ForegroundColor $ForegroundColor -nonewline; Write-Host "███     ▒▒▒▒▓█" -ForegroundColor $BackgroundColor
Write-Host "        \ `$`$   | `$`$   for Azure Log Analytics &   " -ForegroundColor $ForegroundColor -nonewline; Write-Host "█  ▒▒▒▒▒▒▒▒██" -ForegroundColor $BackgroundColor
Write-Host "        |__|   |__/            Microsoft Sentinel  " -ForegroundColor $ForegroundColor -nonewline; Write-Host "██▒▒▒▒▒▒▒▒▒██" -ForegroundColor $BackgroundColor
Write-Host "                                                    █▒▒▒▒▒▒▒▒▒▒▒██" -ForegroundColor $BackgroundColor
Write-Host "                                                    █▒▒▒▒▒▒▒▒▒▒▒  █▓" -ForegroundColor $BackgroundColor
Write-Host "                                                     ██▒▒▒▒▒▒▒     ▒█" -ForegroundColor $BackgroundColor
Write-Host "                 LET'S AXE THOSE LOGS! 🪓" -ForegroundColor $HighlightColor -nonewline; Write-Host "            ██▒▒▒▒          ██" -ForegroundColor $BackgroundColor
Write-Host "                                                     ██              ██" -ForegroundColor $BackgroundColor
Write-Host "                                                       ████        ▒█" -ForegroundColor $BackgroundColor
Write-Host "                                                           ████████▓" -ForegroundColor $BackgroundColor
Write-Host "" -ForegroundColor $BackgroundColor

if((Get-AzContext) -eq $null) { 
    Write-Host "Not authenticated to Azure yet! Please run Connect-AzAccount first." -ForegroundColor Yellow
    exit 
}

$modulesToInstall = @(
        'powershell-yaml'
    )
    Write-Host "Installing/Importing PowerShell modules..."
    $modulesToInstall | ForEach-Object {
        if (-not (Get-Module -ListAvailable $_)) {
            Write-Host "   Module [$_] not found, installing..."
            try {
                Install-Module $_ -Force -ErrorAction Stop
            }
            catch {
                Write-Error "Failed to install Yaml module: $($_.Exception.Message)"
                exit
            }
            Install-Module $_ -Force -ErrorAction Stop
        } else {
            Write-Host "   Module [$_] already installed."
        }
    }

    $modulesToInstall | ForEach-Object {
        if (-not (Get-InstalledModule $_)) {
            Write-Host "   Module [$_] not loaded, importing..."
            try {
                Import-Module $_ -Force
            }
            catch {
                Write-Error "Failed to load Yaml module: $($_.Exception.Message)"
                exit
            }
            Import-Module $_ -Force
        } else {
            Write-Host "   Module [$_] already loaded."
        }
    }

try {
    # Get the access token
    $accessToken = (Get-AzAccessToken -ResourceUrl 'https://management.azure.com').Token
} catch {
    Write-Error "Failed to get access token: $($_.Exception.Message)"
    exit
}

try {
    # Set the headers
    $headers = @{
        'Authorization' = "Bearer $accessToken"
    }
} catch {
    Write-Error "Failed to set headers: $($_.Exception.Message)"
    exit
}

# Reset variables for template
$template   = @{}
$resources  = @()

try {
    # Get all YAML files from the directory
    $TransformationFiles = Get-ChildItem -Path "transformations/$WorkspaceName" -Filter '*.yml'
    if($TransformationFiles.Count -eq 0) {
        Write-Error "No YAML files found in directory: $($PathToYamlFiles)"
        exit
    }
} catch {
    Write-Error "Failed to get YAML files: $($_.Exception.Message)"
    exit
}

try {
    # Construct ARM template and add first properties
    $template = @{
        '$schema'      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
        contentVersion = "1.0.0.0"  
        parameters     = @{
            dcrName       = @{
                type         = "string"
                defaultValue = "dcr-" + $WorkspaceName        
            }
            workspaceName = @{
                type         = "string"
                defaultValue = $WorkspaceName
            }
        }
        variables      = @{
            workspaceResourceId = "[resourceId('Microsoft.OperationalInsights/workspaces', parameters('workspaceName'))]"
        }
    }
} catch {
    Write-Error "Failed to construct ARM template: $($_.Exception.Message)"
    exit
}

# Construct initial 'resources' definition for Data Collection Rule. More properties will be added dynamically later
try {
    $resources += @{
        name       = "[parameters('dcrName')]"
        type       = "Microsoft.Insights/dataCollectionRules"
        apiVersion = "2022-06-01"
        dependsOn  = @()
        location   = "[resourceGroup().location]"
        kind       = "WorkspaceTransforms"
        properties = @{
            dataSources  = @{}
            destinations = @{
                logAnalytics = @(
                    @{
                        workspaceResourceId = "[variables('workspaceResourceId')]"
                        name                = "[parameters('workspaceName')]"
                    }
                )
            }
            dataFlows    = @()
        }
    }
} catch {
    Write-Error "Failed to construct initial resources definition: $($_.Exception.Message)"
    exit
}
Write-Host ""
Write-Host "Constructing Data Collection Rule..."

# Iterate over each YAML file
foreach ($File in $TransformationFiles) {
    try {
        Write-Host ""
        Write-Host "   Processing file: $($File.Name)..."
        $FileContent = Get-Content -path $File.FullName -Raw | ConvertFrom-Yaml
    } catch {
        Write-Error "   Failed to read or parse file: $($File.FullName)"
        continue
    }

    Write-Host "      Table name  : $($FileContent.tableName)"

    # Pull in data of existing table via API to retrieve schema for example (only for splitting into basic logs custom table)
    if ($FileContent.basicEnabled) {
        Write-Host "      Basic table : true"
        Write-Host "         Retrieving original table headers..."
        $Uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.OperationalInsights/workspaces/$WorkspaceName/tables/$($FileContent.tablename)?api-version=2022-10-01"
        try {
            $Response = Invoke-RestMethod -Uri $Uri -Headers $headers
            $TableSchema = $response.properties.schema.standardColumns | Where-Object { $_.name -ne "TenantId" } | ConvertTo-Json -Depth 100     # Remove reserved "TenantId" column
        } catch {
            Write-Error "      Failed to retrieve table schema: $($_.Exception.Message)"
            continue
        }
    }
    Write-Host "      Adding to Data Collection Rule template..."
    # Add custom table dependency to DCR deployment in template
    if ($FileContent.basicEnabled) {
        try {
            $dependsOn = "[concat(resourceId('Microsoft.OperationalInsights/workspaces', parameters('workspaceName')), '/tables/$($FileContent.tableName)_CL')]"
            $resources[0].dependsOn += $dependsOn
        } catch {
            Write-Error "      Failed to add custom table dependency: $($_.Exception.Message)"
            continue
        }
    }
    
    # Add dataFlow(s) for this table
    try {
        $dataFlows = @(
            @{
                streams      = @(
                    "Microsoft-Table-$($FileContent.tableName)"
                )
                destinations = @(
                    "[parameters('workspaceName')]"
                )
                transformKql = $FileContent.analyticsTransform
            }
            if ($FileContent.basicEnabled) {
                @{
                    streams      = @(
                        "Microsoft-Table-$($FileContent.tableName)"
                    )
                    outputStream = "Custom-$($FileContent.tableName)_CL"
                    destinations = @(
                        "[parameters('workspaceName')]"
                    )
                    transformKql = $FileContent.basicTransform
                }
            }
        )
        $resources[0].properties.dataFlows += $dataFlows
    } catch {
        Write-Error "      Failed to add data flows: $($_.Exception.Message)"
        continue
    }

    # Contruct 'resources' property for this specific table(s) and add to 'resources' array
    try {
        $resources += @(
            @{
                id         = "[concat(resourceId('Microsoft.OperationalInsights/workspaces', parameters('workspaceName')), '/tables/$($FileContent.tableName)')]"
                name       = "[concat(parameters('workspaceName'), '/$($FileContent.tableName)')]"
                type       = "Microsoft.OperationalInsights/workspaces/tables"
                apiVersion = "2022-10-01"
                properties = @{
                    plan                 = "Analytics"
                    totalRetentionInDays = $FileContent.analyticsRetentionInDays
                }
            }
            if ($FileContent.basicEnabled) {
                @{
                    id         = "[concat(resourceId('Microsoft.OperationalInsights/workspaces', parameters('workspaceName')), '/tables/$($FileContent.tableName)_CL')]"
                    name       = "[concat(parameters('workspaceName'), '/$($FileContent.tableName)_CL')]"
                    type       = "Microsoft.OperationalInsights/workspaces/tables"
                    apiVersion = "2021-12-01-preview"
                    properties = @{
                        totalRetentionInDays = $FileContent.basicRetentionInDays
                        plan   = "Basic"
                        name                 = "$($FileContent.tableName)_CL"
                        schema = @{
                            columns              = $TableSchema | ConvertFrom-Json
                            name                 = "$($FileContent.tableName)_CL"
                        }
                    }
                }
            }
        )
    } catch {
        Write-Error "      Failed to construct resources property: $($_.Exception.Message)"
        continue
    }

}

# Now that all tables and streams are processed, resources can be added to the template
try {
    $template.Add("resources", $resources)
} catch {
    Write-Error "      Failed to add resources to the template: $($_.Exception.Message)"
} 

# Convert to JSON
try {
    $jsontemplate = $template | ConvertTo-Json -Depth 100
} catch {
    Write-Error "      Failed to convert template to JSON: $($_.Exception.Message)"
}

# Convert into hashtable
try{
    $finaltemplate = ConvertFrom-Json $jsontemplate -AsHashtable
} catch {
    Write-Error "      Failed to convert from Json $($_.Exception.Message)"
}

# Deploy the template
try {
    Write-Host ""
    Write-Host "Deploying Data Collection Rule template..."
    New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateObject $finaltemplate
    Write-Host ""
    Write-Host "Done!" -ForegroundColor Green
} catch {
    Write-Error "Failed to deploy template: $($_.Exception.Message)"
}