<#
    Koos Goossens 2023
    
    .DESCRIPTION
    Permission requirements:
    - Azure AD Application needs ThreatHunting.Read.All on Microsoft Graph.
    - User running this script should be Owner, or both contributor and User Access Administrator, on the Azure subscription.

    .PARAMETER tenantId [string]
    The Tenant ID of the Azure Active Directory in which the app registration and Azure subscription resides.
    .PARAMETER appId [string]
    The App ID of the application used to query Microsoft Graph to retrieve Defender table schemas.
    .PARAMETER appSecret [string]
    An active secret for the App Registration to query Microsoft Graph to retrieve Defender table schemas.
    .PARAMETER subscriptionId [string]
    Azure Subscription ID in which the archive resources should be deployed.
    .PARAMETER resourceGroupName [string]
    Name of the Resource Group in which archive resources should be deployed.
    .PARAMETER m365defenderTables [string]
    Comma-separated list of tables you want to setup an archive for. Keep in mind to user proper "PascalCase" for table names!
    If this parameter is not provided, the script will use all tables supported by streaming API, and will setup archival on all of them.
    .PARAMETER outputAdxScript [switch]
    Used for debugging purposes so that the script will output the ADX script on screen before it gets passed into the deployments.
    .PARAMETER saveAdxScript [switch]
    Use -savedAdxScript to write content of $adxScript to 'adxScript.kusto' file. File can be re-used with -useAdxScript parameter.
    .PARAMETER useAdxScript [string]
    Provide path to existing 'adxScript.kusto' file created by -saveAdxScript parameter.
    .PARAMETER skipPreReqChecks [switch]
    Skip Azure subscription checks like checking enabled resource providers and current permissions. Useful when using this script in a pipeline where you're already sure of these prerequisites.
    .PARAMETER noDeploy [switch]
    Used for debugging purposes so that the actual Azure deployment steps are skipped.
    .PARAMETER deploySentinelFunctions [switch]
    Use -deploySentinelFunctions to add optional step to the deployment process where (Sentinel) workspace functions are deployed (savedSearches) to be able to query ADX from Log Analytics / Sentinel UI.

#>

[CmdletBinding()]
param (
    [Parameter (Mandatory = $true)]
    [String] $SubscriptionId,

    [Parameter (Mandatory = $true)]
    [String] $WorkspaceName,

    [Parameter (Mandatory = $true)]
    [String] $PathToYamlFiles,

    [Parameter (Mandatory = $true)]
    [String] $ResourceGroupName,

    [Parameter (Mandatory = $false)]
    [Switch] $saveTemplate

)

$ErrorActionPreference = "Stop" # Stop on all errors
Set-StrictMode -Version Latest  # Stop on uninitialized variables

Clear-Host

# Function defined for displaying status messages in a nice and consistent way
function Write-Message {
    param (
        [String]    $type = "header",           # user either 'header', 'item' or 'counter'
        [String]    $icon = "-",                # icon to display in header. only used when $type = 'header'
        [Int32]     $level = 0,                 # defines the level of indentation
        [String]    $message,                   # message to display
        [Int32]     $countMax = 0,              # defines first number and current item. i.e. 16/##. only used when $type = 'counter'
        [Int32]     $countMin = 0,              # defines second number and total items. i.e. ##/20. only used when $type = 'counter'
        [String]    $color1 = "Magenta",        # color of brackets
        [String]    $color2 = "White",          # color of icons and numbers
        [String]    $color3 = "Gray"            # color of message
    )

    # Generate leading spaces
    if ($level -gt 0) {
        $spaces = 0
        do {
            Write-Host "      " -NoNewLine;
            $spaces ++
        } until (
            $spaces -eq $level
        )
    }
    

    Switch ($type) {
        'header'.ToLower() {
            Write-Host "[ " -ForegroundColor $color1 -NoNewLine; Write-Host $icon -ForegroundColor $color2 -NoNewLine; Write-Host " ] " -ForegroundColor $color1 -NoNewLine;
        }
        'counter'.ToLower() {
            Write-Host "[ " -ForegroundColor $color1 -NoNewLine; Write-Host $CountMin -ForegroundColor $color2 -NoNewLine; Write-Host " / " -ForegroundColor $color2 -NoNewLine; Write-Host $CountMax -ForegroundColor $color2 -NoNewLine; Write-Host " ] " -ForegroundColor $color1 -NoNewLine;
        }
        'item'.ToLower() {
            Write-Host "  └─  " -ForegroundColor $color2 -NoNewLine;
        }
    }

    # Generate message
    Write-Host "$message" -ForegroundColor $color3
}

