param (
    [string]$AutomaticDeploymentEnv =  "C:\jenkins-ws\da-remote-install\automatedDeployment\AD_perBuild\distributedLab_$buildNumber",
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
    [string]$NumberOfMPInstances,
    [string]$daEnronValidate,
    [string]$AWS_Account,
    [string]$buildNumber,
    [string]$job_name,
    [string]$testBrowserType
    
)
 
    aws configure set AWS_ACCESS_KEY_ID AKIAJ64LA7AI557VBVVQ
aws configure set AWS_SECRET_ACCESS_KEY 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
aws configure set default.region us-west-2



# Copy automatedDeployment Lab per build

Write-Host " ================ Create a new AutomaticDeployment Lab per $buildNumber number ============================"
$pathToautomatedDeploymentHome = 'C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab'
$newAutomatedDeplymentPerRun = "C:\jenkins-ws\da-remote-install\automatedDeployment\AD_perBuild\distributedLab_$buildNumber"

Copy-Item -Path $pathToautomatedDeploymentHome -Destination $newAutomatedDeplymentPerRun -recurse -Force 



# Create a folder to put all the running stuff

[string]$outputFilesPath = "C:\jenkins-ws\da-remote-install\ADOutputFiles\output_$buildNumber"
[string]$exportToJSON = "--output json >C:\jenkins-ws\da-remote-install\ADOutputFiles\output_$buildNumber\deploymentState.json"
[string]$exportDeployIdToText = "--output=text >C:\jenkins-ws\da-remote-install\ADOutputFiles\output_$buildNumber\deployId.txt"
[string]$hostName = $outputFilesPath + '\HostName.txt'
[string]$path2deploymentId = $outputFilesPath + '\deployId.txt'
[string]$path2eTag = $outputFilesPath + '\output.txt'

$AutomaticDeploymentEnv =  $newAutomatedDeplymentPerRun
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
 $path_to_launch_mySQL = 'C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\launch_mySQL_Instance.ps1'
[string]$iam_Instance = ' --iam-instance-profile Name="EC2_CodeDeploy"'
[string]$last_part_script= ' --instance-type m4.xlarge --key-name CodeDeployKey --security-groups DefaultGS --output json'
[string]$output=' > C:\jenkins-ws\da-remote-install\ADOutputFiles\output_'+$buildNumber+'\startedMySQLInstanceId.json'
[string]$firstPart= 'aws ec2 run-instances --image-id   ami-ccbd04b4 --count '
$run_mySQL_Instnace=   $firstPart +$Number_of_MySQL_servers+  $iam_Instance  + $last_part_script +  $output | Out-File $path_to_launch_mySQL
#Write-Host "$run_FC_Instnace"
write-host "======== Start $Number_of_FC_Servers of FileCluster Instance for deployment and Testing  ========"
       &C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\launch_mySQL_Instance.ps1

    }



#Start FileCluster instance

$path_to_launch_FC = "C:\jenkins-ws\da-remote-install\automatedDeployment\AD_perBuild\distributedLab_$buildNumber\launch_FC_Instance.ps1"
[string]$iam_Instance = ' --iam-instance-profile Name="CodeDeployDemo-EC2"'
[string]$last_part_script= ' --instance-type m4.xlarge --key-name AWS_Tomer_Key_Pair --security-groups "hardened security group" --output json'
[string]$output=" > C:\jenkins-ws\da-remote-install\ADOutputFiles\output_$buildNumber\startedFC_InstanceId.json"
[string]$firstPart= 'aws ec2 run-instances --image-id   ami-7056d608 --count '
$run_FC_Instnace=   $firstPart +$Number_of_FC_Servers+  $iam_Instance  + $last_part_script +  $output | Out-File $path_to_launch_FC
#Write-Host "$run_FC_Instnace"
write-host "======== Start $Number_of_FC_Servers of FileCluster Instance for deployment and Testing  ========"
       &C:\jenkins-ws\da-remote-install\automatedDeployment\AD_perBuild\distributedLab_$buildNumber\launch_FC_Instance.ps1

#Start MP instance

