param(

[string]$DAHome= 'C:\Installation\DAInstallation\Latest',
[string]$runFCInstallation = $DAHome + '\DA_silence_FC_Installation.bat',
[string]$runMPInstalation = $DAHome + '\DA_silence_MP_Installation.bat',
[string]$runMySQL_SolrInstallation = $DAHome + '\DA_silence_MySQL_Solr_Installation.bat',
[string]$runAIO_Automation_Machine = $DAHome + '\DA_silence_AIO_Installation.bat'


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
}

$myFQDN=(Get-WmiObject win32_computersystem).Domain
if ($myFQDN -eq "simple.docauthority.com")

{
aws configure set AWS_ACCESS_KEY_ID AKIAJ64LA7AI557VBVVQ
aws configure set AWS_SECRET_ACCESS_KEY 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
aws configure set default.region us-west-2
}


$getTagName= aws ec2 describe-instances  --instance-ids $instanceID --output json > C:\Installation\DAInstallation\Latest\instance.json
Write-Host $getTagName

$json_TagName = (Get-Content C:\Installation\DAInstallation\Latest\instance.json -Raw) | ConvertFrom-Json
$instanceTagName= $json_TagName.Reservations.Instances.Tags.Value

Write-Host $instanceTagName


if ($instanceTagName.EndsWith("_FC"))
{
 &$runFCInstallation
 break
 }

 if ($instanceTagName.Contains("_MP_"))
 {
  &$runMPInstalation
  break
  }

  if ($instanceTagName.EndsWith("_MySQL"))
 {
  &$runMySQL_SolrInstallation
  break
  }

if ($instanceTagName.StartsWith("AIO_"))
{
  &$runAIO_Automation_Machine
  break
  }

   