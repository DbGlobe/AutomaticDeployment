param(

[string]$DAHome= 'C:\DAInstallation\Latest',
[string]$runFCInstallation  =$DAHome + '\DA_silence_FC_Installation.bat',
[string]$runSolrInstalation = $DAHome + '\DA_silence_Solr_Installation.bat'

)
aws configure set AWS_ACCESS_KEY_ID AKIAJ64LA7AI557VBVVQ
aws configure set AWS_SECRET_ACCESS_KEY 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
aws configure set default.region us-west-2

$instanceTagName = Get-Content -Path $DAHome\InstanceName.txt

if ($instanceTagName.EndsWith("_FC"))
{
 &$runFCInstallation}
 if ($instanceTagName.EndsWith("_Solr") )
 {
  &$runSolrInstalation}
  if ($instanceTagName.EndsWith("_MySQL"))
  {Exit-PSSession}