param (
    [string]$AutomaticDeploymentEnv =  'C:\jenkins-ws\da-remote-install\automatedDeployment\setupUpdate',
    [string]$path = 'C:\Program Files (x86)\Jenkins\userContent\pro_v16',
    [string]$destination = $AutomaticDeploymentEnv+'\DAInstallation',
    [string]$pushToS3 = $AutomaticDeploymentEnv + '\pushToS3.bat',
    [string]$deployRevision = $AutomaticDeploymentEnv + '\deployRevision.bat',
    [string]$path2eTag = $outputFilesPath + '\output.txt',
    [string]$revisionFileDestination = $AutomaticDeploymentEnv + '\deployRevision.bat',
    [string]$createApplication = $AutomaticDeploymentEnv + '\CreateApplication.bat',
    
    [string]$deleteGroupDeployment = $AutomaticDeploymentEnv + '\DeleteDeploymentGroup.bat',
    [string]$deleteApplication = $AutomaticDeploymentEnv + '\DeleteApplication.bat',
    [string]$startUpInstance = $AutomaticDeploymentEnv + '\launceEC2fromAMI.bat',
    [string]$checkInstanceStatus = $AutomaticDeploymentEnv + '\verifyInstanceStatus.bat',
    [string]$applyNameForInstance = $AutomaticDeploymentEnv + '\applyInstanceName.bat',
    [string]$InstanceKeyName = '--tags Key=Name,Value=codeDeploy',
    [string]$path2deploymentId = $outputFilesPath + '\deployId.txt',
    [string]$deploymentStateFile = $AutomaticDeploymentEnv + '\deploymentState.bat',
    [string]$exportToJSON = '--output json >C:\jenkins-ws\da-remote-install\ADOutputFiles\setupUpdate\deploymentState.json',
    [string]$exportDeployIdToText = '--output=text >C:\jenkins-ws\da-remote-install\ADOutputFiles\setupUpdate\deployId.txt',
    [string]$pathToLogs ='C:\Running_Logs\RunLog_',
    [string]$outputFilesPath = 'C:\jenkins-ws\da-remote-install\ADOutputFiles\setupUpdate',
    [string]$gradleBuild = 'C:\jenkins-ws\da-remote-install\robot-framework\sut\remote_121.py',
    [string]$hostName = $outputFilesPath + '\HostName.txt',
    [string]$runAutomationSuit = $AutomaticDeploymentEnv + '\runAutomationSuit.bat',
    [string]$robotLogsOutput = 'C:\jenkins-ws\da-remote-install\robot-framework\target',
    [string]$terminateInstance = $AutomaticDeploymentEnv + 'terminateInstanceByID.bat',
    [string]$Deployment_Name,
    [string]$Branch_Name,
    [string]$Deployment_Type
 )

aws configure set AWS_ACCESS_KEY_ID AKIAJ64LA7AI557VBVVQ
aws configure set AWS_SECRET_ACCESS_KEY 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
aws configure set default.region us-west-2

# Create a folder to put all the running stuff
$runningFolderName = [GUID]::NewGuid()
$runningFolder = New-Item -ItemType directory -Path $outputFilesPath\RunFolder_$runningFolderName

$date = Get-Date -format M-d
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path $runningFolder\ADRunLog_$date  -append



$path_To_Source = 'C:\Program Files (x86)\Jenkins\userContent\'+$Branch_Name
$files = Get-ChildItem -Path $path_To_Source -Filter *.exe | sort LastWriteTime -Descending #Date Modified

$counter = 0
$daFiles = @()

write-host "======== Searching $path_To_Source for files... ========"

foreach($file in $files)
{
    $fileName = $file.Name

    if($fileName.StartsWith('DocAuthority_')) #-And  $fileName.StartsWith($Branch_Name))
    {
        write-host $file.Name " " $file.LastWriteTime
        $counter++
        $daFiles+=$file
    }

}

$newDAFile = $daFiles[0]

