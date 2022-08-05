# ----------------------------------------------------------------------------------------------------
# Script to stop and restart Azure Functions
# ----------------------------------------------------------------------------------------------------
Function StartStopEnvironmentFunctions
{
    CLS
    $Script:subscriptionName = "Lyles Azure Sandbox"
    $Script:envCode = "test"
	$appNumber = "-1"
	$serviceList = @("lll-funcdemo-func-")

    cls
    Write-Host "----------------------------------------------------------------------"
    Write-Host "Azure Functions Demo Project"
    Write-Host "----------------------------------------------------------------------"
    $envChoice = Read-Host -Prompt 'Select an Environment:  1=DEV, 2=QA, 3=PROD'
    switch($envChoice) {
        '3' {
            Write-Host "You chose the PROD environment!"
            $Script:subscriptionName = "Lyles Azure Sandbox"
            $Script:envCode = "prod"
        } 
        '2' {
            Write-Host "You chose the QA environment!"
            $Script:subscriptionName = "Lyles Azure Sandbox"
            $Script:envCode = "qa"
        } 
        '1' {
            Write-Host "You chose the DEV environment!"
            $Script:subscriptionName = "Lyles Azure Sandbox"
            $Script:envCode = "dev"
        } 
    }

	$resourceGroupName = "rg_functiondemo_" + $envCode
	$prompt = "Do you want to stop the Demo Functions in " + $envCode + "? (y/n)"
	$confirmation = Read-Host $prompt
	if ($confirmation -eq 'y') {
	  ForEach ($svc in $serviceList) {
		$svcName = $svc + $envCode + $appNumber
        Write-Host "Stopping " $svcName " in " $resourceGroupName
		Stop-AzureRmWebApp -ResourceGroupName $resourceGroupName -Name $svcName
	  }
	}
	else {
		$prompt = "Do you want to start the Demo Functions in " + $envCode + "? (y/n)"
		$confirmation = Read-Host $prompt
		if ($confirmation -eq 'y') {
		  ForEach ($svc in $serviceList) {
			$svcName = $svc + $envCode + $appNumber
			Write-Host "Starting " $svcName " in " $resourceGroupName
			Start-AzureRmWebApp -ResourceGroupName $resourceGroupName -Name $svcName
		  }
		}
	}
}
StartStopEnvironmentFunctions