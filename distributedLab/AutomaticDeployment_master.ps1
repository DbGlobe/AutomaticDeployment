param (
    [string]$AutomaticDeploymentEnv =  'C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab',
    [string]$destination = $AutomaticDeployment+'\DAInstallation',
    [string]$pushToS3 = $AutomaticDeploymentEnv + '\pushToS3.bat',
    [string]$deployRevision = $AutomaticDeploymentEnv + '\deployRevision.bat',
    
    [string]$revisionFileDestination = $AutomaticDeploymentEnv + '\deployRevision.bat',
    [string]$createApplication = $AutomaticDeploymentEnv + '\CreateApplication.bat',
    [string]$createGroupDeployment = $AutomaticDeploymentEnv + '\CreateGroupDeploy.bat',
    [string]$deleteGroupDeployment = $AutomaticDeploymentEnv + '\DeleteDeploymentGroup.bat',
    [string]$deleteApplication = $AutomaticDeploymentEnv + '\DeleteApplication.bat',

    [string]$launch_MySQL_Instance = $AutomaticDeploymentEnv + '\launch_MySQL_Instance_Testing.bat',

    
    [string]$checkInstanceStatus = $AutomaticDeploymentEnv + '\verifyInstanceStatus.bat',

    [string]$applyInstanceNameTo_MySQL = $AutomaticDeploymentEnv + '\applyInstanceNameTo_MySQL.bat',
    [string]$applyInstanceNameTo_MP = $AutomaticDeploymentEnv + '\applyInstanceNameTo_MP.bat',
    [string]$applyInstanceNameTo_FileCluster = $AutomaticDeploymentEnv + '\applyInstanceNameTo_FileCluster.bat',

    
    [string]$deploymentStateFile = $AutomaticDeploymentEnv + '\deploymentState.bat',
    #[string]$exportToJSON = '--output json >C:\jenkins-ws\da-remote-install\ADOutputFiles\deploymentState.json',
    #[string]$exportDeployIdToText = '--output=text >C:\jenkins-ws\da-remote-install\ADOutputFiles\deployId.txt',
    #[string]$hostName = $outputFilesPath + '\HostName.txt',
    [string]$runAutomationSuit = $AutomaticDeploymentEnv + '\runAutomationSuit.bat',
    [string]$terminateInstance = $AutomaticDeploymentEnv + 'terminateInstanceByID.bat',
    [string]$Setup_Name,
    [string]$NumberOfInstances,
    # AIO, DoubleInstances, TripleInstances
    [string]$End_Of_Run_Mode,
    [string]$Branch_As_Source,
    [string]$RunAutomation,
    [string]$NumberOfMPInstances,
    [string]$AutomationSuitName,
    [string]$daEnronValidate,
    [string]$daVersion,
    [string]$AWS_Account,
    [string]$buildNumber,
    [string]$job_name
)
 
    aws configure set AWS_ACCESS_KEY_ID AKIAJ64LA7AI557VBVVQ
    aws configure set AWS_SECRET_ACCESS_KEY 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
    aws configure set default.region us-west-2

# Create a folder to put all the running stuff

[string]$outputFilesPath = 'C:\jenkins-ws\da-remote-install\ADOutputFiles\output_'+$buildNumber
[string]$exportToJSON = "--output json >C:\jenkins-ws\da-remote-install\ADOutputFiles\output_$buildNumber\deploymentState.json"
[string]$exportDeployIdToText = "--output=text >C:\jenkins-ws\da-remote-install\ADOutputFiles\output_$buildNumber\deployId.txt"
[string]$hostName = $outputFilesPath + '\HostName.txt'
[string]$path2deploymentId = $outputFilesPath + '\deployId.txt'
[string]$path2eTag = $outputFilesPath + '\output.txt'


$runningFolderName = $buildNumber
$runningFolder = New-Item -ItemType directory -Path $outputFilesPath\RunFolder_$job_name$runningFolderName
$automationFolder = New-Item -ItemType directory -Path $runningFolder\Automation_$buildNumber

$date = Get-Date -format M-d
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path $runningFolder\ADRunLog_$buildNumber  -append


if ($NumberOfInstances -eq "AIO")
{
$Number_of_FC_Servers ="1"
$Number_of_MySQL_servers ="0"
$Number_of_MP_Servers ="0"
Write-Host "============== Deployment Type is: $NumberOfInstances ========================"
}


if ($NumberOfInstances -eq "TripleInstances")
{
$Number_of_FC_Servers ="1"
$Number_of_MySQL_servers ="1"
$Number_of_MP_Servers = $NumberOfMPInstances
Write-Host "============== Deployment Type is: $NumberOfInstances ========================"
}



#Start MySQL instance

if ($NumberOfInstances -eq "TripleInstances") {
 write-host "======== Start MySQL Instance for deployment and Testing ========"
    &$launch_MySQL_Instance}



#Start FileCluster instance

