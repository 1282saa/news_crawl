#!/bin/bash

# Cloud Shell 전용 배포 스크립트

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}   뉴스 크롤러 Cloud Run 배포 스크립트     ${NC}"
echo -e "${BLUE}===========================================${NC}"

# 프로젝트 ID 자동 설정 (Cloud Shell에서)
PROJECT_ID=$GOOGLE_CLOUD_PROJECT
REGION="asia-northeast3"
SERVICE_NAME="news-crawler"

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}ERROR: GOOGLE_CLOUD_PROJECT 환경 변수가 설정되지 않았습니다.${NC}"
    echo "Cloud Shell에서 실행해주세요."
    exit 1
fi

echo -e "${GREEN}프로젝트 ID: $PROJECT_ID${NC}"

# BIGKINDS_KEY 환경 변수 확인
if [ -z "$BIGKINDS_KEY" ]; then
    echo -e "${YELLOW}BIGKINDS_KEY 환경 변수를 설정해주세요:${NC}"
    echo "export BIGKINDS_KEY=\"your-api-key\""
    read -p "지금 입력하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "BIGKINDS API 키를 입력하세요: " BIGKINDS_KEY
        export BIGKINDS_KEY
    else
        echo -e "${RED}배포를 중단합니다.${NC}"
        exit 1
    fi
fi

# .env 파일 생성
echo -e "${GREEN}1. 환경 변수 파일 생성...${NC}"
cd backend
echo "BIGKINDS_KEY=$BIGKINDS_KEY" > .env
cd ..

# API 활성화
echo -e "${GREEN}2. 필요한 API 활성화...${NC}"
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

# React 앱 빌드
echo -e "${GREEN}3. React 앱 빌드...${NC}"
npm install
npm run build

if [ ! -d "build" ]; then
    echo -e "${RED}ERROR: React 빌드 실패${NC}"
    exit 1
fi

echo -e "${YELLOW}빌드된 파일 확인:${NC}"
ls -la build/

# Docker 이미지 빌드
echo -e "${GREEN}4. Docker 이미지 빌드...${NC}"
docker build -t gcr.io/$PROJECT_ID/$SERVICE_NAME -f backend/Dockerfile .

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Docker 빌드 실패${NC}"
    exit 1
fi

# Docker 이미지 푸시
echo -e "${GREEN}5. Container Registry에 이미지 푸시...${NC}"
docker push gcr.io/$PROJECT_ID/$SERVICE_NAME

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Docker 푸시 실패${NC}"
    exit 1
fi

# Cloud Run 배포
echo -e "${GREEN}6. Cloud Run에 배포...${NC}"
gcloud run deploy $SERVICE_NAME \
    --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --set-env-vars "BIGKINDS_KEY=$BIGKINDS_KEY" \
    --memory 512Mi \
    --cpu 1 \
    --min-instances 0 \
    --max-instances 10

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Cloud Run 배포 실패${NC}"
    exit 1
fi

# 서비스 URL 가져오기
echo -e "${GREEN}7. 배포 완료! 서비스 정보 확인...${NC}"
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --platform managed --region $REGION --format 'value(status.url)')

echo -e "${BLUE}===========================================${NC}"
echo -e "${GREEN}✅ 배포 성공!${NC}"
echo -e "${YELLOW}서비스 URL: $SERVICE_URL${NC}"
echo -e "${YELLOW}관리 콘솔: https://console.cloud.google.com/run/detail/$REGION/$SERVICE_NAME${NC}"
echo -e "${BLUE}===========================================${NC}"

# 서비스 상태 확인
echo -e "${GREEN}서비스 상태:${NC}"
gcloud run services describe $SERVICE_NAME --platform managed --region $REGION --format="table(status.conditions[0].type,status.conditions[0].status)"

echo -e "${BLUE}배포가 완료되었습니다. 브라우저에서 위 URL로 접속하여 확인해보세요!${NC}"