#!/usr/bin/ruby
$KCODE="utf-8"

require "extractcontent"
require "open-uri"
require "nkf"
#==========================================================================================
# 【概要】
#   googleで指定クエリにより検索し，検索結果の各ページの内容を取得し，文字列の配列で返す．
#   目標は，APIとほぼ同等の役割を果たすこと．
#==========================================================================================

class WebSearcher
    
    # コンストラクタ
    def initialize(searchEngine)
        @searchEngine = nil

        begin
            if searchEngine.class == SearchEngine
                @searchEngine = searchEngine
            else
                raise "invalid_class_error"
            end
        rescue
            STDERR.puts "web検索エンジンが正しく設定されませんでした．検索エンジンを設定せずに処理を続けます．"
        end
    end

    # googleなり，yahooなりで検索して，その結果を返す
    def retrieve(query, pageCount)

    end
end

class SearchEngine

    # def initialize
        # @addressFormat = ""
        # @searchPattern = ""
    # end

    def createURL(query)
        raise "abstract method is called!"
    end
end

class GoogleSearch < SearchEngine
    def initialize
        @addressFormat = "https://www.google.com/#q=%s&start=%s"
    end

    def createURL(query, pageCount)
        url = sprintf(@addressFormat, query, pageCount.to_s)
        return url
    end
end

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
