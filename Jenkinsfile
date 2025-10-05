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

  stage('Install Terraform (no sudo)') {
  steps {
    sh '''
      set -e
      VER=1.5.6
      mkdir -p .tfbin
      curl -fsSL "https://releases.hashicorp.com/terraform/${VER}/terraform_${VER}_linux_amd64.zip" -o tf.zip
      # unzip via Python stdlib (works even if 'unzip' is missing)
      python3 - <<'PY'
import zipfile
z=zipfile.ZipFile('tf.zip'); z.extract('terraform','./.tfbin'); z.close()
PY
      chmod +x .tfbin/terraform
      echo "PATH=$PWD/.tfbin:$PATH" >> $BASH_ENV || true
      export PATH="$PWD/.tfbin:$PATH"
      terraform -version
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
