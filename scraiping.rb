#!/usr/bin/ruby
$KCODE="utf-8"

require "lib/scraiping.rb"
require "lib/extractcontent.rb"

# TODO:CustomNetClientを作る
# 既知のバグ
#   URLがpdfファイルの時，open.readした結果が読めるものではない
#   retryの部分

# query = ["魔法少女まどか☆マギカ"]
query = ["pdf"]
web_client = WebClient.new
yahoo_search = YahooSearch.new
yahoo_search.web_client = web_client

urlList = yahoo_search.retrieve(0, query)
urlList.each { |url| 
    puts url
    http = web_client.open(url)
    # webへのアクセス成功時の動作
    if http != nil
        encoded_contents = NKF.nkf("-w", http.read)
        body = ExtractContent::analyse(encoded_contents)   
        puts body
        puts "======================================================================"
    end
}