$path_to_launch_FC = 'C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\launch_FC_Instance.ps1'
[string]$iam_Instance = ' --iam-instance-profile Name="CodeDeployDemo-EC2"'
[string]$last_part_script= ' --instance-type m4.xlarge --key-name codeDeployKey --security-groups "free" --output json'
[string]$output=' > C:\jenkins-ws\da-remote-install\ADOutputFiles\output_'+$buildNumber+'\startedFC_InstanceId.json'
[string]$firstPart= 'aws ec2 run-instances --image-id   ami-9d9432e5 --count '
$run_FC_Instnace=   $firstPart +$Number_of_FC_Servers+  $iam_Instance  + $last_part_script +  $output | Out-File $path_to_launch_FC
#Write-Host "$run_FC_Instnace"
write-host "======== Start $Number_of_FC_Servers of FileCluster Instance for deployment and Testing  ========"
       &C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\launch_FC_Instance.ps1

#Start MP instance

if ($NumberOfInstances -eq "TripleInstances")
{
if ($Number_of_MP_Servers -gt "0")
{

for($i=1; $i -le $NumberOfMPInstances; $i++)

{Write-Host "MP installation Number $i"

$path_to_launch_MP = 'C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\launch_MP_Instance.ps1'
[string]$iam_Instance = ' --iam-instance-profile Name="LastRoleForCD"'
[string]$last_part_script= ' --instance-type m4.large --key-name Updated_Testing_Key --security-groups DefaultGS --output json'
[string]$output=' > C:\jenkins-ws\da-remote-install\ADOutputFiles\output_'+$buildNumber+'\startedMPInstanceId.json'
[string]$firstPart= 'aws ec2 run-instances --image-id   ami-d8b765a0  --count 1'
$run_MP_Instnace=   $firstPart +  $iam_Instance  + $last_part_script +  $output | Out-File $path_to_launch_MP
#Write-Host "$run_MP_Instnace"
write-host "======== Start $Number_of_MP_Servers of MP Instance for deployment and Testing  ========"
       &C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\launch_MP_Instance.ps1
sleep 15

#Get the public IP of the MP Instance
$json_MP = (Get-Content $outputFilesPath\startedMPInstanceId.json -Raw) | ConvertFrom-Json
$instanceId_MP= $json_MP.Instances.InstanceId
$instancePrivateIP_MP= $json_MP.Instances.PrivateIpAddress
$InstanceName_MP= $json_MP.Instances.PrivateIpAddress | Out-File $outputFilesPath'\HostName_MP.txt'
$publicInstanceIP_script_MP = aws ec2 describe-instances --instance-ids $instanceId_MP --output json > $outputFilesPath\publicInstanceIP_MP.json
$json_MP = (Get-Content $outputFilesPath\publicInstanceIP_MP.json -Raw) | ConvertFrom-Json
$publicInstanceIP_MP = $json_MP.Reservations.Instances.PublicIpAddress


write-host "======== Running Instance of MP   ===================

                                 InstanceID: $instanceId_MP
                                 InstanceIP: $publicInstanceIP_MP
                                 InstancePrivateIP: $instancePrivateIP_MP

                                   "

#Apply name to MP instance
    [string]$ValueMP='Value='+ $Setup_Name +'_codeDeploy_MP_'+ $i
    [string]$InstanceKeyName =' --tags Key=Name,'+ $ValueMP
    $contentForApplyName= "aws ec2 create-tags --resources $instanceId_MP $InstanceKeyName"
    Set-Content -Value $contentForApplyName -Path $applyInstanceNameTo_MP
    #write-host "======= Apply a name to the new created $instanceId_MP ========="
    &$applyInstanceNameTo_MP
}
}
}

$json_FC = (Get-Content $outputFilesPath\startedFC_InstanceId.json -Raw) | ConvertFrom-Json
$instanceId_FC= $json_FC.Instances.InstanceId
$InstanceName_FC= $json_FC.Instances.PrivateIpAddress | Out-File $outputFilesPath'\HostName_FC.txt'
$instancePrivateIP_FC= $json_FC.Instances.PrivateIpAddress
$privateDnsName = $json_FC.Instances.PrivateDnsName
$privateIP_FC = Get-Content $outputFilesPath'\HostName_FC.txt'

if ($NumberOfInstances -eq "TripleInstances")
{

$json_MP = (Get-Content $outputFilesPath\startedMPInstanceId.json -Raw) | ConvertFrom-Json
$instanceId_MP= $json_MP.Instances.InstanceId
$instancePrivateIP_MP= $json_MP.Instances.PrivateIpAddress
$InstanceName_MP= $json_MP.Instances.PrivateIpAddress | Out-File $outputFilesPath'\HostName_MP.txt'

}
#Choose the relevant response.Varfile
#Type of response.Varfile: AIO, Double (1 for FC and 1 for MP), Triple (1 for FC and 1 for MP - different)

