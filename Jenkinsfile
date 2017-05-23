pipeline {
  agent {
    node {
      label 'master'
    }
    
  }
  stages {
    stage('build') {
      steps {
          print 'test'
        for(int i=1; i<=3; i++){
          agent {
            label "label"$i
          }
          sh 'echo test'
        }
      }
    }
  }
}
