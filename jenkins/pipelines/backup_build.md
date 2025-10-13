#### This stage:

Enters the working directory.  
Creates a timestamped ZIP file of the build directory.  
Moves the ZIP file to a backup location for safekeeping.

```sh
    stage('Old Build Backup') {
        steps {
            dir("${WORKDIR}") {
                script {
                    def timestamp = new Date().format("ddMMyyyy-HHmmss")
                    def zipFileName = "build-backup-${timestamp}.zip"
                    sh "zip -r ${zipFileName} build"
                    sh "mv ${zipFileName} /home/dev/trk_backup/frd_backup/"
                }
            }
        }
    }
```
