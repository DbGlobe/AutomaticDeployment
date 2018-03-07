pushd C:\jenkins-ws\da-remote-install
cmd /C "gradlew build -x test -p C:\jenkins-ws\da-remote-install\robot-framework runRemote"
popd