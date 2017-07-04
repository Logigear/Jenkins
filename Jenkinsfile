pipeline {
    agent {
        node {
            label 'master'
        }
    }
    stages {
        stage('test') {
            steps {
                // Run a set of batch files on each slave in parallel
                script {
                    if (isUnix()) {
                        sh '''
                            rm -rf "${WORKSPACE}/BAT/"*
                            cp -r "${BatchLocation}/"* "${WORKSPACE}/BAT"
                        '''
                    } else {
                        bat '''
                            del "%WORKSPACE%/BAT/*"
                            cd "%BatchLocation_Win%"
                            copy * "%WORKSPACE%/BAT"
                        '''
                    }
                    def jobs = [:]
                    branches = "${BRANCHES}".toString().trim().split(',')
                    for (int k = 0; k < branches.size(); k++) {
                        def _k = k
                        echo branches[_k]
                    }
                    for (int b = 0; b < branches.size(); b++) {
                        def _b = b
                        String branch = branches[_b]
                        //get bat files on workspace (master)
                        def fslLinux = getFiles("BAT/" + branch + "/*.sh")
                        def fslWindows = getFiles("BAT/" + branch + "/*.bat")
                        def fsLinuxContentList = []
                        def fsWindowsContentList = []

                        //Read content of bat files and put into arrayList
                        for (int t = 0; t < fslLinux.size(); t++) {
                            def _t = t
                            string content = readFile(fslLinux[_t].toString())
                            fsLinuxContentList << content
                        }

                        //Read content of bat files and put into arrayList
                        for (int t = 0; t < fslWindows.size(); t++) {
                            def _t = t
                            string content = readFile(fslWindows[_t].toString())
                            fsWindowsContentList << content
                        }
                        //Get online Slaves
                        def slLstLinux = getLinuxSlaves(branch)
                        def slLstWindows = getWindowsSlaves(branch)

                        echo "[" + branch + "]----------LINUX--------"
                        echo "[" + branch + "]number of sh files: " + fslLinux.size()
                        echo "[" + branch + "]number of Linux slaves: " + slLstLinux.size()
                        echo "[" + branch + "]----------WINDOWS--------"
                        echo "[" + branch + "]number of bat files: " + fslWindows.size()
                        echo "[" + branch + "]number of Windows slaves: " + slLstWindows.size()

                        //Loop for Linux slaves
                        for (int i = 0; i < slLstLinux.size(); i++) {
                            def _i = i
                            def slave = slLstLinux[_i]

                            echo 'DisableCheckNewBuild = ' + "${DisableCheckNewBuild}".toString()
                            //Install AUT only once with Linux
                            if (i == 0 && "${DisableCheckNewBuild}".toString() == "false") {
                                node(slave) {
                                    sh '/Landmark/data1/SilentInstall/DSG_Silent_Install/CI-CD/Linux/' + branch + '/silent_install_master.sh'
                                }
                            }
                            // Create a closure for each slave and put it in the map of jobs
                            jobs[slave] = {
                                node(slave) {
                                    //Distribute one bat to one slave
                                    for (int t = 0; t < fslLinux.size(); t++) {
                                        def _t = t
                                        if (_t % slLstLinux.size() == _i) {
                                            def str = fsLinuxContentList[_t].toString()
                                            str = str.replaceAll("/exporthtmlpath  \"\"", "/exporthtmlpath  \"${htmlLocation}/" + branch + "/${BUILD_NUMBER}\"")
                                            //str = str.replaceAll("/xupath  \"\"", "/xupath  \"${xUnitLocation}/${BUILD_NUMBER}\"")
                                            sh str
                                        }
                                    }
                                }
                            }
                        }

                        //Loop for Windows slaves
                        for (int i = 0; i < slLstWindows.size(); i++) {
                            def _i = i
                            def slave = slLstWindows[_i]
                            // Create a closure for each slave and put it in the map of jobs
                            jobs[slave] = {
                                node(slave) {
                                    //Install AUT with silent mode
                                    if ("${DisableCheckNewBuild}".toString() == "false") {
                                        bat '\\\\nas-1\\Landmark\\data1\\SilentInstall\\DSG_Silent_Install\\CI-CD\\Windows\\' + branch + '\\Silent_Installation_Filer.bat'
                                    }

                                    //Distribute one bat to one slave
                                    for (int t = 0; t < fslWindows.size(); t++) {
                                        def _t = t
                                        if (_t % slLstWindows.size() == _i) {
                                            def str = fsWindowsContentList[_t].toString()
                                            str = str.replaceAll("/exporthtmlpath  \"\"", "/exporthtmlpath  \"${WINDOWS_PATH}${htmlLocation}/" + branch + "/Win-${BUILD_NUMBER}\"")
                                            //str = str.replaceAll("/xupath  \"\"", "/xupath  \"${WINDOWS_PATH}${xUnitLocation}/Win-${BUILD_NUMBER}\"")
                                            echo str
                                            bat str
                                        }
                                    }
                                }
                            }
                        }
                    }
                    //jobs.failFast = true
                    parallel jobs
                }
            }
        }

        stage('send mail') {
            steps {
                echo 'Send mail'

                for (int b = 0; b < branches.size(); b++) {
                    def _b = b
                    String branch = branches[_b]
                    //Call generate HTML tool
                    if (isUnix()) {
                        sh 'mkdir -p "${WORKSPACE}/html/' + branch + '/${BUILD_NUMBER}"'
                        sh 'mkdir -p "${WORKSPACE}/email/' + branch + '/${BUILD_NUMBER}"'
                        def number_of_files_linux = sh(script: 'ls "${htmlLocation}/' + branch + '/${BUILD_NUMBER}" | wc -l', returnStdout: true)
                        echo 'number_of_files_linux = ' + number_of_files_linux
                        if (number_of_files_linux.toString().trim() != "0") {
                            sh 'if test -d "${htmlLocation}/' + branch + '/${BUILD_NUMBER}"; then cp -r "${htmlLocation}/' + branch + '/${BUILD_NUMBER}"/* "${WORKSPACE}/html/' + branch + '/${BUILD_NUMBER}"; fi'
                        } else {
                            echo "Result empty"
                        }


                        def number_of_files_windows = sh(script: 'ls "${htmlLocation}/' + branch + '/Win-${BUILD_NUMBER}" | wc -l', returnStdout: true)
                        echo 'number_of_files_windows = ' + number_of_files_windows

                        if (number_of_files_windows.toString().trim() != "0") {
                            sh 'if test -d "${htmlLocation}/' + branch + '/Win-${BUILD_NUMBER}"; then cp -r "${htmlLocation}/' + branch + '/Win-${BUILD_NUMBER}"/* "${WORKSPACE}/html/' + branch + '/${BUILD_NUMBER}"; fi'
                        } else {
                            echo "Result empty"
                        }
                        //Generate HTML template
                        sh 'java -jar "/Landmark/apps/ForDSGAutomation/GenerateSummaryReport/GenerateSummaryReport.jar" ${WORKSPACE}/html/' + branch + '/${BUILD_NUMBER} ${WORKSPACE}/email/' + branch + '/${BUILD_NUMBER}'

                        //Copy to Halli network
                        sh 'bash /Landmark/apps/Scripts/Jenkin_Transfer/jenkin_transfer.sh ' + branch + ' ${BUILD_NUMBER} ${WORKSPACE}/email/' + branch + '/${BUILD_NUMBER}'

                        //remove temporary files
                        //sh 'rm -rf "${WORKSPACE}/html/"*'
                    } else {
                        bat("copy '%WINDOWS_PATH%%htmlLocation%' '%WORKSPACE%/html/%BUILD_NUMBER%'")
                        bat("copy '%WINDOWS_PATH%%htmlLocation%'" + branch + "/%BUILD_NUMBER% '%WORKSPACE%/html/" + branch + "/%BUILD_NUMBER%'")
                        bat("copy '%WINDOWS_PATH%%htmlLocation%'" + branch + "/Win-%BUILD_NUMBER% '%WORKSPACE%/html/" + branch + "/%BUILD_NUMBER%'")
                        bat 'java -jar "//nas-1/Landmark/apps/ForDSGAutomation/GenerateSummaryReport/GenerateSummaryReport.jar" %WORKSPACE%/html/' + branch + '"/%BUILD_NUMBER% %WORKSPACE%/email/' + branch + '"/%BUILD_NUMBER%'
                    }
                    script {
                        //get htm file
                        def htmlFiles = getFiles("email/" + branch + "/${BUILD_NUMBER}/*.html")
                        def fileName
                        if (htmlFiles.size() > 0) {
                            fileName = htmlFiles[0].name
                            //echo fileName
                            def content = readFile("email/" + branch + "/${BUILD_NUMBER}/" + fileName)
                            def autVersion = sh(script: 'grep "AUT Version" ${WORKSPACE}/email/' + branch + '/${BUILD_NUMBER}/' + fileName + '  | sed "s/.*Version: //" | sed "s/<.*//"', returnStdout: true)
                            autVersion = autVersion.replaceAll("\n", ",")
                            //Send email
                            emailext(attachLog: true, body: content, compressLog: true, subject: "Test Results of " + branch + " - " + autVersion, to: '${Recipient}')
                        }
                    }
                }
            }
        }
    }
}
@NonCPS
def getSlaves(def label = "") {
    def slaves = []
    hudson.model.Hudson.instance.slaves.each {
        def sl = it
        if(sl != null && sl.getComputer() != null && sl.getComputer().isOffline() == false){
            if(label == "") {
                slaves << sl.getNodeName()
            }
            else{
                if(sl.getLabelString() == label)
                    slaves << sl.getNodeName()
            }
        }
    }

    return slaves
}

