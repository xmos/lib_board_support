// This file relates to internal XMOS infrastructure and should be ignored by external users

@Library('xmos_jenkins_shared_library@v0.34.0') _

getApproval()
def archiveLib(String repoName) {
    sh "git -C ${repoName} clean -xdf"
    sh "zip ${repoName}_sw.zip -r ${repoName}"
    archiveArtifacts artifacts: "${repoName}_sw.zip", allowEmptyArchive: false
}

def checkout_shallow()
{
  checkout scm: [
    $class: 'GitSCM',
    branches: scm.branches,
    userRemoteConfigs: scm.userRemoteConfigs,
    extensions: [[$class: 'CloneOption', depth: 1, shallow: true, noTags: false]]
  ]
}

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
            defaultValue: 'v6.1.2',
            description: 'The xmosdoc version'
        )
        string(
            name: 'INFR_APPS_VERSION',
            defaultValue: 'v2.0.1',
            description: 'The infr_apps version'
        )
    }
    environment {
        REPO = 'lib_board_support'
        PYTHON_VERSION = "3.12.1"
    }

    stages {
        stage('Build and tests') {
            agent {
                label 'documentation && linux && x86_64'
            }
            stages{
                stage('Checkout'){
                    steps {
                        println "Stage running on: ${env.NODE_NAME}"
                        dir("${REPO}") {
                            checkout_shallow()
                            createVenv()
                            withTools(params.TOOLS_VERSION) {
                                dir("examples") {
                                    sh 'cmake -G "Unix Makefiles" -B build -DDEPS_CLONE_SHALLOW=TRUE'
                                }
                            }
                        } // dir
                    } // steps
                } // stage('Checkout')
                stage('Library checks') {
                    steps {
                        warnError("lib checks") {
                            runLibraryChecks("${WORKSPACE}/${REPO}", "${params.INFR_APPS_VERSION}")
                        }
                    } // steps
                }  // stage('Library checks')
                stage('Build examples'){
                    steps {
                        dir("${REPO}/examples") {
                            withVenv {
                                withTools(params.TOOLS_VERSION) {
                                    sh 'cmake -G "Unix Makefiles" -B build -DDEPS_CLONE_SHALLOW=TRUE'
                                    archiveArtifacts artifacts: "build/manifest.txt", allowEmptyArchive: false
                                    sh "xmake -C build -j 16"
                                    archiveArtifacts artifacts: "**/*.xe", allowEmptyArchive: false
                                    stash name: "xe_files", includes: "**/*.xe"
                                }
                            }
                        }
                    }
                } // stage('Build examples')
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
                } // stage('Test')
                stage('Documentation') {
                    steps {
                        dir("${REPO}") {
                            warnError("Docs") {
                                buildDocs()
                            } // warnError("Docs")
                        } // dir
                    } // steps
                } // stage('Documentation')
                stage("Archive Lib") {
                    steps {
                        archiveLib(REPO)
                    }
                } //stage("Archive Lib")
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
