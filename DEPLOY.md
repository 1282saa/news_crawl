# Google Cloud Run 배포 가이드

## 사전 준비사항

1. **Google Cloud 계정 및 프로젝트 생성**
   - [Google Cloud Console](https://console.cloud.google.com)에서 프로젝트 생성
   - 프로젝트 ID 확인

2. **Google Cloud SDK 설치**
   ```bash
   # macOS
   brew install google-cloud-sdk
   
   # 또는 공식 설치 가이드 참조
   # https://cloud.google.com/sdk/docs/install
   ```

3. **Docker 설치**
   - [Docker Desktop](https://www.docker.com/products/docker-desktop) 설치

## 배포 단계

### 1. 프로젝트 설정

```bash
# deploy.sh 파일 수정
# PROJECT_ID를 실제 프로젝트 ID로 변경
vim deploy.sh
```

### 2. 환경 변수 설정

```bash
# BIGKINDS API 키를 환경 변수로 설정
export BIGKINDS_KEY="your-bigkinds-api-key"
```

### 3. 자동 배포 스크립트 실행

```bash
./deploy.sh
```

### 4. 수동 배포 (선택사항)

```bash
# 1. Google Cloud 로그인
gcloud auth login

# 2. 프로젝트 설정
gcloud config set project YOUR_PROJECT_ID

# 3. API 활성화
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com

# 4. React 빌드
npm install
npm run build

# 5. Docker 이미지 빌드
docker build -t gcr.io/YOUR_PROJECT_ID/news-crawler -f backend/Dockerfile .

# 6. Docker 이미지 푸시
docker push gcr.io/YOUR_PROJECT_ID/news-crawler

# 7. Cloud Run 배포
gcloud run deploy news-crawler \
  --image gcr.io/YOUR_PROJECT_ID/news-crawler \
  --platform managed \
  --region asia-northeast3 \
  --allow-unauthenticated \
  --set-env-vars "BIGKINDS_KEY=$BIGKINDS_KEY"
```

## Cloud Build를 통한 CI/CD (선택사항)

1. **Cloud Build 트리거 설정**
   ```bash
   gcloud builds submit --config cloudbuild.yaml \
     --substitutions=_BIGKINDS_KEY=$BIGKINDS_KEY
   ```

2. **GitHub 연동**
   - Cloud Console에서 Cloud Build 트리거 생성
   - GitHub 저장소 연결
   - main 브랜치 푸시 시 자동 배포

## 환경 변수 관리 (보안)

### Secret Manager 사용 (권장)

```bash
# 1. Secret 생성
echo -n "$BIGKINDS_KEY" | gcloud secrets create bigkinds-api-key --data-file=-

# 2. Cloud Run 서비스 계정에 권한 부여
gcloud secrets add-iam-policy-binding bigkinds-api-key \
  --member="serviceAccount:YOUR_SERVICE_ACCOUNT@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# 3. Cloud Run 배포 시 Secret 사용
gcloud run deploy news-crawler \
  --image gcr.io/YOUR_PROJECT_ID/news-crawler \
  --platform managed \
  --region asia-northeast3 \
  --allow-unauthenticated \
  --set-secrets="BIGKINDS_KEY=bigkinds-api-key:latest"
```

## 배포 후 확인

1. **서비스 URL 확인**
   ```bash
   gcloud run services describe news-crawler \
     --platform managed \
     --region asia-northeast3 \
     --format 'value(status.url)'
   ```

2. **로그 확인**
   ```bash
   gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=news-crawler" --limit 50
   ```

3. **서비스 상태 확인**
   ```bash
   gcloud run services list --platform managed
   ```

## 문제 해결

### CORS 오류
- Cloud Run 서비스 URL을 프론트엔드 코드에서 사용하도록 설정

### 메모리 부족
```bash
gcloud run deploy news-crawler \
  --memory 512Mi \
  --cpu 1
```

### 타임아웃 설정
```bash
gcloud run deploy news-crawler \
  --timeout 300
```

## 비용 관리

- Cloud Run은 사용한 만큼만 비용 발생
- 무료 할당량: 월 200만 요청, 360,000 GB-초의 메모리, 180,000 vCPU-초
- [가격 계산기](https://cloud.google.com/products/calculator)에서 예상 비용 확인