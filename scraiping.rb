#!/usr/bin/ruby
$KCODE="utf-8"

require "lib/scraiping.rb"
require "lib/extractcontent.rb"
require "nkf"

# TODO:CustomNetClientを作る
# 既知のバグ
#   URLがpdfファイルの時，open.readした結果が読めるものではない
#   retryの部分

query = ["魔法少女まどか☆マギカ"]
# query = ["pdf"]
web_client = Scraiping::WebClient.new
yahoo_search = Scraiping::YahooSearch.new
yahoo_search.web_client = web_client

urlList = yahoo_search.retrieve(1, query)
p urlList
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