# Settings colors for ASCII logo
$BackgroundColor    = "DarkGray"
$PrimaryColor       = "DarkRed"
$ForegroundColor    = "DarkGreen"
$HighlightColor     = "Magenta"
$FrameColor         = "White"
# Render ASCII logo
Write-Host "" -ForegroundColor $BackgroundColor
Write-Host "                                      ███████████▃▃" -ForegroundColor $BackgroundColor
Write-Host "                            █████  ███" -ForegroundColor $BackgroundColor -nonewline; Write-Host "░░░░░░░░░░░" -ForegroundColor $PrimaryColor -nonewline; Write-Host "██▀▀" -ForegroundColor $BackgroundColor
Write-Host "                        ████▒▒▒████" -ForegroundColor $BackgroundColor -nonewline; Write-Host "░░░░░░░░░░" -ForegroundColor $PrimaryColor -nonewline; Write-Host "████" -ForegroundColor $BackgroundColor
Write-Host "                      ██▒▒▒▒███" -ForegroundColor $BackgroundColor -nonewline; Write-Host "▒▒▒▒░░░░░░░" -ForegroundColor $PrimaryColor -nonewline; Write-Host "███" -ForegroundColor $BackgroundColor
Write-Host "                    ██▒▒████" -ForegroundColor $BackgroundColor -nonewline; Write-Host "▒▒▒▒▒▒▒▒▒░░░" -ForegroundColor $PrimaryColor -nonewline; Write-Host "██" -ForegroundColor $BackgroundColor
Write-Host "                     ███" -ForegroundColor $BackgroundColor -nonewline; Write-Host "▒▒▒▒▒▒▒▒▒▒▒▒▒░░░" -ForegroundColor $PrimaryColor -nonewline; Write-Host "██" -ForegroundColor $BackgroundColor
Write-Host "                 ████" -ForegroundColor $BackgroundColor -nonewline; Write-Host "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░" -ForegroundColor $PrimaryColor -nonewline; Write-Host "██" -ForegroundColor $BackgroundColor
Write-Host "              ███" -ForegroundColor $BackgroundColor -nonewline; Write-Host "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░" -ForegroundColor $PrimaryColor -nonewline; Write-Host "██" -ForegroundColor $BackgroundColor
Write-Host "          ████" -ForegroundColor $BackgroundColor -nonewline; Write-Host "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░" -ForegroundColor $PrimaryColor -nonewline; Write-Host "█" -ForegroundColor $BackgroundColor
Write-Host "     ▃▃███" -ForegroundColor $BackgroundColor -nonewline; Write-Host "▓▓█▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" -ForegroundColor $PrimaryColor -nonewline; Write-Host "████" -ForegroundColor $BackgroundColor
Write-Host "      ██" -ForegroundColor $BackgroundColor -nonewline; Write-Host "▓▓██▓▓█▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" -ForegroundColor $PrimaryColor -nonewline; Write-Host "▓███▒▒██" -ForegroundColor $BackgroundColor
Write-Host "       ██" -ForegroundColor $BackgroundColor -nonewline; Write-Host "▓▓█▓█▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" -ForegroundColor $PrimaryColor -nonewline; Write-Host "████▓▓▓▒▒▒▒██" -ForegroundColor $BackgroundColor
Write-Host "         ██" -ForegroundColor $BackgroundColor -nonewline; Write-Host "▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" -ForegroundColor $PrimaryColor -nonewline; Write-Host "██▓▓▓▓▓▓▓▓▓▒▒██" -ForegroundColor $BackgroundColor
Write-Host "           █" -ForegroundColor $BackgroundColor -nonewline; Write-Host "▓█▓▓█▒▒▒▒▒▒▒▒▒▒" -ForegroundColor $PrimaryColor -nonewline; Write-Host "▓▓▓▓██▒▒▒▒▓▓▓▒▒▒▒▒▒██" -ForegroundColor $BackgroundColor
Write-Host "            ██" -ForegroundColor $BackgroundColor -nonewline; Write-Host "█▓█▓█▓▒▒▒▒▒" -ForegroundColor $PrimaryColor -nonewline; Write-Host "███░░ ░░██▒▒▒▓▓▓▓▓▓▒▒▒██" -ForegroundColor $BackgroundColor
Write-Host "  ╔════════" -ForegroundColor $FrameColor -nonewline; Write-Host "  ██" -ForegroundColor $BackgroundColor -nonewline; Write-Host "▓█▓▓█▓█▒" -ForegroundColor $PrimaryColor -nonewline; Write-Host "██  " -ForegroundColor $BackgroundColor -nonewline; Write-Host "═════" -ForegroundColor $FrameColor -nonewline; Write-Host "  ██▒▒▒▒▒▓▓▓▓▓▒▒██ " -ForegroundColor $BackgroundColor -NoNewline; Write-Host " ═══════════════╗" -ForegroundColor $FrameColor
Write-Host "  ║" -ForegroundColor $FrameColor -nonewline; Write-Host "            █▓" -ForegroundColor $BackgroundColor -nonewline; Write-Host "█▓▓█▓" -ForegroundColor $PrimaryColor -nonewline; Write-Host "█░            █▓▒▒▒▒▒▓▓▓▒▒▒██" -ForegroundColor $BackgroundColor -NoNewline; Write-Host "                ║" -ForegroundColor $FrameColor
Write-Host "  ║" -ForegroundColor $FrameColor -nonewline; Write-Host "         `$`$" -ForegroundColor $ForegroundColor -nonewline; Write-Host "   █" -ForegroundColor $BackgroundColor -NoNewLine; Write-Host "██" -ForegroundColor $PrimaryColor -nonewline; Write-Host "██               ▓█▒▒▒▒▒▒▒▒▒▒▒" -ForegroundColor $BackgroundColor -nonewline; Write-Host "██" -ForegroundColor $BackgroundColor -NoNewline; Write-Host "               ║" -ForegroundColor $FrameColor
Write-Host "  ║" -ForegroundColor $FrameColor -nonewline; Write-Host "        /`$`$" -ForegroundColor $ForegroundColor -nonewline; Write-Host "    ▀▀        " -ForegroundColor $BackgroundColor -nonewline; Write-Host "/`$`$   /`$`$" -ForegroundColor $ForegroundColor -nonewline; Write-Host "  █" -ForegroundColor $BackgroundColor -nonewline; Write-Host "/`$`$" -ForegroundColor $ForegroundColor -NoNewline; Write-Host " ▒▒▒▒▒▒  " -ForegroundColor $BackgroundColor -NoNewline; Write-Host "/`$`$`$`$`$`$`$" -ForegroundColor $ForegroundColor -NoNewline; Write-Host "       ║" -ForegroundColor $FrameColor
Write-Host "  ║" -ForegroundColor $FrameColor -nonewline; Write-Host "      /`$`$`$`$`$`$           | `$`$ /`$`$`$`$  | `$`$ " -ForegroundColor $ForegroundColor -NoNewline; Write-Host "  ▒▒▒ " -ForegroundColor $BackgroundColor -NoNewline; Write-Host " | `$`$__  `$`$" -ForegroundColor $ForegroundColor -NoNewline; Write-Host "      ║" -ForegroundColor $FrameColor
Write-Host "  ║" -ForegroundColor $FrameColor -nonewline; Write-Host "     /`$`$__  `$`$  /`$`$`$`$`$`$ | `$`$|_  `$`$ /`$`$`$`$`$`$ " -ForegroundColor $ForegroundColor -NoNewline; Write-Host "  ▒▒" -ForegroundColor $BackgroundColor -NoNewline; Write-Host " | `$`$  \ `$`$" -ForegroundColor $ForegroundColor -NoNewline; Write-Host "      ║" -ForegroundColor $FrameColor
Write-Host "  ║" -ForegroundColor $FrameColor -nonewline; Write-Host "    | `$`$  \__/ /`$`$__  `$`$| `$`$  | `$`$|_  `$`$_/      | `$`$`$`$`$`$`$/" -ForegroundColor $ForegroundColor -NoNewline; Write-Host "      ║" -ForegroundColor $FrameColor
Write-Host "  ║" -ForegroundColor $FrameColor -nonewline; Write-Host "    |  `$`$`$`$`$`$ | `$`$  \ `$`$| `$`$  | `$`$  | `$`$ " -ForegroundColor $ForegroundColor -nonewline; Write-Host "▒█     " -ForegroundColor $BackgroundColor -nonewline; Write-Host "| `$`$__  `$`$" -ForegroundColor $ForegroundColor -NoNewline; Write-Host "      ║" -ForegroundColor $FrameColor
Write-Host "  ║" -ForegroundColor $FrameColor -nonewline; Write-Host "     \____  `$`$| `$`$  | `$`$| `$`$  | `$`$  | `$`$ /`$`$" -ForegroundColor $ForegroundColor -nonewline; Write-Host "█   " -ForegroundColor $BackgroundColor -nonewline; Write-Host "| `$`$  \ `$`$" -ForegroundColor $ForegroundColor -NoNewline; Write-Host "      ║" -ForegroundColor $FrameColor
Write-Host "  ║" -ForegroundColor $FrameColor -nonewline; Write-Host "     /`$`$  \ `$`$| `$`$`$`$`$`$`$/| `$`$ /`$`$`$`$`$`$|  `$`$`$`$/ " -ForegroundColor $ForegroundColor -nonewline; Write-Host "██" -ForegroundColor $BackgroundColor -nonewline; Write-Host " | `$`$ " -ForegroundColor $ForegroundColor -nonewline; Write-Host "▒" -ForegroundColor $BackgroundColor -nonewline; Write-Host "| `$`$" -ForegroundColor $ForegroundColor -nonewline; Write-Host "█" -ForegroundColor $BackgroundColor -NoNewline; Write-Host "     ║" -ForegroundColor $FrameColor
Write-Host "  ║" -ForegroundColor $FrameColor -nonewline; Write-Host "    |  `$`$`$`$`$`$/| `$`$____/ |__/|______/ \___/   " -ForegroundColor $ForegroundColor -nonewline; Write-Host "██▒" -ForegroundColor $BackgroundColor -nonewline; Write-Host "|__/  |_ " -ForegroundColor $ForegroundColor -nonewline; Write-Host "▒▓█" -ForegroundColor $BackgroundColor -nonewline; Write-Host "" -ForegroundColor $ForegroundColor -NoNewline; Write-Host "    ║" -ForegroundColor $FrameColor
Write-Host "  ║" -ForegroundColor $FrameColor -nonewline; Write-Host "     \_  `$`$_/ | `$`$                             " -ForegroundColor $ForegroundColor -nonewline; Write-Host "███     ▒▒▒▒▓█" -ForegroundColor $BackgroundColor -NoNewline; Write-Host "   ║" -ForegroundColor $FrameColor
Write-Host "  ║" -ForegroundColor $FrameColor -nonewline; Write-Host "       \ `$`$   | `$`$   for Azure Log Analytics &   " -ForegroundColor $ForegroundColor -nonewline; Write-Host "█  ▒▒▒▒▒▒▒▒██" -ForegroundColor $BackgroundColor -NoNewline; Write-Host "  ║" -ForegroundColor $FrameColor
Write-Host "  ║" -ForegroundColor $FrameColor -nonewline; Write-Host "       |__|   |__/            Microsoft Sentinel  " -ForegroundColor $ForegroundColor -nonewline; Write-Host "██▒▒▒▒▒▒▒▒▒██" -ForegroundColor $BackgroundColor
Write-Host "  ║" -ForegroundColor $FrameColor -nonewline; Write-Host "                                                   █▒▒▒▒▒▒▒▒▒▒▒██" -ForegroundColor $BackgroundColor
Write-Host "  ╚══════════════════════════════════════════════════" -ForegroundColor $FrameColor -nonewline; Write-Host " █▒▒▒▒▒▒▒▒▒▒▒  █▓" -ForegroundColor $BackgroundColor
Write-Host "                                                       ██▒▒▒▒▒▒▒     ▒█" -ForegroundColor $BackgroundColor
Write-Host "                   LET'S " -ForegroundColor $HighlightColor -nonewline; Write-Host "AXE" -ForegroundColor White -nonewline; Write-Host " THOSE LOGS! 🪓" -ForegroundColor $HighlightColor -nonewline; Write-Host "            ██▒▒▒▒          ██" -ForegroundColor $BackgroundColor
Write-Host "                                                       ██              ██" -ForegroundColor $BackgroundColor
Write-Host "                                                         ████        ▒█" -ForegroundColor $BackgroundColor
Write-Host "                                                             ████████▓" -ForegroundColor $BackgroundColor
Write-Host "" -ForegroundColor $BackgroundColor

