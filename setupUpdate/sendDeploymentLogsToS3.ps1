aws configure set AWS_ACCESS_KEY_ID AKIAJ64LA7AI557VBVVQ
aws configure set AWS_SECRET_ACCESS_KEY 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
aws configure set default.region us-west-2

$date = Get-Date -format u
aws s3 cp --recursive C:/ProgramData/Amazon/CodeDeploy/log s3://da-code-deploy-bucket/CodeDeployRunResult_$date
aws s3 cp --recursive C:/ProgramDat/Amazon/CodeDeploy/deployment-logs s3://da-code-deploy-bucket/deployment-logs_$date
Remove-Item -path C:\DAInstallation\Latest\* -Force