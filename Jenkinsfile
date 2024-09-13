// This file relates to internal XMOS infrastructure and should be ignored by external users

@Library('xmos_jenkins_shared_library@v0.33.0') _

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
            defaultValue: '6.0.0',
            description: 'The xmosdoc version'
        )
    }
    environment {
        REPO = 'lib_board_support'
        PYTHON_VERSION = "3.10"
        VENV_DIRNAME = ".venv"
    }

    stages {
        stage('Build and tests') {
            agent {
                label 'linux&&64'
            }
            stages{
                stage('Checkout and lib checks'){
                    steps {
                        println "Stage running on: ${env.NODE_NAME}"
                        sh "git clone -b v1.2.1 git@github.com:xmos/infr_scripts_py"
                        sh "git clone -b v1.6.0 git@github.com:xmos/infr_apps"

                        dir("${REPO}") {
                            checkout scm
                            createVenv()
                            withVenv {
                                sh "pip install -e ../infr_scripts_py"
                                sh "pip install -e ../infr_apps"

                                // Grab dependancies before changelog check
                                withTools(params.TOOLS_VERSION) {
                                    sh "cmake  -G \"Unix Makefiles\" -B build"
                                }

                                // installPipfile(false)
                                withTools(params.TOOLS_VERSION) {
                                    withEnv(["REPO=${REPO}", "XMOS_ROOT=.."]) {
                                        xcoreLibraryChecks("${REPO}", false)
                                        // junit "junit_lib.xml"
                                    } // withEnv
                                } // withTools
                            } // Venv
                        } // dir
                    } // steps
                }

                stage('Build'){
                    steps {
                        dir("${REPO}") {
                            withVenv {
                                withTools(params.TOOLS_VERSION) {
                                    sh "cmake  -G \"Unix Makefiles\" -B build"
                                    archiveArtifacts artifacts: "build/manifest.txt", allowEmptyArchive: false
                                    sh "xmake -C build -j"
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
