## 키움 모의 투자대회를 위한 종목선정 프로젝트
'''크롤링을 통해 각종 데이터를 수집하여 여러가지 내재가치를 파악하는
지표들을 사용하여 종목선정을 해 투자하고 수익률을 실현해본다.'''


#사용할 패키지 정리 ( 없을시 다운로드까지 진행하는 코드 )
pkg = c('magrittr', 'quantmod', 'rvest', 'httr', 'jsonlite',
        'readr', 'readxl', 'stringr', 'lubridate', 'dplyr',
        'tidyr', 'ggplot2', 'corrplot', 'dygraphs',
        'highcharter', 'plotly', 'PerformanceAnalytics',
        'nloptr', 'quadprog', 'RiskPortfolios', 'cccp',
        'timetk', 'broom', 'stargazer', 'timeSeries')

new.pkg = pkg[!(pkg %in% installed.packages()[, "Package"])]
if (length(new.pkg)) {
  install.packages(new.pkg, dependencies = TRUE)}
# 1. 주식종목들의 현재 데이터와 티커 추출
'''이후에 데이터들을 이용해 지표분석을 하고 사용하기 위해
주식 티커(주식종목당 고유의 숫자번호)를 추출해올 필요가 있다.'''

'''한국거래소가 제공하는 산업별 현황과 개별종목의 지표 데이터를
이용하여 티커를 사용한 종목들의 데이터를 가져온다.'''
## 이를 크롤링 하여 데이터를 끌어오려면 쿼리를 입력하여 POST방식으로 보내서 가져오게되는데
## 가장 최근 영업일의 데이터를 끌어오려면 쿼리에 입력해야해서 영업일 날짜를 가져온다.

### 네이버금융 > 증시자금동향 페이지에서 영업일을 끌어온다.
''' Xpath를 이용해 간단히 데이터를 끌어올 수 있는데 Xpath란 XML중 특정값의
태그나 속성을 찾기 쉽게 만든 주소라 생각하면 된다. 개발자도구 > 원하는 부분에서 COPY > Xpath 고르면 된다.'''
url = 'https://finance.naver.com/sise/sise_deposit.nhn'

recent_day = GET(url) %>%
  read_html(encoding = 'EUC-KR') %>%
  html_nodes(xpath =
               '//*[@id="type_1"]/div/ul[2]/li/span') %>%
  html_text() %>%
  str_match(('[0-9]+.[0-9]+.[0-9]+') ) %>%
  str_replace_all('\\.', '')

print(recent_day)
# 최근 영업일 값 
library(httr)
library(rvest)
library(readr)
library(dplyr)

gen_otp_url =
  'http://marketdata.krx.co.kr/contents/COM/GenerateOTP.jspx'
gen_otp_data = list(
  name = 'fileDown',
  filetype = 'csv',
  url = 'MKD/03/0303/03030103/mkd03030103',
  tp_cd = 'ALL',
  date = recent_day,
  lang = 'ko',
  pagePath = '/contents/MKD/03/0303/03030103/MKD03030103.jsp')
## 위는 해당 OTP를 받기위한 쿼리이다.
otp = POST(gen_otp_url, query = gen_otp_data) %>%
  read_html() %>%
  html_text()
## 포스트 방식을 이용하여 쿼리를 넣고 OTP를 받아온다.
down_url = 'http://file.krx.co.kr/download.jspx'
down_sector = POST(down_url, query = list(code = otp),
                   add_headers(referer = gen_otp_url)) %>%
  read_html() %>%
  html_text() %>%
  read_csv()
print(head(down_sector))
## OTP를 쿼리로 제출하고 과정을 유지하기위해 흔적을 같이 보냅니다. (두번째 단계로 바로 보내면 로봇이 인식하지 못함)
''' 거래소 내의 엑셀데이터를 받으려면 먼저
개발자도구에서 network를 보면 GenerateOTP.jspx와 download.jspx가 
있는데, 먼저 Generate에 원하는 항목을 쿼리로 발송하면 해당 쿼리에
해당하는 OTP를 받게된다. >>> 이 OTP를 Download.jspx에 제출하면
해당 엑셀파일을 다운로드 할 수 있다'''

## 이를 csv 파일로 따로 저장한다.
ifelse(dir.exists('data22'), FALSE, dir.create('data22'))
write.csv(down_sector, 'data22/krx_sector.csv')

## 개별종목들의 몇가지 지표데이터들을 끌어온다. (한국거래소 개별종목지표)
gen_otp_url =
  'http://marketdata.krx.co.kr/contents/COM/GenerateOTP.jspx'
gen_otp_data = list(
  name = 'fileDown',
  filetype = 'csv',
  url = "MKD/13/1302/13020401/mkd13020401",
  market_gubun = 'ALL',
  gubun = '1',
  schdate = recent_day,
  pagePath = "/contents/MKD/13/1302/13020401/MKD13020401.jsp")

otp = POST(gen_otp_url, query = gen_otp_data) %>%
  read_html() %>%
  html_text()

down_url = 'http://file.krx.co.kr/download.jspx'
down_ind = POST(down_url, query = list(code = otp),
                add_headers(referer = gen_otp_url)) %>%
  read_html() %>%
  html_text() %>%
  read_csv()
print(head(down_ind))
''' 방식은 위와 비슷하다. 쿼리에 들어가는 속성들의 차이다'''
## 이도 csv 파일로 저장
write.csv(down_ind, 'data22/krx_ind.csv')


# 데이터 정리
'''위에서 받은 두 데이터는 중복된 열과 불필요한 데이터가 있다. 하나로
합친 후 정리를 시도해본다.'''
down_sector = read.csv('data22/krx_sector.csv', row.names = 1,
                       stringsAsFactors = FALSE)
down_ind = read.csv('data22/krx_ind.csv',  row.names = 1,
                    stringsAsFactors = FALSE)

## 두 데이터를 합치기전 우선 중복된 열이 있나 확인한다.
intersect(names(down_sector), names(down_ind))
## 그리고 한곳에만 있는 종목이 있나 확인한다.
setdiff(down_sector[, '종목명'], down_ind[ ,'종목명'])
''' 이들은 주로 선박펀드, 광물펀드, 해외종목등 일반적이지 않은
종목들이라 제외하고 합친다.'''
KOR_ticker = merge(down_sector, down_ind,
                   by = intersect(names(down_sector),
                                  names(down_ind)),
                   all = FALSE
)
''' 종목명 종목코드를 기준으로 합치고 all parameter를 이용해 교집합 종목들만 추출 >> 아까
setdiff를 통해 나온 종목들은 교집합에서 빠져 제외된다.'''
KOR_ticker = KOR_ticker[order(-KOR_ticker['시가총액.원.']), ]
print(head(KOR_ticker))
''' 시가총액기준으로 내림차순을 정리해 ticker 데이터로 저장'''

# 이후 우선주와 스팩주 종목들을 제외한다. 
library(stringr)

KOR_ticker[grepl('스팩', KOR_ticker[, '종목명']), '종목명']  
'''스팩이 들어간 종목을 찾는다.'''
KOR_ticker[str_sub(KOR_ticker[, '종목코드'], -1, -1) != 0, '종목명']
''' 우선주는 끝자리가 0이 아닌 코드를 찾으면 된다.
보통주들은 0 우선주들은 주로 5,6이 된다.'''
KOR_ticker = KOR_ticker[!grepl('스팩', KOR_ticker[, '종목명']), ]  
KOR_ticker = KOR_ticker[str_sub(KOR_ticker[, '종목코드'], -1, -1) == 0, ]
rownames(KOR_ticker) = NULL
write.csv(KOR_ticker, 'data22/KOR_ticker.csv')
''' 행이름을 초기화하고 다시 저장한다.'''


