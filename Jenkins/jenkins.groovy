pipeline{
    agent none
    stages {
        stage ("Jenkins Clean UP") {
            agent {
                label {
                    label "builder"
                    customWorkspace "/opt/my-react-ui-lib"
                }
            }
            steps {
                sh '''
                rm -rf * || true
                rm -rf .* || true
                '''
            }
        }
        stage ("build") {
            agent {
                label {
                    label "builder"
                    customWorkspace "/opt/my-react-ui-lib/"
                }
            }
            steps {
                sh 'ssh-keyscan -H 192.168.10.139 >> ~/.ssh/known_hosts'
                git 'git@192.168.10.139:gaber/my-react-ui-lib.git'
                sh 'npm run build'
            }
        }
        stage ("Push builds to repo") {
            agent {
                label {
                    label "builder"
                    customWorkspace "/opt/my-react-ui-lib/"
                }
            }
            steps {
                    sh '''
                    git init
                    git remote add builds git@192.168.10.139:gaber/my-react-ui-lib-builds.git || true
                    git fetch builds
                    git checkout -b build-branch
                    git add .
                    git config --global user.email jenkins@local.domain
                    git config --global user.name jenkins
                    git commit -m "New build"
                    git rebase builds/master
                    git push builds build-branch:master
                    '''
                }
            }
        stage ("Update users") {
            agent {
                label {
                    label "builder"
                    customWorkspace "/opt/ansible"
                }
            }
            steps {
                sh 'ansible-playbook -i inventory -vvv main.yml'
            }
        }

        }
}