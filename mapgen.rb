#!/usr/bin/env ruby

# mapgen.rb
# 以下の設定により衛星写真とレーダーの白地図を作成、ターミナルに出力
# それをスクリプトにコピペ
# 願わくば間隔空けず連続実行することなかれ

require 'open-uri'
require 'base64'
require 'rmagick'


#### 設定
# これらをスクリプトにコピペ

# 衛星写真座標
# satmap-key.pngを参照
# 下記は本州、首都圏を中心に
$satxa = 27
$satxb = 29
$satya = 11
$satyb = 13

# レーダー座標
# radmap-key.pngを参照
# 下記は首都圏
$radxa = 226
$radxb = 227
$radya = 100
$radyb = 101

####

## satmap

$satmaplist = Magick::ImageList.new

for i in $satxa..$satxb
	ilist = Magick::ImageList.new
	for j in $satya..$satyb
		url = "https://www.jma.go.jp/tile/jma/sat/5/#{i}/#{j}.png"
		png = Magick::Image.from_blob(URI.open(url).read) do |img|
			img.format = 'PNG'
			img.background_color = 'transparent'
		end
		img = png[0].modulate(1.0,1.0,1.0).to_blob
		# ↑ modulate => 明度・彩度・色相を変更（1.0 == 100% == 変更なし）
		list = Magick::ImageList.new
		ilist.from_blob(img)
		ilist += list
	end
	row = ilist.append(true)
	$satmaplist.push(row)
end

satmap = $satmaplist.append(false)

satmap.write("./satmap-test.png")

puts "satmap64 = \"#{Base64.encode64(satmap.to_blob).strip}\""

puts

## radmap

def splitmap(img) # 6144x5888 24x23 (256x256px)
	grid = Magick::ImageList.new
	for x in ($radxa-213)..($radxb-213)
		rowlist = Magick::ImageList.new
		for y in ($radya-90)..($radyb-90)
			tile = img.crop(Magick::NorthWestGravity,x*256,y*256,256,256,true)
			tile.background_color = 'transparent'
			list = Magick::ImageList.new
			rowlist.from_blob(tile.to_blob)
			rowlist += list
		end
		row = rowlist.append(true)
		grid.push(row)
	end
	return grid.append(false)
end

radmap = splitmap(Magick::Image.read("./radmap.png")[0])

radmap.write("./radmap-dark-test.png")
radmap.negate.write("./radmap-light-test.png")

puts "radmap64 = \"#{Base64.encode64(radmap.to_blob).strip}\""

