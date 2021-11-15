pipeline {
    agent any

    environment {
      REGION = "eu-central-1"
      AWSPUT = "text"
      REPONAME = "ravivrepo"
      AWSIP = "3.67.42.146"
    }

    stages {

      stage('echo') {
        steps {
          sh 'echo $BRANCH_NAME'
          }
      }

      stage('On Master'){
        when {
            branch 'master'
        }
        steps{
          sh 'echo $BRANCH_NAME'
        }
      }

      stage('On Branch Feature'){
        when {
          branch 'feature/*'
          }
        steps{
          sh 'echo $BRANCH_NAME'
          }
      }

      stage('When on any other branch'){
        when {
            not {
                anyOf {
                  branch 'feature/*';
                  branch 'master'
                }
            }
        }
          steps{
            sh 'echo $BRANCH_NAME'
            sh 'echo "Im not doing anything"'
            }
          }
      }

      post {
        always {
          sh 'echo nice'
        }
        success {
          mail bcc: '', body: 'Success!', cc: '', from: '', replyTo: '', subject: 'Success!', to: 'ravivnadiv2@gmail.com'
        }
        unsuccessful {
          mail bcc: '', body: 'FAILED', cc: '', from: '', replyTo: '', subject: 'FAILED', to: 'ravivnadiv2@gmail.com'
        }
      }
}
