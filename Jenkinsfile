// This file relates to internal XMOS infrastructure and should be ignored by external users

@Library('xmos_jenkins_shared_library@v0.34.0') _

getApproval()

pipeline {
    agent none

    options {
        disableConcurrentBuilds()
        skipDefaultCheckout()
        timestamps()
        // on develop discard builds after a certain number else keep forever
        buildDiscarder(logRotator(
            numToKeepStr:         env.BRANCH_NAME ==~ /develop/ ? '25' : '',
            artifactNumToKeepStr: env.BRANCH_NAME ==~ /develop/ ? '25' : ''
        ))
    }
    parameters {
        string(
            name: 'TOOLS_VERSION',
            defaultValue: '15.3.0',
            description: 'The XTC tools version'
        )
        string(
            name: 'XMOSDOC_VERSION',
            defaultValue: '6.1.0',
            description: 'The xmosdoc version'
        )
    }
    environment {
        REPO = 'lib_board_support'
        PYTHON_VERSION = "3.12.1"
        VENV_DIRNAME = ".venv"
    }

    stages {
        stage('Build and tests') {
            agent {
                label 'linux&&64'
            }
            stages{
                stage('Checkout'){
                    steps {
                        println "Stage running on: ${env.NODE_NAME}"
                        dir("${REPO}") {
                            checkout scm
                            createVenv()
                            withTools(params.TOOLS_VERSION) {
                                sh "cmake  -G \"Unix Makefiles\" -B build"
                            }
                        } // dir
                    } // steps
                }
                stage('Library checks') {
                    steps {
                        runLibraryChecks("${WORKSPACE}/${REPO}", "v2.0.1")
                    } // steps
                }  // Library checks
                stage('Build'){
                    steps {
                        dir("${REPO}") {
                            withVenv {
                                withTools(params.TOOLS_VERSION) {
                                    sh "cmake  -G \"Unix Makefiles\" -B build"
                                    archiveArtifacts artifacts: "build/manifest.txt", allowEmptyArchive: false
                                    sh "xmake -C build -j 16"
                                    archiveArtifacts artifacts: "**/*.xe", allowEmptyArchive: false
                                    stash name: "xe_files", includes: "**/*.xe"
                                }
                            }
                        }
                    }
                }
                stage('Test'){
                    steps {
                        dir("${REPO}") {
                            withVenv {
                                withTools(params.TOOLS_VERSION) {
                                    // Stage currently empty as no specific tests yet
                                }
                            }
                        }
                    }
                }
                stage('Documentation') {
                    steps {
                        dir("${REPO}") {
                            withVenv {
                                sh "pip install git+ssh://git@github.com/xmos/xmosdoc@v${params.XMOSDOC_VERSION}"
                                    sh 'xmosdoc'
                                    zip zipFile: "${REPO}_docs.zip", archive: true, dir: 'doc/_build'
                            } // withVenv
                        } // dir
                    } // steps
                } // Documentation

            }
            post {
                always{
                    dir("${REPO}/tests") {
                        // No test yet so this is a placeholder
                        // junit 'results.xml'
                    }
                }
                cleanup {
                    xcoreCleanSandbox()
                }
            }
        }
    }
}
