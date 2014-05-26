#!ruby
# -*- coding: utf-8 -*-

require "open-uri"  # ネット上のURLのオープンに必要
require "socket"    # URLオープンのエラー処理に必要

=begin
# ======================================================================
# 【このライブラリの概要】
#  YahooやGoogleのような検索エンジンを使って，
#  検索クエリに合ったサイトのURLを取得するためのライブラリ．
#
# 【使用例】
#  require "scraiping"
#
#  query = ["魔法少女まどか☆マギカ"]                   # 検索クエリを設定
#  page_num = 1                                         # 1ページ目(1件 ~ 10件)の検索結果を表示する
#  web_client = Scraiping::WebClient.new                # ネット上のページにアクセスするオブジェクトを生成
#  yahoo_search = Scraiping::YahooSearch.new            # Yahooの検索エンジンに該当するオブジェクトを生成
#  yahoo_search.web_client = web_client                 # YahooSearchの内部で，web_clientを用いる
#  
#  urlList = yahoo_search.retrieve(page_num, query)     # クエリとページ数を指定して検索．
#  p urlList                                            # 結果を表示
#
#    -> ["http://www.madoka-magica.com/",
#        "http://ja.wikipedia.org/wiki/%E9%AD%94%E6%B3%95%E5%B0%91%E5%A5%B3%E3%81%BE%E3%81%A9%E3%81%8B%E2%98%86%E3%83%9E%E3%82%AE%E3%82%AB",
#        "http://mm.my-gg.com/",
#        "http://www.mbs.jp/madoka-magica/",
#        "http://madokamagica-game.psvita.bngames.net/",
#        "http://tvanimedouga.blog93.fc2.com/blog-entry-10154.html",
#        "https://twitter.com/madoka_magica",
#        "http://dic.nicovideo.jp/a/%E9%AD%94%E6%B3%95%E5%B0%91%E5%A5%B3%E3%81%BE%E3%81%A9%E3%81%8B%E2%98%86%E3%83%9E%E3%82%AE%E3%82%AB",
#        "http://madoka-magica-game.channel.or.jp/",
#        "http://dic.pixiv.net/a/%E9%AD%94%E6%B3%95%E5%B0%91%E5%A5%B3%E3%81%BE%E3%81%A9%E3%81%8B%E2%98%86%E3%83%9E%E3%82%AE%E3%82%AB"]
#
# 【動作環境】
#  Ubuntu 13.10 上の Ruby 1.8.7にて確認
#  nkfのインストールが必要
# ======================================================================
=end
module Scraiping

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
        WAIT_RETRIEVE = 3   # 次の検索までの最低待ち時間

=begin
        # ======================================================================
        # 【abstract】
        #  検索クエリとページ番号から，検索結果のURLを返す
        #  このクラスを継承したクラスが実装することを期待している．
        # 【param】
        #  query      : 検索クエリとなる文字列を要素にもつArray
        #  page_count : 検索エンジンにおけるページ数．int型
        # 【return】
        #  検索結果を表すString.
        # ======================================================================
=end
        def createUrl(query, page_count)
            raise "abstract method is called!"
        end

=begin
        # ======================================================================
        # 【abstract】
        #  検索結果のhtmlソースコードから，アクセスしたいページのURLを抽出する．
        #  このクラスを継承したクラスが実装することを期待している．
        # 【param】
        #  html_source : 検索結果のhtmlソースコード．String
        # 【return】
        #  アクセスしたいページのURL(String)を要素にもつArray.
        # ======================================================================
=end
        def getUrlList(html_source)
            raise "abstract method is called!"
        end

=begin
        # ======================================================================
        # 【abstract】
        #  フィールド変数 @web_client の setter
        # 【param】
        #  value : WebClientクラスのオブジェクト． 
        # ======================================================================
=end
        def web_client=(value) 
            if value.instance_of?(WebClient)
                @web_client = value
            end
        end

=begin
        # ======================================================================
        # 【abstract】
        #  検索クエリとページ数から，アクセスしたいURLのリストを返す
        #
        # 【param】
        #  page_count : 検索クエリにおけるページ数.int．
        #  query      : 検索クエリとなる文字列を要素にもつArray.
        #
        # 【return】
        #  result_url_list : アクセスしたいURL(String)を要素に持つArray.
        #
        # 【Note】
        #  http接続(yahooなど)のみ対応，https(googleなど)は現状非対応
        # ======================================================================
