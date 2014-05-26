#!ruby
# -*- coding: utf-8 -*-

require "./lib/scraiping"
require "./extractcontent/lib/extractcontent"
require "nkf"

# >>>>>>>>>> 検索語を設定 <<<<<<<<<<
query = ["魔法少女まどか☆マギカ"]          # 検索語群を，をStringを要素に持つArrayで表現
# query = ["自然言語処理", "キーワード抽出"]

# >>>>>>>>>> 検索エンジンインスタンス初期化 <<<<<<<<<<
web_client = Scraiping::WebClient.new       # Webアクセスを担当するインスタンスを生成
yahoo_search = Scraiping::YahooSearch.new   # Yahoo検索エンジンのインスタンスを生成
yahoo_search.web_client = web_client        # 検索結果ページへのアクセスにweb_clientインスタンスを使用

# >>>>>>>>>> 検索エンジンを使用して検索<<<<<<<<<<
urlList = yahoo_search.retrieve(1, query)   # 検索クエリで，1~10番目の検索結果のURLを取得

# >>>>>>>>>> 検索結果ページへのアクセス <<<<<<<<<<
urlList.each { |url| 
    http = web_client.open(url)                         # 実際にページにアクセス

    # 検索結果ページが有効でない場合，そのURLへのアクセスをスキップ
    if http == nil
        next
    end

    # 検索結果から本文らしい部分を抽出して表示
    encoded_contents = NKF.nkf("-w", http.read)         # 文字コード変換
    body = ExtractContent::analyse(encoded_contents)    # 本文らしい部分を尤度計算して，抽出
    puts body                                           # 抽出した本文を表示
    puts "======================================================================"
}
