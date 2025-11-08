pipeline {
  agent any

  environment {
    IMAGE = "mojitech/moji-hello-ci"
    TAG = "build-${env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Unit tests (Python 3.12)') {
      steps {
        sh '''
          docker run --rm -v "$PWD":/src -w /src python:3.12-slim bash -lc "
            pip install -r requirements.txt && python -m pip install pytest && pytest -q
          "
        '''
      }
    }

    stage('Build image') {
      steps {
        sh 'docker build -t $IMAGE:$TAG -t $IMAGE:latest .'
      }
    }

    stage('Smoke test container') {
      steps {
        sh '''
          set -e
          docker rm -f moji-hello-ci-test 2>/dev/null || true
          docker run -d --name moji-hello-ci-test -p 8000:8000 $IMAGE:$TAG
          docker run --rm --network container:moji-hello-ci-test curlimages/curl:8.11.0 -s http://localhost:8000/healthz | grep '"ok":true'
        '''
      }
    }
  }

  post {
    always {
      sh 'docker rm -f moji-hello-ci-test 2>/dev/null || true'
    }
  }
}
