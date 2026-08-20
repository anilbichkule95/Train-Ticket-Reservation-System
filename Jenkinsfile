pipeline {
    agent {
        label 'openshift-agent'
    }

    environment {
        PROJECT = 'train-ticket'
        APP_NAME = 'trainbook'
        IMAGE_TAG = '1.2'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify Source') {
            steps {
                sh '''
                    echo "======================================"
                    echo "Source Code"
                    echo "======================================"

                    pwd
                    ls -la

                    echo ""
                    echo "OpenShift files:"
                    ls -la openshift/

                    echo ""
                    echo "Dockerfile:"
                    ls -l Dockerfile

                    echo ""
                    echo "pom.xml:"
                    ls -l pom.xml
                '''
            }
        }

        stage('Maven Build') {
            steps {
                container('maven') {
                    sh '''
                        echo "======================================"
                        echo "Maven Build"
                        echo "======================================"

                        java -version
                        mvn -version

                        mvn -B clean package -DskipTests
                    '''
                }
            }
        }

        stage('Run Tests') {
            steps {
                container('maven') {
                    sh '''
                        echo "======================================"
                        echo "Running Tests"
                        echo "======================================"

                        mvn -B test
                    '''
                }
            }
        }

        stage('Verify WAR') {
            steps {
                sh '''
                    echo "======================================"
                    echo "Generated WAR"
                    echo "======================================"

                    find target -type f -name "*.war" -print
                '''
            }
        }

        stage('OpenShift Login Check') {
            steps {
                container('oc') {
                    sh '''
                        echo "======================================"
                        echo "OpenShift Connection"
                        echo "======================================"

                        oc version

                        echo ""
                        echo "Current User:"
                        oc whoami

                        echo ""
                        echo "Current Project:"
                        oc project
                    '''
                }
            }
        }

        stage('Select Application Project') {
            steps {
                container('oc') {
                    sh '''
                        echo "======================================"
                        echo "Selecting Project"
                        echo "======================================"

                        oc project ${PROJECT}

                        echo ""
                        oc project
                    '''
                }
            }
        }

        stage('Apply BuildConfig') {
            steps {
                container('oc') {
                    sh '''
                        echo "======================================"
                        echo "Applying BuildConfig"
                        echo "======================================"

                        oc apply -f openshift/buildconfig.yaml

                        echo ""
                        echo "BuildConfig:"
                        oc get bc ${APP_NAME}

                        echo ""
                        echo "ImageStream:"
                        oc get is ${APP_NAME}
                    '''
                }
            }
        }

        stage('Build OpenShift Image') {
            steps {
                container('oc') {
                    sh '''
                        echo "======================================"
                        echo "OpenShift Binary Build"
                        echo "======================================"

                        oc start-build ${APP_NAME} \
                            --from-dir=. \
                            --follow

                        echo ""
                        echo "Build completed."
                    '''
                }
            }
        }

        stage('Verify Image') {
            steps {
                container('oc') {
                    sh '''
                        echo "======================================"
                        echo "Verify Image"
                        echo "======================================"

                        oc get istag ${APP_NAME}:${IMAGE_TAG}

                        echo ""
                        oc get builds
                    '''
                }
            }
        }

        stage('Deploy Configuration') {
            steps {
                container('oc') {
                    sh '''
                        echo "======================================"
                        echo "Applying Configuration"
                        echo "======================================"

                        oc apply -f openshift/configmap.yaml
                        oc apply -f openshift/secret.yaml
                    '''
                }
            }
        }

        stage('Deploy Application') {
            steps {
                container('oc') {
                    sh '''
                        echo "======================================"
                        echo "Deploying Application"
                        echo "======================================"

                        oc apply -f openshift/deployment.yaml
                        oc apply -f openshift/service.yaml
                    '''
                }
            }
        }

        stage('Fix Deployment Image') {
            steps {
                container('oc') {
                    sh '''
                        echo "======================================"
                        echo "Setting Application Image"
                        echo "======================================"

                        oc set image deployment/${APP_NAME} \
                            ${APP_NAME}=image-registry.openshift-image-registry.svc:5000/${PROJECT}/${APP_NAME}:${IMAGE_TAG}

                        echo ""
                        echo "Deployment image:"
                        oc get deployment ${APP_NAME} \
                            -o jsonpath='{.spec.template.spec.containers[0].image}'

                        echo ""
                    '''
                }
            }
        }

        stage('Rollout') {
            steps {
                container('oc') {
                    sh '''
                        echo "======================================"
                        echo "Waiting for Deployment"
                        echo "======================================"

                        oc rollout status deployment/${APP_NAME} \
                            --timeout=180s
                    '''
                }
            }
        }

        stage('Application Status') {
            steps {
                container('oc') {
                    sh '''
                        echo "======================================"
                        echo "Application Status"
                        echo "======================================"

                        echo ""
                        echo "Pods:"
                        oc get pods -l app=${APP_NAME}

                        echo ""
                        echo "Deployment:"
                        oc get deployment ${APP_NAME}

                        echo ""
                        echo "Service:"
                        oc get svc ${APP_NAME}

                        echo ""
                        echo "Routes:"
                        oc get route
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '======================================'
            echo 'TRAINBOOK DEPLOYMENT SUCCESSFUL'
            echo '======================================'
        }

        failure {
            echo '======================================'
            echo 'TRAINBOOK DEPLOYMENT FAILED'
            echo '======================================'
        }

        always {
            echo 'Cleaning Jenkins workspace...'
            deleteDir()
        }
    }
}