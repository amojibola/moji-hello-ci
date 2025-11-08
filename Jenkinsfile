pipeline {
  agent any
  environment {
    IMAGE = "mojitech/moji-hello-ci"
    TAG   = "build-${env.BUILD_NUMBER}"
    PATH  = "/usr/local/bin:/usr/bin:/bin"       // make sure /usr/local/bin is in PATH
    DOCKER = "/usr/local/bin/docker"             // use explicit docker path
  }
  stages {
    stage('Checkout') { steps { checkout scm } }

    stage('Unit tests (Python 3.12)') {
      steps {
        sh '''
          "$DOCKER" run --rm -v "$PWD":/src -w /src python:3.12-slim bash -lc "
            pip install -r requirements.txt && python -m pip install pytest && pytest -q
          "
        '''
      }
    }

    stage('Build image') {
      steps { sh '"$DOCKER" build -t $IMAGE:$TAG -t $IMAGE:latest .' }
    }

    stage('Smoke test container') {
      steps {
        sh '''
          set -e
          "$DOCKER" rm -f moji-hello-ci-test 2>/dev/null || true
          "$DOCKER" run -d --name moji-hello-ci-test $IMAGE:$TAG
          "$DOCKER" run --rm --network container:moji-hello-ci-test curlimages/curl:8.11.0 -s http://localhost:8000/healthz | grep '"ok":true'
        '''
      }
    }
  }
  post {
    always { sh '"$DOCKER" rm -f moji-hello-ci-test 2>/dev/null || true' }
  }
}
