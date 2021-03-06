#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Localized AzureAutomationPack.Resource.psd1
#
#########################################################################################

ConvertFrom-StringData @'
###PSLOC
        InvalidGraphRunbookFile=The graph runbook file '{0}' is invalid. Validation error: '{1}'.
        PathNotFound=Cannot find the path '{0}' because it does not exist.
        GraphRunbookFileIsMissing=Runbook file '{0}' is missing, ensure that your Azure Graph Runbook folder '{1}' contains '{0}' file.
        MissingGraphRunbookManifestFile=Runbook manifest file '{0}' is missing. Use New-AzureGraphRunbookManifest cmdlet to create the Azure Graph Runbook manifest file.
        DescriptionParameterIsRequired=Description is required for publishing the Runbook '{0}'. Try again after specifying the Description parameter.

        UpdateToValidateTheTemplateFile=Unable to validate the root template file.
        TemplateFileNameAndAutomationPackFolderNameShouldBeSame=Template file name '{0}' and Azure Automation Pack folder name '{1}' is not same, ensure that both are same.
        TemplateFileIsMissing='{0}' file is missing, ensure that your Azure Automation Pack folder contains '{0}' file.
        TemplateParameterFileIsMissing='{0}' file is missing, ensure that your Azure Automation Pack folder contains '{0}' file.
        ExistingAutomationPackManifest=Azure Automation Pack manifest file '{0}' already exists. Use Update-AzureAutomationPackManifest cmdlet to update the Azure Automation Pack manifest file.
        
        VatidatingTheRootTemplate=Validating the root template file '{0}'.
###PSLOC
'@
