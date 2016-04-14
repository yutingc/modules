<#
.SYNOPSIS
    Downloads a specific blob in an Azure Storage container or all blobs in the container to a local directory

.DESCRIPTION
    Downloads a specific blob in an Azure Storage container or all blobs in the container to a local directory.
    If the Blob property is not set, then all of the blobs in the container are downloaded to the local directory.
    You can use the Blob property to get just a single file or everything under a directory in the container.

    If the local file does not match the file in the Azure Storage container, then it will be downloaded, otherwise it will not download the file.

.PARAMETER NodeName
    Array of nodes for this configuration. Defaults to localhost if none are passed in.

.PARAMETER StorageAccountName
    The name of the storage account

.PARAMETER StorageAccountKey
    The storgage account key for this storage account. You can run Get-AzureRmStorageAccountKey to get the key for the storage account.

.PARAMETER StorageAccountContainer
    The name of the storage account container

.PARAMETER Blob
    The specific blob or directory in the container to download. All contents in the container are download if this property is not included. Optional Parameter.

.EXAMPLE
    SampleAzureStorageStorageConfig  -Path "c:\localdirectory" -Blob "StorageDir/BlobFile"  -StorageAccountName "yourstorageaccount" -StorageAccountContainer "yourstoragecontainer"  -StorageAccountKey "aaabbbcco+CByOCS5/8abc6MkZEjaddddjU8APAoO4pyNXw+6U5nGJcddKKOWm8SvPvARQ==" 

    Start-DscConfiguration -Path .\SampleAzureStorageStorageConfig -Wait -Force -Verbose

.EXAMPLE
    SampleAzureStorageStorageConfig -Path "c:\localdirectory" -StorageAccountName "yourstorageaccount" -StorageAccountContainer "yourstoragecontainer"  -StorageAccountKey "aaabbbcco+CByOCS5/8abc6MkZEjaddddjU8APAoO4pyNXw+6U5nGJcddKKOWm8SvPvARQ==" 

    Start-DscConfiguration -Path .\SampleAzureStorageStorageConfig -Wait -Force -Verbose


.NOTES
    AUTHOR: Eamon O'Reilly
    LASTEDIT: March 18th, 2016 
#>

Configuration SampleAzureStorageStorageConfig { 
    param ( 
        [string[]]$NodeName = 'localhost',
        [parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [parameter(Mandatory = $true)]
        [System.String]
        $StorageAccountName,

        [parameter(Mandatory = $true)]
        [System.String]
        $StorageAccountKey,

        [parameter(Mandatory = $true)]
        [System.String]
        $StorageAccountContainer,

        [parameter(Mandatory = $false)]
        [System.String]
        $Blob = $null
          
    ) 
 
    Import-DscResource -Module cAzureStorage  -ModuleVersion 1.0.0.0
 
    Node $NodeName { 
 
        cAzureStorage SampleConfig {
            Path                    = $Path
            StorageAccountName      = $StorageAccountName
            StorageAccountContainer = $StorageAccountContainer
            StorageAccountKey       = $StorageAccountKey
            Blob = $Blob
        }
 
    } 
} 
SampleAzureStorageStorageConfig  -Path "c:\localdirectory" -Blob "StorageDir/BlobFile"  -StorageAccountName "yourstorageaccount" `
                                         -StorageAccountContainer "yourstoragecontainer" `
                                         -StorageAccountKey "aaabbbcco+CByOCS5/8abc6MkZEjaddddjU8APAoO4pyNXw+6U5nGJcddKKOWm8SvPvARQ==" 

Start-DscConfiguration -Path .\SampleAzureStorageStorageConfig -Wait -Force -Verbose
