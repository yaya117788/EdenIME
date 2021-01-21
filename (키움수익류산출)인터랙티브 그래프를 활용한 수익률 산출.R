## 키움모의투자 수익률 확인을 위한 주가 확인

# 인터랙티브 그래프를 사용
'''인터랙티브 그래프를 직접 사용해보며 투자한 일부터 쭉 확인해본다.'''
library(highcharter)
library(quantmod)
library(stringr)
library(httr)
library(rvest)
library(readr)

getSymbols('226490.KS')
head(`226490.KS`)
prices <-  Cl(`226490.KS`)
head(Op(`226490.KS`))
openpricemk <- Op(`226490.KS`)

# 시장지수로 KODEX KOSPI ETF를 이용한다.
## 각각 종가그래프와 시가 그래프를 통해 투자를 시작한 01/12시가에서 21 종가를 통해 시장지수 수익률 계산
highchart(type = 'stock') %>%
  hc_add_series(prices) %>%
  hc_scrollbar(enable = FALSE)
# 그래프에서 etf 01/21 종가는 32075원이다.

highchart(type = 'stock') %>%
  hc_add_series(openpricemk) %>%
  hc_scrollbar(enable = FALSE)
# 그래프에서 etf 01/12 시가는 31895원이다.

returnrat <- ((32075 - 31895)/ 31895) * 100
returnrat 
# 9일동안의 시장지표는 0.5%의 수익률을 보였다.
''' 이미 KOSPI는 3000포인트 돌파라는 최고점을 찍은 후 12일부터는 조정장 + 지지하려는 움직임을 보여 수익률면에서 하락,
상승장의 반복으로 지지부진 했다.'''


'''
저변동성 선정종목 
2    016800       퍼시스 0.1466
5    134380     미원화학 0.1761
6    007330 푸른저축은행 0.1946
7    034590 인천도시가스 0.1829
8    273060   와이즈버즈 0.1799
'''
name <- c('016800','134380','007330','034590','273060')
dd <- data.frame()
for(i in 1:length(name)){
  url = paste0(
    'https://fchart.stock.naver.com/sise.nhn?symbol=',
    name[i],'&timeframe=day&count=500&requestType=0')
  data = GET(url)
  data_html = read_html(data, encoding = 'EUC-KR') %>%
    html_nodes('item') %>%
    html_attr('data') 
  
  print(head(data_html))
  price = read_delim(data_html, delim = '|')
  price = price[c(1,2,5)] 
  price = data.frame(price)
  colnames(price) = c('Date', 'Open Price','Close Price')

  startpr <- tail(price,n=8)[1,'Open Price']
  closepr <- tail(price,n=8)[8,'Close Price']
  
  return <- (closepr - startpr) / startpr 
  
  dd[i,1] <- name[i]
  dd[i,2] <- return
  
  }


dd
# 각각 종목들의 수익률을 dataframe으로 만들어서 나타내었다.
mean(dd[,2]) *100
'''저변동성을 통해 선정된 종목에 투자한 결과 10일간 평균 수익률은 -0.613% 를 기록하였다.
이는 시장지표의 수익률 0.5% 상승보다도 훨씬 낮은 수치로 코로나시국으로 인한 상승장과 최근 01/12
~ 01/21기간의 조정기 장에선 좋지않은 지표임을 파악할 수 있다.'

'''
멀티팩터 선정 종목 
44     030200               KT 0.05 10.73    1.56
117    001040               CJ 0.02  9.66    1.60
596    006840         AK홀딩스 0.07 11.80    0.70
651    045100       한양이엔지 0.25 10.07    1.66
792    008060             대덕 0.27  3.60    1.00
844    023600         삼보판지 0.16  6.68    1.14
942    090350       노루페인트 0.04  9.71    1.43
1422   225190       삼양옵틱스 0.35  7.42    2.14
1552   094820         일진파워 0.18  7.37    0.80
1980   025530        SJM홀딩스 0.01  9.17    2.15
'''
name <- c('030200','001040','006840','045100','008060','023600','090350',
          '225190','094820','025530')
dd <- data.frame()
for(i in 1:length(name)){
  url = paste0(
    'https://fchart.stock.naver.com/sise.nhn?symbol=',
    name[i],'&timeframe=day&count=500&requestType=0')
  data = GET(url)
  data_html = read_html(data, encoding = 'EUC-KR') %>%
    html_nodes('item') %>%
    html_attr('data') 
  
  print(head(data_html))
  price = read_delim(data_html, delim = '|')
  price = price[c(1,2,5)] 
  price = data.frame(price)
  colnames(price) = c('Date', 'Open Price','Close Price')
  
  startpr <- tail(price,n=8)[1,'Open Price']
  closepr <- tail(price,n=8)[8,'Close Price']
  
  return <- (closepr - startpr) / startpr 
  
  dd[i,1] <- name[i]
  dd[i,2] <- return
  
}
dd
## 각각의 수익률을 보면 천차만별임을 알 수 있다. 최근 코로나의 종식에 대한 기대로 
## 각종 테마주들이 급등을 하고 그 외 종목은 하락하는 시장추세 때문이다.
mean(dd[,2]) * 100
## 그럼에도 평균적으로 3.8%의 수익률을 기록한 것을 알 수 있다. 

''' 변동성이 심하고 코로나 장에선 저변동성 전략의 종목들이 큰 힘을 발휘하지 못했으며,
벨류,퀄리티, 모멘텀팩터를 활용한 종목들은 시장지표 대비 월등한 수익률을 기록하였다.
특히 이런 고변동장과 각종 테마주가 뜨는 시점에선 단기모멘텀 (1개월, 3개월) 지표에 비중을 높인 결과가
좋은 수익률 실현에 도움을 준것으로 파악된다.'''