$responseFile_AIO=$AutomaticDeploymentEnv+'\responseFiles\response_AIO.varfile'
$responseFile_Triple_FC=$AutomaticDeploymentEnv+'\responseFiles\response_FC.varfile'
$responseFile_Triple_MP=$AutomaticDeploymentEnv+'\responseFiles\response_MP.varfile'
$responseFile_Triple_MySQL=$AutomaticDeploymentEnv+'\responseFiles\response_MySQL_Solr.varfile'
$responseFile_Triple_FC_secondRun=$AutomaticDeploymentEnv+'\responseFiles\response_secondRun_FC.varfile'


if ($NumberOfInstances -eq "AIO")
{
  $relevantResponse = $responseFile_AIO
}



if ($NumberOfInstances -eq "TripleInstances"){


$json_MySQL = (Get-Content $outputFilesPath\startedMySQLInstanceId.json -Raw) | ConvertFrom-Json
$instanceId_MySQL= $json_MySQL.Instances.InstanceId
$instancePrivateIP_MySQL= $json_MySQL.Instances.PrivateIpAddress

#FOR MP MACHINE
######################################################################
$path_varfile11 = $responseFile_Triple_MP
$localPort = ':61616'
$word11 = "activemq.address="
$replacement11 = "activemq.address=$instancePrivateIP_FC$localPort"
$text11 = get-content $path_varfile11
$newText11 = $text11 -replace $word11,$replacement11
$newText11 > $path_varfile11

$path_varfile11 = $responseFile_Triple_MP
$word11 = "activemq.address.host="
$replacement11 = "activemq.address.host=$instancePrivateIP_FC"
$text11 = get-content $path_varfile11
$newText11 = $text11 -replace $word11,$replacement11
$newText11 > $path_varfile11

$path_varfile11 = $responseFile_Triple_MP
$word11 = "appserver.host="
$replacement11 = "appserver.host=$instancePrivateIP_FC"
$text11 = get-content $path_varfile11
$newText11 = $text11 -replace $word11,$replacement11
$newText11 > $path_varfile11

$path_varfile7 = $responseFile_Triple_MP
$word7 = "solr.address.host="
$replacement7 = "solr.address.host=$instancePrivateIP_MySQL"
$text7 = get-content $path_varfile7
$newText7 = $text7 -replace $word7,$replacement7
$newText7 > $path_varfile7


$path_varfile7 = $responseFile_Triple_MP
$scriptPart1="\:2181/solr"
$word7 = "solr.zookeeper.address="
$replacement7 = "solr.zookeeper.address=$instancePrivateIP_MySQL$scriptPart1"
$text7 = get-content $path_varfile7
$newText7 = $text7 -replace $word7,$replacement7
$newText7 > $path_varfile7

$path_varfile7 = $responseFile_Triple_MP
$scriptPart1="\:2181"
$word7 = "zookeeper.address.host="
$replacement7 = "zookeeper.address.host=$instancePrivateIP_MySQL$scriptPart1"
$text7 = get-content $path_varfile7
$newText7 = $text7 -replace $word7,$replacement7
$newText7 > $path_varfile7
#########################################################################

#FOR LDAP Connection
######################################################################

#$ldapProperties = '\\172.31.41.248\d$\AutomationData\ldap.properties'
#$path_varfile22 = $ldapProperties
#$localPort = ':61616'
#$word22 = "da.ldap.host="
#$replacement22 = "da.ldap.host=172.31.10.39"
#$text22 = get-content $path_varfile22
#$newText22 = $text22 -replace $word22,$replacement22
#$newText22 > $path_varfile22

#FOR MySQL MACHINE
######################################################################
$path_varfile22 = $responseFile_Triple_MySQL
$localPort = ':61616'
$word22 = "activemq.address="
$replacement22 = "activemq.address=$instancePrivateIP_FC$localPort"
$text22 = get-content $path_varfile22
$newText22 = $text22 -replace $word22,$replacement22
$newText22 > $path_varfile22

$path_varfile11 = $responseFile_Triple_MySQL
$word11 = "activemq.address.host="
$replacement11 = "activemq.address.host=$instancePrivateIP_FC"
$text11 = get-content $path_varfile11
$newText11 = $text11 -replace $word11,$replacement11
$newText11 > $path_varfile11

$path_varfile11 = $responseFile_Triple_MySQL
$word11 = "appserver.host="
$replacement11 = "appserver.host=$instancePrivateIP_FC"
$text11 = get-content $path_varfile11
$newText11 = $text11 -replace $word11,$replacement11
$newText11 > $path_varfile11
#########################################################################




#Create alignShards script
########################################################################
$outputDoAlign = $AutomaticDeploymentEnv + '\doAlignShards.bat'
$solrPort = ':2181'
$createDoAlignShardsScript = "C:\Installation\DocAuthority\solr_cloud_config.bat align-shards $instancePrivateIP_MySQL$solrPort/solr alignShards.bat" | Out-File $outputDoAlign
#Get-Content C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\doAlignShards.bat | Set-Content -Encoding utf8 Get-Content C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\doAlignShards_utf-8.bat

$MyPath = 'C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\doAlignShards.bat'

$MyFile = Get-Content $MyPath
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllLines($MyPath, $MyFile, $Utf8NoBomEncoding)

#FOR FC First Run MACHINE
#################################################################
#Inject IP to the MySQL URL
$path_varfile7 = $responseFile_Triple_FC
$scriptPart1="jdbc\:mysql\://"
$scriptPart2="\:3306/docauthority?autoReconnect\=true&useUnicode\=true&createDatabaseIfNotExist\=true&characterEncoding\=utf-8"
$word7 = "filecluster.mysql.url="
$replacement7 = "filecluster.mysql.url=$scriptPart1$instancePrivateIP_MySQL$scriptPart2"
$text7 = get-content $path_varfile7
$newText7 = $text7 -replace $word7,$replacement7
$newText7 > $path_varfile7


$path_varfile7 = $responseFile_Triple_FC
$word7 = "filecluster.mysql.host="
$replacement7 = "filecluster.mysql.host=$instancePrivateIP_MySQL"
$text7 = get-content $path_varfile7
$newText7 = $text7 -replace $word7,$replacement7
$newText7 > $path_varfile7

$path_varfile7 = $responseFile_Triple_FC
$scriptPart1="\:2181/solr"
$word7 = "solr.address="
$replacement7 = "solr.address=$instancePrivateIP_MySQL$scriptPart1"
$text7 = get-content $path_varfile7
$newText7 = $text7 -replace $word7,$replacement7
$newText7 > $path_varfile7

$path_varfile7 = $responseFile_Triple_FC
$word7 = "solr.address.host="
$replacement7 = "solr.address.host=$instancePrivateIP_MySQL"
$text7 = get-content $path_varfile7
$newText7 = $text7 -replace $word7,$replacement7
$newText7 > $path_varfile7


$path_varfile7 = $responseFile_Triple_FC
$scriptPart1="\:2181/solr"
$word7 = "solr.zookeeper.address="
$replacement7 = "solr.zookeeper.address=$instancePrivateIP_MySQL$scriptPart1"
$text7 = get-content $path_varfile7
$newText7 = $text7 -replace $word7,$replacement7
$newText7 > $path_varfile7


$path_varfile7 = $responseFile_Triple_FC
$scriptPart1="\:2181"
$word7 = "zookeeper.address.host="
$replacement7 = "zookeeper.address.host=$instancePrivateIP_MySQL$scriptPart1"
$text7 = get-content $path_varfile7
$newText7 = $text7 -replace $word7,$replacement7
$newText7 > $path_varfile7

####################################################################

#FOR FC Second Run MACHINE
#################################################################
#Inject IP to the MySQL URL
$path_varfile7 = $responseFile_Triple_FC_secondRun
$scriptPart1="jdbc\:mysql\://"
$scriptPart2="\:3306/docauthority?autoReconnect\=true&useUnicode\=true&createDatabaseIfNotExist\=true&characterEncoding\=utf-8"
$word7 = "filecluster.mysql.url="
$replacement7 = "filecluster.mysql.url=$scriptPart1$instancePrivateIP_MySQL$scriptPart2"
$text7 = get-content $path_varfile7
$newText7 = $text7 -replace $word7,$replacement7
$newText7 > $path_varfile7


$path_varfile7 = $responseFile_Triple_FC_secondRun
$scriptPart1="\:2181/solr"
$word7 = "solr.address="
$replacement7 = "solr.address=$instancePrivateIP_MySQL$scriptPart1"
$text7 = get-content $path_varfile7
$newText7 = $text7 -replace $word7,$replacement7
$newText7 > $path_varfile7

$path_varfile7 = $responseFile_Triple_FC_secondRun
$word7 = "solr.address.host="
$replacement7 = "solr.address.host=$instancePrivateIP_MySQL"
$text7 = get-content $path_varfile7
$newText7 = $text7 -replace $word7,$replacement7
$newText7 > $path_varfile7


$path_varfile7 = $responseFile_Triple_FC_secondRun
$scriptPart1="\:2181/solr"
$word7 = "solr.zookeeper.address="
$replacement7 = "solr.zookeeper.address=$instancePrivateIP_MySQL$scriptPart1"
$text7 = get-content $path_varfile7
$newText7 = $text7 -replace $word7,$replacement7
$newText7 > $path_varfile7


$path_varfile7 = $responseFile_Triple_FC_secondRun
$scriptPart1="\:2181"
$word7 = "zookeeper.address.host="
$replacement7 = "zookeeper.address.host=$instancePrivateIP_MySQL$scriptPart1"
$text7 = get-content $path_varfile7
$newText7 = $text7 -replace $word7,$replacement7
$newText7 > $path_varfile7

####################################################################

Get-Content C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\responseFiles\response_FC.varfile | Set-Content -Encoding utf8 C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\responseFiles\response_FC1.varfile
Get-Content C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\responseFiles\response_secondRun_FC.varfile | Set-Content -Encoding utf8 C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\responseFiles\response_secondRun_FC1.varfile
Get-Content C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\responseFiles\response_MP.varfile | Set-Content -Encoding utf8 C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\responseFiles\response_MP1.varfile
Get-Content C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\responseFiles\response_MySQL_Solr.varfile | Set-Content -Encoding utf8 C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\responseFiles\response_MySQL_Solr1.varfile
}

