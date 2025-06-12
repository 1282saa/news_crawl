# Google Cloud Shell을 통한 배포 가이드

## 1. GitHub에 프로젝트 업로드

### 로컬에서 GitHub 저장소 생성
```bash
cd news-crawler-web
git init
git add .
git commit -m "Initial commit: News crawler web application"

# GitHub에서 저장소 생성 후
git remote add origin https://github.com/your-username/news-crawler-web.git
git branch -M main
git push -u origin main
```

## 2. Google Cloud Shell에서 배포

### Cloud Shell 접속
1. [Google Cloud Console](https://console.cloud.google.com) 접속
2. 우상단의 Cloud Shell 아이콘 클릭 (>_ 모양)
3. Cloud Shell 터미널이 브라우저 하단에 열림

### 프로젝트 클론 및 설정
```bash
# 1. GitHub에서 프로젝트 클론
git clone https://github.com/your-username/news-crawler-web.git
cd news-crawler-web

# 2. 프로젝트 ID 확인 (Cloud Shell에 자동 설정됨)
echo $GOOGLE_CLOUD_PROJECT

# 3. 환경 변수 설정
export PROJECT_ID=$GOOGLE_CLOUD_PROJECT
export BIGKINDS_KEY="254bec69-1c13-470f-904a-c4bc9e46cc80"

# 4. .env 파일 생성
cd backend
cp .env.example .env
echo "BIGKINDS_KEY=$BIGKINDS_KEY" > .env
cd ..
```

### 필요한 API 활성화
```bash
# Cloud Build, Cloud Run, Container Registry API 활성화
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

### React 앱 빌드
```bash
# Node.js 버전 확인 (Cloud Shell에는 기본 설치됨)
node --version
npm --version

# 의존성 설치 및 빌드
npm install
npm run build
```

### Docker 이미지 빌드 및 배포
```bash
# Docker 이미지 빌드
docker build -t gcr.io/$PROJECT_ID/news-crawler -f backend/Dockerfile .

# Container Registry에 푸시
docker push gcr.io/$PROJECT_ID/news-crawler

# Cloud Run에 배포
gcloud run deploy news-crawler \
  --image gcr.io/$PROJECT_ID/news-crawler \
  --platform managed \
  --region asia-northeast3 \
  --allow-unauthenticated \
  --set-env-vars "BIGKINDS_KEY=$BIGKINDS_KEY" \
  --memory 512Mi \
  --cpu 1
```

### 배포 URL 확인
```bash
# 서비스 URL 가져오기
gcloud run services describe news-crawler \
  --platform managed \
  --region asia-northeast3 \
  --format 'value(status.url)'
```

## 3. 원클릭 배포 스크립트

### deploy-cloudshell.sh 사용
```bash
# 실행 권한 부여
chmod +x deploy-cloudshell.sh

# 배포 실행
./deploy-cloudshell.sh
```

## 4. 업데이트 배포

코드 수정 후 재배포:
```bash
# 1. 최신 코드 가져오기
git pull origin main

# 2. React 앱 다시 빌드
npm run build

# 3. Docker 이미지 재빌드 및 배포
docker build -t gcr.io/$PROJECT_ID/news-crawler -f backend/Dockerfile .
docker push gcr.io/$PROJECT_ID/news-crawler

# 4. Cloud Run 서비스 업데이트
gcloud run deploy news-crawler \
  --image gcr.io/$PROJECT_ID/news-crawler \
  --platform managed \
  --region asia-northeast3
```

## 5. Cloud Build를 통한 자동 배포 (CI/CD)

### Cloud Build 트리거 설정
```bash
# Cloud Build로 배포
gcloud builds submit --config cloudbuild.yaml \
  --substitutions=_BIGKINDS_KEY=$BIGKINDS_KEY
```

### GitHub과 Cloud Build 연동
1. Cloud Console → Cloud Build → 트리거
2. "트리거 만들기" 클릭
3. GitHub 저장소 연결
4. 트리거 조건: main 브랜치 푸시
5. 빌드 구성: cloudbuild.yaml 사용
6. 환경 변수에 BIGKINDS_KEY 추가

## 6. 문제 해결

### 메모리 부족 오류
```bash
gcloud run deploy news-crawler \
  --memory 1Gi \
  --cpu 2
```

### 빌드 시간 초과
```bash
gcloud builds submit --timeout=1200s
```

### 로그 확인
```bash
# Cloud Run 로그
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=news-crawler" --limit 50

# Cloud Build 로그
gcloud builds list --limit=10
```

## 7. 비용 최적화

### 자동 스케일링 설정
```bash
gcloud run deploy news-crawler \
  --min-instances 0 \
  --max-instances 10 \
  --concurrency 80
```

### 리소스 제한
```bash
gcloud run deploy news-crawler \
  --memory 256Mi \
  --cpu 0.5
```

## Cloud Shell의 장점

1. **사전 설정**: Google Cloud SDK, Docker 등이 미리 설치됨
2. **인증 자동화**: gcloud 인증이 자동으로 처리됨
3. **무료 사용**: 월 50시간 무료 사용 가능
4. **영구 스토리지**: $HOME 디렉터리는 5GB 영구 보존
5. **웹 기반**: 브라우저만 있으면 어디서든 접근 가능