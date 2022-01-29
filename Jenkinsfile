pipeline {
    agent any

    parameters {
        booleanParam defaultValue: false, description: 'Destroy Terraform Build', name: 'destroy'
    }

    stages {
        stage('checkout') {
            steps {
                script {
                    dir('terraform') {
                        checkout([$class: 'GitSCM', branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[credentialsId: 'AWS_GitHub_Token', url: 'https://github.com/kairu97/tf-ec2-lb.git']]])
                    }            
                }
            }
        }

        stage('Plan'){
            when {
                not {
                    equals expected: true, actual: params.destroy
                }
            }
            steps {
                sh 'terraform init -input=false'
                sh 'terraform plan -input=false -out tfplan'
                sh 'terraform show -no-color tfplan > tfplan.txt'
            }
        }

        stage('Approval') {
            when {
                not {
                    equals expected: true, actual: params.destroy
                }
            }

            steps {
                script {
                    def plan = readFile 'tfplan.txt'
                    input message: "Do you want to apply the plan"
                    parameters: [text(name: 'Plan', description: 'Please review the plan', defaultValue: plan)]
                }
            }
        }

        stage('Apply') {
            when {
                not {
                    equals expected: true, actual: params.destroy
                }
            }

            steps {
                sh 'terraform apply -input=false tfplan'
            }
        }

        stage('Destroy') {
            when {
                equals expected: true, actual: params.destroy
            }

            steps {
                sh 'terraform destroy --auto-approve'
            }
        }
    }
}