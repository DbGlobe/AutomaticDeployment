param(

[string]$DAHome= 'C:\DAInstallation\Latest',
[string]$runFCInstallation  =$DAHome + '\DA_silence_FC_Installation.bat',
[string]$runSolrInstalation = $DAHome + '\DA_silence_Solr_Installation.bat'

)

aws configure set AWS_ACCESS_KEY_ID AKIAJ64LA7AI557VBVVQ
aws configure set AWS_SECRET_ACCESS_KEY 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
aws configure set default.region us-west-2

$instanceId = Get-Content -Path $DAHome\InstanceID.txt
$getTagName= aws ec2 describe-instances  --instance-ids $instanceID --output json > $DAHome\instance.json
Write-Host $getTagName

$json_TagName = (Get-Content $DAHome\instance.json -Raw) | ConvertFrom-Json
$instanceTagName= $json_TagName.Reservations.Instances.Tags.Value | Out-File $DAHome\InstanceName.txt

Write-Host $instanceTagName