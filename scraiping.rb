#!/usr/bin/ruby
$KCODE="utf-8"

require "extractcontent"
require "uri"
require "open-uri"
require "nkf"
require "socket"

# TODO:CustomNetClientを作る

# ======================================================================
# 検索エンジンを表すクラス
# createUrl, getUrlListをオーバーライドすること
#
# createurl :URIエンコードした文字列とオフセットから，検索するURLを生成する関数
# getUrlList:検索結果のHTMLから，欲しいURLを抽出し，配列で返す関数
# ======================================================================
class SearchEngine

    def createUrl(query, pageCount)
        raise "abstract method is called!"
    end

    def getUrlList(html_source)
        raise "abstract method is called!"
    end

    def web_client=(value) 
        if value.instance_of?(WebClient)
            @web_client = value
        end
    end

    # http接続(yahooなど)のみ対応，https(googleなど)は現状非対応
    def retrieve(pageCount, query)
        # encoded_query = URI.escape(query)                       # クエリのエンコード
        encoded_query = query.map{|each_query| URI.escape(each_query)}
        search_url = self.createUrl(pageCount, encoded_query)   # 検索エンジン毎に指定したフォーマットでURL作成
        search_result = @web_client.secureOpen(search_url).read # 生成したURLで検索し，結果のHTMLを取得
        result_url_list = self.getUrlList(search_result)        # 検索結果URLから，ヒットしたページのURLを取得

        return result_url_list end end

# Googleはhttps接続するため，このままでは動かないと思われる．
# class GoogleSearch < SearchEngine
    # def initialize
        # @addressFormat = "https://www.google.com/?hl=ja#hl=ja&q=%s&start=%s"
        # @searchPattern = /<h3 class="r"><a href="(.*?)" onmousedown=.*?>/
    # end

# end

# Yahoo検索のためのクラス
class YahooSearch < SearchEngine
    def initialize
        @addressFormat = "http://search.yahoo.co.jp/search?p=%s&aq=-1&ei=UTF-8&pstart=1&fr=top_ga1_sa&b=%s"
        @searchPattern = /((<\/h2><ol>)|(<\/em><\/li>))<li><a href="(.*?)">/
    end

    def createUrl(pageCount, query)
        page_palamater = (10 * pageCount.to_i) + 1                   # yahooは何番目のページから10個，という表示をする
        query_string = query.join("+")
        url = sprintf(@addressFormat, query, page_palamater.to_s)
        return url
    end

    def getUrlList(html_source)
        url_list = html_source.scan(@searchPattern).map{|match| match[3]}
        return url_list
    end
end

# 本当は，エラー処理部分は別途クラス化するべき
class WebClient

    LIMIT_RETRY = 3
    WAIT_RETRY = 10000
    WAIT_RETRIEVE = 3000
    ERROR_SKIP_MESSAGE = ["404 Not Found", 
                          "403 Forbidden"]

    def initialize
        @continuous_retry_count
    end

    # ======================================================================
    # 【概要】
    # URLにアクセスし，HTMLオブジェクト(確か)を返す. 失敗した場合は，nilを返す．
    # 【入力】
    # url   String型，URL
    # 【出力】
    # html_source   アクセス成功時はHTMLオブジェクト，失敗時にはnil
    # ======================================================================
    def secureOpen(url)
        html_source = nil
        @continuous_retry_count = 0

        # エラー処理は，現状やっつけ仕事
        begin
            html_source = open(url)

        # HTTPエラーコードが帰ってきた場合
        rescue OpenURI::HTTPError => error
            # エラーの種類によって場合分け
            if isSkip(error)
                self.skip
            else
                self.retry
            end
            
        # ネットが繋がっていない，接続先サーバが見つからない場合
        rescue SocketError
            self.skip

        # 上記以外のエラー
        rescue StandardError
            self.retry

        # サーバのタイムアウト
        # StandardErrorクラスを継承していないため，別途rescueが必要
        rescue Timeout::Error
            self.retry
        end

        return html_source
    end

    # 上記のsecureOpenにおけるリトライの動作
    def retry
        if @continuous_retry_count < LIMIT_RETRY
            @continuous_retry_count += 1
            retry
        # リトライ回数が上限を超えたとき，空白文字列を返す．
        end
    end

    # 上記のsecureOpenにおけるスキップする際の動作
    def skip
        # 現状は，何もしない
    end

    # エラーがスキップするべきものかを判定する関数
    def isSkip(error)
        is_skip = false

        ERROR_SKIP_MESSAGE.each { |skip_message| 
            if error.message == skip_message
                is_skip = true
            end
        }

        return is_skip
    end
end

query = ["チャージマン研", "頭の中にダイナマイト"]
web_client = WebClient.new
yahoo_search = YahooSearch.new
yahoo_search.web_client = web_client

urlList = yahoo_search.retrieve(0, query)
urlList.each { |url| 
    http = web_client.secureOpen(url)
    # webへのアクセス成功時の動作
    if http != nil
        encoded_contents = NKF.nkf("-w", http.read)
        body = ExtractContent::analyse(encoded_contents)   
        puts body
        puts "======================================================================"
    end
}
