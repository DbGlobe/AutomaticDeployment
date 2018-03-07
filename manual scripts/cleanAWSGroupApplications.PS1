

#Define the $number to start the deletion process
$number=1
Do {
    $number
    $number++
    aws deploy delete-deployment-group --application-name DAInstallation --deployment-group-name DA_Installation_$number
    }

#Define the number to stop the deletion process
While ($number -le 20)