if ($NumberOfInstances -eq "TripleInstances")
{
if ($Number_of_MP_Servers -gt "0")
{

for($i=1; $i -le $NumberOfMPInstances; $i++)

{Write-Host "MP installation Number $i"

$path_to_launch_MP = 'C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\launch_MP_Instance.ps1'
[string]$iam_Instance = ' --iam-instance-profile Name="EC2_CodeDeploy"'
[string]$last_part_script= ' --instance-type m4.large --key-name CodeDeployKey --security-groups DefaultGS --output json'
[string]$output=' > C:\jenkins-ws\da-remote-install\ADOutputFiles\output_'+$buildNumber+'\startedMPInstanceId.json'
[string]$firstPart= 'aws ec2 run-instances --image-id   ami-022aab7a  --count 1'
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
$createDoAlignShardsScript = "C:\Installation\DocAuthority\solr_cloud_config.bat align-shards $instancePrivateIP_MySQL$solrPort/solr C:\Installation\DocAuthority\alignShards.bat" | Out-File $outputDoAlign
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

Get-Content C:\jenkins-ws\da-remote-install\automatedDeployment\AD_perBuild\distributedLab_$buildNumber\responseFiles\response_FC.varfile | Set-Content -Encoding utf8 C:\jenkins-ws\da-remote-install\automatedDeployment\AD_perBuild\distributedLab_$buildNumber\responseFiles\response_FC1.varfile
Get-Content C:\jenkins-ws\da-remote-install\automatedDeployment\AD_perBuild\distributedLab_$buildNumber\responseFiles\response_secondRun_FC.varfile | Set-Content -Encoding utf8 C:\jenkins-ws\da-remote-install\automatedDeployment\AD_perBuild\distributedLab_$buildNumber\responseFiles\response_secondRun_FC1.varfile
Get-Content C:\jenkins-ws\da-remote-install\automatedDeployment\AD_perBuild\distributedLab_$buildNumber\responseFiles\response_MP.varfile | Set-Content -Encoding utf8 C:\jenkins-ws\da-remote-install\automatedDeployment\AD_perBuild\distributedLab_$buildNumber\responseFiles\response_MP1.varfile
Get-Content C:\jenkins-ws\da-remote-install\automatedDeployment\AD_perBuild\distributedLab_$buildNumber\responseFiles\response_MySQL_Solr.varfile | Set-Content -Encoding utf8 C:\jenkins-ws\da-remote-install\automatedDeployment\AD_perBuild\distributedLab_$buildNumber\responseFiles\response_MySQL_Solr1.varfile
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

    aws configure set AWS_ACCESS_KEY_ID AKIAJ64LA7AI557VBVVQ
aws configure set AWS_SECRET_ACCESS_KEY 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
aws configure set default.region us-west-2
    sleep 15

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

    write-host "======================  Copy $path_To_Source\$newDAFile TO $newAutomatedDeplymentPerRun ========================"
    
    Copy-Item  $path_To_Source\$newDAFile -Destination $newAutomatedDeplymentPerRun  -Force

    write-host "Done Copying!" -BackgroundColor Green
    Rename-Item -NewName DocAuthority_windows.exe -Path $newAutomatedDeplymentPerRun\$newDAFile -Force

    # Create Group in CodeDeploy
    

    $pathToCreateGroup=$AutomaticDeploymentEnv+'\CreateGroupDeploy.bat'
    $valueToScript = '_codeDeploy*'
    #$createGroupDeployment = "aws deploy create-deployment-group --application-name DAInstallation --deployment-config-name CodeDeployDefault.OneAtATime --deployment-group-name DA_Installation_$buildNumber --ec2-tag-filters Key=Name,Value=$Setup_Name$valueToScript,Type=KEY_AND_VALUE --service-role-arn arn:aws:iam::968670743267:role/EC2_CodeDeploy"
    $createGroupDeployment  = "aws deploy create-deployment-group --application-name DAInstallation --deployment-config-name CodeDeployDefault.OneAtATime --deployment-group-name DA_Installation_$buildNumber --ec2-tag-filters Key=Name,Value=$Setup_Name$valueToScript,Type=KEY_AND_VALUE --service-role-arn arn:aws:iam::620345901349:role/CodeDeployDemo-EC2"

    Set-Content -Value $createGroupDeployment -Path $pathToCreateGroup
    Write-Host "========Create Code Deploy GroupDeployment" -BackgroundColor Blue
    &$pathToCreateGroup

      
    write-host "========Found Installation file is going to push to S3"  -BackgroundColor Blue
    write-host "========Running: $pushToS3 ========"
    $pushToS3 = "aws deploy push --application-name DAInstallation  --ignore-hidden-files --s3-location s3://testingcodedeploybucket/TestInstallation.zip --source C:\jenkins-ws\da-remote-install\automatedDeployment\AD_perBuild\distributedLab_$buildNumber > C:\jenkins-ws\da-remote-install\ADOutputFiles\output_$buildNumber\output.txt"
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

#Write-Host "===== Delete Installation file ======="
#Remove-Item -path $AutomaticDeploymentEnv\DocAuthority_windows.exe -Force

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
        
#Delete DeploymentGroup

aws deploy delete-deployment-group --application-name DAInstallation --deployment-group-name DA_Installation_$buildNumber
Write-Host " ============ Delete deplyment group: DA_Installation_$buildNumber ========================="



#Run Testing configuration for Remote file Serenity
[string]$outputFilesPath = "$runningFolder\ADRunLog_$buildNumber\Automation_$buildNumber"
[string]$port='9000'
[string]$pathToHost = "C:\jenkins-ws\da-remote-install\ADOutputFiles\output_$buildNumber"


$firstRow = Get-Content $pathToHost\HostName_FC.txt -First 1


if ($NumberOfInstances -eq "TripleInstances") {
$firstRow_SQL = Get-Content $pathToHost\HostName_MySQL.txt -First 1
}

write-host "====== prepare the testing remote config file ======"
Write-host "======SUT.Properties file =========================="
$path_SUT_File = "C:\jenkins-ws\DA-Automation\sut_orig.properties"
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

$word31 = "da.enron.isValidate=" 
$replacement31 = "da.enron.isValidate=$daEnronValidate"
$text31 = get-content $path_SUT_File 
$newText31 = $text31 -replace $word31,$replacement31
$newText31 > $path_SUT_File

$word41 = "da.log.level="
$replacement41 = "da.log.level=$LogLevel"
$text41 = get-content $path_SUT_File 
$newText41 = $text41 -replace $word41,$replacement41
$newText41 > $path_SUT_File

$word45 = "da.web.protocol="
$replacement45 = "da.web.protocol=https"
$text45 = get-content $path_SUT_File 
$newText45 = $text45 -replace $word45,$replacement45
$newText45 > $path_SUT_File


$word40 = "da.web.host="
$replacement40 = "da.web.host=$firstRow"
$text40 = get-content $path_SUT_File 
$newText40 = $text40 -replace $word40,$replacement40
$newText40 > $path_SUT_File


$word46 = "da.web.port="
$replacement46 = "da.web.port=$port"
$text46 = get-content $path_SUT_File 
$newText46 = $text46 -replace $word46,$replacement46
$newText46 > $path_SUT_File

$UserName = "aa"
$word20 = "da.web.username="
$replacement20 = "da.web.username=$UserName"
$text20 = get-content $path_SUT_File 
$newText20 = $text20 -replace $word20,$replacement20
$newText20 > $path_SUT_File

$Password = "123"
$word30 = "da.web.password="
$replacement30 = "da.web.password=$Password"
$text30 = get-content $path_SUT_File 
$newText30 = $text30 -replace $word30,$replacement30
$newText30 > $path_SUT_File


if ($NumberOfInstances -eq  "AIO") {
$portSQL = "3306"
$word203 = "da.mysql.host="
$replacement203 = "da.mysql.host=$firstRow"
$text203 = get-content $path_SUT_File
$newText203 = $text203 -replace $word203,$replacement203
$newText203 > $path_SUT_File
Write-Host "$replacement203"
}

if ($NumberOfInstances -eq "TripleInstances") {

$portSQL = "3306"
$word203 = "da.db.host="
$replacement203 = "da.db.host=$firstRow_SQL"
$text203 = get-content $path_SUT_File
$newText203 = $text203 -replace $word203,$replacement203
$newText203 > $path_SUT_File
Write-Host "$replacement203"

}

$word201 = "da.mysql.port="
$replacement201 = "da.mysql.port=$portSQL"
$text201 = get-content $path_SUT_File
$newText201 = $text201 -replace $word201,$replacement201
$newText201 > $path_SUT_File
Write-Host "$replacement201"


$word202 = "da.mysql.sid="
$replacement202 = "da.mysql.sid=docauthority"
$text202 = get-content $path_SUT_File
$newText202 = $text202 -replace $word202,$replacement202
$newText202 > $path_SUT_File
Write-Host "$replacement202"

$word203 = "da.mysql.username="
$replacement203 = "da.mysql.username=root"
$text203 = get-content $path_SUT_File
$newText203 = $text203 -replace $word203,$replacement203
$newText203 > $path_SUT_File
Write-Host "$replacement203"

$word204= "da.mysql.password="
$replacement204 = "da.mysql.password=root"
$text204 = get-content $path_SUT_File
$newText204 = $text204 -replace $word204,$replacement204
$newText204 > $path_SUT_File
Write-Host "$replacement203"

$word41 = "da.filecluster.log.path="
$replacement41 = "da.filecluster.log.path=\\\\$firstRow\\c$\\Installation\\DocAuthority\\filecluster\\logs"
$text41 = get-content $path_SUT_File 
$newText41 = $text41 -replace $word41,$replacement41
$newText41 > $path_SUT_File


$word42 = "test.browser.type="
$replacement42 = "test.browser.type=$testBrowserType"
$text42 = get-content $path_SUT_File 
$newText42 = $text42 -replace $word42,$replacement42
$newText42 > $path_SUT_File

$word50 = "test.log.path="
$replacement50 = "test.log.path=C:\\jenkins-ws\\AutomationLogs"
$text50 = get-content $path_SUT_File 
$newText50 = $text50 -replace $word50,$replacement50
$newText50 > $path_SUT_File

$word60 = "test.data.path="
$replacement60 = "test.data.path=\\\\172.31.27.238\\AutomationData"
$text60 = get-content $path_SUT_File 
$newText60 = $text60 -replace $word60,$replacement60
$newText60 > $path_SUT_File


$word61 = "test.log.level="
$replacement61 = "test.log.level=$LogLevel"
$text61 = get-content $path_SUT_File 
$newText61 = $text61 -replace $word61,$replacement61
$newText61 > $path_SUT_File



if ($AutomationSuitName -eq "Regression")
{
$automationPropertiesFileRegression = "C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\runAutomationSuit_regression.bat"
$updateGradleProperties = "pushd C:\jenkins-ws\da-remote-install\
                           gradlew test aggregate -i -p C:\jenkins-ws\DA-Automation_$buildNumber\da-test-full-regression
                           popd"
Set-Content -Value $updateGradleProperties -Path $automationPropertiesFileRegression

}

if ($AutomationSuitName -eq "Sanity")
{
$automationPropertiesFileSanity = "C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\runAutomationSuit.bat"
$updateGradleProperties = "pushd C:\jenkins-ws\da-remote-install\
                           gradlew test aggregate -i -p C:\jenkins-ws\DA-Automation\da-test-sanity
                           popd"
Set-Content -Value $updateGradleProperties -Path $automationPropertiesFileSanity

}

Get-Content C:\jenkins-ws\DA-Automation\sut_orig.properties | Set-Content -Encoding utf8 C:\jenkins-ws\DA-Automation\sut.properties


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

#Delete DeploymentGroup
sleep -Seconds 30
aws deploy delete-deployment-group --application-name DAInstallation --deployment-group-name DA_Installation_$buildNumber
Write-Host " ============ Delete deplyment group: DA_Installation_$buildNumber ========================="


Write-Host " ============================== Copy Logs ========================================================="
# ZIP the folder with the output logs
$source = $runningFolder+'\ADRunLog_'+$buildNumber
$destination = "C:\Program Files (x86)\Jenkins\userContent\AutomationResults\DeploymentLogs\Logs_$buildNumber"


Add-Type -assembly "system.io.compression.filesystem"
ZIP Test Result Package
[io.compression.zipfile]::CreateFromDirectory($Source, $destination)



Write-Host " ===================== Delete Automation WS ========================="
Remove-Item  C:\jenkins-ws\DA-Automation_$buildNumber\* -recurse
Remove-Item  C:\jenkins-ws\DA-Automation_$buildNumber.zip -recurse
write-host "========Running: $deleteGroupDeployment + $deleteApplication ========"
    


Stop-Transcript