#Get the public IP of the FC Instance
$publicInstanceIP_script_FC = aws ec2 describe-instances --instance-ids $instanceId_FC --output json > $outputFilesPath\publicInstanceIP_FC.json
$json_FC = (Get-Content $outputFilesPath\publicInstanceIP_FC.json -Raw) | ConvertFrom-Json
$publicInstanceIP_FC = $json_FC.Reservations.Instances.PublicIpAddress
$clientPort = ':9000'

write-host "======== Running Instance of FC   =================

                                 InstanceID: $instanceId_FC
                                 InstanceIP: $publicInstanceIP_FC
                                 InstancePrivateIP: $instancePrivateIP_FC
                                 Address For Browsing: https://$publicInstanceIP_FC$clientPort

                                  "




if ($NumberOfInstances -eq "TripleInstances")

{


#Get the public IP of the MySQL Instance

$json_MySQL = (Get-Content $outputFilesPath\startedMySQLInstanceId.json -Raw) | ConvertFrom-Json
$instanceId_MySQL= $json_MySQL.Instances.InstanceId
$instancePrivateIP_MySQL= $json_MySQL.Instances.PrivateIpAddress
$InstanceName_MySQL= $json_MySQL.Instances.PrivateIpAddress | Out-File $outputFilesPath'\HostName_MySQL.txt'
$publicInstanceIP_script_MySQL = aws ec2 describe-instances --instance-ids $instanceId_MySQL --output json > $outputFilesPath\publicInstanceIP_MySQL.json
$json_MySQL = (Get-Content $outputFilesPath\publicInstanceIP_MySQL.json -Raw) | ConvertFrom-Json
$publicInstanceIP_MySQL = $json_MySQL.Reservations.Instances.PublicIpAddress

write-host "======== Running Instance of MySQL

                                 InstanceID: $instanceId_MySQL
                                 InstanceIP: $publicInstanceIP_MySQL
                                 InstancePrivateIP: $instancePrivateIP_MySQL

                                    "
}

