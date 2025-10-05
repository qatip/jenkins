pipeline {
  agent any
  environment {
    // Azure auth (Service Principal) from Jenkins credentials
    ARM_CLIENT_ID       = credentials('azure_sp_client_id')
    ARM_CLIENT_SECRET   = credentials('azure_sp_client_secret')
    ARM_SUBSCRIPTION_ID = credentials('azure_subscription_id')
    ARM_TENANT_ID       = credentials('azure_tenant_id')

    // Terraform version to install locally (no sudo)
    TERRAFORM_VERSION = "1.5.6"

    // Ensure our local bin is on PATH for ALL sh steps
    PATH = "${env.WORKSPACE}/.tfbin:${env.PATH}"
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
          VER="${TERRAFORM_VERSION}"
          mkdir -p "$WORKSPACE/.tfbin"
          if ! command -v terraform >/dev/null 2>&1; then
            echo "[INFO] Installing Terraform ${VER} locally..."
            curl -fsSL "https://releases.hashicorp.com/terraform/${VER}/terraform_${VER}_linux_amd64.zip" -o tf.zip
            # Use Python stdlib to unzip (works even if 'unzip' isn't installed)
            python3 - <<'PY'
import zipfile
z=zipfile.ZipFile('tf.zip'); z.extract('terraform','./.tfbin'); z.close()
PY
            chmod +x "$WORKSPACE/.tfbin/terraform"
            rm -f tf.zip
          fi
          terraform -version
        '''
      }
    }

    stage('Init, Plan, Apply') {
      steps {
        withCredentials([file(credentialsId: 'vm-pubkey-file', variable: 'PUBKEY_FILE')]) {
          sh '''
            set -e
            # Provide the path to the public key file to Terraform
            export TF_VAR_ssh_public_key_path="$PUBKEY_FILE"

            # If the job variable isn't set in the UI, default to open (change as needed)
            ALLOWED_JSON='${ALLOWED_IP_CIDRS}'
            [ -z "$ALLOWED_JSON" ] && ALLOWED_JSON='["0.0.0.0/0"]'

           terraform init -input=false -reconfigure
           terraform validate
           terraform plan -out=tfplan
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

