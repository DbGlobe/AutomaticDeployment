param (
 [string] $runCreateCollection= 'C:\Installation\DAInstallation\Latest\runCreateCollection',
 [string] $resetScheme_secondRun = 'C:\Installation\DAInstallation\Latest\DA_silence_FC_Installation_secondRun.bat',
 [string] $resetScheme = 'C:\Installation\DAInstallation\Latest\resetScheme.bat',
 [string] $startFileClusterService = 'C:\Installation\DAInstallation\Latest\startFileClusterService',
 [string] $doAlignShards = 'C:\Installation\DAInstallation\Latest\doAlignShards.bat',
 [string] $AlignShards = 'C:\Installation\DAInstallation\Latest\AlignShards.bat do-align'


)


$env:Path += ';C:\Program Files\Amazon\AWSCLI'
Enable-PSRemoting -Force
write-host "AWS SET PARAMTERS"

$instanceID = (New-Object System.Net.WebClient).DownloadString("http://169.254.169.254/latest/meta-data/instance-id")

Write-Host "$instanceID"

$myFQDN=(Get-WmiObject win32_computersystem).Domain
if ($myFQDN -eq "testing.da.com")

{
aws configure set AWS_ACCESS_KEY_ID AKIAJES7XW26B4A4CD3A
aws configure set AWS_SECRET_ACCESS_KEY 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
aws configure set default.region us-west-2
Write-Host "My DOMAIN is: ==== testing.da.com  =========="
}

$myFQDN=(Get-WmiObject win32_computersystem).Domain
if ($myFQDN -eq "simple.docauthority.com")

{
aws configure set AWS_ACCESS_KEY_ID AKIAJ64LA7AI557VBVVQ
aws configure set AWS_SECRET_ACCESS_KEY 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
aws configure set default.region us-west-2
Write-Host "My DOMAIN is: ==== simple.docauthority.com =========="
}



$getTagName= aws ec2 describe-instances  --instance-ids $instanceID --output json > C:\Installation\DAInstallation\Latest\instance.json
Write-Host $getTagName

$json_TagName = (Get-Content C:\Installation\DAInstallation\Latest\instance.json -Raw) | ConvertFrom-Json
$instanceTagName= $json_TagName.Reservations.Instances.Tags.Value

Write-Host $instanceTagName

if ($instanceTagName.EndsWith("_FC"))
{
 Write-Host  "Create Solr Collections"
 &$runCreateCollection

Write-Host  "Do Align Shards"
 &$doAlignShards

Write-Host "Align Shards"
&$AlignShards

Write-Host  "Reset DB Scheme"
&$resetScheme

Write-Host  "Start FileCluster Service"
&$startFileClusterService

 break
 }

if ($instanceTagName.StartsWith("AIO_"))
{
 Write-Host  "Create Solr Collections"
&$runCreateCollection

Write-Host  "Reset DB Scheme"
&$resetScheme

Write-Host  "Start FileCluster Service"
&$startFileClusterService

 break
 }