if($counter -gt 0)
{


	write-host "======================"
    write-host "Found $counter file matching the creteria."

    write-host "======== Copying " $newDAFile.FullName " to $AutomaticDeploymentEnv ======"
    Copy-Item  $newDAFile.FullName -Destination $AutomaticDeploymentEnv  -Force
    write-host "Done Copying!" -BackgroundColor Green
    Rename-Item -NewName DocAuthority_windows.exe -Path $AutomaticDeploymentEnv\$newDAFile -Force

    $newFilePath = $destination + '\' +$newDAFile.Name
	Write-Host "========Clean the Application and the GroupDeploy" -BackgroundColor DarkGreen
    write-host "========Running: $deleteGroupDeployment + $deleteApplication ========"
    &$deleteApplication
    Write-Host "========Create Code Deploy Application" -BackgroundColor Blue
    write-host "========Running: $createApplication ========"
    &$createApplication
    sleep -Seconds 5

    $pathToCreateGroup=$AutomaticDeploymentEnv+'\CreateGroupDeploy.bat'
    #$valueToScript = '_codeDeploy'
    $createGroupDeployment = "aws deploy create-deployment-group --application-name DAUpdate_Deploy --deployment-config-name CodeDeployDefault.OneAtATime --deployment-group-name DA_Update_Installation --ec2-tag-filters Key=Name,Value=$Deployment_Name,Type=KEY_AND_VALUE --service-role-arn arn:aws:iam::620345901349:role/CodeDeployServiceRole"

    Set-Content -Value $createGroupDeployment -Path $pathToCreateGroup
    Write-Host "========Create Code Deploy GroupDeployment" -BackgroundColor Blue
    &$pathToCreateGroup
    write-host "========Found Installation file is going to pushed to S3"  -BackgroundColor Blue
    write-host "========Running: $pushToS3 ========"
    &$pushToS3

    write-host "========Installation is going to be deployed in the CodeDeploy machine"


}
else
{
    write-host "No file matching the creteria were found." -BackgroundColor Red
}

write-host
write-host " =========== Creting Revision File: ============"


$input = Get-Content -Path $outputFilesPath\output.txt

foreach($line in $input)
{
    $line = $line.Split(",").Split(" ")
    foreach($splt in $line)
    {
        if($splt.Contains("eTag"))
        {
            $eTag = $splt.Remove(0,5)
            Write-Host $etag
        }
    }

}

$deployRevisionScript= "aws deploy create-deployment --application-name DAUpdate_Deploy --s3-location bucket=da-code-deploy-bucket,key=updateSetup.zip,bundleType=zip,eTag=$eTag --deployment-group-name DA_Update_Installation --deployment-config-name CodeDeployDefault.AllAtOnce --description DA_Update_Installation --ignore-application-stop-failures  $exportDeployIdToText"


#Run revision deployment
Set-Content -Value $deployRevisionScript -Path $revisionFileDestination
write-host "========Running: $revisionFileDestination ========"
    &$revisionFileDestination

Write-Host "===== Delete Installation file ======="
Remove-Item -path $AutomaticDeploymentEnv\DocAuthority_windows.exe -Force

#Get Deployment Status
$deploymentId = Get-Content -Path C:\jenkins-ws\da-remote-install\ADOutputFiles\setupUpdate\DeployId.txt
$deploymentState= "aws deploy get-deployment --deployment-id $deploymentId $exportToJSON"
Set-Content -Value $deploymentState -Path $deploymentStateFile
Write-Host "========== Get Deployment Status ======"
&$deploymentStateFile

while($generalState -eq "InProgress" -or $genetalState -eq "Pending" -or "Created")
{
   $time = Get-Date -format u
   Write-Host "The deployment status is InProgress or Pending $time"
   $convertToJSON= aws deploy get-deployment --deployment-id $deploymentId --output json >C:\jenkins-ws\da-remote-install\ADOutputFiles\setupUpdate\deploymentState.json
   $json = (Get-Content C:\jenkins-ws\da-remote-install\ADOutputFiles\setupUpdate\deploymentState.json -Raw) | ConvertFrom-Json
   $generalState = $json.deploymentInfo.status
   write-host $generalState
   sleep -Seconds 45

   if ($generalState -eq "Succeeded")
   { write-host "===================================== Deployment is Succeeded =============================" -BackgroundColor Green
   break}

   if ($generalState -eq "Failed")
   {write-host "======================================= Deployment is Failed ================================" -BackgroundColor Red

    write-host "Stopping Instance and Automation won't run" -BackgroundColor Gray
     $stopInstanceId = "aws ec2 terminate-instances --instance-ids $instanceId"
     Set-Content -Value $stopInstanceId -Path $terminateInstance
     &$terminateInstance
    #sleep -Seconds 45
    exit}
        }
