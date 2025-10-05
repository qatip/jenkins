pipeline {
  agent any
  environment {
    ARM_CLIENT_ID       = credentials('azure_sp_client_id')
    ARM_CLIENT_SECRET   = credentials('azure_sp_client_secret')
    ARM_SUBSCRIPTION_ID = credentials('azure_subscription_id')
    ARM_TENANT_ID       = credentials('azure_tenant_id')
    TERRAFORM_VERSION   = "1.5.6"
    ALLOW_INBOUND_CIDR = "0.0.0.0/0"
  }
  stages {
    stage('Checkout') {
      steps {
        git branch: 'main', url: 'https://github.com/qatip/jenkins.git'
      }
    }
    stage('Install Terraform') {
      steps {
        sh '''
          if ! command -v terraform >/dev/null 2>&1; then
            sudo apt-get update -y && sudo apt-get install -y unzip
            curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o tf.zip
            unzip -o tf.zip && sudo mv terraform /usr/local/bin/ && rm -f tf.zip
          fi
          terraform --version
        '''
      }
    }
    stage('Init, Plan, Apply') {
      steps {
        withCredentials([file(credentialsId: 'vm-pubkey-file', variable: 'PUBKEY_FILE')]) {
          sh '''
            export TF_VAR_ssh_public_key_path="$PUBKEY_FILE"
            terraform init -input=false -reconfigure
            terraform validate
            terraform plan \
              -var "allow_inbound_cidr=${ALLOW_INBOUND_CIDR:-0.0.0.0/0}" \
              -out=tfplan
            terraform apply -auto-approve tfplan
          '''
        }
      }
    }
  }
  post {
    success { echo 'Resources created successfully!' }
    failure { echo 'Pipeline failed. Check logs.' }
  }
}
