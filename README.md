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

## 不具合

警報はデータ不足のため全種類未点検



![screenshot](https://user-images.githubusercontent.com/589440/111020619-33717d80-83bf-11eb-9bce-e318f49e1c58.png)
