pipeline {
  agent any

  environment {
    IMAGE = "mojitech/moji-hello-ci"
    TAG   = "build-${env.BUILD_NUMBER}"
    DOCKER = "/usr/local/bin/docker"   // stable path Jenkins can see
    PATH  = "/usr/local/bin:/usr/bin:/bin" // ensure docker path is in PATH for shell steps
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
          "$DOCKER" run --rm -v "$PWD":/src -w /src python:3.12-slim bash -lc "
            pip install -r requirements.txt && python -m pip install pytest && pytest -q
          "
        '''
      }
    }

    stage('Build image') {
      steps {
        sh '"$DOCKER" build -t $IMAGE:$TAG -t $IMAGE:latest .'
      }
    }

    stage('Smoke test container') {
      steps {
        sh '''
          set -e
          "$DOCKER" rm -f moji-hello-ci-test 2>/dev/null || true
          "$DOCKER" run -d --name moji-hello-ci-test $IMAGE:$TAG

          echo "🔍 Running smoke test against container..."
          # Retry loop: check health endpoint up to 20 times (≈20s max)
          for i in {1..20}; do
            if "$DOCKER" run --rm --network container:moji-hello-ci-test curlimages/curl:8.11.0 \
                 -s http://localhost:8000/healthz | grep -q '"ok":true'; then
              echo "✅ Health check passed on attempt $i"
              exit 0
            fi
            echo "⏳ Waiting for app to start... ($i/20)"
            sleep 1
          done

          echo "❌ Health check failed after waiting"
          echo "---- Container logs ----"
          "$DOCKER" logs moji-hello-ci-test || true
          exit 1
        '''
      }
    }

    stage('Deploy (dev)') {
      steps {
        // Pass DOCKER into the script so it uses the same docker binary
        sh 'DOCKER="$DOCKER" bash deploy/dev.sh $IMAGE:$TAG'
      }
    }
  }

  post {
    always {
      sh '"$DOCKER" rm -f moji-hello-ci-test 2>/dev/null || true'
    }
  }
}