# Check if authenticated to Azure
if ($null -eq (Get-AzContext)) { 
    Write-Host "Not authenticated to Azure yet! Please run Connect-AzAccount first." -ForegroundColor Yellow
    Write-Host "" -ForegroundColor Yellow
    exit 
}

# Make sure all PowerShell modules are installed
$modulesToInstall = @(
    'powershell-yaml'
)
Write-Message -icon "🔎" -message "Checking if required PowerShell modules are available..."
$modulesToInstall | ForEach-Object {
    if (-not (Get-Module -ListAvailable $_)) {
        Write-Message -type "item" -message "Module [$_] not found, installing..."
        try {
            Install-Module $_ -Force -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to install Yaml module: $($_.Exception.Message)"
            exit
        }
        Install-Module $_ -Force -ErrorAction Stop
    }
    else {
        Write-Message -type "item" -level 1 -message "Module [$_] already installed."
    }
}

$modulesToInstall | ForEach-Object {
    if (-not (Get-InstalledModule $_)) {
        Write-Message -type "item" -message "Module [$_] not loaded, importing..."
        try {
            Import-Module $_ -Force
        }
        catch {
            Write-Error "Failed to load Yaml module: $($_.Exception.Message)"
            exit
        }
        Import-Module $_ -Force
    }
    else {
        Write-Message -type "item" -level 1 -message "Module [$_] already loaded."
    }
}

