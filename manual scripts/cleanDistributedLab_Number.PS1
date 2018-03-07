$number=20
Do {
    $number
    $number++
    Remove-Item C:\jenkins-ws\da-remote-install\automatedDeployment\AD_perBuild\distributedLab_$number -Recurse
    }
While ($number -le 22)