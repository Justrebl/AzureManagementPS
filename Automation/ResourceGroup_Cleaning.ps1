Connect-AzAccount

#Declare Global Variables for future initiation
$today = Get-Date
$devMode = $true

if($devMode){
    $subscriptionID = "208994fb-68f7-45b6-9caa-3ba51a5bf077"
    $daysToKeep = 14
    $tagToWatch = 'todelete'
    $executionMode = 'Audit'
}
else {
    $subscriptionID = Get-AutomationVariable -Name 'ResourceGroupCleaner_SubscriptionIDToWatch'
    $daysToKeep = Get-AutomationVariable -Name 'ResourceGroupCleaner_DaysToKeep'
    $executionMode = Get-AutomationVariable -Name 'ResourceGroupCleaner_ExecutionMode'
    $tagToWatch = Get-AutomationVariable -Name 'ResourceGroupCleaner_TagToWatchForRGDeletion'
}

Set-AzContext -Subscription $subscriptionID

#Extract resource groups that has the "env" tag set to "ToDelete"
$resourceGroups = Get-AzResourceGroup  | Where-Object {$_.Tags.env -eq $tagToWatch}

foreach ($rg in $resourceGroups) 
{
    #display RG infos 
    Write-host "Resource Group currently being audited : $($rg.ResourceGroupName) `r"

    $strCreatedOn = $rg.Tags.createdOn
    
    #Getting the date from which the resourcegroup should be deleted 
    try {
	    $createdOn = [datetime]::ParseExact($strCreatedOn, 'yyyy/MM/dd', $null)
    }
    catch{
        write-host "Need to set RG.createdOn tag as 'yyyy/MM/dd' before being audited for cleaning : RG Name : $($rg.ResourceGroupName) / Created On : $strCreatedOn `r"
        Write-Error
    }

	$dateToDelete = $createdOn.AddDays($daysToKeep)

	if($today -gt $dateToDelete){
		if($devMode -or $executionMode -eq 'Audit'){
            Write-host "$($rg.ResourceGroupName) will be delete after : $dateToDelete `r"
        }
        elseif ($executionMode -eq 'Production'){
            #Remove Resource Group if it's older than number of days to keep
            Write-host "$($rg.ResourceGroupName) will be deleted as it was created on : $createdOn `r"
			Remove-AzResourceGroup -Name $rg.ResourceGroupName
        }
    }    
}