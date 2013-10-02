#!/usr/bin/ruby
$KCODE="utf-8"

require "extractcontent"
require "uri"
require "open-uri"
require "nkf"
#==========================================================================================
# 【概要】 
#  指定検索エンジンで検索し，ヒットしたURLを返すためのクラス
#  TODO:httpアクセス時のエラー処理(CustomNetクラス？)
#==========================================================================================

class WebSearcher
    
    # コンストラクタ
    def initialize(searchEngine = nil)
        @searchEngine = searchEngine
    end

    # googleなり，yahooなりで検索して，その結果を返す
    # http接続(yahooなど)のみ対応，https(googleなど)は現状非対応
    def retrieve(query, pageCount)
        encoded_query = URI.escape(query)                                       # クエリのエンコード
        searchUrl = @searchEngine.createURL(encoded_query, pageCount)           # 検索エンジン毎に指定したフォーマットでURL作成
        searchResult = open(searchUrl).read                                     # 生成したURLで検索し，結果のHTMLを取得
        resultUrlList = searchResult.scan(@searchEngine.searchPattern).flatten  # 検索結果URLから，ヒットしたページのURLを取得

        return resultUrlList
    end

    # Getter
    def searchEngine
        return @searchEngine
    end

    # Setter
    def searchEngine=(value)
        begin
            # 引数searchEngineが，SearchEngineクラスを継承したものか判定
            if value.kind_of?(SearchEngine)
                @searchEngine = value 
            else
                raise "invalid_class_error"
            end
        rescue
            STDERR.puts "web検索エンジンが正しく設定されませんでした．検索エンジンを設定せずに処理を続けます．"
        end
    end

    
end

# ======================================================================
# 抽象クラス 検索エンジンを表す
# コンストラクタと，createURLをオーバーライドすること
# ======================================================================
class SearchEngine

    def initialize
        @addressFormat = ""
        @searchPattern = ""
    end

    def createURL(query)
        raise "abstract method is called!"
    end

    # Getter
    def addressFormat
        return @addressFormat
    end

    def searchPattern
        return @searchPattern
    end
end

# Googleはhttps接続するため，このままでは動かないと思われる．
class GoogleSearch < SearchEngine
    def initialize
        @addressFormat = "https://www.google.com/?hl=ja#hl=ja&q=%s&start=%s"
        @searchPattern = /<h3 class="r"><a href="(.*?)" onmousedown=.*?>/
    end

    def createURL(query, pageCount)
        url = sprintf(@addressFormat, query, pageCount.to_s)
        return url
    end
end

class YahooSearch < SearchEngine
    def initialize
        @addressFormat = "http://search.yahoo.co.jp/search?p=%s&aq=-1&ei=UTF-8&pstart=1&fr=top_ga1_sa&b=%s"
        @searchPattern = /<li><a href="(.*?)">/
    end

    def createURL(query, pageCount)
        pagePalamater = (10 * pageCount.to_i) + 1                   # yahooは何番目のページから10個，という表示をする
        url = sprintf(@addressFormat, query, pagePalamater.to_s)
        return url
    end
end

yahoo_search = YahooSearch.new
searcher = WebSearcher.new(yahoo_search)
query = "中二病でも恋がしたい"
urlList = searcher.retrieve(query, 4)
p urlList
urlList.each { |url| 
    encoded_contents = NKF.nkf("-w", open(url).read)
    body = ExtractContent::analyse(encoded_contents)   
    puts body
    puts "======================================================================"
}

# 以下はネットからソースをダウンロードして，UTF8エンコードして返すプログラム
# url = "http://www.google.co.jp"
# contents = open(url).read
# encodedString = NKF.nkf("-w", contents)
# puts encodedString

# html = File.open("./sampleHTML/ruby2.html").read
# opt = {:waste_expressions => /お問い合わせ|会社概要/}
# ExtractContent::set_default(opt)

# body, title = ExtractContent::analyse(html) # 本文抽出
# puts body
