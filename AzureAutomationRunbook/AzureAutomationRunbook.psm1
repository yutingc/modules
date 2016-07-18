
#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# AzureGraphRunbook Module
#
#########################################################################################

Microsoft.PowerShell.Core\Set-StrictMode -Version Latest

Microsoft.PowerShell.Utility\Import-LocalizedData  LocalizedData -filename AzureAutomationRunbook.Resource.psd1

#region *-Runbook cmdlets
function Publish-Runbook
{
    <#
    .ExternalHelp AzureGraphRunbook.psm1-help.xml
    #>
    [CmdletBinding(SupportsShouldProcess=$true,
                   PositionalBinding=$false)]
    Param
    (
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $NuGetApiKey,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Repository,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Version]
        $Version,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Author,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Guid]
        $Guid,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $CompanyName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Copyright,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Tags,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $ProjectUri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $LicenseUri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $IconUri,

        [Parameter()]
        [string]
        $ReleaseNotes
    )

    Process
    {
        <#
            Publishes the specified graph runbook to the target repository.

            Following operations are performed by the Publish-AzureGraphRunbook cmdlet:
            -	Checks for the existence of <Name>.graphrunbook file and folder name should be <Name>
            -	Validates the .graphrunbook file contents.
            -	Creates or Updates the PowerShell module manifest file using specified metadata parameters.
            -	Validates the existence of specified repository name. 
            -   NuGetApiKey is required for a web-based repository.
            -	Graph runbook folder will be published to the specified repository
        #>

        $ev = $null        
        $repo = PowerShellGet\Get-PSRepository -Name $Repository -ErrorVariable ev
        if($ev)
        {
            return
        }

        $GraphRunbookBase = Validate-AzureGraphRunbookFolder -Path $Path -CallerPSCmdlet $PSCmdlet

        if($GraphRunbookBase)
        {
            if($Repository)
            {
                $null = $PSBoundParameters.Remove('Repository')
            }

            if($NuGetApiKey)
            {
                $null = $PSBoundParameters.Remove('NuGetApiKey')
            }


            $GraphRunbookName = Split-Path -Path $GraphRunbookBase -Leaf
            $ModulePathWithVersion = $false
        
            # if the Leaf of the $resolvedPath is a version, use its parent folder name as the module name
            $ModuleVersion = New-Object System.Version
            if([System.Version]::TryParse($GraphRunbookName, ([ref]$ModuleVersion)))
            {
                $GraphRunbookName = Microsoft.PowerShell.Management\Split-Path -Path (Microsoft.PowerShell.Management\Split-Path $GraphRunbookBase -Parent) -Leaf
                $modulePathWithVersion = $true
            }

            $GraphRunbookFileName = "$GraphRunbookName.graphrunbook"
            $ManifestFileName = "$GraphRunbookName.psd1"

            $GraphRunbookFilePath = Join-Path -Path $GraphRunbookBase -ChildPath $GraphRunbookFileName
            $ManifestFilePath = Join-Path -Path $GraphRunbookBase -ChildPath $ManifestFileName

            $ev = $null

            if((Microsoft.PowerShell.Management\Test-Path -Path $ManifestFilePath -PathType Leaf) -and
               (Microsoft.PowerShell.Core\Test-ModuleManifest -Path $ManifestFilePath -ErrorAction SilentlyContinue))
            {
                Update-AzureGraphRunbookManifest @PSBoundParameters -ErrorVariable ev
            }
            else
            {
                if(-not $Description)
                {                    
                    $message = $LocalizedData.DescriptionParameterIsRequired -f ($GraphRunbookBase)
                    ThrowError -ExceptionName 'System.ArgumentException' `
                               -ExceptionMessage $message `
                               -ErrorId 'DescriptionParameterIsRequired' `
                               -CallerPSCmdlet $PSCmdlet `
                               -ErrorCategory InvalidArgument `
                               -ExceptionObject $GraphRunbookBase
                    return
                }
                if($modulePathWithVersion)
                {
                    $PSBoundParameters['Version'] = $ModuleVersion
                }
                New-AzureGraphRunbookManifest @PSBoundParameters -ErrorVariable ev
            }

            #if($ev)
            #{
            #   return
            #}
        }

        $publishParameters = @{Path = $Path}
        if($Repository)
        {
            $publishParameters['Repository'] = $Repository
        }

        if($NuGetApiKey)
        {
            $publishParameters['NuGetApiKey'] = $NuGetApiKey
        }        

        if(Validate-AzureGraphRunbookFolder -Path $Path -ValidateManifest -CallerPSCmdlet $PSCmdlet)
        {
            $test = $publishParameters
            PowerShellGet\Publish-Module @publishParameters `
                                         -Verbose:$VerbosePreference `
                                         -Debug:$DebugPreference `
                                         -WarningAction $WarningPreference `
                                         -ErrorAction $ErrorActionPreference
        }
    }
}

function Find-Runbook
{
    <#
    .ExternalHelp AzureGraphRunbook.psm1-help.xml
    #>
    [CmdletBinding()]
    [outputtype("PSCustomObject[]")]
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Name,

        [Parameter()]
        [ValidateNotNull()]
        [Version]
        $MinimumVersion,

        [Parameter()]
        [ValidateNotNull()]
        [Version]
        $MaximumVersion,
        
        [Parameter()]
        [ValidateNotNull()]
        [Version]
        $RequiredVersion,

        [Parameter()]
        [switch]
        $AllVersions,

        [Parameter()]
        [ValidateNotNull()]
        [string]
        $Filter,
        
        [Parameter()]
        [ValidateNotNull()]
        [string[]]
        $Tag,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Repository
    )

    Begin
    {
    }

    Process
    {
        if(-not $Tag)
        {
            $Tag = @()
        }

        $Tag += 'Runbook'
        $PSBoundParameters['Tag'] = $Tag

        PowerShellGet\Find-Module @PSBoundParameters | Where-Object {($_.Tags -contains 'Runbook')}
    }
}

function Save-Runbook
{
    <#
    .ExternalHelp AzureGraphRunbook.psm1-help.xml
    #>
    [CmdletBinding(DefaultParameterSetName='NameAndPathParameterSet',                   
                   SupportsShouldProcess=$true)]
    Param
    (
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName='NameAndPathParameterSet')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Name,

        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName='InputOjectAndPathParameterSet')]
        [ValidateNotNull()]
        [PSCustomObject[]]
        $InputObject,

        [Parameter(ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='NameAndPathParameterSet')]
        [ValidateNotNull()]
        [Version]
        $MinimumVersion,

        [Parameter(ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='NameAndPathParameterSet')]
        [ValidateNotNull()]
        [Version]
        $MaximumVersion,
        
        [Parameter(ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='NameAndPathParameterSet')]
        [ValidateNotNull()]
        [Version]
        $RequiredVersion,

        [Parameter(ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='NameAndPathParameterSet')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Repository,

        [Parameter(Mandatory=$true, ParameterSetName='NameAndPathParameterSet')]
        [Parameter(Mandatory=$true, ParameterSetName='InputOjectAndPathParameterSet')]
        [string]
        $Path,

        [Parameter()]
        [switch]
        $Force
    )

    Process
    {
        $Null = $PSBoundParameters.Remove("Path")
        $RunbookToSave= Find-Runbook @PSBoundParameters  
        $PSBoundParameters['Path'] = $Path
        PowerShellGet\Save-Module @PSBoundParameters
    }
}

#endregion *-AzureGraphRunbook cmdlets


function Validate-AzureGraphRunbook
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $RunbookFilePath
    )

    Process
    {
        if(-not (Microsoft.PowerShell.Management\Test-Path -Path $RunbookFilePath -PathType Leaf))
        {            
            $message = $LocalizedData.PathNotFound -f ($RunbookFilePath)
            ThrowError -ExceptionName 'System.ArgumentException' `
                       -ExceptionMessage $message `
                       -ErrorId 'TemplateFilePathNotFound' `
                       -CallerPSCmdlet $PSCmdlet `
                       -ErrorCategory InvalidArgument `
                       -ExceptionObject $RunbookFilePath
            return
        }

        $SerializedRunbook = Microsoft.PowerShell.Management\Get-Content -Path $RunbookFilePath -Force
        $RunbookContainer = $null
        try
        {
            $RunbookContainer = [Orchestrator.GraphRunbook.Model.Serialization.RunbookSerializer]::DeserializeRunbookContainer($SerializedRunbook)
            $GraphRunbook = [Orchestrator.GraphRunbook.Model.Serialization.RunbookSerializer]::GetRunbook($RunbookContainer)
        }
        catch
        {
            $message = $LocalizedData.InvalidGraphRunbookFile -f ($RunbookFilePath, "$_")
            ThrowError -ExceptionName 'System.ArgumentException' `
                       -ExceptionMessage $message `
                       -ErrorId 'InvalidGraphRunbookFile' `
                       -CallerPSCmdlet $PSCmdlet `
                       -ErrorCategory InvalidArgument `
                       -ExceptionObject $RunbookFilePath
            return            
        }

        $Tags = @()
        
        if($RunbookContainer -and $RunbookContainer.RunbookType)
        {
            $Tags += "$($RunbookContainer.RunbookType)"
        }
        else
        {
            # Default runbook type is Graph Runbook Workflow
            $Tags += 'GraphicalPSWFRunbook','Workflow'
        }
        if(-not ($Tags -Contains "Runbook"))
        {
            $Tags += 'Runbook'
        }
        if(-not ($Tags -Contains "AzureAutomation"))
        {
            $Tags += 'AzureAutomation'
        }

        return $Tags
    }
}

function Validate-AzureGraphRunbookFolder
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter()]
        [switch]
        $ValidateManifest,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $CallerPSCmdlet
    )

    Process
    {
        $GraphRunbookPath =Resolve-PathHelper -Path $Path -CallerPSCmdlet $PSCmdlet | Microsoft.PowerShell.Utility\Select-Object -First 1

        if(-not $GraphRunbookPath -or -not (Microsoft.PowerShell.Management\Test-Path -Path $GraphRunbookPath -PathType Container))
        {
            if(-not $GraphRunbookPath -or -not (Microsoft.PowerShell.Management\Test-Path -LiteralPath $GraphRunbookPath -PathType Container))
            {
                $message = $LocalizedData.PathNotFound -f ($Path)
                ThrowError -ExceptionName 'System.ArgumentException' `
                           -ExceptionMessage $message `
                           -ErrorId 'GraphRunbookPathNotFound' `
                           -CallerPSCmdlet $CallerPSCmdlet `
                           -ErrorCategory InvalidArgument `
                           -ExceptionObject $Path

                return
            }
        }

        $GraphRunbookName = Microsoft.PowerShell.Management\Split-Path -Path $GraphRunbookPath -Leaf
        $ModulePathWithVersion = $false
        
        # if the Leaf of the $resolvedPath is a version, use its parent folder name as the module name
        $ModuleVersion = New-Object System.Version
        if([System.Version]::TryParse($GraphRunbookName, ([ref]$ModuleVersion)))
        {
            $GraphRunbookName = Microsoft.PowerShell.Management\Split-Path -Path (Microsoft.PowerShell.Management\Split-Path $GraphRunbookPath -Parent) -Leaf
            $modulePathWithVersion = $true
        }

        $GraphRunbookFilePath = Join-Path -Path $GraphRunbookPath -ChildPath "$GraphRunbookName.graphrunbook"

        if(-not (Microsoft.PowerShell.Management\Test-Path -Path $GraphRunbookFilePath -PathType Leaf))
        {
            $message = $LocalizedData.GraphRunbookFileIsMissing -f ($GraphRunbookFilePath, $Path)
            ThrowError -ExceptionName 'System.ArgumentException' `
                       -ExceptionMessage $message `
                       -ErrorId 'GraphRunbookFileIsMissing' `
                       -CallerPSCmdlet $CallerPSCmdlet `
                       -ErrorCategory InvalidArgument `
                       -ExceptionObject $GraphRunbookFilePath
            return
        }

        return $GraphRunbookPath
    }
}

function New-AzureGraphRunbookManifest
{
    <#
    .ExternalHelp AzureGraphRunbook.psm1-help.xml
    #>
    [CmdletBinding(SupportsShouldProcess=$true,
                   PositionalBinding=$false)]
    Param
    (
        [Parameter(Mandatory=$true,
                   Position=0,                    
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Version]
        $Version,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Author,

        [ValidateNotNullOrEmpty()]
        [Guid]
        $Guid,

        [Parameter()] 
        [ValidateNotNullOrEmpty()]
        [String]
        $CompanyName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Copyright,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Tags,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $ProjectUri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $LicenseUri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $IconUri,

        [Parameter()]
        [string]
        $ReleaseNotes
    )

    Process
    {
        if($Version)
        {
            $PSBoundParameters['ModuleVersion'] = $Version
            $null = $PSBoundParameters.Remove('Version')
        }

        $ModuleBasePath = Validate-AzureGraphRunbookFolder -Path $Path -CallerPSCmdlet $PSCmdlet

        if(-not $ModuleBasePath)
        {
            return
        }

        $GraphRunbookName = Split-Path -Path $ModuleBasePath -Leaf

        # if the Leaf of the $resolvedPath is a version, use its parent folder name as the module name
        $ModuleVersion = New-Object System.Version
        if([System.Version]::TryParse($GraphRunbookName, ([ref]$ModuleVersion)))
        {
            $GraphRunbookName = Microsoft.PowerShell.Management\Split-Path -Path (Microsoft.PowerShell.Management\Split-Path $ModuleBasePath -Parent) -Leaf
            $modulePathWithVersion = $true
        }
        
        $GraphRunbookFileName = "$GraphRunbookName.graphrunbook"
        $ManifestFileName = "$GraphRunbookName.psd1"

        $GraphRunbookFilePath = Join-Path -Path $ModuleBasePath -ChildPath $GraphRunbookFileName
        $ManifestFilePath = Join-Path -Path $ModuleBasePath -ChildPath $ManifestFileName

        $PSBoundParameters['FileList'] = @($ManifestFileName, $GraphRunbookFileName)
        $PSBoundParameters['Path'] = $ManifestFilePath

        $RunbookTags = Validate-AzureGraphRunbook -RunbookFilePath $GraphRunbookFilePath

        if(-not $RunbookTags)
        {
            return
        }
        
        $Tags += @('AzureAutomation', 'Runbook')
        $Tags += $RunbookTags

        $PSBoundParameters['Tags'] = $Tags | Select-Object -Unique

        Microsoft.PowerShell.Core\New-ModuleManifest @PSBoundParameters
    }
}

function Update-AzureGraphRunbookManifest
{
    <#
    .ExternalHelp AzureGraphRunbook.psm1-help.xml
    #>
    [CmdletBinding(SupportsShouldProcess=$true,
                   PositionalBinding=$false)]
    Param
    (
        [Parameter(Mandatory=$true,
                   Position=0,                    
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [ValidateNotNullOrEmpty()]
        [Guid]
        $Guid,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Author,

        [Parameter()] 
        [ValidateNotNullOrEmpty()]
        [String]
        $CompanyName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Copyright,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Version]
        $Version,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Tags,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $ProjectUri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $LicenseUri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $IconUri,

        [Parameter()]
        [string]
        $ReleaseNotes
    )

    Process
    {
        if($Version)
        {
            $PSBoundParameters['ModuleVersion'] = $Version
            $null = $PSBoundParameters.Remove('Version')
        }

        $ModuleBasePath = Validate-AzureGraphRunbookFolder -Path $Path -ValidateManifest -CallerPSCmdlet $PSCmdlet

        if(-not $ModuleBasePath)
        {
            return
        }

        $GraphRunbookName = Split-Path -Path $ModuleBasePath -Leaf
        $ModulePathWithVersion = $false
        
        # if the Leaf of the $resolvedPath is a version, use its parent folder name as the module name
        $ModuleVersion = New-Object System.Version
        if([System.Version]::TryParse($GraphRunbookName, ([ref]$ModuleVersion)))
        {
            $GraphRunbookName = Microsoft.PowerShell.Management\Split-Path -Path (Microsoft.PowerShell.Management\Split-Path $ModuleBasePath -Parent) -Leaf
            $modulePathWithVersion = $true
        }
        
        $GraphRunbookFileName = "$GraphRunbookName.graphrunbook"
        $ManifestFileName = "$GraphRunbookName.psd1"

        $GraphRunbookFilePath = Join-Path -Path $ModuleBasePath -ChildPath $GraphRunbookFileName
        $ManifestFilePath = Join-Path -Path $ModuleBasePath -ChildPath $ManifestFileName
        
        $PSBoundParameters['FileList'] = @($ManifestFileName, $GraphRunbookFileName)
        $PSBoundParameters['Path'] = $ManifestFilePath

        if(-not $Tags)
        {
            $moduleInfo = Microsoft.PowerShell.Core\Test-ModuleManifest -Path $ManifestFilePath

            # Remove the existing graph runbook resource tags, so that updated resource tags will be added later
            if($moduleInfo -and $moduleInfo.Tags)
            {
                $Tags = $moduleInfo.Tags | Where-Object {
                                                            ($_ -ne 'GraphPowerShell') -and 
                                                            ($_ -ne 'GraphPowerShellWorkflow')
                                                        }
            }
        }
        else
        {
            $Tags += @('AzureAutomation')
        }

        $RunbookTags = Validate-AzureGraphRunbook -RunbookFilePath $GraphRunbookFilePath

        if(-not $RunbookTags)
        {
            return
        }

        $Tags += $RunbookTags
        $PSBoundParameters['Tags'] = $Tags | Select-Object -Unique
        $PSBoundParameters['Path'] = $ManifestFilePath
        $test = $PSBoundParameters
        PowerShellGet\Update-ModuleManifest @PSBoundParameters
    }
}

#region Common functions

# Utility to throw an errorrecord
function ThrowError
{
    param
    (        
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $CallerPSCmdlet,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]        
        $ExceptionName,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ExceptionMessage,
        
        [System.Object]
        $ExceptionObject,
        
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ErrorId,

        [parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorCategory]
        $ErrorCategory
    )
        
    $exception = New-Object $ExceptionName $ExceptionMessage;
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $ErrorId, $ErrorCategory, $ExceptionObject    
    $CallerPSCmdlet.ThrowTerminatingError($errorRecord)
}

# Utility to support resolve full path
function Resolve-PathHelper
{
    param 
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $path,

        [Parameter()]
        [switch]
        $isLiteralPath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $callerPSCmdlet
    )
    
    $resolvedPaths =@()

    foreach($currentPath in $path)
    {
        try
        {
            if($isLiteralPath)
            {
                $currentResolvedPaths = Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $currentPath -ErrorAction Stop
            }
            else
            {
                $currentResolvedPaths = Microsoft.PowerShell.Management\Resolve-Path -Path $currentPath -ErrorAction Stop
            }
        }
        catch
        {
            $errorMessage = ($LocalizedData.PathNotFound -f $currentPath)
            ThrowError  -ExceptionName "System.InvalidOperationException" `
                        -ExceptionMessage $errorMessage `
                        -ErrorId "PathNotFound" `
                        -CallerPSCmdlet $callerPSCmdlet `
                        -ErrorCategory InvalidOperation
        }

        foreach($currentResolvedPath in $currentResolvedPaths)
        {
            $resolvedPaths += $currentResolvedPath.ProviderPath
        }
    }

    $resolvedPaths
}

#endregion

Export-ModuleMember -Function 'Publish-Runbook',
                              'Find-Runbook',
                              'Save-Runbook'
