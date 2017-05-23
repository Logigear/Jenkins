pipeline {
  agent {
    node {
      label 'master'
    }
    
  }
  stages {
    stage('build') {
      steps {
        for(int i=1; i<=3; i++){
          parallel(
            'label':{
              node ('label' $i){
                sh 'echo test'
              }
            }
          )
        }
      }
    }
  }
}