if ($NumberOfInstances -eq "TripleInstances")

{

#Apply name to MySQL instance

    [string]$ValueSQL='Value='+ $Setup_Name +'_codeDeploy_MySQL'
    [string]$InstanceKeyName =' --tags Key=Name,'+ $ValueSQL
    $contentForApplyName= "aws ec2 create-tags --resources $instanceId_MySQL $InstanceKeyName"
    Set-Content -Value $contentForApplyName -Path $applyInstanceNameTo_MySQL
    #write-host "======= Apply a name to the new created $instanceId_MySQL ========="
    &$applyInstanceNameTo_MySQL



#Apply name to FileCluster instance
    [string]$ValueFC='Value='+ $Setup_Name +'_codeDeploy_FC'
    [string]$InstanceKeyName =' --tags Key=Name,'+ $ValueFC
    $contentForApplyName= "aws ec2 create-tags --resources $instanceId_FC $InstanceKeyName"
    Set-Content -Value $contentForApplyName -Path $applyInstanceNameTo_FileCluster
    #write-host "======= Apply a name to the new created $instanceId_FC ========="
    &$applyInstanceNameTo_FileCluster
}

if ($NumberOfInstances -eq "AIO")
{
#Apply name to FileCluster instance
Write-Host "SetInstanceName --------------------------------------"
    [string]$ValueFC='Value='+ $Setup_Name +'_codeDeploy_Automation'
    [string]$InstanceKeyName =' --tags Key=Name,'+ $ValueFC
    $contentForApplyName= "aws ec2 create-tags --resources $instanceId_FC $InstanceKeyName"
    Set-Content -Value $contentForApplyName -Path $applyInstanceNameTo_FileCluster
    #write-host "======= Apply a name to the new created $instanceId_FC ========="
    &$applyInstanceNameTo_FileCluster
    }
$path_To_Source = 'C:\Program Files (x86)\Jenkins\userContent\'+$Branch_As_Source
$files = Get-ChildItem -Path $path_To_Source -Filter *.exe | sort LastWriteTime -Descending #Date Modified

$counter = 0
$daFiles = @()

write-host "======== Searching $path_To_Source for files... ========"

