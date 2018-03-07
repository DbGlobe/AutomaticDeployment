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
    [string]$runAutomationSuit = $AutomaticDeploymentEnv + '\runAutomationSuit.bat',
    [string]$terminateInstance = $AutomaticDeploymentEnv + 'terminateInstanceByID.bat',
    [string]$buildNumber,
    [string]$source_branch
    
)
 
    aws configure set AWS_ACCESS_KEY_ID AKIAJ64LA7AI557VBVVQ
aws configure set AWS_SECRET_ACCESS_KEY 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
aws configure set default.region us-west-2



# Copy automatedDeployment Lab per build

Write-Host "---------------- $source_branch ----------------"

Write-Host " ================ Create a new AutomaticDeployment Lab per $buildNumber number ============================"
$pathToautomatedDeploymentHome = 'C:\jenkins-ws\da-remote-install\automatedDeployment\continiousIntegration'
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




$path_To_Source = 'C:\Program Files (x86)\Jenkins\userContent\'+$source_branch
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

    $InstallationHome = "\\CIMACHINE\Installation\DAInstallation\Latest"
	write-host "======================"
    write-host "Found $counter file matching the criteria."

    write-host "======================  Copy $path_To_Source\$newDAFile TO $InstallationHome ========================"
    
    Copy-Item  $path_To_Source\$newDAFile -Destination $InstallationHome  -Force
    
    write-host "Done Copying!" -BackgroundColor Green
    Rename-Item -NewName DocAuthority_windows.exe -Path $InstallationHome\$newDAFile -Force

    # Create Group in CodeDeploy
    

    $pathToCreateGroup=$AutomaticDeploymentEnv+'\CreateGroupDeploy.bat'
    $valueToScript = '_codeDeploy*'
    #$createGroupDeployment = "aws deploy create-deployment-group --application-name DAInstallation --deployment-config-name CodeDeployDefault.OneAtATime --deployment-group-name DA_Installation_$buildNumber --ec2-tag-filters Key=Name,Value=$Setup_Name$valueToScript,Type=KEY_AND_VALUE --service-role-arn arn:aws:iam::968670743267:role/EC2_CodeDeploy"
    $createGroupDeployment  = "aws deploy create-deployment-group --application-name DAInstallation --deployment-config-name CodeDeployDefault.OneAtATime --deployment-group-name DA_Installation_$buildNumber --ec2-tag-filters Key=Name,Value=AIO$valueToScript,Type=KEY_AND_VALUE --service-role-arn arn:aws:iam::620345901349:role/CodeDeployDemo-EC2"

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
   sleep -Seconds 15

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




# Download Automation WS from S3 
aws configure set AWS_ACCESS_KEY_ID AKIAJ64LA7AI557VBVVQ
aws configure set AWS_SECRET_ACCESS_KEY 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
aws configure set default.region us-west-2

if ($source_branch -eq "Master")
{

Write-Host "==== Download Automation WS from S3 for Master====="
aws s3 cp s3://da-builds/DA-Automation/DA_Automation_Master/DA-Automation_Master.zip C:\jenkins-ws\DA-Automation_$buildNumber.zip

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

}

if ($source_branch -eq "Dev_16_patch_03")
{



Write-Host "==== Download Automation WS from S3 for Release 16 ====="
aws s3 cp s3://da-builds/DA-Automation/DA_Automation_Release16/DA-Automation_Release16.zip C:\jenkins-ws\DA-Automation_$buildNumber.zip

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

}



if ($source_branch -eq "Dev_Andromeda")
{


Write-Host "==== Download Automation WS from S3 for andromeda ====="
aws s3 cp s3://da-builds/DA-Automation/DA_Automation_andromeda/DA-Automation_andromeda.zip C:\jenkins-ws\DA-Automation_$buildNumber.zip

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

}



#Run Testing configuration for Remote file Serenity
[string]$outputFilesPath = "$runningFolder\ADRunLog_$buildNumber\Automation_$buildNumber"
[string]$port='9000'
[string]$pathToHost = "C:\jenkins-ws\da-remote-install\ADOutputFiles\output_$buildNumber"


$firstRow = '172.31.1.239'




write-host "====== prepare the testing remote config file ======"
Write-host "======SUT.Properties file =========================="
$path_SUT_File = "C:\jenkins-ws\DA-Automation_$buildNumber\sut_orig.properties"
$word40 = "da.url="
$replacement40 = "da.url=https://172.31.1.239$port"
$text40 = get-content $path_SUT_File
$newText40 = $text40 -replace $word40,$replacement40
$newText40 > $path_SUT_File
Write-host "$replacement40"

$word1 = "da.version="
$replacement1 = "da.version=2.0"
$text1 = get-content $path_SUT_File
$newText1 = $text1 -replace $word1,$replacement1
$newText1 > $path_SUT_File
Write-host "$replacement1"

$word31 = "da.enron.isValidate=" 
$replacement31 = "da.enron.isValidate=false"
$text31 = get-content $path_SUT_File 
$newText31 = $text31 -replace $word31,$replacement31
$newText31 > $path_SUT_File

$word41 = "da.log.level="
$replacement41 = "da.log.level=ERROR"
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



$portSQL = "3306"
$word203 = "da.mysql.host="
$replacement203 = "da.mysql.host=$firstRow"
$text203 = get-content $path_SUT_File
$newText203 = $text203 -replace $word203,$replacement203
$newText203 > $path_SUT_File
Write-Host "$replacement203"




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
$replacement42 = "test.browser.type=CHROME"
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
$replacement61 = "test.log.level=ERROR"
$text61 = get-content $path_SUT_File 
$newText61 = $text61 -replace $word61,$replacement61
$newText61 > $path_SUT_File





$automationPropertiesFileSanity = "C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\runAutomationSuit.bat"
$updateGradleProperties = "pushd C:\jenkins-ws\da-remote-install\
                           gradlew test aggregate -i -p C:\jenkins-ws\DA-Automation_$buildNumber\da-test-sanity
                           popd"
Set-Content -Value $updateGradleProperties -Path $automationPropertiesFileSanity

Get-Content C:\jenkins-ws\DA-Automation_$buildNumber\sut_orig.properties | Set-Content -Encoding utf8 C:\jenkins-ws\DA-Automation_$buildNumber\sut.properties


#Run Automation




Write-Host "========== Run Automation Suit ============="
Write-Host "===================Sanity Automation is running================="
$runtAutomation= "C:\jenkins-ws\da-remote-install\automatedDeployment\distributedLab\runAutomationSuit.bat"
&$runtAutomation





#Delete DeploymentGroup
sleep -Seconds 30
aws deploy delete-deployment-group --application-name DAInstallation --deployment-group-name DA_Installation_$buildNumber
Write-Host " ============ Delete deplyment group: DA_Installation_$buildNumber ========================="

Stop-Transcript
