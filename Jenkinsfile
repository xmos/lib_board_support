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
    }
    environment {
        REPO = 'lib_board_support'
        PYTHON_VERSION = "3.10.5"
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
                        sh 'mkdir ${REPO}'
                        // source checks require the directory
                        // name to be the same as the repo name
                        dir("${REPO}") {
                            // checkout repo
                            checkout scm
                            installPipfile(false)
                            withVenv {
                                withTools(params.TOOLS_VERSION) {
                                    sh "git clone -b v1.2.1 git@github.com:xmos/infr_scripts_py"
                                    sh "git clone -b v1.6.0 git@github.com:xmos/infr_apps"
                                    sh "pip install -e infr_scripts_py"
                                    sh "pip install -e infr_apps"
                                    
                                    withEnv(["REPO=${REPO}", "XMOS_ROOT=.."]) {
                                        xcoreLibraryChecks("${REPO}", false)
                                        junit "junit_lib.xml"
                                    } // withEnv
                                }
                            }
                        }
                    }
                }
                stage('Docs') {
                    environment { XMOSDOC_VERSION = "v4.0" }
                    steps {
                        dir("${REPO}") {
                            sh "docker pull ghcr.io/xmos/xmosdoc:$XMOSDOC_VERSION"
                            sh """docker run -u "\$(id -u):\$(id -g)" \
                                --rm \
                                -v \$(pwd):/build \
                                ghcr.io/xmos/xmosdoc:$XMOSDOC_VERSION -v html latex"""

                            // Zip and archive doc files
                            zip dir: "doc/_build/html", zipFile: "${REPO}_docs_html.zip"
                            archiveArtifacts artifacts: "${REPO}_docs_html.zip"
                            archiveArtifacts artifacts: "doc/_build/latex/${REPO}_*.pdf"
                        }
                    }
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
                                    // junit 'tests/results.xml'
                                }
                            }
                        }
                    }
                }
            }
            post {
                cleanup {
                    xcoreCleanSandbox()
                }
            }
        }
    }
}