foreach($file in $files)
{
    $fileName = $file.Name

    if($fileName.StartsWith('DocAuthority_') -And -not $fileName.StartsWith('patch'))
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
    write-host "Found $counter file matching the criteria."

    
    write-host "======== Copying " $newDAFile.FullName " to $AutomaticDeploymentEnv ======"
    Copy-Item  $newDAFile.FullName -Destination $AutomaticDeploymentEnv  -Force
    write-host "Done Copying!" -BackgroundColor Green
    Rename-Item -NewName DocAuthority_windows.exe -Path $AutomaticDeploymentEnv\$newDAFile -Force

    $newFilePath = $destination + '\' +$newDAFile.Name
	
    # Create Application in CodeDeploy
    aws configure set AWS_ACCESS_KEY_ID AKIAJ64LA7AI557VBVVQ
    aws configure set AWS_SECRET_ACCESS_KEY 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
    aws configure set default.region us-west-2

    Write-Host " ====================  Create Application (DA_$buildNumber$Installation) in CodeDeploy =================="
    $Installation = "Installation"
    $createApplication = "aws deploy create-application --application-name DAInstallation"
    $pathToCreateApplication = $AutomaticDeploymentEnv+ '\CreateApplication.bat'
    Set-Content -Value $createApplication -Path $pathToCreateApplication 
    &$pathToCreateApplication 

    # Create Application in CodeDeploy
    aws configure set AWS_ACCESS_KEY_ID AKIAJ64LA7AI557VBVVQ
    aws configure set AWS_SECRET_ACCESS_KEY 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
    aws configure set default.region us-west-2

    Write-Host " ====================  Create Application (DA_) in CodeDeploy =================="
    $Installation = "Installation"
    $createApplication = "aws deploy create-application --application-name DAInstallation"
    $pathToCreateApplication = $AutomaticDeploymentEnv+ '\CreateApplication.bat'
    Set-Content -Value $createApplication -Path $pathToCreateApplication 
    &$pathToCreateApplication 
   aws configure set AWS_ACCESS_KEY_ID AKIAJ64LA7AI557VBVVQ
    aws configure set AWS_SECRET_ACCESS_KEY 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
    aws configure set default.region us-west-2

    $pathToCreateGroup=$AutomaticDeploymentEnv+'\CreateGroupDeploy.bat'
    $valueToScript = '_codeDeploy*'
    $createGroupDeployment = "aws deploy create-deployment-group --application-name DAInstallation --deployment-config-name CodeDeployDefault.OneAtATime --deployment-group-name DA_Installation_$buildNumber --ec2-tag-filters Key=Name,Value=$Setup_Name$valueToScript,Type=KEY_AND_VALUE --service-role-arn arn:aws:iam::620345901349:role/CodeDeployDemo-EC2"
    
    Set-Content -Value $createGroupDeployment -Path $pathToCreateGroup
    Write-Host "========Create Code Deploy GroupDeployment" -BackgroundColor Blue
    &$pathToCreateGroup

      
    write-host "========Found Installation file is going to push to S3"  -BackgroundColor Blue
    write-host "========Running: $pushToS3 ========"
    $pushToS3 = "aws deploy push --application-name DAInstallation  --ignore-hidden-files --s3-location s3://testingcodedeploybucket/TestInstallation.zip --source C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab > C:\jenkins-ws\da-remote-install\ADOutputFiles\output_$buildNumber\output.txt"
    $pathToS3file = $AutomaticDeploymentEnv+ '\pushToS3.bat'
    Set-Content -Value $pushToS3 -Path $pathToS3file 
    &$pathToS3file
        write-host "======== DA Installation is going to be deployed in the CodeDeploy machine"
    
    
    


}
else
{
    write-host "No file matching the creteria were found." -BackgroundColor Red
}

write-host
write-host " =========== Creating Revision File: ============"


$input = Get-Content -Path C:\jenkins-ws\da-remote-install\ADOutputFiles\output_$buildNumber\output.txt

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

$deployRevisionScript= "aws deploy create-deployment --application-name DAInstallation --s3-location bucket=testingcodedeploybucket,key=TestInstallation.zip,bundleType=zip,eTag=$eTag --deployment-group-name DA_Installation_$buildNumber --deployment-config-name CodeDeployDefault.AllAtOnce --description DAInstallation_Deploy --ignore-application-stop-failures $exportDeployIdToText"


#Run revision deployment
Set-Content -Value $deployRevisionScript -Path $revisionFileDestination
write-host "========Running: $revisionFileDestination ========"
    &$revisionFileDestination

Write-Host "===== Delete Installation file ======="
Remove-Item -path $AutomaticDeploymentEnv\DocAuthority_windows.exe -Force

#Get Deployment Status
$deploymentId = Get-Content -Path C:\jenkins-ws\da-remote-install\ADOutputFiles\output_$buildNumber\deployId.txt
$deploymentState= "aws deploy get-deployment --deployment-id $deploymentId $exportToJSON"
Set-Content -Value $deploymentState -Path $deploymentStateFile
Write-Host "========== Get Deployment Status ======"
&$deploymentStateFile

