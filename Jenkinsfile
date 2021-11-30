pipeline {
    agent any

    environment {
      NOTHING = "NOTHING"
    }

    stages {

      stage('Build'){
        when {
            branch 'master'
            branch 'release/*'
        }
        steps{
          sh 'echo $BRANCH_NAME'
          sh 'docker build -t portfolio .'
        }
      }

      stage('Tests'){
        when {
            branch 'master'
            branch 'release/*'
        }
        steps{
          sh 'echo $BRANCH_NAME'
          sh 'docker-compose up --build -d'
          sh 'sleep 10'
          sh 'docker exec flask curl localhost:5000'
          sh 'docker-compose down'
        }
      }

      stage('Push Latest'){
        when {
            branch 'master'
        }
        steps{
          sh 'echo $BRANCH_NAME'
          sh 'docker login -u AWS -p $(aws ecr get-login-password --region eu-central-1) 377834893374.dkr.ecr.eu-central-1.amazonaws.com'
          sh 'docker tag portfolio:latest 377834893374.dkr.ecr.eu-central-1.amazonaws.com/portfolio:latest'
          sh 'docker push 377834893374.dkr.ecr.eu-central-1.amazonaws.com/portfolio:latest'
          sh 'git clean -f'
        }
      }

      stage('Pushing Release'){
        when {
            branch 'release/*'
        }
        steps{
          sh 'echo $BRANCH_NAME'
          sh 'git fetch --tags'
          sh 'echo $BRANCH_NAME | cut -d/ -f2 > RELNUM'
          sh 'git tag | grep $(cat RELNUM) | tail -1 | echo "$(($(cut -d. -f3)+1))" > TAGY'
          sh 'echo $(cat TAGY)'
          sh 'echo $(cat RELNUM)'
          sh 'echo "$(cat RELNUM).$(cat TAGY)" > TAGVER'
          sh 'docker login -u AWS -p $(aws ecr get-login-password --region eu-central-1) 377834893374.dkr.ecr.eu-central-1.amazonaws.com'
          sh 'docker tag portfolio:latest 377834893374.dkr.ecr.eu-central-1.amazonaws.com/portfolio:$(cat TAGVER)'
          sh 'docker push 377834893374.dkr.ecr.eu-central-1.amazonaws.com/portfolio:$(cat TAGVER)'
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
