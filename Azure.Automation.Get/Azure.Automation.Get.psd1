@{

RootModule = 'Azure.Automation.Get.psm1'

ModuleVersion = '1.0.0.0'

GUID = 'c99aedfd-cb46-445c-9f7f-9e504ab44052'

Author = 'Microsoft Corporation'

CompanyName = 'Microsoft Corporation'

Copyright = '(c) Microsoft Corporation. All rights reserved.'

Description = @'

Cmdlets for publishing, discovering and saving the Azure Graph Runbooks.

The Publish-Runbook cmdlet will validate the graph runbok and publishes to the specified repository.

The Azure Graph Runbook can be deployed to the Azure Automation by clicking the 'Deploy to Azure Automation' button on PowerShell Gallery.

To publish an Azure Graph Runbook to the PowerShell Gallery, specify the metadata and your NuGetAPIKey the same way you use Publish-Module. 
The Publish-Runbook cmdlet validates the Azure Graph Runbook prior to publishing it.

An Azure Graph Runbook requires:
- A valid Graph Runbook file with the same name as the module name (i.e., <ModuleName>.graphrunbook)
- Metadata like Author, Description, ReleaseNotes, Tags, ProjectUri, etc.,
'@

PowerShellVersion = '3.0'

NestedModules = @()

RequiredAssemblies = ('Orchestrator.GraphRunbook.Model.dll')

FunctionsToExport = @('Publish-Runbook',
                      'Find-Runbook',
                      'Save-Runbook')

VariablesToExport = @()

AliasesToExport = @()

FileList = @('Azure.Automation.Get.psm1'
             'Azure.Automation.Get.Resource.psd1'
             'Orchestrator.GraphRunbook.Model.dll'
            )

RequiredModules = @('PowerShellGet')

}
