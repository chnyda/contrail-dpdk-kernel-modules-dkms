// Load shared libs
def common = new com.mirantis.mk.Common()
def aptly = new com.mirantis.mk.Aptly()
def debian = new com.mirantis.mk.Debian()


node('docker') {

    try {

        def timestamp = common.getDatetime()
        def workspace = common.getWorkspace()
        checkout scm

        stage("Cleanup") {
            debian.cleanup()
        }

        stage("Build binary") {

            sh("""
                export TIMESTAMP=$timestamp && \
                export DIST=$DIST && \
                export DPDK_BRANCH=$SOURCE_BRANCH && \
                make all \
                """)
        }

        archiveArtifacts artifacts: "build-area/*.deb"

        stage("Upload package") {
            buildSteps = [:]
            debFiles = sh script: "ls build-area/*.deb", returnStdout: true
            for (file in debFiles.tokenize()) {
                def fh = new File("${workspace}/${file}".trim())
                buildSteps[fh.name.split('_')[0]] = aptly.uploadPackageStep(
                    "build-area/${fh.name}",
                    APTLY_URL,
                    APTLY_REPO,
                    true
                )
            }
            parallel buildSteps
        }
    } catch (Throwable e) {
       currentBuild.result = "FAILURE"
       throw e
    } finally {
       common.sendNotification(currentBuild.result, "", ["slack"])
    }
}
