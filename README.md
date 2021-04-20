# jma-ruby

Display local weather in Japan with BitBar/SwiftBar/xBar

日本気象情報をBitBar/[SwiftBar](https://github.com/swiftbar/SwiftBar/)/[xBar](https://github.com/matryer/xbar)で表示

気象庁ホームページリニューアル版に対応（ほとんど）JSON万歳 ＼(^o^)／

`mapgen.rb`で白地図を作成、地域コードをサイトまたは[JSON](https://www.jma.go.jp/bosai/common/const/area.json)から取得、スクリプト冒頭に書き込むこと

DarkSkyサービス終了に向け、観測データは気象庁から

OpenWeather、VisualCrossing、ClimaCellでそれを補足（任意）

Requires ruby >= 2.4, imagemagick, rubygems: activesupport, nokogiri, faraday, rmagick, nkf, mk_sunmoon

## TODO

台風地図点検

警報はデータ不足のため全種類未点検

![screenshot](https://user-images.githubusercontent.com/589440/115321646-c72f2a00-a173-11eb-9221-1a9a0f8e3b02.gif)

## 凡例

**温**　気温（体感温度※）一日間の最低最高気温、観測時

**湿**　相対湿度（露点）

**圧**　気圧

**風**　方向、速度（一日間の突風、観測時）

**雨／雪**　一時間の降水量（一日間の降水量）

**雲**　雲量（雲の高さ〈ClimaCell〉）

**視**　視程

**時**　気象庁データの観測時間

**震**　【一ヶ月間の震度3以上で最近の地震】

　　　マグニチュード（設定観測地点における震度）震源、深さ、観測日時

---

**予報**　最低最高気温　誤差幅表記の例: 2̤0̇ => 18〜20〜21度

　　　　　　　　　　　　　　　　　  2͔0͐ => ≤16〜20〜≥24度（±4以上）

　　　降水確率　10% ＿▁▂▃▄▅▆▇█▓ 100%

※　体感温度は有効温度の公式によって計算される ([参照](https://link.springer.com/article/10.1007/s00484-011-0453-2)).

---

地図データは[国土地理院](https://maps.gsi.go.jp/vector/)の白地図を基に作成

アイコンは、「[Climacons](http://adamwhitcroft.com/climacons/)」Adam Whitcroft氏が作成【[出典](https://github.com/christiannaths/Climacons-Font)】（矢印などは自作）