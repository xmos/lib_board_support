// This file relates to internal XMOS infrastructure and should be ignored by external users

@Library('xmos_jenkins_shared_library@v0.39.0') _

getApproval()
pipeline {

    agent {
        label 'x86_64 && linux && documentation'
    }

    options {
        buildDiscarder(xmosDiscardBuildSettings())
        skipDefaultCheckout()
        timestamps()
    }

    parameters {
        string(
            name: 'TOOLS_VERSION',
            defaultValue: '15.3.1',
            description: 'The XTC tools version'
        )
        string(
            name: 'XMOSDOC_VERSION',
            defaultValue: 'v7.2.0',
            description: 'The xmosdoc version'
        )
        string(
            name: 'INFR_APPS_VERSION',
            defaultValue: 'v2.1.0',
            description: 'The infr_apps version'
        )
    }
    environment {
        REPO_NAME = 'lib_board_support' // Needed for xcoreBuild()
                                        // (https://github.com/xmos/xmos_jenkins_shared_library/issues/370)
        PYTHON_VERSION = '3.12.1'
    }

    stages{
        stage('Checkout & build'){
            steps {
                println "Stage running on: ${env.NODE_NAME}"
                dir("${REPO_NAME}") {
                    checkoutScmShallow()
                    withTools(params.TOOLS_VERSION) {
                        dir("examples") {
                            // Note, archives xe files
                            xcoreBuild()
                        }
                    }
                } // dir
            } // steps
        } // stage('Checkout & build')
        stage('Library checks') {
            steps {
                warnError("lib checks") {
                    runLibraryChecks("${WORKSPACE}/${REPO_NAME}", "${params.INFR_APPS_VERSION}")
                }
            } // steps
        }  // stage('Library checks')
        stage('Test'){
            steps {
                dir("${REPO_NAME}") {
                    createVenv()
                    withVenv {
                        withTools(params.TOOLS_VERSION) {
                            // Stage currently empty as no specific tests yet
                        }
                    }
                }
            }
        } // stage('Test')
        stage('Documentation') {
            steps {
                dir("${REPO_NAME}") {
                    warnError("Docs") {
                        buildDocs()
                    } // warnError("Docs")
                } // dir
            } // steps
        } // stage('Documentation')
        stage("Archive") {
            steps {
                archiveSandbox(REPO_NAME)
            }
        } //stage("Archive")
    }
    post {
        always{
            dir("${REPO_NAME}/tests") {
                // No test yet so this is a placeholder
                // junit 'results.xml'
            }
        }
        cleanup {
            xcoreCleanSandbox()
        }
    }
}
