#### Stage : Build backup Zip

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
#### Stage : Delete older backup files
(works along with Stage : Build backup Zip)

Lists all backup ZIP files in the backup directory.  
Sorts them by name (which includes a timestamp).  
Keeps the two most recent backups.  
Deletes all older backups to save disk space.

```sh
stage('Cleanup Old Backups') {
    steps {
        script {
            def backupDir = "/home/dev/trk_backup/frd_backup"
            def backups = sh(script: "ls -1 ${backupDir}/build-backup-*.zip | sort", returnStdout: true).trim().split("\n")
            if (backups.size() > 2) {
                def oldBackups = backups[0..<(backups.size() - 2)]
                oldBackups.each { file ->
                    sh "rm -f ${file}"
                }
            }
         }
     }
  }
```
