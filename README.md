# jma.bitbar

Display local weather in Japan with BitBar/SwiftBar

日本気象情報をBitBar/SwiftBarで表示

気象庁ホームページリニューアル版に対応（ほとんど）JSON万歳 ＼(^o^)／

地域コードをサイトから取得、スクリプト冒頭に書き込むこと

DarkSkyサービス終了に向け、OpenWeather、VisualCrossing、ClimaCellなどで代替を模索中

Requires ruby >= 2.4, activesupport (gem), nokogiri (gem), faraday (gem), nkf (gem), rmagick (gem), imagemagick

## TODO

単独画像でなくなったレーダーや衛星写真の画像を挿入

絵文字からPNGアイコンへ移行

体感温度って何？

非ダークモード対応

## 不具合

警報はデータ不足のため全種類未点検

絵文字の幅が異なり、文字列が不整頓

![screenshot](https://user-images.githubusercontent.com/589440/81513083-46d23900-9315-11ea-8f0e-9d7351007e43.png)
