# This is a Pester test suite to validate the PowerShellGet cmdlets for Publish-Runbook
#
# Copyright (c) Microsoft Corporation, 2016

#if ( $PSVersionTable.PSVersion -lt '5.1' )
#{
#    return
#}

Import-Module "$PSScriptRoot\PSGetTestUtils.psm1" -WarningAction SilentlyContinue

$RepositoryName = 'LocalGallery'
$SourceLocation = "$PSScriptRoot\PSGalleryTestRepo"
$RegisteredINTRepo = $false
$SystemModulesPath = Join-Path -Path $PSHOME -ChildPath 'Modules'
$ProgramFilesModulesPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell\Modules"
$Script:RunbookFolder = "$PSScriptRoot\TestRunbooks"
$Script:TempSaveLocation = "$PSScriptRoot\TestSaveRepo"

Install-NuGetBinaries
Import-Module Azure.Automation.Get -Scope:Local -PassThru

if(-not (Test-Path -Path $SourceLocation -PathType Container))
{
    $null = New-Item -Path $SourceLocation -ItemType Directory -Force
}

if(-not (Test-Path -Path $Script:TempSaveLocation -PathType Container))
{
    $null = New-Item -Path $Script:TempSaveLocation -ItemType Directory -Force
}

$repo = Get-PSRepository -ErrorAction SilentlyContinue | 
            Where-Object {$_.SourceLocation.StartsWith($SourceLocation, [System.StringComparison]::OrdinalIgnoreCase)}
if($repo)
{
    $RepositoryName = $repo.Name
}
else
{
    Register-PSRepository -Name $RepositoryName -SourceLocation $SourceLocation -InstallationPolicy Trusted
    $RegisteredINTRepo = $true
}

Describe "PublishValidRunbook" -Tags 'BVT'{
   
    Context "When it's graphical runbook with manifest" {
        Publish-Runbook -Path "$Script:RunbookFolder\StartAzureRMVM" -Repository $RepositoryName -Description "Azure graph runbook test" -Author "Yuting" -Version 1.0
        It "Published the runbook"{
            $result = Find-Runbook -Name "StartAzureRMVM" -Repository $RepositoryName | Should Not BeNullOrEmpty
        }
        It "Has Runbook tag and AzureAutomation Tags"{
            $result = Find-Runbook -Name "StartAzureRMVM" -Repository $RepositoryName
            $ResultTags = $result.Tags | Where-Object {($_ -eq 'AzureAutomation') -or 
                                          ($_ -eq 'Runbook')}
            $ResultTags.Count | Should BeExactly 2
                                        
        }
        
    }
    Context "When it's graphical runbook without manifest" {
        Publish-Runbook -Path "$Script:RunbookFolder\AzureAutomationTutorial" -Repository $RepositoryName -Description "AzureAutomationTutorial" -Author "Yuting" -Version 1.0
        It "Published the runbook"{
            $result = Find-Runbook -Name "AzureAutomationTutorial" -Repository $RepositoryName | Should Not BeNullOrEmpty
        }
        RemoveItem "$Script:RunbookFolder\AzureAutomationTutorial\*.psd1"
    }

    Context "When the module has versions"{
        Publish-Runbook -Path "$Script:RunbookFolder\StopAzureRMVM\1.0" -Repository $RepositoryName -Description "StopAzureRMVM test folder" -Author "Yuting" -Version 1.0
        It "Published the runbook"{
            $result = Find-Runbook -Name "StopAzureRMVM" -Repository $RepositoryName | Should Not BeNullOrEmpty
        }
        Publish-Runbook -Path "$Script:RunbookFolder\StopAzureRMVM\1.1" -Repository $RepositoryName -Description "StopAzureRMVM test folder" -Author "Yuting"
        It "Published the runbook with higher version"{
            $result = Find-Runbook -Name "StopAzureRMVM" -Repository $RepositoryName -RequiredVersion 1.1 | Should Not BeNullOrEmpty
            $runbooks =  Find-Runbook -Name "StopAzureRMVM" -Repository $RepositoryName -AllVersions 
            $runbooks.Count | Should BeExactly 2
        }
    }

    Context "When it's graphic workflow runbook"{
        Publish-Runbook -Path "$Script:RunbookFolder\Find-EmptyResourceGroups" -Repository $RepositoryName -Description "Find-EmptyResourceGroups test workflow" -Author "Yuting" -Version 1.0
        It "Published the runbook"{
            $result = Find-Runbook -Name "Find-EmptyResourceGroups" -Repository $RepositoryName 
            $Tags = $result.Tags
            $ResultTags = $result.Tags | Where-Object {($_ -eq 'GraphicalPSWFRunbook')} 
            $ResultTags | Should Not BeNullOrEmpty
                                         
        }
    }

    Context "When the full path to runbook is specified"{
        Publish-Runbook -Path "$Script:RunbookFolder\Hello-WorldGraphical.graphrunbook" -Repository $RepositoryName -Description "Test path to graphrunbook" -Author "Yuting" -Version 1.0
        It "Published the runbook"{
            $result = Find-Runbook -Name "Hello-WorldGraphical" -Repository $RepositoryName 
            $Tags = $result.Tags
            $ResultTags = $result.Tags | Where-Object {($_ -eq 'GraphicalPSWFRunbook')} 
            $ResultTags | Should Not BeNullOrEmpty
                                         
        }
    }

    AfterAll{
         RemoveItem "$PSScriptRoot\PSGalleryTestRepo\*"
    }
}