=end
        def retrieve(page_count, query)
            # encoded_query = URI.escape(query)                     # クエリのエンコード
            encoded_query = query.map{|each_query| URI.escape(each_query)}
            search_url = self.createUrl(page_count, encoded_query)   # 検索エンジン毎に指定したフォーマットでURL作成
            search_result = @web_client.open(search_url).read       # 生成したURLで検索し，結果のHTMLを取得
            sleep(WAIT_RETRIEVE)
            result_url_list = self.getUrlList(search_result)        # 検索結果URLから，ヒットしたページのURLを取得

            return result_url_list 
        end 
    end

    # Yahoo検索のためのクラス
    class YahooSearch < SearchEngine

        # >>>>>>>>>> クラス定数宣言 <<<<<<<<<<
        # 検索結果を表すURLのフォーマット．%sの部分には，sprintfによってstring変数が代入される．
        ADDRESS_FORMAT = "http://search.yahoo.co.jp/search?p=%s&aq=-1&ei=UTF-8&pstart=1&fr=top_ga1_sa&b=%s"

        # 検索結果のURLから，アクセスしたいURLが書かれている部分を大まかに抽出するための正規表現
        # 範囲を予め限定することで，ゴミが抽出されることを防ぐ
        TARGET_PATTERN = /(<h2>ウェブ<\/h2>.*?)$/

        # URL抽出するための正規表現
        SEARCH_PATTERN = /((<\/h2><ol>)|(<\/em><\/li>))<li><a href="(.*?)">/

=begin
        # ======================================================================
        # 【abstract】
        #  Yahooの検索結果を表すページのURLを作成する関数
        #
        # 【param】
        #  page_count : 何ページ目かを表すint型
        #  query     : 検索query．String型を要素に持つArray.
        #
        # 【return】
        #  url       : URLを表す文字列
        # ======================================================================
=end
        def createUrl(page_count, query)
            page_palamater = (10 * (page_count-1).to_i) + 1                   # yahooは何番目のページから10個，という表示をする
            query_string = query.join("+")
            url = sprintf(ADDRESS_FORMAT, query_string, page_palamater.to_s)
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
            target_region = html_source.gsub(/\n/, "").scan(TARGET_PATTERN).join("+")
            url_list = target_region.scan(SEARCH_PATTERN).map{|match| match[3]}
            return url_list
        end
    end

=begin
    # ======================================================================
    # 【abstract】
    #  Webのhtmlへのアクセス，及びエラー処理を担当するクラス
    #  ERROR_SKIP_MESSAGE にないエラーは，LIMIT_RETRY回までリトライをする．
    #  ERROR_SKIP_MESSAGE にあるエラーは，リトライせずにスキップする．
    # 【note】
    #  本当は，エラー処理部分は別途クラス化するべき
    # 【TODO】
    #  シングルトン化
    #  スレッド的な感じにして，前回の検索からの秒数で，待ち時間を変える
    # ======================================================================
=end
    class WebClient

        # >>>>>>>>>> クラス定数宣言 <<<<<<<<<<
        LIMIT_RETRY = 0                         # 1URLへのリトライの制限回数
        WAIT_RETRY = 3                          # リトライするときの待ち時間
        ERROR_SKIP_MESSAGE = ["404 Not Found",  # リトライせずにスキップするエラー
                              "403 Forbidden"]

        # コンストラクタ．フィールド変数の初期化
        def initialize
            @continuous_retry_count=0           # 1URLの連続リトライ回数
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

=begin
        # ======================================================================
        # 【abstract】
        # URLが実際にアクセスするに値するかどうかを判定する (URL抽出で発生したゴミかどうかを判定)
        # これにより，無駄なアクセス，待ち時間の削減が見込める
        # 【param】
        #  url : アクセスするURL．String.
        # 【return】
        #  有用なURLならtrue, そうでなければfalse.
        # ======================================================================
=end
        def isValidURL(url)
            # 現状，pdfは開けない．
            if url =~ /^http:\/\/rd.listing\.yahoo\.co\.jp\/o\/search\/FOR=/
                return false

                # ~~~.pdf#search=~~~ といったURLがよく抽出されるため
            elsif url =~ /\.pdf(#)*/    
                return false
            end

            return true
        end
    end
end # End of Module "Scraiping"
