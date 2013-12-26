#!/usr/bin/ruby
$KCODE="utf-8"
# require "extractcontent" 
require "uri"
require "open-uri"
require "nkf"
require "socket"

# TODO:CustomNetClientを作る
# 既知のバグ
#   URLがpdfファイルの時，open.readした結果が読めるものではない
#   retryの部分

=begin
# ======================================================================
# 検索エンジンを表すクラス
# createUrl, getUrlListをオーバーライドすること
#
# createurl :URIエンコードした文字列とオフセットから，検索するURLを生成する関数
# getUrlList:検索結果のHTMLから，欲しいURLを抽出し，配列で返す関数
# ======================================================================
=end
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
        search_result = @web_client.open(search_url).read # 生成したURLで検索し，結果のHTMLを取得
        result_url_list = self.getUrlList(search_result)        # 検索結果URLから，ヒットしたページのURLを取得

        return result_url_list 
    end 
end

# Yahoo検索のためのクラス
class YahooSearch < SearchEngine
    def initialize
        @addressFormat = "http://search.yahoo.co.jp/search?p=%s&aq=-1&ei=UTF-8&pstart=1&fr=top_ga1_sa&b=%s"
        @targetPattern = /(<h2>ウェブ<\/h2>.*?)$/
        @searchPattern = /((<\/h2><ol>)|(<\/em><\/li>))<li><a href="(.*?)">/
    end

=begin
    # ======================================================================
    # 【abstract】
    #  Yahooの検索結果を表すページのURLを作成する関数
    #
    # 【param】
    #  pageCount : 何ページ目かを表すint型
    #  query     : 検索query．String型を要素に持つArray.
    #
    # 【return】
    #  url       : URLを表す文字列
    # ======================================================================
=end
    def createUrl(pageCount, query)
        page_palamater = (10 * pageCount.to_i) + 1                   # yahooは何番目のページから10個，という表示をする
        query_string = query.join("+")
        url = sprintf(@addressFormat, query, page_palamater.to_s)
        return url
    end

=begin
    # ======================================================================
    # 【abstract】
    #  Yahooの検索結果のページののhtmlから，検索結果となるページ10件へのリンクを
    #  抽出して，リストとして返す
    #
    # 【param】
    #  html_source : 検索結果のhtmlソースコード．string型
    #
    # 【return】
    #  url_list    : リンクを表すstring型を要素に持つArray.
    # ======================================================================
=end
    def getUrlList(html_source)
        target_region = html_source.gsub(/\n/, "").scan(@targetPattern).join("+")
        url_list = target_region.scan(@searchPattern).map{|match| match[3]}
        return url_list
    end
end

# 本当は，エラー処理部分は別途クラス化するべき
class WebClient

    LIMIT_RETRY = 3
    WAIT_RETRY = 3
    WAIT_RETRIEVE = 3
    ERROR_SKIP_MESSAGE = ["404 Not Found", 
                          "403 Forbidden"]

    def initialize
        @continuous_retry_count=0
    end

=begin
    # ======================================================================
    # 【概要】
    #  URLにアクセスし，HTMLオブジェクト(確か)を返す. 失敗した場合は，nilを返す．
    # 【入力】
    #  url   String型，URL
    # 【出力】
    #  html_source   アクセス成功時はHTMLオブジェクト，失敗時にはnil
    # ======================================================================
=end
    def open(url)
        html_source = nil

        if !isValidURL(url)
            return nil
        end

        # エラー処理は，現状やっつけ仕事
        begin
            STDERR.puts "Reading... : " + url
            html_source = Kernel.open(url)

        # HTTPエラーコードが帰ってきた場合
        rescue OpenURI::HTTPError => error
            # エラーの種類によって場合分け
            if isSkip(error)
                self.skip
            else
                self.retry(url)
            end
            
        # ネットが繋がっていない，接続先サーバが見つからない場合
        rescue SocketError
            self.skip

        # 上記以外のエラー
        rescue StandardError
            self.retry(url)

        # サーバのタイムアウト
        # StandardErrorクラスを継承していないため，別途rescueが必要
        rescue Timeout::Error
            self.retry(url)
        end

        @continuous_retry_count = 0
        return html_source
    end

    # 上記のopenにおけるリトライの動作
    def retry(url)
        if @continuous_retry_count < LIMIT_RETRY
            @continuous_retry_count += 1
            STDERR.puts "Can't read this page. Retry to open after " + WAIT_RETRY.inspect + " sec."
            sleep(WAIT_RETRY)
            self.open(url)
        else
            # リトライ回数が上限を超えたとき，空白文字列を返す．
            self.skip
        end
    end

    # 上記のopenにおけるスキップする際の動作
    def skip
        # 現状は，何もしない
        STDERR.puts "This page is not found. We'll skip this page."
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

    def isValidURL(url)
        if url =~ /^http:\/\/rd.listing\.yahoo\.co\.jp\/o\/search\/FOR=/
            return false
        elsif url =~ /\.pdf(#)*/
            return false
        end

        return true
    end
end
