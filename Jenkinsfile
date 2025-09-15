pipeline {
  agent any
  environment {
    ARM_CLIENT_ID       = credentials('azure_sp_client_id')
    ARM_CLIENT_SECRET   = credentials('azure_sp_client_secret')
    ARM_SUBSCRIPTION_ID = credentials('azure_subscription_id')
    ARM_TENANT_ID       = credentials('azure_tenant_id')
    TERRAFORM_VERSION   = "1.5.6"
    ALLOWED_IP_CIDRS = '["86.153.89.63/32","108.143.120.41/32"]'
    
  }
  stages {
    stage('Checkout') {
      steps {
        git branch: 'main', url: 'https://github.com/qatip/jenkins.git'
        // if TF is in a subfolder, add: dir('infra/azure/vm'){ ... } around TF steps below
      }
    }
    stage('Install Terraform') {
      steps {
        sh '''
          if ! command -v terraform >/dev/null 2>&1; then
            curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o tf.zip
            unzip -o tf.zip && sudo mv terraform /usr/local/bin/
          fi
          terraform --version
        '''
      }
    }
    stage('Terraform Init') {
      steps {
        sh 'terraform init -reconfigure'
      }
    }
    stage('Validate & Plan') {
      steps {
        withCredentials([string(credentialsId: 'ssh_public_key', variable: 'SSH_PUB')]) {
          sh '''
            terraform validate
            terraform plan \
              -var "ssh_public_key=$SSH_PUB" \
              -var "allowed_ip_cidrs=${ALLOWED_IP_CIDRS}" \
              -out=tfplan
          '''
        }
      }
    }
    stage('Apply') {
      steps {
        sh 'terraform apply -auto-approve tfplan'
      }
    }
  }
  post {
    always { archiveArtifacts artifacts: '**/*.log', allowEmptyArchive: true }
    success { echo 'Resources created successfully!' }
    failure { echo 'Pipeline failed. Check logs.' }
  }
}