Describe "PublishInValidRunbook" -Tags 'BVT'{
    Context "When the path is invalid" {
        { Publish-Runbook -Path "$Script:RunbookFolder\TestNonExistingPath" -Repository $RepositoryName -Description "Test non-existing path" -Author "Yuting" -Version 1.0 } | Should Throw
    }
    Context "When there is no .graphrunbook" {   
        { Publish-Runbook -Path "$Script:RunbookFolder\TestInvalidRunbookFolder" -Repository $RepositoryName -Description "Test module folder without runbook file" -Author "Yuting" -Version 1.0 } | Should Throw
    }   
    Context "When the graphrunbook is invalid" {   
        { Publish-Runbook -Path "$Script:RunbookFolder\Invalid-GraphicalRB" -Repository $RepositoryName -Description "Invalid .graphrunbook file" -Author "Yuting" -Version 1.0 } | Should Throw
    }
    AfterAll{
         RemoveItem "$PSScriptRoot\PSGalleryTestRepo\*"
    }
}

Describe "FindRunbook" -Tags 'BVT'{
    Context "Find an existing runbook" {
        Publish-Runbook -Path "$Script:RunbookFolder\AzureAutomationTutorial" -Repository $RepositoryName -Description "AzureAutomationTutorial test workflow" -Author "Yuting" -Version 1.0
        It "Will find the runbook"{
            $runbook = Find-Runbook -Name "AzureAutomationTutorial" 
            $runbook | Should Not BeNullOrEmpty
        }
    }
    Context "Find runbook that is workflow" {
        Publish-Runbook -Path "$Script:RunbookFolder\Find-EmptyResourceGroups" -Repository $RepositoryName -Description "Find-EmptyResourceGroups test workflow" -Author "Yuting" -Version 1.0
        It "can find the runbook with workflow tag"{
            $runbook = Find-Runbook -Name "Find-EmptyResourceGroups" -Tag "Workflow" | Should Not BeNullOrEmpty
        }
        It "can find the runbook with Azure Automation tag"{
            $runbook = Find-Runbook -Name "Find-EmptyResourceGroups" -Tag "AzureAutomation" | Should Not BeNullOrEmpty
        }
    }
    
    AfterAll{
         RemoveItem "$PSScriptRoot\PSGalleryTestRepo\*"
    }
}

Describe "SaveRunbook" -Tags 'BVT'{
    Context "Find a runbook and save it locally" {
        Publish-Runbook -Path "$Script:RunbookFolder\AzureAutomationTutorial" -Repository $RepositoryName -Description "AzureAutomationTutorial test workflow" -Author "Yuting" -Version 1.0
        It "Will find the runbook and save only the .graphrunbook"{
            Save-Runbook -Name AzureAutomationTutorial -Path $Script:TempSaveLocation
            Test-Path "$Script:TempSaveLocation\AzureAutomationTutorial.psd1" | Should Be $False
            Get-Item "$Script:TempSaveLocation\AzureAutomationTutorial.graphrunbook" | Should Be $True
        }
    }

    Context "Find a runbook base on the version and save it locally" {
        Publish-Runbook -Path "$Script:RunbookFolder\StopAzureRMVM\1.0" -Repository $RepositoryName -Description "StopAzureRMVM test folder" -Author "Yuting" 
        Publish-Runbook -Path "$Script:RunbookFolder\StopAzureRMVM\1.1" -Repository $RepositoryName -Description "StopAzureRMVM test folder" -Author "Yuting"
        It "Can find the higher version and save it"{
            Save-Runbook -Name StopAzureRMVM -Path $Script:TempSaveLocation
            Test-Path "$Script:TempSaveLocation\StopAzureRMVM.psd1" | Should Be $False
            Get-Item "$Script:TempSaveLocation\StopAzureRMVM.graphrunbook" | Should Be $True
        }
        It "Can find the specified version and save it"{
            Save-Runbook -Name StopAzureRMVM -Path $Script:TempSaveLocation -RequiredVersion 1.0
            Get-Item "$Script:TempSaveLocation\StopAzureRMVM.graphrunbook" | Should Be $True
        }
    }
    
    AfterAll{
         RemoveItem "$PSScriptRoot\PSGalleryTestRepo\*"
         RemoveItem "$Script:TempSaveLocation\*"
    }
}