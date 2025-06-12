#!/bin/bash

# 프로젝트 ID 설정
PROJECT_ID="your-project-id"
REGION="asia-northeast3"
SERVICE_NAME="news-crawler"

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Google Cloud Run 배포 시작...${NC}"

# 프로젝트 ID 확인
if [ "$PROJECT_ID" == "your-project-id" ]; then
    echo -e "${RED}ERROR: deploy.sh 파일에서 PROJECT_ID를 설정해주세요.${NC}"
    exit 1
fi

# gcloud 로그인 확인
echo -e "${GREEN}1. Google Cloud 인증 확인...${NC}"
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "Google Cloud에 로그인이 필요합니다."
    gcloud auth login
fi

# 프로젝트 설정
echo -e "${GREEN}2. 프로젝트 설정: $PROJECT_ID${NC}"
gcloud config set project $PROJECT_ID

# API 활성화
echo -e "${GREEN}3. 필요한 API 활성화...${NC}"
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

# React 앱 빌드
echo -e "${GREEN}4. React 앱 빌드...${NC}"
npm install
npm run build

# Docker 이미지 빌드 및 푸시
echo -e "${GREEN}5. Docker 이미지 빌드...${NC}"
docker build -t gcr.io/$PROJECT_ID/$SERVICE_NAME -f backend/Dockerfile .

echo -e "${GREEN}6. Docker 이미지 푸시...${NC}"
docker push gcr.io/$PROJECT_ID/$SERVICE_NAME

# Cloud Run 배포
echo -e "${GREEN}7. Cloud Run에 배포...${NC}"
gcloud run deploy $SERVICE_NAME \
    --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --set-env-vars "BIGKINDS_KEY=$BIGKINDS_KEY"

# 서비스 URL 가져오기
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --platform managed --region $REGION --format 'value(status.url)')

echo -e "${GREEN}✅ 배포 완료!${NC}"
echo -e "${YELLOW}서비스 URL: $SERVICE_URL${NC}"