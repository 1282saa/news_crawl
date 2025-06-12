# 뉴스 데이터 수집기 웹 애플리케이션

React와 Flask를 사용한 뉴스 데이터 수집 웹 애플리케이션입니다.

## 기능

- 빅카인즈 API를 통한 뉴스 검색
- 날짜 범위, 언론사, 카테고리별 필터링
- CSV/Excel 파일로 다운로드
- 제목만 추출하여 토큰 비용 절감
- 기본 500개 결과 수집
- 카테고리 전체 선택 기능

## 로컬 개발 환경 설정

### 1. 백엔드 설정

```bash
cd backend
pip install -r requirements.txt

# .env 파일 생성
cp .env.example .env
# .env 파일에 실제 API 키 입력

# 서버 실행
python app.py
```

### 2. 프론트엔드 설정

```bash
# 프로젝트 루트에서
npm install
npm start
```

## Google Cloud Run 배포

### 방법 1: Cloud Shell 사용 (권장)

1. **GitHub에 코드 업로드**
2. **Cloud Shell에서 배포**:
   ```bash
   git clone https://github.com/your-username/news-crawler-web.git
   cd news-crawler-web
   export BIGKINDS_KEY="your_api_key"
   ./deploy-cloudshell.sh
   ```

### 방법 2: 로컬에서 배포

```bash
# deploy.sh에서 PROJECT_ID 수정 후
export BIGKINDS_KEY="your_api_key"
./deploy.sh
```

## 배포 가이드 문서

- **[Cloud Shell 배포](CLOUDSHELL_DEPLOY.md)**: Google Cloud Shell을 사용한 상세 배포 가이드
- **[일반 배포](DEPLOY.md)**: 로컬 환경에서의 배포 가이드

## 환경 변수

```bash
BIGKINDS_KEY=your_bigkinds_api_key
```

## 사용 방법

1. 검색 키워드 입력 (선택사항)
2. 날짜 범위 설정
3. 카테고리 선택 (전체 또는 개별 선택)
4. 최대 결과 수 설정 (기본값: 500)
5. 파일 형식 선택 (CSV 기본값)
6. "뉴스 검색" 버튼 클릭
7. 결과 확인 후 다운로드

## 프로젝트 구조

```
news-crawler-web/
├── backend/              # Flask 백엔드
│   ├── app.py           # 메인 애플리케이션
│   ├── Dockerfile       # Docker 설정
│   ├── requirements.txt # Python 의존성
│   └── .env.example     # 환경 변수 예시
├── src/                 # React 프론트엔드
├── public/              # 정적 파일
├── deploy-cloudshell.sh # Cloud Shell 배포 스크립트
├── cloudbuild.yaml      # Cloud Build 설정
└── README.md           # 이 파일
```