try {
    # Get the access token
    $accessToken = (Get-AzAccessToken -ResourceUrl 'https://management.azure.com').Token
}
catch {
    Write-Error "Failed to get access token: $($_.Exception.Message)"
    exit
}

# Set the headers
$headers = @{
    'Authorization' = "Bearer $accessToken"
    "Content-Type"  = "application/json"
}

# Reset variables for template
$template = @{}
$resources = @()
$count = 1

try {
    # Get all YAML files from the directory
    Write-Host ""
    Write-Message -icon "🔎" -message "Looking for YAML files in $($PathToYamlFiles)..."
    $TransformationFiles = Get-ChildItem -Path "transformations/$WorkspaceName" -Filter '*.yml'
    if ($TransformationFiles.Count -eq 0) {
        Write-Message -icon "‼️" -message "No YAML files found in directory: $($PathToYamlFiles)" -color1 DarkRed -color2 Red
        exit
    }
    Write-Message -type "item" -message "Found $($TransformationFiles.Count) YAML files."
}
catch {
    Write-Error "Failed to get YAML files: $($_.Exception.Message)"
    exit
}


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
    outputs        = @{
        ResourceId = @{
            type  = "string"
            value = "[resourceId('Microsoft.Insights/dataCollectionRules', parameters('dcrName'))]"
        }
    }
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
}
catch {
    Write-Error "Failed to construct initial resources definition: $($_.Exception.Message)"
    exit
}
Write-Host ""
Write-Message -icon "🛠️" -message "Constructing Data Collection Rule..."