# 섹터정보 크롤링
## 한국에서 주식의 섹터는 한국거래소 GIGS 기준정보나 와이즈인덱스의 WICS 섹터를 이용한다.
'''WISE INdex에서 제공하는 섹터별 종목들을 끌어오기 위해 
JSON 형식의 데이터를 크롤링해서 가져온다. '''
library(jsonlite)

url = 'http://www.wiseindex.com/Index/GetIndexComponets?ceil_yn=0&dt=20190607&sec_cd=G10'
data = fromJSON(url)

lapply(data, head)
'''각 리스트 항목에는 해당섹터의 구성종목, 다른 섹터의 코드 등을 알 수 있다.
URL부분의 sec_cd = 부분에 섹터코드들만 변경하면 모든 섹터 데이터를 추출할 수 있다.'''
sector_code = c('G25', 'G35', 'G50', 'G40', 'G10',
                'G20', 'G55', 'G30', 'G15', 'G45')
data_sector = list()

for (i in sector_code) {
  
  url = paste0(
    'http://www.wiseindex.com/Index/GetIndexComponets',
    '?ceil_yn=0&dt=', recent_day,'&sec_cd=',i)
  data = fromJSON(url)
  data = data$list
  
  data_sector[[i]] = data
  
  Sys.sleep(1)
}

data_sector = do.call(rbind, data_sector)
write.csv(data_sector, 'data22/KOR_sector.csv')
''' 섹터코드를 변경해가며 for loop를 통해 다 끌어와 모아 저장한다.'''

# 코로나 이후 섹터별 산업의 최근전망과 수익률비교
'''섹터별 최근 한달의 수익률과 6개월의 수익률을 가져와 어떤 섹터가
코로나시대에 주목을 끌었으며 최근전망은 어떤가 확인해본다.'''
sector_code = c('G25', 'G35', 'G50', 'G40', 'G10',
                'G20', 'G55', 'G30', 'G15', 'G45')
data_sector_return = data.frame()
k = 1
for( i in sector_code ){
  url = paste0('http://www.wiseindex.com/Index/GetIndexPerformanceInfo?ceil_yn=0&dt=20210108&fromdt=20200107&sec_cd=',i)
  datat = fromJSON(url)
  lapply(datat, tail)
  rtn_1w = as.numeric(datat$data$RTN_1W)
  rtn_6m = as.numeric(datat$data$RTN_6M)
  data_sector_return[k,c(1,2,3)] = c(i,rtn_1w,rtn_6m)
  k <- k +  1 
}
names(data_sector_return) <- c('SectorCode','Onewreturn','sixmreturn')
str(data_sector_return)
data_sector_return$`1W return` = as.numeric(data_sector_return$`1W return`)
data_sector_return$`6M return` = as.numeric(data_sector_return$`6M return`)
str(data_sector_return)
data_sector_return %>%
  mutate('OnewRANK' = row_number(desc(Onewreturn)),
         'SixmRANK' = row_number(desc(sixmreturn))) %>%
  select_all %>%
  arrange(desc(Onewreturn))
#그래프로 표현
data_sector_return %>%
  mutate('OnewRANK' = row_number(desc(Onewreturn)),
         'SixmRANK' = row_number(desc(sixmreturn))) %>%
  select_all %>%
  arrange(desc(Onewreturn)) %>%
  ggplot(aes(x = SectorCode, y = Onewreturn )) +
  geom_bar(stat = 'identity') 
  
''' 섹터별 수익률중 최근 일주일, 6개월간의 누적수익률을 구해와
어떤 섹터가 시장을 이끌었고 최근엔 그 추세가 어떤지 파악한다.'''
##unique(data_sector_return['SectorCode'][,])
sectorlist = list()
si = 1
for(i in unique(data_sector_return['SectorCode'][,])){
  nm <-  str_sub(KOR_sector[KOR_sector$IDX_CD == i,"IDX_NM_KOR"],6,15)[2]
  print(nm)
  cd <-  i
  print(cd)
  sectorlist[[si]] <- c(nm,cd)
  si <- si + 1
  Sys.sleep(2)
}
sectorlist <- do.call(rbind,sectorlist) %>% data.frame()
sectorlist[order(sectorlist[,2]),]
'''이렇게 각 섹터코드에 맞는 섹터이름을 확인하여 코로나 이후
섹터별 수익률과 최근추세를 알 수 있다.'''

# 종목별 수정주가 불러오기 
'''네이버 금융> 차트 부분은 주가데이터를 받아 그래프를 그려주는
형태이다. 일봉차트를 선택해서 매일의 수정주가 데이터를
받아올 수 있다. 이렇게 모든 종목의 주가를 끌어온다.'''
library(stringr)
library(xts)
library(lubridate)
library(timetk)
library(httr)
library(rvest)
library(readr)

KOR_ticker = read.csv('data/KOR_ticker.csv', row.names = 1)
KOR_ticker$'종목코드'
print(KOR_ticker$'종목코드'[1])
'''파일을 불러오는과정에서 앞에 00들이 사라진다. 다시 추가해줘야 6자리 티커가 된다.'''
KOR_ticker$'종목코드' =
  str_pad(KOR_ticker$'종목코드', 6, side = c('left'), pad = '0')

ifelse(dir.exists('data22/KOR_price'), FALSE,
       dir.create('data22/KOR_price'))
'''각각 개별종목의 주가를 끌어와 저장할 폴더를 만든다'''

for(i in 1 : nrow(KOR_ticker) ) {
  
  price = xts(NA, order.by = Sys.Date()) # 빈 시계열 데이터 생성
  name = KOR_ticker$'종목코드'[i] # 티커 부분 선택
  
  # 오류 발생 시 이를 무시하고 다음 루프로 진행
  tryCatch({
    # url 생성 name에는 각각의 티커가 들어간다.
    url = paste0(
      'https://fchart.stock.naver.com/sise.nhn?symbol='
      ,name,'&timeframe=day&count=500&requestType=0')
    
    # 데이터 다운로드
    data = GET(url)
    data_html = read_html(data, encoding = 'EUC-KR') %>%
      html_nodes("item") %>%
      html_attr("data") 
    
    # 데이터를 받아오면 | 형태로 구분자가 있는데 이를 기점으로 분해해 테이블 형태로 만들어준다.
    price = read_delim(data_html, delim = '|')
    
    # 필요한 열만 선택 후 클렌징 1열의 날짜, 5열의 수정주가 종가를 끌어온다.
    price = price[c(1, 5)] 
    price = data.frame(price)
    colnames(price) = c('Date', 'Price')
    price[, 1] = ymd(price[, 1])
    # ymd 함수를 사용하여 날짜를 0000-00-00 형태로 변경하고 데이터형태도 Date 형태로 바꾼다.
    
    rownames(price) = price[, 1]
    price[, 1] = NULL
    
  }, error = function(e) {
    
    # 오류 발생시 해당 종목명을 출력하고 다음 루프로 이동
    warning(paste0("Error in Ticker: ", name))
  })
  
  # 다운로드 받은 파일을 생성한 폴더 내 csv 파일로 저장
  write.csv(price, paste0('data22/KOR_price/', name,
                          '_price.csv'))
  
  # 타임슬립 적용
  Sys.sleep(2)
}



