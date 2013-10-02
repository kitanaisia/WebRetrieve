#!/usr/bin/ruby
$KCODE="utf-8"

require "extractcontent"
require "uri"
require "open-uri"
require "nkf"
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

    # http接続(yahooなど)のみ対応，https(googleなど)は現状非対応
    def retrieve(query, pageCount)
        encoded_query = URI.escape(query)                    # クエリのエンコード
        searchUrl = self.createUrl(encoded_query, pageCount) # 検索エンジン毎に指定したフォーマットでURL作成
        searchResult = open(searchUrl).read                  # 生成したURLで検索し，結果のHTMLを取得
        resultUrlList = self.getUrlList(searchResult)        # 検索結果URLから，ヒットしたページのURLを取得

        return resultUrlList
    end
end

# Googleはhttps接続するため，このままでは動かないと思われる．
class GoogleSearch < SearchEngine
    def initialize
        @addressFormat = "https://www.google.com/?hl=ja#hl=ja&q=%s&start=%s"
        @searchPattern = /<h3 class="r"><a href="(.*?)" onmousedown=.*?>/
    end

    def createUrl(query, pageCount)
        url = sprintf(@addressFormat, query, pageCount.to_s)
        return url
    end

    def getUrlList(html_source)
    end
end

class YahooSearch < SearchEngine
    def initialize
        @addressFormat = "http://search.yahoo.co.jp/search?p=%s&aq=-1&ei=UTF-8&pstart=1&fr=top_ga1_sa&b=%s"
        @searchPattern = /((<\/h2><ol>)|(<\/em><\/li>))<li><a href="(.*?)">/
    end

    def createUrl(query, pageCount)
        pagePalamater = (10 * pageCount.to_i) + 1                   # yahooは何番目のページから10個，という表示をする
        url = sprintf(@addressFormat, query, pagePalamater.to_s)
        return url
    end

    def getUrlList(html_source)
        url_list = html_source.scan(@searchPattern).map{|match| match[3]}
        return url_list
    end
end

query = "プラナス・ガール"
yahoo_search = YahooSearch.new
urlList = yahoo_search.retrieve(query, 4)
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