# Iterate over each YAML file
foreach ($File in $TransformationFiles) {
    try {
        Write-Host ""
        Write-Message -type "counter" -countMin $count -countMax $($TransformationFiles.Count) -level 1 -message "Processing file: $($File.Name)..."
        $FileContent = Get-Content -path $File.FullName -Raw | ConvertFrom-Yaml
    }
    catch {
        Write-Error "Failed to read or parse file: $($File.FullName)"
        continue
    }

    Write-Message -type "item" -level 3 -message "Table name  : $($FileContent.tableName)"

    # Pull in data of existing table via API to retrieve schema for example (only for splitting into basic logs custom table)
    if ($FileContent.basicEnabled) {
        Write-Message -type "item" -level 3 -message "Basic table : true"
        Write-Message -type "item" -level 4 -message "Retrieving original table headers..."
        $Uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.OperationalInsights/workspaces/$WorkspaceName/tables/$($FileContent.tablename)?api-version=2022-10-01"
        try {
            $Response = Invoke-RestMethod -Uri $Uri -Headers $headers
            $TableSchema = $response.properties.schema.standardColumns | Where-Object { $_.name -ne "TenantId" } | ConvertTo-Json -Depth 99     # Remove reserved "TenantId" column
        }
        catch {
            Write-Error "      Failed to retrieve table schema: $($_.Exception.Message)"
            continue
        }
    }
    Write-Message -type "item" -level 3 -message "Adding to Data Collection Rule template..."
    # Add custom table dependency to DCR deployment in template
    if ($FileContent.basicEnabled) {
        try {
            $dependsOn = "[concat(resourceId('Microsoft.OperationalInsights/workspaces', parameters('workspaceName')), '/tables/$($FileContent.tableName)_CL')]"
            $resources[0].dependsOn += $dependsOn
        }
        catch {
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
    }
    catch {
        Write-Error "Failed to add data flows: $($_.Exception.Message)"
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
                        plan                 = "Basic"
                        name                 = "$($FileContent.tableName)_CL"
                        schema               = @{
                            columns = $TableSchema | ConvertFrom-Json
                            name    = "$($FileContent.tableName)_CL"
                        }
                    }
                }
            }
        )
    }
    catch {
        Write-Error "Failed to construct resources property: $($_.Exception.Message)"
        continue
    }

    $count++

}