#Run Testing configuration for Remote file
write-host "====== prepare the testing remote config file ======"
[string]$outputFilesPath = 'C:\jenkins-ws\da-remote-install\ADOutputFiles\setupUpdate'
[string]$port=':9000'

#Get Instance ID
$instanceID= aws ec2 describe-tags --filters "Name=value,Values=$Deployment_Name" --output json >C:\jenkins-ws\da-remote-install\ADOutputFiles\setupUpdate\instance.json
$json_instanceID = (Get-Content C:\jenkins-ws\da-remote-install\ADOutputFiles\setupUpdate\instance.json -Raw) | ConvertFrom-Json
$instanceID= $json_instanceID.Tags.ResourceId


$InstanceIP= aws ec2 describe-instances --instance-ids $instanceID --output json >C:\jenkins-ws\da-remote-install\ADOutputFiles\setupUpdate\InstancePrivateIP.json
$json_instanceIP = (Get-Content C:\jenkins-ws\da-remote-install\ADOutputFiles\setupUpdate\InstancePrivateIP.json -Raw) | ConvertFrom-Json
$instanceID= $json_instanceIP.Reservations.Instances.PrivateIpAddress
$repaireHostName = "url = 'http://$instanceID$port'
user =   'admin'
password =   '123'
samples_folder = 'c:\samples'
"
Set-Content -Value $repaireHostName -Path $gradleBuild

#Run Automation
Write-Host " ========================================= Start Automation Test Suite on the Remote Machine $InstanceName ========================== " -BackgroundColor DarkGreen
&$runAutomationSuit
Get-ChildItem $robotLogsOutput -recurse | Copy-Item -destination $runningFolder\

#$json = (Get-Content $outputFilesPath\startedInstanceId.json -Raw) | ConvertFrom-Json
$instancePrivateIP= $json.Instances.PrivateIpAddress | Out-File C:\jenkins-ws\da-remote-install\ADOutputFiles\setupUpdate\InstancePrivateIP.txt
$privateIP = Get-Content -Path C:\jenkins-ws\da-remote-install\ADOutputFiles\setupUpdate\InstancePrivateIP.txt

#Copy FileCluster Logs from the remote machine
Write-Host "==== Copy FileCluster Logs ====="
$fileClusterLogs = $runningFolder + '\fileClusterLogs\'
$copyLogsFromRemote= "net use \\$instanceID\c$\DocAuthority\filecluster J!VEuznVxt /USER:administrator
copy \\$instanceID\c$\DocAuthority\filecluster\logs\* $runningFolder"
#$copyLogsFromRemote = "copy \\$privateIP\c$\DocAuthority\filecluster\logs\* $runningFolder\fileClusterLogs\"
Set-Content -Value $copyLogsFromRemote -Path $AutomaticDeploymentEnv\copyFileClusterLogs.bat
$runCopyFileClusterLogs = $AutomaticDeploymentEnv + '\copyFileClusterLogs.bat'
&$runCopyFileClusterLogs


#Copy ui Logs from the remote machine
Write-Host "==== Copy UI Logs ====="
$copyLogsFromRemote= "net use \\$instanceID\c$\DocAuthority\filecluster J!VEuznVxt /USER:administrator
 copy \\$instanceID\c$\DocAuthority\da-ui\log\* $runningFolder"
Set-Content -Value $copyLogsFromRemote -Path $AutomaticDeploymentEnv\copyUILogs.bat
$runCopyUILogs = $AutomaticDeploymentEnv + '\copyUILogs.bat'
&$runCopyUILogs



Stop-Transcript

