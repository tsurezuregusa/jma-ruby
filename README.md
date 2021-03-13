# jma.bitbar

Display local weather in Japan with BitBar/SwiftBar/xBar

日本気象情報をBitBar/SwiftBar/xBarで表示

気象庁ホームページリニューアル版に対応（ほとんど）JSON万歳 ＼(^o^)／

`mapgen.rb`で白地図を作成、地域コードをサイトから取得、スクリプト冒頭に書き込むこと

DarkSkyサービス終了に向け、観測データは気象庁から

OpenWeather、VisualCrossing、ClimaCellでそれを補足（任意）

Requires ruby >= 2.4, activesupport (gem), nokogiri (gem), faraday (gem), nkf (gem), rmagick (gem), imagemagick

## TODO

台風地図

警報はデータ不足のため全種類未点検

![screenshot](https://user-images.githubusercontent.com/589440/111020619-33717d80-83bf-11eb-9bce-e318f49e1c58.png)

## 凡例

**温**　気温（体感温度）一日間の最低最高気温、観測時

**湿**　対湿度（露点）

**圧**　気圧

**風**　方向、速度（一日間の突風、観測時）

**雨／雪**　一時間の降水量（一日間の降水量）

**雲**　雲量（雲の高さ〈ClimaCell〉）

**視**　視程

**時**　気象庁データの観測時間

**震**　【一ヶ月間の震度3以上で最近の地震】　マグニチュード（設定観測地点における震度）震源、深さ、観測日時