# Now that all tables and streams are processed, resources can be added to the template
try {
    $template.Add("resources", $resources)
}
catch {
    Write-Error "Failed to add resources to the template: $($_.Exception.Message)"
} 

# Save template to disk
if ($saveTemplate) {
    Write-Host ""
    Write-Message -icon "💾" -message "Saving template to file..."
    try {
        $template | ConvertTo-Json -Depth 99 | Out-File -FilePath "Workspace-DataCollectionRule-template.json"
        Write-Message -type "item" -message "Done!"
    }
    catch {
        Write-Message -type "item" -message "There was an issue writing the template to disk!" -color2 Red -color3 Red
    }
}

# Deploy the template
$deploymentName = "Workspace-DCR-$([System.Guid]::NewGuid().Guid)"
$resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName

$body = @{
    "properties" = @{
        "mode"     = "Incremental"
        "template" = $template
    }
}
$params = @{
    "Method"  = "Put"
    "Uri"     = "https://management.azure.com$($resourceGroup.ResourceId)/providers/Microsoft.Resources/deployments/$($deploymentName)?api-version=2022-09-01"
    "Headers" = $headers
    "Body"    = $body | ConvertTo-Json -Depth 99 -Compress
}
Write-Host ""
Write-Message -icon "🚀" -message "Deploying Data Collection Rule template as deployment '$($deploymentName)' ..."
$deployment = Invoke-RestMethod @params -UseBasicParsing

# Check deployment status ...
$params = @{
    "Method"  = "Get"
    "Uri"     = "https://management.azure.com$($resourceGroup.ResourceId)/providers/Microsoft.Resources/deployments/$($deploymentName)?api-version=2022-09-01"
    "Headers" = $headers
}
# Initiate deployment and wait for completion
do {
    Start-Sleep -Seconds 1
    $deployment = Invoke-RestMethod @params -UseBasicParsing
} while ($deployment.properties.provisioningState -in @("Accepted", "Created", "Creating", "Running", "Updating"))

# Display deployment status
if ($deployment.properties.provisioningState -eq "Succeeded") {
    Write-Message -icon "✅" -level 1 -message "Deployment '$($deploymentName)' completed with the status '$($deployment.properties.provisioningState)'" -color1 Green -color3 Green
    
    # Check if Data Collection Rule is associated with the workspace
    Write-Message -level 2 -message "Checking if Data Collection Rule is associated with the workspace..."

    $workspace = Get-AzOperationalInsightsWorkspace -Name "la-logging-01" -ResourceGroupName "rg-logging-01"
    If ($null -eq $workspace.DefaultDataCollectionRuleResourceId) {
        Write-Message -type "item" -level 2 -message "Setting 'DefaultDataCollectionRuleResourceId' on the workspace '$WorkspaceName'..."
        try {
            Set-AzOperationalInsightsWorkspace -Workspace $workspace -DefaultDataCollectionRuleResourceId $($deployment.properties.outputs.ResourceId.value) | Out-Null
        }
        catch {
            Write-Message -icon "‼️" -level 2 -message "There was an issue configuring the 'DefaultDataCollectionRuleResourceId' property on workspace $WorkspaceName!" -color1 DarkRed -color2 Red -color3 Red
        }
    } else {
        Write-Message -type "item" -level 2 -message "Data Collection Rule Association on '$WorkspaceName' already in place."
    }
} else {
    Write-Message -icon "‼️" -level 2 -message "There was an issue with the deployment. Status: '$($deployment.properties.provisioningState)'" -color1 DarkRed -color2 Red -color3 Red
}

Write-Host ""