while($generalState -eq "InProgress" -or $genetalState -eq "Pending" -or "Created")
{
   $time = Get-Date -format u
   Write-Host "The deployment status is InProgress or Pending $time"
   $convertToJSON= aws deploy get-deployment --deployment-id $deploymentId --output json >C:\jenkins-ws\da-remote-install\ADOutputFiles\output_$buildNumber\deploymentState.json
   $json = (Get-Content C:\jenkins-ws\da-remote-install\ADOutputFiles\output_$buildNumber\deploymentState.json -Raw) | ConvertFrom-Json
   $generalState = $json.deploymentInfo.status
   write-host $generalState
   sleep -Seconds 30

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



#############################################
#Establish Automation WS per run            #
#############################################

# Download Automation WS from S3 
aws configure set AWS_ACCESS_KEY_ID AKIAJ64LA7AI557VBVVQ
aws configure set AWS_SECRET_ACCESS_KEY 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
aws configure set default.region us-west-2

Write-Host "==== Download Automation WS from S3 ====="
aws s3 cp s3://da-builds/DA-Automation/DA-Automation.zip C:\jenkins-ws\DA-Automation_$buildNumber.zip

#Unzip the downloaded package
Write-Host " ==================== Unzip Automation WS package ========================="

$zipfile= "C:\jenkins-ws\DA-Automation_$buildNumber.zip"
$outpath= "C:\jenkins-ws\DA-Automation_$buildNumber" 

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

Unzip "$zipfile" "$outpath"

#Run Testing configuration for Remote file Serenity
[string]$outputFilesPath = "$runningFolder\ADRunLog_$buildNumber\Automation_$buildNumber"
[string]$port=':9000'


$firstRow = Get-Content $outputFilesPath\HostName_FC.txt -First 1

if ($NumberOfInstances -eq "TripleInstances") {
$firstRow_SQL = Get-Content $outputFilesPath\HostName_MySQL.txt -First 1
}

write-host "====== prepare the testing remote config file ======"
Write-host "======SUT.Properties file =========================="
$path_SUT_File = "C:\jenkins-ws\DA-Automation_$buildNumber\sut_orig.properties"
$word40 = "da.url="
$replacement40 = "da.url=https://$instancePrivateIP_FC$port"
$text40 = get-content $path_SUT_File
$newText40 = $text40 -replace $word40,$replacement40
$newText40 > $path_SUT_File
Write-host "$replacement40"

$word1 = "da.version="
$replacement1 = "da.version=$daVersion"
$text1 = get-content $path_SUT_File
$newText1 = $text1 -replace $word1,$replacement1
$newText1 > $path_SUT_File
Write-host "$replacement1"

$word20 = "da.web.username="
$replacement20 = "da.web.username=aa"
$text20 = get-content $path_SUT_File
$newText20 = $text20 -replace $word20,$replacement20
$newText20 > $path_SUT_File
Write-Host "$replacement20"

$word30 = "da.web.password="
$replacement30 = "da.web.password=123"
$text30 = get-content $path_SUT_File
$newText30 = $text30 -replace $word30,$replacement30
$newText30 > $path_SUT_File
Write-Host "$replacement30"


Write-Host "==================== $daEnronValidate ================="
$word31 = "da.enron.isValidate="
$replacement31 = "da.enron.isValidate=$daEnronValidate"
$text31 = get-content $path_SUT_File
$newText31 = $text31 -replace $word31,$replacement31
$newText31 > $path_SUT_File
Write-Host "$replacement31"

$word41 = "da.filecluster.log.path="
$replacement41 = "da.filecluster.log.path=\\\\$firstRow\\c$\\Installation\\DocAuthority\\filecluster\\logs"
$text41 = get-content $path_SUT_File
$newText41 = $text41 -replace $word41,$replacement41
$newText41 > $path_SUT_File
Write-Host "$replacement41"

$automationFolder = "C:\\jenkins-ws\\da-remote-install\\ADOutputFiles\\output_'$buildNumber\\Automation"
$word50 = "da.test.log.path="
$replacement50 = "da.test.log.path=$automationFolder"
$text50 = get-content $path_SUT_File
$newText50 = $text50 -replace $word50,$replacement50
$newText50 > $path_SUT_File
Write-Host "$replacement50"

$word60 = "da.test.common.folder.path="
$replacement60 = "da.test.common.folder.path=\\\\172.31.41.248\\d$\\AutomationData"
$text60 = get-content $path_SUT_File
$newText60 = $text60 -replace $word60,$replacement60
$newText60 > $path_SUT_File
Write-Host "$replacement60"

$word201 = "da.db.username="
$replacement201 = "da.db.username=root"
$text201 = get-content $path_SUT_File
$newText201 = $text201 -replace $word201,$replacement201
$newText201 > $path_SUT_File
Write-Host "$replacement201"


$word202 = "da.db.password="
$replacement202 = "da.db.password=root"
$text202 = get-content $path_SUT_File
$newText202 = $text202 -replace $word202,$replacement202
$newText202 > $path_SUT_File
Write-Host "$replacement202"

if ($NumberOfInstances -eq "AIO") {
$portSQL = ":3306"
$word203 = "da.db.url="
$replacement203 = "da.db.url=//$firstRow$portSQL/docauthority"
$text203 = get-content $path_SUT_File
$newText203 = $text203 -replace $word203,$replacement203
$newText203 > $path_SUT_File
Write-Host "$replacement203"
}

if ($NumberOfInstances -eq "TripleInstances") {

$portSQL = ":3306"
$word203 = "da.db.url="
$replacement203 = "da.db.url=//$firstRow_SQL$portSQL/docauthority"
$text203 = get-content $path_SUT_File
$newText203 = $text203 -replace $word203,$replacement203
$newText203 > $path_SUT_File
Write-Host "$replacement203"

}

pushd C:\jenkins-ws\da-remote-install\
gradlew build -i -p C:\jenkins-ws\DA-Automation\da-test-full-regression
popd

if ($AutomationSuitName -eq "Regression")
{
$automationPropertiesFileRegression = "C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\runAutomationSuit_regression.bat"
$updateGradleProperties = "pushd C:\jenkins-ws\da-remote-install\
                           gradlew build -i -p C:\jenkins-ws\DA-Automation_$buildNumber\da-test-full-regression
                           popd"
Set-Content -Value $updateGradleProperties -Path $automationPropertiesFileRegression

}

if ($AutomationSuitName -eq "Sanity")
{
$automationPropertiesFileSanity = "C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\runAutomationSuit.bat"
$updateGradleProperties = "pushd C:\jenkins-ws\da-remote-install\
                           gradlew build -i -p C:\jenkins-ws\DA-Automation_$buildNumber\da-test-sanity
                           popd"
Set-Content -Value $updateGradleProperties -Path $automationPropertiesFileSanity

}

Get-Content C:\jenkins-ws\DA-Automation_$buildNumber\sut_orig.properties | Set-Content -Encoding utf8 C:\jenkins-ws\DA-Automation_$buildNumber\sut.properties


#Run Automation

if ($RunAutomation -eq "No")
{
break
}

if ($RunAutomation -eq "Yes")
{
Write-Host "========== Run Automation Suit ============="

if ($AutomationSuitName -eq "Sanity")
{
Write-Host "===================Sanity Automation is running================="
$runtAutomation= "C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\runAutomationSuit.bat"
&$runtAutomation
}

if ($AutomationSuitName -eq "Regression")
{
Write-Host "======================Regression Automation is running======================"
$runtAutomation_regression= "C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\runAutomationSuit_regression.bat"
&$runtAutomation_regression
}
}


#Run the End Of Run mode - Stop / Terminate / KeepOnRunning
if ($End_Of_Run_Mode -eq "KeepOnRunning")
{
Write-Host "=========================  The Setup will keep on running and any termination activity should be taken in the future  =================================="
exit
}

if ($End_Of_Run_Mode -eq "stop" -or "terminate")
{

aws ec2 describe-instances --query 'Reservations[].Instances[].Tags[?Key==`Name`].Value[]'--output json > 'C:\jenkins-ws\da-remote-install\ADOutputFiles\output_'$buildNumber\Start_Stop_Terminate_Logs\activity.json

$input = Get-Content -Path 'C:\jenkins-ws\da-remote-install\ADOutputFiles\output_'$buildNumber\Start_Stop_Terminate_Logs\activity.json
foreach($line in $input)
{
    $line = $line.Split().Split(" ")
    foreach($splt in $line)
    {
        if($splt.Contains($Setup_Name))
        {
            $splt = $splt.Replace('"','').Replace(",","")
            $splt | Out-File "c:\$splt.txt" -Append
            Write-Host $splt
            $instanceID= aws ec2 describe-tags --filters "Name=value,Values=$splt" --output json >'C:\jenkins-ws\da-remote-install\ADOutputFiles\output_'$buildNumber\Start_Stop_Terminate_Logs\activity.json
            $json_instanceID = (Get-Content 'C:\jenkins-ws\da-remote-install\ADOutputFiles\output_'$buildNumber\Start_Stop_Terminate_Logs\activity.json -Raw) | ConvertFrom-Json
            $instanceID= $json_instanceID.Tags.ResourceId

            aws ec2 $End_Of_Run_Mode-instances --instance-ids $instanceID
        }

    }
}
Write-Host "=========================  The Setup will be in $End_Of_Run_Mode mode!!  In case it's in STOPPED mode, there is an option to RUN it from 'Start_Stop_Terminate AWS instance' - Jenkins Job  =================================="

}

Write-Host " ============================== Copy Logs ========================================================="
# ZIP the folder with the output logs
$source = $runningFolder+'\ADRunLog_'+$buildNumber
$destination = "C:\Program Files (x86)\Jenkins\userContent\AutomationResults\DeploymentLogs\Logs_$buildNumber"


Add-Type -assembly "system.io.compression.filesystem"

[io.compression.zipfile]::CreateFromDirectory($Source, $destination)

Write-Host " ===================== Delete Automation WS ========================="
Remove-Item  C:\jenkins-ws\DA-Automation_$buildNumber\* -recurse
Remove-Item  C:\jenkins-ws\DA-Automation_$buildNumber.zip -recurse
write-host "========Running: $deleteGroupDeployment + $deleteApplication ========"
    
aws deploy delete-deployment-group --application-name DAInstallation_$buildNumber --deployment-group-name DA_Installation
aws deploy delete-application --application-name DAInstallation_$buildNumber


Stop-Transcript