@NonCPS
def getWindowsSlaves(def label = "") {
    def slaves = []
    hudson.model.Hudson.instance.slaves.each {
        def sl = it
        if(sl != null && sl.getComputer() != null && sl.getComputer().isOffline() == false && sl.getComputer().getOSDescription() == "Windows"){
            if(label == "") {
                slaves << sl.getNodeName()
            }
            else{
                if(sl.getLabelString() == label)
                    slaves << sl.getNodeName()
            }
        }
    }

    return slaves
}


@NonCPS
def getLinuxSlaves(def label = "") {
    def slaves = []
    hudson.model.Hudson.instance.slaves.each {
        def sl = it
        if(sl != null && sl.getComputer() != null && sl.getComputer().isOffline() == false && sl.getComputer().getOSDescription() == "Unix"){
            if(label == "") {
                slaves << sl.getNodeName()
            }
            else{
                if(sl.getLabelString() == label)
                    slaves << sl.getNodeName()
            }
        }
    }

    return slaves
}

@NonCPS
def getLabel(String slave) {
    hudson.model.Hudson.instance.slaves.each {
        def index = it
        def result = ""
        if(index != null || index.getNodeName() == slave)
            result = index.getLabelString()
        return result
    }
}


@NonCPS
def getFiles(def wildcard) {
    pwd()
    return findFiles(glob: wildcard)
}