# 재무제표 데이터를 다운로드
''' 주가와 더불어 각종 지표들을 구하고 또 얻기위해 재무제표 데이터는
필수라 할 수 있다. 이를 위해 FnGuide가 제공하는 
CompanyGuide 사이트를 통해 재무제표 데이터를 다운로드 한다.'''

## CompanyGuide에서 기업정보 > 재무제표 메뉴를 들어가서 추출
ifelse(dir.exists('data22/KOR_fs'), FALSE,
       dir.create('data22/KOR_fs'))
''' 재무제표를 저장할 폴더를만든다.'''
for(i in 1 : nrow(KOR_ticker) ) {
  
  data_fs = c()
  name = KOR_ticker$'종목코드'[i]
  print(name)
  tryCatch({
    
    Sys.setlocale('LC_ALL', 'English')
    # 한글로된 페이지를 크롤링할때 오류를 방지하기 위해 영어로 잠시 변경
    
    # url 생성
    url = paste0(
      'http://comp.fnguide.com/SVO2/ASP/'
      ,'SVD_Finance.asp?pGB=1&gicode=A',
      name)
    
    # 데이터 다운로드 후 테이블 추출(테이블형식으로 제공된다)
    # 또한 FnGuide는 크롤러와 같이 정체가 불분명한 웹브라우저의 접근을 막는다.
    # 마치 크롬이나 모질라를 통해 접근한 것처럼 데이터를 요청(user_agent 함수 이용)
    data = GET(url,
               user_agent('Mozilla/5.0 (Windows NT 10.0; Win64; x64)
                          AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36')) %>%
      read_html() %>%
      html_table()
    
    Sys.setlocale('LC_ALL', 'Korean')
    ## 다시 언어를 Korean으로 변경한다.
    
    # 3개 재무제표를 하나로 합치기
    data_IS = data[[1]]
    data_BS = data[[3]]
    data_CF = data[[5]]
    #처음 재무제표 테이블에는 포괄손익계산서, 재무상태표, 현금프름표가 각각 연간별, 분기별
    #로 들어가있다. 여기서 각각 연간기준 재무제표에 해당하는 3가지를 선택한다.
    data_IS = data_IS[, 1:(ncol(data_IS)-2)]
    #포괄손익계산서(연간)에는 마지막 뒤에 전년동기, 전년동기(%) 열이 있는데 통일성을 위해 해당
    #열을 삭제한다. 그렇게 되면 각 년의 재무제표 데이터만 남는다.
    #ex > 2017/12 , 2018/12
    data_fs = rbind(data_IS, data_BS, data_CF)
    
    # 데이터 클랜징
    data_fs[, 1] = gsub('계산에 참여한 계정 펼치기',
                        '', data_fs[, 1])
    #첫번째 열인 계정명에는 페이지내의 펼치기 (+)역할하는 버튼이 있어
    #이것이 -계산에 참여한계정펼치기-라고 되어있다. 이를 지워 온전한 계정명만 남긴다.
    data_fs = data_fs[!duplicated(data_fs[, 1]), ]
    #중복되는 계정명이 다수 있는데 대부분 불필요한 항목이다. 제거필요
    
    
    rownames(data_fs) = NULL
    rownames(data_fs) = data_fs[, 1]
    # 행이름을 초기화한후 계정명을 행이름으로 변경한다.
    data_fs[, 1] = NULL
    
    # 12월 재무제표만 선택
    data_fs =
      data_fs[, substr(colnames(data_fs), 6,7) == "12"]
    # 간혹 12월 결산하지 않은 재무제표이거나 분기재무제표가 끼어들어가 있을수가
    # 있다. 그러면 안되니 통일성을 위해 12월 결산데이터만 가져온다.
    
    data_fs = sapply(data_fs, function(x) {
      str_replace_all(x, ',', '') %>%
        as.numeric()
    }) %>%
      data.frame(., row.names = rownames(data_fs))
   }, error = function(e) {
    
    # 오류 발생시 해당 종목명을 출력하고 다음 루프로 이동
    data_fs <<- NA
    warning(paste0("Error in Ticker: ", name))
  })
  write.csv(data_fs, paste0('data22/KOR_fs/', name, '_fs.csv'))
  # 2초간 타임슬립 적용
  Sys.sleep(2)
}


# 재무제표데이터를 이용해 가치지표를 계산하기
'''흔히사용되는 가치지표인 PER,PBR,PCR,PSR을 구한다. 분자는 주가, 부모는 각각
지표에 맞는 재무제표 데이터를 사용한다.'''
'''각 분모 : PER(Earnings : 순이익(지배주주순이익)), PBR(Book Value : 순자산(자본)),
PCR(Cashflow : 영업활동현금흐름(영업활동으로인한현금흐름)), PSR(Sales : 매출액)을 이용한다.'''
ifelse(dir.exists('data22/KOR_value'), FALSE,
       dir.create('data22/KOR_value'))
# 저장할 폴더를 만든다.
for(i in 1 : nrow(KOR_ticker) ) {
  data_value = c()
  name = KOR_ticker$'종목코드'[i]
  tryCatch({
    value_type = c('지배주주순이익', 
                   '자본', 
                   '영업활동으로인한현금흐름', 
                   '매출액') 
    value_index = data_fs[match(value_type, rownames(data_fs)),
                          ncol(data_fs)]
    #네가지 값과 해당항목이 위치하는 지점을 찾고 맨 오른쪽 열 즉, 최근년도
    #재무제표 데이터만을 선택한다.
    
    # Snapshot 페이지 불러오기
    url =
      paste0(
        'http://comp.fnguide.com/SVO2/ASP/SVD_Main.asp',
        '?pGB=1&gicode=A',name)
    data = GET(url,
               user_agent('Mozilla/5.0 (Windows NT 10.0; Win64; x64)
                      AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36'))
    
    # 현재 주가 크롤링
    price = read_html(data) %>%
      html_node(xpath = '//*[@id="svdMainChartTxt11"]') %>%
      html_text() %>%
      parse_number()
    # Company Guide 사이트에서 Xpath를 이용해 현재 주가를 크롤링 해서 가져온다.
    # 원 데이터는 52,220 이런식이니 parse_number함수를 이용해
    # 콤마를 없애고 자연스레 숫자형으로 변경해준다.
    
    # 보통주 발행주식수 크롤링
    share = read_html(data) %>%
      html_node(
        xpath =
          '//*[@id="svdMainGrid1"]/table/tbody/tr[7]/td[1]') %>%
      html_text() %>%
      strsplit('/') %>%
      unlist() %>%
      .[1] %>%
      parse_number()
    #주당순이익 등을 계산하기 위해 주가와 현재 발행주식수를 구하는데, companyguide
    #내에서는 보통주/우선주의 형태로만 발행주식수가 저장된다. 앞에 보통주 주식수만 추출한다.'''
    
    # 가치지표 계산
    data_value = price / (value_index * 100000000/ share)
    names(data_value) = c('PER', 'PBR', 'PCR', 'PSR')
    data_value[data_value < 0] = NA
    # 가치지표가 음수인것들은 NA값을 입력한다.
  }, error = function(e) {
    data_value <<- NA
    warning(paste0("Error in Ticker: ", name))
  })
  write.csv(data_value, paste0('data22/KOR_value/', name,
                               '_value.csv'))
  
  # 2초간 타임슬립 적용
  Sys.sleep(2)
}




# 데이터들 정리하기
''' 위에서 수집한 각각종목들의 재무제표, 수정주가, 가치지표 데이터들을
각각 재무제표, 수정주가, 가치지표의 하나의 엑셀 파일로 만든다'''

## 1. 수정주가 데이터 합치기
library(stringr)
library(xts)
library(magrittr)

KOR_ticker = read.csv('data/KOR_ticker.csv', row.names = 1)
KOR_ticker$'종목코드' =
  str_pad(KOR_ticker$'종목코드', 6, side = c('left'), pad = '0')

price_list = list()

for (i in 1 : nrow(KOR_ticker)) {
  
  name = KOR_ticker[i, '종목코드']
  price_list[[i]] =
    read.csv(paste0('data/KOR_price/', name,
                    '_price.csv'),row.names = 1) %>%
    as.xts()
  
}
 '''각각 종목의 price값을 가져와서 리스트에 하나씩 저장시킨다. 저장시킬때
 시계열형식으로 만든 후 저장한다.'''
price_list = do.call(cbind, price_list) %>% na.locf()
''' 열로 합쳐서 데이터프레임을 만든다. na.locf 함수로 결측치를 전일데이터로 사용한다.''' 
colnames(price_list) = KOR_ticker$'종목코드'
'''열이름을 각각의 종목코드로 넣어서 만들어준다.'''
write.csv(data.frame(price_list), 'data22/KOR_price.csv')
## 재무제표 데이터 정리하기 
library(stringr)
library(magrittr)
library(dplyr)

KOR_ticker = read.csv('data/KOR_ticker.csv', row.names = 1)
KOR_ticker$'종목코드' =
  str_pad(KOR_ticker$'종목코드', 6, side = c('left'), pad = '0')

data_fs = list()

for (i in 1 : nrow(KOR_ticker)){
  
  name = KOR_ticker[i, '종목코드']
  data_fs[[i]] = read.csv(paste0('data/KOR_fs/', name,
                                 '_fs.csv'), row.names = 1)
}
'''위와 동일하게 티커를 불러와 for문을 통해 각각의 재무제표 데이터를 리스트에 저장한다.'''
fs_item = data_fs[[1]] %>% rownames()
length(fs_item)
print(head(fs_item))
''' 재무제표 항목은 정말 많고 업종별로 상이할 수 있다. 이로인해 기준을 정하고 그 기준에
맞춰 재무제표 데이터를 정리할 필요가 있다. > 기준으로 국내시가총액1위 삼성전자의 재무제표
항목을 기준으로 뽑아낸다. 삼성전자의 재무제표는 237개로 나머지또한 이에 맞춰 클린젱해본다.'''
fs_list = list()

for (i in 1 : length(fs_item)) {
  select_fs = lapply(data_fs, function(x) {
    # 삼성전자 재무항목에 있는 것이 해당 항목이 있을시 데이터를 선택
    if ( fs_item[i] %in% rownames(x) ) {
      x[which(rownames(x) == fs_item[i]), ]
      
      # 해당 항목이 존재하지 않을 시, NA로 된 데이터프레임 생성
    } else {
      data.frame(NA)
    }
  })
  
  # 리스트 데이터를 행으로 묶어줌 (열의 개수가 달라도 가능 NA로 처리한다.)
  select_fs = bind_rows(select_fs)
  
  # 열이름이 '.' 혹은 'NA.'인 지점은 삭제 (NA열은 삭제제)
  select_fs = select_fs[!colnames(select_fs) %in%
                          c('.', 'NA.')]
  
  # 연도 순별로 정리
  select_fs = select_fs[, order(names(select_fs))]
  
  # 행이름을 티커로 변경
  rownames(select_fs) = KOR_ticker[, '종목코드']
  
  # 각 항목들을 추출해 리스트에 최종 저장
  fs_list[[i]] = select_fs
  
}

# 리스트 이름을 재무 항목으로 변경
names(fs_list) = fs_item

saveRDS(fs_list, 'data/KOR_fs.Rds')
'''리스트 형태 그대로 저장하기 위해 saveRDS() 함수를 이용해 KOR_fs.Rds 파일로 저장합니다.
Rds 형식은 파일을 더블 클릭한 후 연결 프로그램을 R Studio로 설정해 파일을 불러올 수 있습니다. 혹은 readRDS() 함수를 이용해 파일을 읽어올 수도 있습니다.'''



## 가치지표 정리하기
library(stringr)
library(magrittr)
library(dplyr)

KOR_ticker = read.csv('data/KOR_ticker.csv', row.names = 1)
KOR_ticker$'종목코드' =
  str_pad(KOR_ticker$'종목코드', 6, side = c('left'), pad = '0')

data_value = list()

for (i in 1 : nrow(KOR_ticker)){
  
  name = KOR_ticker[i, '종목코드']
  data_value[[i]] =
    read.csv(paste0('data/KOR_value/', name,
                    '_value.csv'), row.names = 1) %>%
    t() %>% data.frame()
  
}
data_value = bind_rows(data_value)
print(head(data_value))
data_value = data_value[colnames(data_value) %in%
                          c('PER', 'PBR', 'PCR', 'PSR')]

data_value = data_value %>%
  mutate_all(list(~na_if(., Inf)))

rownames(data_value) = KOR_ticker[, '종목코드']
print(head(data_value))
'''일부 종목은 재무 데이터가 0으로 표기되어 
가치지표가 Inf로 계산되는 경우가 있습니다. mutate_all() 내에 na_if() 함수를 이용해 Inf 데이터를 NA로 변경'''
write.csv(data_value, 'data22/KOR_value.csv')

# 데이터 EDA
library(stringr)

KOR_ticker = read.csv('data/KOR_ticker.csv', row.names = 1,
                      stringsAsFactors = FALSE)
KOR_sector = read.csv('data/KOR_sector.csv', row.names = 1,
                      stringsAsFactors = FALSE)

KOR_ticker$'종목코드' =
  str_pad(KOR_ticker$'종목코드', 6,'left', 0)
KOR_sector$'CMP_CD' =
  str_pad(KOR_sector$'CMP_CD', 6, 'left', 0)

data_market = left_join(KOR_ticker, KOR_sector,
                        by = c('종목코드' = 'CMP_CD',
                               '종목명' = 'CMP_KOR'))

head(data_market)
data_market = data_market %>%
  rename(`시가총액` = `시가총액.원.`)

''' 두 데이터를 합쳐 eda를 해본다'''
data_market = data_market %>%
  mutate(`PBR` = as.numeric(PBR),
         `PER` = as.numeric(PER),
         `ROE` = PBR / PER,
         `ROE` = round(ROE, 4),
         `size` = ifelse(`시가총액` >=
                           median(`시가총액`, na.rm = TRUE),
                         'big', 'small')
  )
'''각 가치지표를 수치형으로 바꾸고 ROE열을 추가한다. 그리고 SIZE를 통해 시총규모로 두그룸으로 분류'''
glimpse(data_market)
## 현재 종목들의 지표들이 나와있는 ticker 데이터와 sector데이터를 합쳐 데이터를 구성한 후
## 섹터별 가치지표들의 중간값을 뽑아 어느 종목이 섹터지표보다 저평가되어있나 확인
data_market = data_market %>%
  mutate(`EPS` = as.numeric(EPS)
  )
medivalue <- data_market %>%
  filter(!is.na(SEC_NM_KOR)) %>%
  group_by(SEC_NM_KOR) %>%
  summarize(PER_sector = median(PER, na.rm = TRUE),
            PBR_sector = median(PBR, na.rm = TRUE),
            EPS_vector = median(EPS, na.rm = TRUE)
  )
'''분석결과 IT,건강관리, 커뮤니케이션섹터가 PER의 중간값이 가장 크며,
IT, 건강관리, 커뮤니케이션서비스가 PBR의 중간값이 크다. 즉, 가치지표를 이용해
저평가,고평가를 파악할때 상대적으로 비교할 수치가 크다할 수 있다. 
예를들어 건강관리에서 PER이 34면 저평가지만 금융에서 34면 산업평균보다
고평가임을 나타낸다.'''

## 시가총액별 종목들을 분위수로 분류하여 나열해본다. 
data_market %>%
  mutate(rank_aggvalue = ntile(desc(시가총액), n = 4)) %>%
  select(종목명, rank_aggvalue, 시가총액,) %>%
  head()

## 멀티팩터에사용할 PER,ROE간의 상관관계를 산포도를 이용해 파악하기
data_market %>%
  filter(!is.na(SEC_NM_KOR)) %>%
  ggplot(., aes(x = ROE, y = PER, color = `SEC_NM_KOR`, shape = `SEC_NM_KOR`)) +
    geom_point() +
    geom_smooth(method = 'lm',level = 0.1) +
    coord_cartesian(xlim = c(0, 0.5), ylim = c(0, 100))


# 시장구분으로 우량주 벤쳐주의 PER,ROE 상관관계를 비교한다.
ggplot(data_market, aes(x = ROE, y = PER, color = `시장구분`, shape = `시장구분`)) +
  geom_point() +
  geom_smooth(method = 'lm',level = 0.5) +
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 100))

data_market[c("ROE",'PER')]
data_market[c("ROE",'PER')] %>%
  cor(use = 'complete.obs') %>%
  round(., 2) %>%
  corrplot(method = 'color', type = 'upper',
           addCoef.col = 'black', number.cex = 1,
           tl.cex = 0.6, tl.srt = 45, tl.col = 'black',
           col =
             colorRampPalette(c('blue', 'white', 'red'))(200),
           mar=c(0,0,0.5,0))
'''PER ROE는 음의 상관관계를 나타낸다는 것을 알 수있다. 그리고 코스닥
종목과 산업재,커뮤니케이션,경기관련 섹터일수록 기울기가 더 심하다. 이는
소형,중형주와 섹터 3종는 좀더 PER,ROE에 대해 민감하게 움직인다는 것을 알 수있다.'''








# 종목선정하기 

## 1. 저변동성과 베타 팩터를 이용해 종목선정해보기
### 저변동성 전략과   Baker의 저베타효과를 이용하는 종목을 선정해본다.
'''코로나시대에 워낙 자금유입이 커 계속 상승장을 유지하고있는데 
이때 저변동성이 맞을까 의문, 장기적
으로봤을땐 좋지만 단기엔 아닐수 있어 따로 분류하여 수익률분석해본다.
그리고 베타는 상승장일땐 고베타 종목을 선정해야하지만 최근 코스피가 3100선을 돌파하고
이 지수가 고점인지 조정장이 언제 올지 앞을 내다볼 수 없다. 그래서
그래서 상승장임을 가만해 고베타 2 : 저베타 1 종목을 선정해 리스크를 헷지해본다. 그리고 
저베타 효과에 의한 수익도 추가적으로 기대해본다.'''

### 저변동성전략 

#### 일간 변동성 기준 
library(stringr)
library(xts)
library(PerformanceAnalytics)
library(magrittr)
library(ggplot2)
library(dplyr)
KOR_price = read.csv('data/KOR_price.csv', row.names = 1,
                     stringsAsFactors = FALSE) %>% as.xts()
KOR_ticker = read.csv('data/KOR_ticker.csv', row.names = 1,
                      stringsAsFactors = FALSE) 
KOR_ticker$'종목코드' = 
  str_pad(KOR_ticker$'종목코드', 6, 'left', 0)

ret = Return.calculate(KOR_price)
'''수익률을 계산해주는 함수를 사용해 수익률 계산'''
std_12m_daily = xts::last(ret, 252) %>% apply(., 2, sd) %>%
  multiply_by(sqrt(252))
'''XTS의 last 함수를 이용해 마지막 252일을 기준으로 하고 (이는 일년영업일) 변동성을 구하기
위해 apply 함수를 이용한다. 또한 연율화를 적용하기 위해 sqrt(252)를 계산해준다.'''
head(std_12m_daily)
std_12m_daily %>% 
  data.frame() %>%
  ggplot(aes(x = (`.`))) +
  geom_histogram(binwidth = 0.01) +
  annotate("rect", xmin = -0.02, xmax = 0.02,
           ymin = 0,
           ymax = sum(std_12m_daily == 0, na.rm = TRUE) * 1.1,
           alpha=0.3, fill="red") +
  xlab(NULL)
'''변동성 히스토그램을 보면 0에 위치하는 종목들이 다수있다. 이는 최근 1년간 거래정지 등으로
인해 가격이 변하지 않아 변동성이 없는 종목입니다. 이를 NA로 처리해준다.'''
std_12m_daily[std_12m_daily == 0] = NA

std_12m_daily[rank(std_12m_daily) <= 10]
''' 저변동성을 가진 10종목을 추출하기 위해 순위를 
내주는 rank 함수를 이용해 불러온다. rank함수의 default는 오름차순'''
invest_lowvol = rank(std_12m_daily) <= 10
KOR_ticker[invest_lowvol, ] %>%
  select(`종목코드`, `종목명`) %>%
  mutate(`변동성` = round(std_12m_daily[invest_lowvol], 4))

''' 이렇게 저변동성을 가진 10가지 종목을 선정해 투자해본다. 코로나장 속에서
엄청난 유동성과 변동성, 상승장이 계속되고 있는 추세속에서도 과연 저변동성종목을 투자하는것이
큰 수익 실현에 영향을 미칠지 다른 팩터와 비교해본다.'''


#### 베타 측정하여 저베타, 고베타 종목 선정
library(quantmod)




symbols <- '102110.KS'
''' 시장수익률 대용치로 KOSPI ETF(KODEX KOSPI)를 이용해본다.'''
getSymbols('226490.KS',from = '2018-12-01', to = '2020-12-31')
head(Cl(`226490.KS`))
ret = Return.calculate(KOR_price)
ret = ret['2018-12-20::2020-12-28']
ret1 = Return.calculate(Cl(`226490.KS`))
ret1 = ret1['2018-12-20::2020-12-28']
'''2018-12-20~ 2020-12-28까지의 데이터를 이용해 수익률을 계산한다.'''


betav <- data.frame()
for(i in 1:ncol(KOR_price)){
  reg = lm(ret[,i] ~ ret1)
  summary(reg)
  comname <- str_sub(colnames(KOR_price[,i]),2,7)
  betav[i,1] <- comname
  betav[i,2] <- reg$coefficients[2]
}
'''각각 종목들의 수익률을 시장수익률과 회귀분석을 통해 베타를 구해낸다.
이후 데이터 프레임을 만들어 각 베타값과 종목코드를 저장한다.'''

colnames(betav) <- c("종목코드","Betavalue")
head(betav)
betav[rank(-betav[,'Betavalue']) <= 10,]
betav[rank(betav[,'Betavalue']) <= 10,]
''' 베타값이 가장높은 고베타 종목 10개와 가장 낮은 
저베타 종목 10개를 선정한다.'''

## 2. 모멘텀 팩터 이용
'''모멘텀이란 주가 혹은 이익의 추세로서, 상승 추세의 주식은 지속적으로 상승하며 하락 추세의 주식은 지속적으로 하락하는 현상을 말한다.'''

''' 평소 모멘텀팩터를 이용할때는 가격모멘텀에서 중기모멘텀(6개월~12개월)을 주로 팩터로 사용하지만
코로나 상황이고 모의투자를 위한 단기투자를 위해서 단기모멘텀을 이용한다.
그래서 나는 1월효과를 있을것으로 보아 최근 1개월의 모멘텀과 3개월모멘텀을
보아 종목을 선정해본다.''' 


#이상치 데이터 윈터라이징으로 대체
''' 모든 데이터분석에서 중요한 문제중 하나가 이상치(OUTLIER) 처리방법이다. 하지만 포트폴리오 구성시
이상치를 완전히 제거하는 방식은 잘 사용하지 않는다. 데이터의 손실이 발생하고
그 손실데이터가 정말 좋은종목일 수 있기 때문이다. 
>>> 그래서 윈터라이징 대체기법을 사용하여 극단값을 대체시킨다.'''
''' 벨류팩터를 이용하기위해 PER,PBR 값들의 이상치를 윈터라이징을 대체시킨다.
상위99%를 초과하는 데이터는 99%값으로 대체 하위 1%미만 데이터는 1%로 대체한다.'''

## PER을 예시로 이상치 데이터를 확인해본다.
library(magrittr)
library(ggplot2)

KOR_value = read.csv('data/KOR_value.csv', row.names = 1,
                     stringsAsFactors = FALSE)

max(KOR_value$PER, na.rm = TRUE)
KOR_value %>%
  filter(!is.na(PER)) %>%
  ggplot(aes(x = PER)) +
  geom_histogram(binwidth = 0.1)
''' 이처럼 PER 히스토그램을 그려보면 오른쪽 꼬리가 매우길다. 대부분 0~100 근처에 모여
있지만 몇가지가 1000이상 최대 6475의 값을 가진다. 이를
윈터라이징 대체방법을 이용해 극단치를 대체시켜 그래프를 그려본다.'''

value_winsor = KOR_value %>%
  select(PER) %>%
  mutate(PER = ifelse(percent_rank(PER) > 0.99,
                      quantile(., 0.99, na.rm = TRUE), PER),
         PER = ifelse(percent_rank(PER) < 0.01,
                      quantile(., 0.01, na.rm = TRUE), PER))
# percent_rank는 각 값이 포함되는 백분율을 나타내준다.
value_winsor %>%
  ggplot(aes(x = PER)) +
  geom_histogram(binwidth = 0.1)
''' 그림을 확인해보면 양끝 그래프막대가 길어진 것을 확인할 수 있고 
PER의 극단값들이 6000 > 1000대 이하로 많이 감소시킨것을 알 수 있다.'''
##library(data.table)
##KOR_value1 <- copy(KOR_value)
##head(KOR_value1) 데이터를 카피해 적용이 되는지 확인 할때 쓴 DATAframe

# 1. PER 적용
KOR_value$PER = KOR_value %>%
  select(PER) %>%
  mutate(PER = ifelse(percent_rank(PER) > 0.99,
                      quantile(., 0.99, na.rm = TRUE), PER),
         PER = ifelse(percent_rank(PER) < 0.01,
                      quantile(., 0.01, na.rm = TRUE), PER))

# 2. PBR 적용
print(max(KOR_value['PBR'],na.rm = TRUE)) # 510.312
KOR_value$PBR = KOR_value %>%
  select(PBR) %>%
  mutate(PBR = ifelse(percent_rank(PBR) > 0.99,
                      quantile(., 0.99, na.rm = TRUE), PBR),
         PBR = ifelse(percent_rank(PBR) < 0.01,
                      quantile(., 0.01, na.rm = TRUE), PBR))
print(max(KOR_value['PBR'],na.rm = TRUE)) # 32.41755

# 3. PCR 적용
print(max(KOR_value['PCR'],na.rm = TRUE)) #5150.491
KOR_value$PCR = KOR_value %>%
  select(PCR) %>%
  mutate(PCR = ifelse(percent_rank(PCR) > 0.99,
                      quantile(., 0.99, na.rm = TRUE), PCR),
         PCR = ifelse(percent_rank(PCR) < 0.01,
                      quantile(., 0.01, na.rm = TRUE), PCR))
print(max(KOR_value['PCR'],na.rm = TRUE)) # 533.3245

# 4. PSR 적용
print(max(KOR_value['PSR'],na.rm = TRUE)) #2674.76
KOR_value$PSR = KOR_value %>%
  select(PSR) %>%
  mutate(PSR = ifelse(percent_rank(PSR) > 0.99,
                      quantile(., 0.99, na.rm = TRUE), PSR),
         PSR = ifelse(percent_rank(PSR) < 0.01,
                      quantile(., 0.01, na.rm = TRUE), PSR))
print(max(KOR_value['PSR'],na.rm = TRUE)) #201.64





# 멀티팩터 포트폴리오를 구성하기
'''퀄리티, 벨류, 모멘텀 지표를 활용하여 멀티팩터 포트폴리오를 구성해본다. 이후 각각 팩터들의 분산효과가 있나 확인후 종목선정까지 진행한다.
퀄리티팩터의 경우 기업의 우량성을 나타내는데 여기선 수익성지표인 자기자본이익률(ROE), 매출총이익(GPA), 영업활동현금흐름(CFO)를 이용해 팩터구성한다.
벨류팩터의 경우 기업의 내재 가치를 평가할때 사용하는데 여기선 가장 대중적인 PER,PBR,PCR,PSR을 종합해서 사용한다.
모멘텀팩터의 경우 투자자의 비합리성으로인해 생기는 추세현상으로 여기선 코로나장의 특수성을 적용해 단기모멘텀을 적용해
3개월, 1개월 모멘텀을 이용해 팩터에 결합한다.'''


## 1. 퀄리티(Quality)팩터를 이용한 전략
library(stringr)
library(ggplot2)
library(PerformanceAnalytics)
library(dplyr)
library(tidyr)
KOR_fs = readRDS('data/KOR_fs.Rds')
KOR_ticker = read.csv('data/KOR_ticker.csv', row.names = 1,
                      stringsAsFactors = FALSE) 

KOR_ticker$'종목코드' =
  str_pad(KOR_ticker$'종목코드', 6, 'left', 0)

## 현재의 월이 1~4월일경우 아직 전년도의 재무제표가 발표되지 않은 상황이다. 그래서 이때 보수적으로 전년도가 아닌 전전년도 회계데이터를 사용한다.
if ( lubridate::month(Sys.Date()) %in% c(1,2,3,4) ) {
  num_col = ncol(KOR_fs[[1]]) - 1
} else {
  num_col = ncol(KOR_fs[[1]]) 
}
'''lubridate 패키지로 현재 월을 뽑아와 1,2,3,4월일시 
전전년도 회계데이터를 사용하기위해 num_col값을 조정한다.'''


quality_roe = (KOR_fs$'지배주주순이익' / KOR_fs$'자본')[num_col]
# ROE(자기자본수익률)을 구하기 위해 재무제표데이터에서 순이익,자본데이터 추출
quality_gpa = (KOR_fs$'매출총이익' / KOR_fs$'자산')[num_col]
# 팩터에서 매출총이익은 노비 막스교수가 발표한 팩터로 매출총이익/자산으로 구한다. 
# 이는 (매출액-매출원가)/(자기자본+부채)로 쪼갤 수 있다.
quality_cfo =
  (KOR_fs$'영업활동으로인한현금흐름' / KOR_fs$'자산')[num_col]
# 영업활동현금흐름도 자산으로 나누어주어 팩터로 사용한다.
quality_profit =
  cbind(quality_roe, quality_gpa, quality_cfo) %>%
  setNames(., c('ROE', 'GPA', 'CFO'))
head(quality_profit)
# 따로 세 지표를 이용해 data.frame을 만든다.

factor_quality = quality_profit %>% 
  mutate_all(list(~min_rank(desc(.))))

## 퀄리티 팩터는 높을수록 좋은 지표이기 때문에 내림차순으로 rank를 추출한다.
cor(factor_quality, use = 'complete.obs') %>%
  round(., 2) %>%
  corrplot(method = 'color', type = 'upper',
           addCoef.col = 'black', number.cex = 1,
           tl.cex = 0.6, tl.srt = 45, tl.col = 'black',
           col =
             colorRampPalette(c('blue', 'white', 'red'))(200),
           mar=c(0,0,0.5,0))
'''수익성 지표들 역시 서로간의 상관관계가 크지않아, 세 지표를 통합적으로
고려하여 분산효과를 기대할 수 있다.'''


## 2. 벨류(Value) 팩터를 이용한 전략
''' PER,PBR,PCR,PSR 상대가치지표를 종합적으로 고려해서 내재가치가 저평가되어있는 종목을 발굴한다.'''
factor_value = KOR_value %>% 
  mutate_all(list(~min_rank(.)))
head(factor_value)
# NA열이 있어 상관관계그래프가 그려지지 않아 제거한다.
factor_value <- factor_value[,c(1,2,3,4)]

cor(factor_value, use = 'complete.obs') %>%
  round(., 2) %>%
  corrplot(method = 'color', type = 'upper',
           addCoef.col = 'black', number.cex = 1,
           tl.cex = 0.6, tl.srt=45, tl.col = 'black',
           col = colorRampPalette(
             c('blue', 'white', 'yellow'))(200),
           mar=c(0,0,0.5,0))
''' 상관관계를 그려보면 같은 가치지표임에도 불구하고 서로같의 상관관계가 낮은 지표도 꽤 있다.
PBR,PCR과 PSR간의 상관관계가 좀 높게 나타나지만 4가지를 종합적으로 고려해보면 분산효과를 기대할 수 있다.'''


## 3. 모멘텀(Momentum) 팩터를 이용한 전략 
'''모멘텀이란 주가 혹은 이익의 추세로서 상승추세는 지속상승현상을 예로 들수있습니다.
가격모멘텀의 중기모멘텀(6~12개월)을 주로 사용하지만, 코로나장 속의 큰유동성과
변동성과 신고점이 계속 갱신되는 상승장속에서 단기모멘텀을 지표로 사용한다.'''
KOR_price = read.csv('data/KOR_price.csv', row.names = 1,
                     stringsAsFactors = FALSE) %>% as.xts()
KOR_ticker = read.csv('data/KOR_ticker.csv', row.names = 1,
                      stringsAsFactors = FALSE) 
KOR_ticker$'종목코드' =
  str_pad(KOR_ticker$'종목코드', 6, 'left', 0)

# 먼저 최근 3개월간의 수익률에 관한 모멘텀을 계산한다.
ret_3m = Return.calculate(KOR_price) %>% xts::last(60) %>%
  sapply(., function(x) {prod(1+x) - 1})
ret_1m = Return.calculate(KOR_price) %>% xts::last(20) %>%
  sapply(., function(x) {prod(1+x) - 1})
''' 우선 과거수익률로만 모멘텀종목을 선정하는데 이러면 테마주나 이벤트에 따른 급등으로 
변동성이 지나치게 높은 종목이 있을 수도있다. 코로나시대에 예를 들어 바이오주를 들 수 있다.
그래서 누적수익률을 변동성으로 나누어 샤프지수(Sharp ratio)로 위험을 고려한 위험조정수익률로 
상대적으로 안정적인 모멘텀 종목을 선정한다.'''
ret3 <- Return.calculate(KOR_price) %>% xts::last(60)
std_3m = ret3 %>% apply(., 2, sd) %>% multiply_by(sqrt(60))
sharpe_3m = ret_3m / std_3m
ret1 <- Return.calculate(KOR_price) %>% xts::last(20)
std_1m = ret1 %>% apply(., 2, sd) %>% multiply_by(sqrt(20))
sharpe_1m = ret_1m / std_1m
sharpe_1m
# 각각종목의 샤프지수를 구해놓는다.
ret_bind = cbind(sharpe_1m,sharpe_3m) %>% data.frame()
# 두개의 데이터를 합쳐서 데이터프레임을 구성한다.

factor_mom = ret_bind %>%
  mutate_all(list(~min_rank(desc(.))))
head(factor_mom)
''' 샤프지수를 통해 안정적인 모멘텀팩터를 추출했다. 섹터중립까지는 이미
변동성이 큰 종목을 제외하는 방식이 샤프지수에 어느정도 반영되어있기 때문에 따로 시도하지 않는다.'''



# 팩터들의 결합 방식 
'''위에 세종류의 팩터들을 구해놨지만 단순히 랭킹을 더하는 방법을 통해
포트폴리오를 구성할 시 여러 문제점을 가지고 있다. '''
'''>>> 예로 각 지표들은 최댓값이 서로 다른데, 이는 지표별 결측치로인해 유효 데이터의 개수가
다르기 때문에 나타나는 현상으로 서로 다른범위 분포를 합치는것은 좋지않다.'''

## Z-SCORE를 활용한 정규화
'''기본적으로 랭킹의 분포가 가진 극단치 효과가 사라지는 점과 균등 분포의 장점을 
유지하고 있으며, 분포의 범위 역시 0을 중점으로 거의 동일하게 바뀐다.
이처럼 여러 팩터를 결합해 포트폴리오를 구성하고자 하는 경우, 먼저 각 팩터(지표)별 랭킹을 정규화한 뒤 
더해야 왜곡 효과가 제거되어 안정적입니다.'''

### Quality Factor 정규화 적용
factor_quality = factor_quality %>%
  mutate_all(list(~scale(.))) %>%
  rowSums()
head(factor_quality)
factor_quality %>% 
  data.frame() %>%
  ggplot(aes(x = `.`)) +
  geom_histogram()

### Value Factor 정규화 적용
factor_value = factor_value %>%
  mutate_all(list(~scale(.))) %>%
  rowSums()
factor_value %>% 
  data.frame() %>%
  ggplot(aes(x = `.`)) +
  geom_histogram()

### Momentum Factor 정규화 적용
factor_mom = factor_mom %>%
  mutate_all(list(~scale(.))) %>%
  rowSums()
factor_mom %>% 
  data.frame() %>%
  ggplot(aes(x = `.`)) +
  geom_histogram()


## 세팩터의 상관관계를 비교한다.
cbind(factor_quality, factor_value, factor_mom) %>%
  data.frame() %>%
  setNames(c('Quality', 'Value', 'Momentum')) %>%
  cor(use = 'complete.obs') %>%
  round(., 2) %>%
  corrplot(method = 'color', type = 'upper',
           addCoef.col = 'black', number.cex = 1,
           tl.cex = 0.6, tl.srt = 45, tl.col = 'black',
           col =
             colorRampPalette(c('blue', 'white', 'red'))(200),
           mar=c(0,0,0.5,0))
'''퀄리티, 밸류, 모멘텀 팩터 간의 랭크의 서로 간 상관관계가 매우 낮으며,
여러 팩터를 동시에 고려함으로서 분산효과를 기대할 수 있습니다.'''


# 최종 종목 선정 (멀티팩터 포트폴리오)
factor_qvm =
  cbind(factor_quality, factor_value, factor_mom) %>%
  data.frame() %>%
  mutate_all(list(~scale(.))) %>%
  mutate(factor_quality = factor_quality * 0.25,
         factor_value = factor_value * 0.25,
         factor_mom = factor_mom * 0.5) %>%
  rowSums()

invest_qvm = rank(factor_qvm) <= 20
'''키움 모의투자대회를 위한 단기 투자의 관점에선 value와 quality 팩터보단
momentum 팩터의 비중을 크게 잡는게 좋을 것이라 판단했다.
장기투자 관점에선 저평가,수익성이 좋지만 단기투자에선 둘의 비중을 어느정도 둔상태로
1월효과와 상승장의 추세를 타기위해 모멘텀지표의 비중을 40으로 주었다.'''

### 선택된 종목의 퀄리티 지표 분포
''' 수익성이 대체로 높게 나타나는것을 알 수 있다.'''

quality_profit[invest_qvm, ] %>%
  gather() %>%
  ggplot(aes(x = value)) +
  geom_histogram() +
  facet_wrap(. ~ key, scale = 'free', ncol = 1) +
  xlab(NULL)
### 선택된 종목의 벨류 지표 분포
KOR_value <- KOR_value[,c(1,2,3,4)]
head(KOR_value232)
rownames(KOR_value) <- str_pad(KOR_ticker$'종목코드', 6, 'left', 0)

glimpse(KOR_value232[invest_qvm, ])
KOR_value232[invest_qvm, ]
KOR_value232[invest_qvm, ] %>%
  gather() %>%
  ggplot(aes(x = value)) +
  geom_histogram() +
  facet_wrap(. ~ key, scale = 'free', ncol = 1) +
  xlab(NULL)

### 선택된 종목의 모멘텀(샤프지수이용) 지표 분포
ret_bind[invest_qvm, ] %>%
  gather() %>%
  ggplot(aes(x = value)) +
  geom_histogram() +
  facet_wrap(. ~ key, scale = 'free', ncol = 1) +
  xlab(NULL)

# 종목선정
final <- KOR_ticker[invest_qvm, ] %>%
  select('종목코드', '종목명') %>%
  cbind(round(quality_roe[invest_qvm, ], 2)) %>%
  cbind(round(KOR_value$PER[invest_qvm,], 2)) %>%
  cbind(round(sharpe_1m[invest_qvm], 2)) %>%
  setNames(c('종목코드', '종목명', 'ROE', 'PER', 'Sharp1m'))
final
'''포트폴리오 내 종목들을 대상으로 팩터별 대표적인 지표인 ROE, PBR, 1개월 위험조정수익률을 나타냈다.
특정 팩터의 강도가 약하더라도 나머지 팩터의 강도가 충분히 강하다면, 포트폴리오에 편입되는 모습을 보이기도 한다.'''

# 마지막으로 포트폴리오 내 종목들의 지표별 평균값을 구해본다.
cbind(quality_profit, KOR_value, ret_bind)[invest_qvm, ] %>% 
  apply(., 2, mean) %>% round(3) %>% t()

## 선정된 종목별 섹터비교
ddd <- data_market[invest_qvm, ] %>%
  select(`SEC_NM_KOR`) %>%
  group_by(`SEC_NM_KOR`) %>%
  summarize(n = n())
ddd$sectorname <- NA
ddd
for(i in 1:nrow(ddd)){
  print(i)
  print("====================")
  for(j in 1:nrow(sectorlist)){
    print(ddd[i,1])
    print(sectorlist[j,1])
    if(ddd[i,1] == sectorlist[j,1]){
      ddd$sectorname[i] <- sectorlist[j,2]
    } else{
      aadsad <- 0
    }
  }
}
returndata <- data_sector_return %>%
  mutate('OnewRANK' = row_number(desc(Onewreturn)),
         'SixmRANK' = row_number(desc(sixmreturn))) %>%
  select_all %>%
  arrange(desc(Onewreturn))
ddd$onewreturn <- NA
ddd$sixmreturn <- NA
for(i in 1:nrow(ddd)){
  print(i)
  print("====================")
  for(j in 1:nrow(returndata)){
    print(ddd[i,1])
    print(sectorlist[j,2])
    if(ddd[i,3] == returndata[j,1]){
      ddd$onewreturn[i] <- returndata[j,2]
      ddd$sixmreturn[i] <- returndata[j,3]
    } else{
      aadsad <- 0
    }
  }
}
ddd

## 선정된 종목들 각 섹터의 수와 6개월 누적수익률
ddd %>%
  ggplot(aes(x = reorder(`SEC_NM_KOR`, `n`),
             y = `n`, label = n)) +
  geom_col() +
  geom_text(aes(label = paste(ddd$sixmreturn, '%')),color = 'black', size = 4, hjust = -0.3) +
  xlab(NULL) +
  ylab(NULL) +
  coord_flip() +
  scale_y_continuous(expand = c(0, 0, 0.1, 0)) + 
  theme_classic()

## 선정된 종목들 각 섹터의 수와 최근 1주 누적수익률
ddd %>%
  ggplot(aes(x = reorder(`SEC_NM_KOR`, `n`),
             y = `n`, label = n)) +
  geom_col() +
  geom_text(aes(label = paste(ddd$onewreturn, '%')),color = 'black', size = 4, hjust = -0.3) +
  xlab(NULL) +
  ylab(NULL) +
  coord_flip() +
  scale_y_continuous(expand = c(0, 0, 0.1, 0)) + 
  theme_classic()

''' 필수소비재, 커뮤니케이션 서비스 종목을 제외하고는 대체적으로 6개월 , 최근 1주일의 
누적수익률이 모두 괜찮다.'''

## 위에서 구한 섹터별 PER 중간값과 비교하여 저평가 되어있는지 확인
newfinal <- merge(final,data_market,
                  by = "종목코드",
                  all = FALSE)
final2 <-  merge(newfinal,medivalue,
                 by = "SEC_NM_KOR",
                 all = FALSE)
final2
final2 <- final2 %>%
  select("종목코드","종목명.x","PER.x","PER_sector")
final2
''' 선정된 종목 모두 섹터의 중간값보다 낮은 PER을 가지고 있다.
오직 삼성전자만이 주가의 최근 계속된 상승으로 PER이 커져 섹터 중간과 가까워지고 있다.'''

