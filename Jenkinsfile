pipeline{
  agent any
  environment {
    TF_IN_AUTOMATION = 'true'
    TF_CLI_CONFIG_FILE = credentials('tf-cred')
    AWS_SHARED_CREDENTIALS_FILE='/home/ubuntu/.aws/credentials'
  }
  stages{
    stage('Destroy'){
      steps{
        sh 'terraform destroy --auto-approve -no-color -var-file="$BRANCH_NAME.tfvars"'
      }
    }
  }
  post {
    success{
      echo 'Successs!'
    }
    failure{
      sh 'terraform destroy --auto-approve -no-color -var-file="$BRANCH_NAME.tfvars"'
      echo 'Failure!'
    }
    aborted{
      sh 'terraform destroy --auto-approve -no-color -var-file="$BRANCH_NAME.tfvars"'
    }
  }
}