import React, { useState } from 'react';
import './App.css';
import axios from 'axios';

function App() {
  const [keyword, setKeyword] = useState('');
  const [fromDate, setFromDate] = useState(new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString().split('T')[0]);
  const [untilDate, setUntilDate] = useState(new Date().toISOString().split('T')[0]);
  const [provider, setProvider] = useState('');
  const [categories, setCategories] = useState({
    all: true,
    정치: false,
    경제: false,
    사회: false,
    문화: false,
    국제: false,
    IT_과학: false,
    스포츠: false
  });
  const [limit, setLimit] = useState(500);
  const [fileFormat, setFileFormat] = useState('csv');
  const [loading, setLoading] = useState(false);
  const [results, setResults] = useState(null);
  const [error, setError] = useState('');

  const handleCategoryChange = (category) => {
    if (category === 'all') {
      setCategories({
        all: !categories.all,
        정치: false,
        경제: false,
        사회: false,
        문화: false,
        국제: false,
        IT_과학: false,
        스포츠: false
      });
    } else {
      setCategories({
        ...categories,
        all: false,
        [category]: !categories[category]
      });
    }
  };

  const getSelectedCategories = () => {
    if (categories.all) return [];
    return Object.keys(categories).filter(cat => cat !== 'all' && categories[cat]);
  };

  const handleSearch = async () => {
    setLoading(true);
    setError('');
    setResults(null);

    try {
      const response = await axios.post('/api/search', {
        keyword,
        fromDate,
        untilDate,
        provider,
        categories: getSelectedCategories(),
        limit
      });

      if (response.data.success) {
        setResults(response.data);
      } else {
        setError(response.data.error);
      }
    } catch (err) {
      setError(err.response?.data?.error || '검색 중 오류가 발생했습니다.');
    }

    setLoading(false);
  };

  const handleDownload = async () => {
    if (!results?.data) return;

    try {
      const response = await axios.post('/api/download', {
        data: results.data,
        format: fileFormat
      }, {
        responseType: 'blob'
      });

      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `뉴스데이터_${new Date().toISOString().slice(0, 10)}.${fileFormat}`);
      document.body.appendChild(link);
      link.click();
      link.remove();
    } catch (err) {
      setError('다운로드 중 오류가 발생했습니다.');
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>📰 뉴스 데이터 수집기</h1>
        <p>빅카인즈 API를 사용하여 뉴스 데이터를 검색하고 다운로드합니다.</p>
      </header>

      <div className="container">
        <div className="search-panel">
          <h2>검색 조건</h2>
          
          <div className="form-group">
            <label>검색 키워드</label>
            <input
              type="text"
              value={keyword}
              onChange={(e) => setKeyword(e.target.value)}
              placeholder="검색할 키워드를 입력하세요"
            />
          </div>

          <div className="form-group">
            <label>검색 기간</label>
            <div className="date-range">
              <input
                type="date"
                value={fromDate}
                onChange={(e) => setFromDate(e.target.value)}
              />
              <span>~</span>
              <input
                type="date"
                value={untilDate}
                onChange={(e) => setUntilDate(e.target.value)}
              />
            </div>
          </div>

          <div className="form-group">
            <label>언론사 (선택사항)</label>
            <input
              type="text"
              value={provider}
              onChange={(e) => setProvider(e.target.value)}
              placeholder="특정 언론사 입력"
            />
          </div>

          <div className="form-group">
            <label>카테고리</label>
            <div className="categories">
              <label className="checkbox">
                <input
                  type="checkbox"
                  checked={categories.all}
                  onChange={() => handleCategoryChange('all')}
                />
                전체
              </label>
              {Object.keys(categories).filter(cat => cat !== 'all').map(category => (
                <label key={category} className="checkbox">
                  <input
                    type="checkbox"
                    checked={categories[category]}
                    onChange={() => handleCategoryChange(category)}
                  />
                  {category.replace('_', '/')}
                </label>
              ))}
            </div>
          </div>

          <div className="form-group">
            <label>최대 결과 수</label>
            <input
              type="number"
              value={limit}
              onChange={(e) => setLimit(Number(e.target.value))}
              min="10"
              max="1000"
              step="10"
            />
          </div>

          <div className="form-group">
            <label>파일 형식</label>
            <div className="radio-group">
              <label className="radio">
                <input
                  type="radio"
                  value="csv"
                  checked={fileFormat === 'csv'}
                  onChange={(e) => setFileFormat(e.target.value)}
                />
                CSV
              </label>
              <label className="radio">
                <input
                  type="radio"
                  value="xlsx"
                  checked={fileFormat === 'xlsx'}
                  onChange={(e) => setFileFormat(e.target.value)}
                />
                Excel
              </label>
            </div>
          </div>

          <button 
            className="search-button"
            onClick={handleSearch}
            disabled={loading}
          >
            {loading ? '검색 중...' : '🔍 뉴스 검색'}
          </button>
        </div>

        <div className="results-panel">
          {error && (
            <div className="error">
              ❌ {error}
            </div>
          )}

          {results && (
            <div className="results">
              <h2>검색 결과</h2>
              <p>총 {results.total}개 중 {results.count}개 검색됨</p>
              
              <button 
                className="download-button"
                onClick={handleDownload}
              >
                📥 {fileFormat.toUpperCase()} 다운로드
              </button>

              <div className="results-preview">
                <table>
                  <thead>
                    <tr>
                      <th>제목</th>
                      <th>발행시간</th>
                      <th>언론사</th>
                      <th>기자</th>
                    </tr>
                  </thead>
                  <tbody>
                    {results.data.slice(0, 10).map((item, index) => (
                      <tr key={index}>
                        <td>{item.제목}</td>
                        <td>{item.발행시간}</td>
                        <td>{item.언론사}</td>
                        <td>{item.기자}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                {results.data.length > 10 && (
                  <p className="more-results">... 외 {results.data.length - 10}개 더 있음</p>
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default App;