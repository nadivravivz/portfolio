pipeline {
    agent any

    environment {
      NOTHING = "NOTHING"
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
          sh 'echo "------------------------Building and E2E TEST---------------------------"'
          sh 'docker build -t <AWS ID>.dkr.ecr.eu-central-1.amazonaws.com/portfolio:latest .'
          sh 'docker-compose up --build -d'
          sh 'sleep 10'
          sh 'docker exec flask curl localhost:5000'
          sh 'docker-compose down'
          sh 'echo "------------------------Pushing to ECR---------------------------"'
          sh 'docker login -u AWS -p $(aws ecr get-login-password --region eu-central-1) <AWS ID>.dkr.ecr.eu-central-1.amazonaws.com'
          sh 'docker push <AWS ID>.dkr.ecr.eu-central-1.amazonaws.com/portfolio:latest'
          sh 'git clean -f'
        }
      }

      stage('On Branch Feature'){
        when {
          branch 'release/*'
          }
        steps{
          sh 'echo $BRANCH_NAME'
          sh 'echo "------------------------Calculate Tag---------------------------"'
          sh 'git fetch --tags'
          sh 'echo $BRANCH_NAME | cut -d/ -f2 > RELNUM'
          sh 'git tag | grep $(cat RELNUM) | tail -1 | echo "$(($(cut -d. -f3)+1))" > TAGY'
          sh 'echo $(cat TAGY)'
          sh 'echo $(cat RELNUM)'
          sh 'echo "$(cat RELNUM).$(cat TAGY)" > TAGVER'
          sh 'echo "------------------------Building and E2E TEST---------------------------"'
          sh 'docker build -t <AWS ID>.dkr.ecr.eu-central-1.amazonaws.com/portfolio:$(cat TAGVER) .'
          sh 'docker-compose up --build -d'
          sh 'sleep 10'
          sh 'docker exec flask curl localhost:5000'
          sh 'docker-compose down'
          sh 'echo "------------------------Pushing to ECR---------------------------"'
          sh 'docker login -u AWS -p $(aws ecr get-login-password --region eu-central-1) <AWS ID>.dkr.ecr.eu-central-1.amazonaws.com'
          sh 'docker push <AWS ID>.dkr.ecr.eu-central-1.amazonaws.com/portfolio:$(cat TAGVER)'
          sh 'echo "------------------------Tagging and Push Tag---------------------------"'
          sh 'git tag $(cat TAGVER)'
          sh 'git push --tags'
          sh 'git clean -f'
          }
      }

      stage('When on any other branch'){
        when {
            not {
                anyOf {
                  branch 'release/*';
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
