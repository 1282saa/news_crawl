from flask import Flask, request, jsonify, send_file, send_from_directory
from flask_cors import CORS
import requests
import os
import pandas as pd
from datetime import datetime
from dotenv import load_dotenv
import io
import tempfile

load_dotenv()
API_KEY = os.getenv("BIGKINDS_KEY")

app = Flask(__name__, static_folder='build', static_url_path='/')
CORS(app)

@app.route('/api/search', methods=['POST'])
def search_news():
    data = request.json
    
    # API 요청 URL
    url = "https://tools.kinds.or.kr/search/news"
    
    # 요청 payload 구성
    payload = {
        "access_key": API_KEY,
        "argument": {
            "query": data.get('keyword', ''),
            "published_at": {
                "from": data.get('fromDate'),
                "until": data.get('untilDate')
            },
            "provider": [data.get('provider')] if data.get('provider') else [],
            "category": data.get('categories', []),
            "category_incident": [],
            "provider_subject": [],
            "subject_info": [],
            "sort": {"date": "desc"},
            "return_from": 0,
            "return_size": data.get('limit', 500),
            "fields": ["title", "published_at", "provider", "byline"]
        }
    }
    
    try:
        response = requests.post(url, json=payload)
        
        if response.status_code == 200:
            result = response.json()
            documents = result["return_object"]["documents"]
            total_hits = result["return_object"]["total_hits"]
            
            # 제목만 추출하여 데이터 구성
            data_list = []
            for doc in documents:
                data_list.append({
                    "제목": doc.get("title", ""),
                    "발행시간": doc.get("published_at", ""),
                    "언론사": doc.get("provider", ""),
                    "기자": doc.get("byline", "")
                })
            
            return jsonify({
                "success": True,
                "data": data_list,
                "total": total_hits,
                "count": len(documents)
            })
        else:
            return jsonify({
                "success": False,
                "error": f"API 요청 실패: {response.status_code}"
            }), 400
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/api/download', methods=['POST'])
def download_news():
    data = request.json
    news_data = data.get('data', [])
    file_format = data.get('format', 'csv')
    
    df = pd.DataFrame(news_data)
    
    if file_format == 'csv':
        output = io.StringIO()
        df.to_csv(output, index=False, encoding='utf-8-sig')
        output.seek(0)
        
        return send_file(
            io.BytesIO(output.getvalue().encode('utf-8-sig')),
            mimetype='text/csv',
            as_attachment=True,
            download_name=f'뉴스데이터_{datetime.now().strftime("%Y%m%d_%H%M%S")}.csv'
        )
    else:
        output = io.BytesIO()
        with pd.ExcelWriter(output, engine='openpyxl') as writer:
            df.to_excel(writer, index=False)
        output.seek(0)
        
        return send_file(
            output,
            mimetype='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            as_attachment=True,
            download_name=f'뉴스데이터_{datetime.now().strftime("%Y%m%d_%H%M%S")}.xlsx'
        )

@app.route('/')
def serve():
    return send_from_directory(app.static_folder, 'index.html')

@app.errorhandler(404)
def not_found(e):
    return send_from_directory(app.static_folder, 'index.html')

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(debug=False, host='0.0.0.0', port=port)