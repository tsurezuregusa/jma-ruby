#!/usr/bin/env ruby

# <bitbar.title>Japan Weather</bitbar.title>
# <bitbar.version>0.5</bitbar.version>
# <bitbar.author.github>tsurezuregusa</bitbar.author.github>
# <bitbar.desc>Display local weather in Japan</bitbar.desc>
# <bitbar.dependencies>ruby >= 2.4, nokogiri (gem), activesupport (gem), faraday (gem), rmagick (gem), darksky-weather</bitbar.dependencies>

require 'open-uri'
require 'faraday'
require 'time'
require 'json'
require 'nkf'
require 'base64'
require 'rubygems'
require 'nokogiri'
require 'active_support/core_ext/numeric'
require 'rmagick'

$darkskyapi = nil
$latlon = '35.6895,139.6917'
$place = '東京'
$area = '319'
$subarea = 0
$weeksub = 0

# 301 Hokkaido: Souya
# 302 Hokkaido: 0 Kamikawa, 1 Rumoi
# 303 Hokkaido: 0 Abashiri, 1 Kitami, 2 Monbetsu
# 304 Hokkaido: 0 Kushiro, 1 Nemuro, 2 Tokachi
# 305 Hokkaido: 0 Iburi, 1 Hidaka
# 306 Hokkaido: 0 Ishikari, 1 Sorachi, 2 Shiribeshi
# 307 Hokkaido: 0 Oshima, 1 Hiyama
# 308 Aomori
# 309 Akita
# 310 Iwate
# 311 Yamagata
# 312 Miyagi
# 313 Fukushima
# 316 Tochigi
# 315 Gunma
# 317 Saitama
# 314 Ibaraki
# 318 Chiba
# 319 Tokyo: 0 Tokyo, 1 Izu Oshima, 2 Izu Hachijojima, 3 Ogasawara
# 320 Kanagawa
# 322 Nagano
# 321 Yamanashi
# 327 Shizuoka
# 328 Gifu
# 329 Aichi
# 330 Mie
# 323 Nigata
# 324 Toyama
# 325 Ishikawa
# 326 Fukui
# 334 Shiga
# 333 Kyoto
# 335 Nara
# 331 Osaka
# 332 Hyougo
# 336 Wakayama
# 339 Tottori
# 337 Shimane
# 340 Okayama
# 338 Hiroshima
# 341 Kagawa
# 343 Tokushima
# 342 Ehime
# 344 Kochi
# 345 Yamaguchi
# 346 Fukuoka
# 350 Oita
# 347 Saga
# 349 Kumamoto
# 348 Nagasaki
# 351 Miyazaki
# 352 Kagoshima
# 353 Okinawa
# 354 Okinawa: Daito
# 355 Okinawa: Miyako
# 356 Okinawa: Yaeyama

$region = '206'
# 206 Kanto

$warnlocal = '1311300'
# http://www.jma.go.jp/jp/warn/

$local = '44126'
# http://www.jma.go.jp/jp/amedas/000.html

$satfreq = 'gms150jp'
# 'gms' <- 10m
# 'gms150jp' <- 2.5m

$sattype = 'colorenhanced'
# infrared, visible, colorenhanced, watervapor
# colorenhanced Feb-April night unavailable

$naoopt = 13

######

class Time
	def round_off(seconds = 60)
		Time.at((self.to_f / seconds).round * seconds)
	end

	def floor(seconds = 60)
		Time.at((self.to_f / seconds).floor * seconds)
	end
end

$dt = Time.now
$d = $dt.strftime("%Y%m%d")
$today = Time.now.strftime("%-d")
$t = Time.now
$h = ($t-6.minutes).strftime("%H").to_i
$tr = $t.floor(5.minutes).strftime("%H%M")
if $satfreq == 'gms150jp'
	$ts = ($t-6.minutes).floor(150.seconds).strftime("%H%M%S")
else
	$ts = ($t-8.minutes).floor(10.minutes).strftime("%H%M")
end

$koyomi = Nokogiri::HTML(open("http://eco.mtk.nao.ac.jp/cgi-bin/koyomi/sunmoon.cgi"))
$sunrise = Time.parse($koyomi.css('td').select{|text| text['class'] != 'left'}[0].text.strip)
$sunset = Time.parse($koyomi.css('td').select{|text| text['class'] != 'left'}[2].text.strip)
moonrisetext = $koyomi.css('td').select{|text| text['class'] != 'left'}[3].text.strip
if not moonrisetext['-']
	$moonrise = moonrisetext
else
	$moonrise = Time.parse('0:00')
end
moonsettext = $koyomi.css('td').select{|text| text['class'] != 'left'}[5].text.strip
if not moonsettext['-']
	$moonrise = moonsettext
else
	$moonrise = Time.parse('0:00')
end

# cloudy, fine, fine night, rain, heavy rain, snow, heavy snow; then, occasional, once
# 🌞🌝🌛🌜🌚🌕🌖🌗🌘🌑🌒🌓🌔🌙☀️🌤⛅️🌥☁️🌦🌧⛈🌩🌨❄️☃️⛄️🌬💨💧💦☔️☂️🌈⚡️✨☁︎☀︎☼☾☂︎❆❄︎

CLOUDY = '☁️'

FINE = '☀️'

FINENIGHT = '🌙'

RAIN = '💧'

HEAVYRAIN = '💦'

SNOW = '❄️'

HEAVYSNOW = '☃️'

# THEN = '∕'
# THEN = ' → '
# THEN = ' > '
# THEN = '>'
# THEN = '⟶'
THEN = '⤇'
# THEN = '➡️'

# OCCASIONAL = ' ⇌ '
# OCCASIONAL = '<->'
# OCCASIONAL = '∕'
# OCCASIONAL = '⟋'
# OCCASIONAL = '⟷'
# OCCASIONAL = '⟺'
OCCASIONAL = '⟳'
# OCCASIONAL = '🔁'

# ONCE = ' ❘ '
# ONCE = '|' % does not work with bitbar
# ONCE = ' ⥄ '
# ONCE = ' ⥄ '
# ONCE = '⟷'
# ONCE = '⟻'
ONCE = '⥄'
# ONCE = '↩️'

ICONLENGTH = 7.5

FINECLOUD = '🌤'

CLOUDFINE = '⛅️'

LIGHTNING = '⚡️'

WIND = '💨'

$yoho = Nokogiri::HTML(open("http://www.jma.go.jp/jp/yoho/#{$area}.html"))
$week = Nokogiri::HTML(open("http://www.jma.go.jp/jp/week/#{$area}.html"))

def typhoonimg
	begin
		img = Magick::Image::from_blob(URI.open('http://www.jma.go.jp/jp/typh/images/wide/all-00.png').read).first.crop(0,0,480,335, true)
		return "| refresh=true image=#{Base64.encode64(img.to_blob).gsub(/\n/, '')}"
	rescue
		return '❌'
	end
end

def typhooninfo
	html = Nokogiri::HTML(open("http://www.jma.go.jp/jp/typh/"))
	info = html.css('div').select{|text| text['class'] == 'typhoonInfo'}

	typhid = html.xpath('//div[@class="typhoonInfo"]/@id')

	typhlist = []

	typhid.each do |typhoon|
		typhlist.push(html.css('option').select{|text| text['value'] == typhoon.to_s}.first.text.delete('台風'))
	end

	typhinfo = ''
	i = 0
	info.each do |typhoon|
		typhinfo += "--#{typhlist[i]} #{typhoon.css('td')[3].text unless typhoon.css('td')[3].text.match?('-')} #{typhoon.css('td')[5].text unless typhoon.css('td')[5].text.match?('-')} #{typhoon.css('td')[7].text}  #{typhoon.css('td')[13].text.split('(')[0].insert(-5,' ') unless not typhoon.css('td').text.include?('風速')}  #{typhoon.css('td')[15].text.insert(-4,' ')}  #{typhoon.css('td')[17].text.split('(')[0].insert(-4,' ')} (#{typhoon.css('td')[19].text.split('(')[0].insert(-4,' ') unless not typhoon.css('td').text.include?('風速')}) | color=#{$textcolor}\n".gsub(/   +/, '  ').gsub(/ っ/,'っ').gsub(/\(\)/,'')
		i += 1
	end
	return typhinfo
end

## yoho

# city
# puts yoho.css('td').select{|text| text['class'] == "city"}[i]
# 0,2,4,6

def city
	case $subarea
	when 0
		$yoho.css('td').select{|text| text['class'] == "city"}[0]
	when 1
		$yoho.css('td').select{|text| text['class'] == "city"}[2]
	when 2
		$yoho.css('td').select{|text| text['class'] == "city"}[4]
	when 3
		$yoho.css('td').select{|text| text['class'] == "city"}[6]
	end
end

# date
# puts yoho.css('th').select{|text| text['class'] == "weather"}[i].text
# today
# 0,3,6,9
# tomorrow
# 1,4,7,10
# aftertom
# 2,5,8,11

def yohodate
	[$yoho.css('th').select{|text| text['class'] == "weather"}[0].text.strip, $yoho.css('th').select{|text| text['class'] == "weather"}[1].text.strip, $yoho.css('th').select{|text| text['class'] == "weather"}[2].text.strip]
end

# forecast icon
# puts yoho.css('img').select{|text| text['align'] == "middle"}[i]['title']
# today
# 0,3,6,9
# tomorrow
# 1,4,7,10
# aftertom
# 2,5,8,11

def yohoicon
	case $subarea
	when 0
		[$yoho.css('img').select{|text| text['align'] == "middle"}[0]['title'], $yoho.css('img').select{|text| text['align'] == "middle"}[1]['title'], $yoho.css('img').select{|text| text['align'] == "middle"}[2]['title']]
	when 1
		[$yoho.css('img').select{|text| text['align'] == "middle"}[3]['title'], $yoho.css('img').select{|text| text['align'] == "middle"}[4]['title'], $yoho.css('img').select{|text| text['align'] == "middle"}[5]['title']]
	when 2
		[$yoho.css('img').select{|text| text['align'] == "middle"}[6]['title'], $yoho.css('img').select{|text| text['align'] == "middle"}[7]['title'], $yoho.css('img').select{|text| text['align'] == "middle"}[8]['title']]
	when 3
		[$yoho.css('img').select{|text| text['align'] == "middle"}[9]['title'], $yoho.css('img').select{|text| text['align'] == "middle"}[10]['title'], $yoho.css('img').select{|text| text['align'] == "middle"}[11]['title']]
	end
end

# forecast text
# puts yoho.css('td').select{|text| text['class'] == "info"}[i]
# today
# 0,3,6,9
# tomorrow
# 1,4,7,10
# aftertom
# 2,5,8,11

def yohotext
	case $subarea
	when 0
		[$yoho.css('td').select{|text| text['class'] == "info"}[0]&.text, $yoho.css('td').select{|text| text['class'] == "info"}[1]&.text, $yoho.css('td').select{|text| text['class'] == "info"}[2]&.text]
	when 1
		[$yoho.css('td').select{|text| text['class'] == "info"}[3]&.text, $yoho.css('td').select{|text| text['class'] == "info"}[4]&.text, $yoho.css('td').select{|text| text['class'] == "info"}[5]&.text]
	when 2
		[$yoho.css('td').select{|text| text['class'] == "info"}[6]&.text, $yoho.css('td').select{|text| text['class'] == "info"}[7]&.text, $yoho.css('td').select{|text| text['class'] == "info"}[8]&.text]
	when 3
		[$yoho.css('td').select{|text| text['class'] == "info"}[9]&.text, $yoho.css('td').select{|text| text['class'] == "info"}[10]&.text, $yoho.css('td').select{|text| text['class'] == "info"}[11]&.text]
	end
end

# temp
# puts yoho.css('td').select{|text| text['class'] == "min"}[i] # blank 度
# puts yoho.css('td').select{|text| text['class'] == "max"}[i] # trailing endline 度
# today
# 0,2,4,6
# tomorrow
# 1,3,5,7

def yohotemp # today min max, tomorrow min max
	case $subarea
	when 0
		[$yoho.css('td').select{|text| text['class'] == "min"}[0]&.text.strip.gsub(/度/, '°'), $yoho.css('td').select{|text| text['class'] == "max"}[0]&.text.strip.gsub(/度/, '°'), $yoho.css('td').select{|text| text['class'] == "min"}[1]&.text.strip.gsub(/度/, '°'), $yoho.css('td').select{|text| text['class'] == "max"}[1]&.text.strip.gsub(/度/, '°')]
	when 1
		[$yoho.css('td').select{|text| text['class'] == "min"}[2]&.text.strip.gsub(/度/, '°'), $yoho.css('td').select{|text| text['class'] == "max"}[2]&.text.strip.gsub(/度/, '°'), $yoho.css('td').select{|text| text['class'] == "min"}[3]&.text.strip.gsub(/度/, '°'), $yoho.css('td').select{|text| text['class'] == "max"}[3]&.text.strip.gsub(/度/, '°')]
	when 2
		[$yoho.css('td').select{|text| text['class'] == "min"}[4]&.text.strip.gsub(/度/, '°'), $yoho.css('td').select{|text| text['class'] == "max"}[4]&.text.strip.gsub(/度/, '°'), $yoho.css('td').select{|text| text['class'] == "min"}[5]&.text.strip.gsub(/度/, '°'), $yoho.css('td').select{|text| text['class'] == "max"}[5]&.text.strip.gsub(/度/, '°')]
	when 3
		[$yoho.css('td').select{|text| text['class'] == "min"}[6]&.text.strip.gsub(/度/, '°'), $yoho.css('td').select{|text| text['class'] == "max"}[6]&.text.strip.gsub(/度/, '°'), $yoho.css('td').select{|text| text['class'] == "min"}[7]&.text.strip.gsub(/度/, '°'), $yoho.css('td').select{|text| text['class'] == "max"}[7]&.text.strip.gsub(/度/, '°')]
	end
end

# rain
# puts yoho.css('td').select{|text| text['align'] == "right"}[i]
# today
# 0-6: 0,8,16,24
# 6-12: 1,9,17,25
# 12-18: 2,10,18,26
# 18-24: 3,11,19,27
# tomorrow
# 0-6: 4,12,20,28
# 6-12: 5,13,21,29
# 12-18: 6,14,22,30
# 18-24: 7,15,23,31

def yohorain # today 0-6 6-12 12-18 18-24, tomorrow 0-6 6-12 12-18 18-24
	case $subarea
	when 0
		[$yoho.css('td').select{|text| text['align'] == "right"}[0].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[1].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[2].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[3].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[4].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[5].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[6].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[7].text.gsub(/--%/, ' ')]
	when 1
		[$yoho.css('td').select{|text| text['align'] == "right"}[8].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[9].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[10].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[11].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[12].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[13].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[14].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[15].text.gsub(/--%/, ' ')]
	when 2
		[$yoho.css('td').select{|text| text['align'] == "right"}[16].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[17].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[18].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[19].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[20].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[21].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[22].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[23].text.gsub(/--%/, ' ')]
	when 3
		[$yoho.css('td').select{|text| text['align'] == "right"}[24].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[25].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[26].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[27].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[28].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[29].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[30].text.gsub(/--%/, ' '), $yoho.css('td').select{|text| text['align'] == "right"}[31].text.gsub(/--%/, ' ')]
	end
end

def gaikyo
	text = $yoho.css('pre').text.gsub(/天気概況.+?$\n/, '')
	text.gsub!(/([\p{Hiragana}\p{Katakana}])\s*$\n/, '\1')
	text.gsub!(/([一-龠々&&[^表]])\s*$\n/, '\1')
	# text.gsub!(/([一-龠々])\s*$\n/, '\1')
	text.gsub!(/\n\n\n/, "\n\n")
	text.gsub!(/[しりが]、/, '\0\n')
	text.gsub!(/。/, '\0\n')
	text.gsub!(/\\n/, "\n")
	text.gsub!(/\n^　+$\n/, "\n")
	text.gsub!(/\n\n/, "\n")
	text.gsub!(/\n\s*\n\s*\n/, "\n\n")
	text = NKF.nkf('-X -w', text).tr('０-９．', '0-9.')
	return text
end

def warning(html)
	times = html.css('td').select{|t| t['class'] == "double_border title_time"}.map {|l| l.text.strip }
	zero = times.each_index.select {|i| times[i].match?(/^0/)}.last
	
	warnings = []
	table = html.css('table').select{|t| t['class'] == "WarnJikeiTable"}.first
	temp = ''
	table.css('tr')[3..-1].each do |l|
		x = l.css('td').select{|t| t['rowspan'] =~ /\d+/}
		y = l.css('td').select{|t| t['colspan'] =~ /\d+/}
		z = l.css('td').select{|t| not (t['colspan'] =~ /\d+/ or t['rowspan'] =~ /\d+/ or t['class'] =~ /\w+/)}
		
		if x == [] or x.length == 0
			x = temp
		else
			temp = x.first
			x = x.first
		end
		str = ''
		y.each {|z| str += z.text.strip.gsub(/（.+）/,'').gsub(/\(|\)/,'') + ' '}
		if not z.first.nil? and z.first.text.match(/[一-龠々]/)
			str += z.first.text + ' '
		end
		
		list = l.css('td').select{|t| (t['class'] =~ /jikei_/ and not t['class'] =~ /type/ and not t['class'] =~ /rmks/) or not t['class'] =~ /jikei_/ and t.text != "陸上" and t.text != "海上" and t['colspan'].nil? and t['rowspan'].nil?}
		remarks = l.css('td').select{|t| t['class'] =~ /jikei_/ and t['class'] =~ /rmks/}.map {|l| l.text.strip}
		warnings.push(:type => x.text.strip, :detail => str.strip, :times => list, :remarks => remarks.join(' '))
	end
	
	if warnings.length > 0
		hash = []
		warnings.each do |w|
			warning = []
			i = 0
			w[:times].each do |t|
				# puts t['class'].to_s
				if t['class'].to_s.sub('jikei_','').split(' ').length > 1
					warning.push(:class => t['class'].to_s.sub('jikei_','').split(' ').first, :type => t['class'].to_s.sub('jikei_','').split.last, :tag => t.text, :time => times[i])
				elsif t['class'].nil? and t.text != ""
					warning.push(:class => :data, :tag => t.text, :time => times[i])
				else
					warning.push(:class => t['class'].to_s.sub('jikei_','').split(' ').first, :tag => t.text, :time => times[i])
				end
				i += 1
			end
			hash.push(:warning => w[:type], :detail => w[:detail], :remarks => w[:remarks], :times => warning)
		end
		# puts hash.pretty_inspect
		today = []
		tomorrow = []
		hash.each_with_index do |w,i|
			str = w[:warning]
			if w[:detail] != ''
				str += " #{w[:detail]}"
			end
			if not w[:remarks].nil?
				str += "（#{NKF.nkf('-X -w', w[:remarks]).tr('０-９．', '0-9.')}）"
			else
				str += "　"
			end
			types = w[:times].select {|t| t[:class] != "none" and t[:class] != "white" and not t[:time].nil? and not t[:class].nil? }.map {|l| {:class => l[:class],:type => l[:type]} }.uniq
			# puts "types: #{types}"
			types.each do |type|
				# puts  w[:times].select {|t| t[:class] == type[:class]} 
				first = w[:times].select {|t| t[:class] == type[:class] and t[:type] == type[:type]}.first[:time]
				last = w[:times].select {|t| t[:class] == type[:class] and t[:type] == type[:type] and not t[:time].nil?}.last[:time]
				
				if type[:class] == "wrn"
					str += " 警報 "
				elsif type[:class] == "adv"
					str += " 注意 "
				end
				if type[:type] =~ /arw_([EWSN]+)/
					case $1
					when "E"
						str += "東"
					when "W"
						str += "西"
					when "S"
						str += "南"
					when "N"
						str += "北"
					when "NE"
						str += "東北"
					when "SE"
						str += "東南"
					when "NW"
						str += "西北"
					when "SW"
						str += "西南"
					end
					tags = w[:times].select {|t| t[:class] == type[:class]}.map {|l| l[:tag] }.uniq
					if tags.length > 1
						str += " #{tags.first}-#{tags.last} m/s "
					elsif tags.length > 0
						str += " #{tags.first} m/s "
					end
				elsif w[:warning] == "波浪"
					tags = w[:times].select {|t| t[:class] == type[:class]}.map {|l| l[:tag] }.uniq
					if tags.length > 1
						str += "#{tags.first}-#{tags.last} m "
					elsif tags.length > 0
						str += "#{tags.first} m "
					end
				elsif w[:warning] == "高潮"
					tags = w[:times].select {|t| t[:class] == type[:class]}.map {|l| l[:tag] }.uniq
					if tags.length > 1
						str += " #{tags.first}-#{tags.last} m "
					elsif tags.length > 0
						str += " #{tags.first} m "
					end
				elsif w[:detail] == "１時間最大雨量"
					tags = w[:times].select {|t| t[:class] == type[:class] and not t[:time].nil?}.map {|l| l[:tag] }.uniq.reject(&:empty?)
					if tags.length > 1
						str += " #{tags.first}-#{tags.last} mm "
					elsif tags.length > 0
						str += " #{tags.first} mm "
					end
				end
				
				if times.index(first) >= zero
					str += "#{first.split('-')[0]}-#{last.split('-')[1]}時 "
					tomorrow.push(str)
				elsif times.rindex(last) >= zero
					str += "今日#{first.split('-')[0]}時-明日#{last.split('-')[1]}時 "
					today.push(str)
				else
					str += "#{first.split('-')[0]}-#{last.split('-')[1]}時 "
					today.push(str)
				end
			end
		end
		return today,tomorrow
	else
		return nil
	end
end

## week

# date
# puts page.css('th')[i].text # [\d+曜]
# tomorrow 1 > 2,3,4,5,6,7

def weekdate
	[$week.css('th')[1].text.insert(-2, '日（').insert(-1, '）'), $week.css('th')[2].text.insert(-2, '日（').insert(-1, '）'), $week.css('th')[3].text.insert(-2, '日（').insert(-1, '）'), $week.css('th')[4].text.insert(-2, '日（').insert(-1, '）'), $week.css('th')[5].text.insert(-2, '日（').insert(-1, '）'), $week.css('th')[6].text.insert(-2, '日（').insert(-1, '）'), $week.css('th')[7].text.insert(-2, '日（').insert(-1, '）')]
end

# forecast
# puts week.css('td').select{|text| text['class'] == "for"}[i].text
# 0-6,28-34,56-62
# rain
# 7-13,35-41,63-69
# max ranges 17 \n (15～20)
# 14-20,42-48,70-76
# min
# 21-27,49-55,77-83

def weekicon
	case $weeksub
	when 0
		[$week.css('td').select{|text| text['class'] == "for"}[0].text, $week.css('td').select{|text| text['class'] == "for"}[1].text, $week.css('td').select{|text| text['class'] == "for"}[2].text, $week.css('td').select{|text| text['class'] == "for"}[3].text, $week.css('td').select{|text| text['class'] == "for"}[4].text, $week.css('td').select{|text| text['class'] == "for"}[5].text, $week.css('td').select{|text| text['class'] == "for"}[6].text]
	when 1
		[$week.css('td').select{|text| text['class'] == "for"}[28].text, $week.css('td').select{|text| text['class'] == "for"}[29].text, $week.css('td').select{|text| text['class'] == "for"}[30].text, $week.css('td').select{|text| text['class'] == "for"}[31].text, $week.css('td').select{|text| text['class'] == "for"}[32].text, $week.css('td').select{|text| text['class'] == "for"}[33].text, $week.css('td').select{|text| text['class'] == "for"}[34].text]
	when 2
		[$week.css('td').select{|text| text['class'] == "for"}[56].text, $week.css('td').select{|text| text['class'] == "for"}[57].text, $week.css('td').select{|text| text['class'] == "for"}[58].text, $week.css('td').select{|text| text['class'] == "for"}[59].text, $week.css('td').select{|text| text['class'] == "for"}[60].text, $week.css('td').select{|text| text['class'] == "for"}[61].text, $week.css('td').select{|text| text['class'] == "for"}[62].text]
	end
end

def weekrain
	case $weeksub
	when 0
		[$week.css('td').select{|text| text['class'] == "for"}[7].text, $week.css('td').select{|text| text['class'] == "for"}[8].text, $week.css('td').select{|text| text['class'] == "for"}[9].text, $week.css('td').select{|text| text['class'] == "for"}[10].text, $week.css('td').select{|text| text['class'] == "for"}[11].text, $week.css('td').select{|text| text['class'] == "for"}[12].text, $week.css('td').select{|text| text['class'] == "for"}[13].text]
	when 1
		[$week.css('td').select{|text| text['class'] == "for"}[35].text, $week.css('td').select{|text| text['class'] == "for"}[36].text, $week.css('td').select{|text| text['class'] == "for"}[37].text, $week.css('td').select{|text| text['class'] == "for"}[38].text, $week.css('td').select{|text| text['class'] == "for"}[39].text, $week.css('td').select{|text| text['class'] == "for"}[40].text, $week.css('td').select{|text| text['class'] == "for"}[41].text]
	when 2
		[$week.css('td').select{|text| text['class'] == "for"}[63].text, $week.css('td').select{|text| text['class'] == "for"}[64].text, $week.css('td').select{|text| text['class'] == "for"}[65].text, $week.css('td').select{|text| text['class'] == "for"}[66].text, $week.css('td').select{|text| text['class'] == "for"}[67].text, $week.css('td').select{|text| text['class'] == "for"}[68].text, $week.css('td').select{|text| text['class'] == "for"}[69].text]
	end
end

def weekmax
	case $weeksub
	when 0
		[$week.css('td').select{|text| text['class'] == "for"}[14].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[15].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[16].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[17].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[18].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[19].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[20].text.gsub(/\s+/, ' ')]
	when 1
		[$week.css('td').select{|text| text['class'] == "for"}[42].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[43].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[44].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[45].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[46].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[47].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[48].text.gsub(/\s+/, ' ')]
	when 2
		[$week.css('td').select{|text| text['class'] == "for"}[70].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[71].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[72].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[73].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[74].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[75].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[76].text.gsub(/\s+/, ' ')]
	end
end

def weekmin
	case $weeksub
	when 0
		[$week.css('td').select{|text| text['class'] == "for"}[21].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[22].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[23].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[24].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[25].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[26].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[27].text.gsub(/\s+/, ' ')]
	when 1
		[$week.css('td').select{|text| text['class'] == "for"}[49].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[50].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[51].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[52].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[53].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[54].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[55].text.gsub(/\s+/, ' ')]
	when 2
		[$week.css('td').select{|text| text['class'] == "for"}[77].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[78].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[79].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[80].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[81].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[82].text.gsub(/\s+/, ' '), $week.css('td').select{|text| text['class'] == "for"}[83].text.gsub(/\s+/, ' ')]
	end
end

# 🌞🌝🌛🌜🌚🌕🌖🌗🌘🌑🌒🌓🌔🌙

def isnight
	if $dt > $sunset
		return true
	else
		return false
	end
end

def ifdarkmode
	if `/usr/bin/defaults read -g AppleInterfaceStyleSwitchesAutomatically 2> /dev/null`['1']
		if $dt < ($sunrise + 1.hours) or $dt > ($sunset - 1.hours)
			return true
		else
			return false
		end
	else
		return true
	end
end

def julian(year, month, day)
	a = (14 - month) / 12
	y = year + 4800- a
	m = (12 * a) - 3 + month
	return day + (153 *m + 2) / 5 + (365 * y) + y/4 - y/100 + y/400 - 32045
end

def moon(thedate)
	p = (julian(thedate.year, thedate.month, thedate.day) - julian(2000, 1, 6)) % 29.530588853

	if p < 1.84566
		return "🌑"  # new
	elsif p < 5.53699
		return "🌒"  # waxing crescent
	elsif p < 9.22831
		return "🌓"  # first quarter
	elsif p < 12.91963
		return "🌔"  # waxing gibbous
	elsif p < 16.61096
		return "🌕"  # full
	elsif p < 20.30228
		return "🌖"  # waning gibbous
	elsif p < 23.99361
		return "🌗"  # last quarter
	elsif p < 27.68493
		return "🌘"  # waning crescent
	else
		return "🌑"  # new
	end
end

def forecasticon(text)
	text.gsub!('のち', '後')
	text.gsub!('晴れ', '晴')
	text.gsub!('曇り', '曇')
	text.strip!
	case text
	when "晴"
		icon = "#{FINE}"
	when "晴時々曇"
		icon = "#{FINE} #{OCCASIONAL} #{CLOUDY}"
	when "晴一時曇"
		icon = "#{FINE} #{ONCE} #{CLOUDY}"
	when "晴時々雨"
		icon = "#{FINE} #{OCCASIONAL} #{RAIN}"
	when "晴一時雨"
		icon = "#{FINE} #{ONCE} #{RAIN}"
	when "晴時々雪"
		icon = "#{FINE} #{OCCASIONAL} #{SNOW}"
	when "晴一時雪"
		icon = "#{FINE} #{ONCE} #{SNOW}"
	when "晴後曇"
		icon = "#{FINE} #{THEN} #{CLOUDY}"
	when "晴後雨"
		icon = "#{FINE} #{THEN} #{RAIN}"
	when "晴後雪"
		icon = "#{FINE} #{THEN} #{SNOW}"
	when "曇"
		icon = "#{CLOUDY}"
	when "曇時々晴"
		icon = "#{CLOUDY} #{OCCASIONAL} #{FINE}"
	when "曇一時晴"
		icon = "#{CLOUDY} #{ONCE} #{FINE}"
	when "曇時々雨"
		icon = "#{CLOUDY} #{OCCASIONAL} #{RAIN}"
	when "曇一時雨"
		icon = "#{CLOUDY} #{ONCE} #{RAIN}"
	when "曇時々雪"
		icon = "#{CLOUDY} #{OCCASIONAL} #{SNOW}"
	when "曇一時雪"
		icon = "#{CLOUDY} #{ONCE} #{SNOW}"
	when "曇後晴"
		icon = "#{CLOUDY} #{THEN} #{FINE}"
	when "曇後雨"
		icon = "#{CLOUDY} #{THEN} #{RAIN}"
	when "曇後一時雨"
		icon = "#{CLOUDY} #{ONCE} #{RAIN}"
	when "曇後雪"
		icon = "#{CLOUDY} #{THEN} #{SNOW}"
	when "雨"
		icon = "#{RAIN}"
	when "雨時々晴"
		icon = "#{RAIN} #{OCCASIONAL} #{FINE}"
	when "雨一時晴"
		icon = "#{RAIN} #{ONCE} #{FINE}"
	when "雨時々曇"
		icon = "#{RAIN} #{OCCASIONAL} #{CLOUDY}"
	when "雨時々止む"
		icon = "#{RAIN} #{OCCASIONAL} #{CLOUDY}"
	when "雨一時曇"
		icon = "#{RAIN} #{ONCE} #{CLOUDY}"
	when "雨時々雪"
		icon = "#{RAIN} #{OCCASIONAL} #{SNOW}"
	when "雨一時雪"
		icon = "#{RAIN} #{ONCE} #{SNOW}"
	when "雨後晴"
		icon = "#{RAIN} #{THEN} #{FINE}"
	when "雨後曇"
		icon = "#{RAIN} #{THEN} #{CLOUDY}"
	when "雨後雪"
		icon = "#{RAIN} #{THEN} #{SNOW}"
	when "雪"
		icon = "#{SNOW}"
	when "雪時々晴"
		icon = "#{SNOW} #{OCCASIONAL} #{FINE}"
	when "雪一時晴"
		icon = "#{SNOW} #{ONCE} #{FINE}"
	when "雪時々曇"
		icon = "#{SNOW} #{OCCASIONAL} #{CLOUDY}"
	when "雪一時曇"
		icon = "#{SNOW} #{ONCE} #{CLOUDY}"
	when "雪時々雨"
		icon = "#{SNOW} #{OCCASIONAL} #{RAIN}"
	when "雪一時雨"
		icon = "#{SNOW} #{ONCE} #{RAIN}"
	when "雪後晴"
		icon = "#{SNOW} #{THEN} #{FINE}"
	when "雪後曇"
		icon = "#{SNOW} #{THEN} #{CLOUDY}"
	when "雪後雨"
		icon = "#{SNOW} #{THEN} #{RAIN}"
	else
		icon = "❓"
	end
end

def lightning(text)
	if text["雷"]
		return true
	else
		return false
	end
end

def strongrain(text)
	if text["強い雨"] or text["激しい雨"] or text["猛烈な雨"] or text["激しく　降る"]
		return true
	else
		return false
	end
end

def strongwind(text)
	if text["強い風"] | text["猛烈な風"]
		return true
	else
		return false
	end
end

def forecastdetailsicon(forecast,details,istoday)
	forecast.gsub!('のち', '後')
	forecast.gsub!('晴れ', '晴')
	forecast.gsub!('曇り', '曇')
	forecast.strip!
	case forecast
	when "晴"
		if istoday and isnight
			icon = moon($dt)
		else
			icon = "#{FINE}"
		end
	when "晴時々曇"
		if istoday and isnight
			icon = "#{moon($dt)} #{OCCASIONAL} #{CLOUDY}"
		else
			icon = "#{FINE} #{OCCASIONAL} #{CLOUDY}"
		end
	when "晴一時曇"
		icon = "#{FINE} #{ONCE} #{CLOUDY}"
	when "晴時々雨"
		if strongrain(details)
			if istoday and isnight
				icon = "#{moon($dt)} #{OCCASIONAL} #{HEAVYRAIN}"
			else
				icon = "#{FINE} #{OCCASIONAL} #{HEAVYRAIN}"
			end
		elsif lightning(details)
			if istoday and isnight
				icon = "#{moon($dt)} #{OCCASIONAL} #{LIGHTNING}"
			else
				icon = "#{FINE} #{OCCASIONAL} #{LIGHTNING}"
			end
 		else
			if istoday and isnight
				icon = "#{moon($dt)} #{OCCASIONAL} #{RAIN}"
			else
				icon = "#{FINE} #{OCCASIONAL} #{RAIN}"
			end
		end
	when "晴一時雨"
		if strongrain(details)
			if istoday and isnight
				icon = "#{moon($dt)} #{ONCE} #{HEAVYRAIN}"
			else
				icon = "#{FINE} #{ONCE} #{HEAVYRAIN}"
			end
		elsif lightning(details)
			if istoday and isnight
				icon = "#{moon($dt)} #{ONCE} #{LIGHTNING}"
			else
				icon = "#{FINE} #{ONCE} #{LIGHTNING}"
			end
 		else
			if istoday and isnight
				icon = "#{moon($dt)} #{ONCE} #{RAIN}"
			else
				icon = "#{FINE} #{ONCE} #{RAIN}"
			end
		end
	when "晴時々雪"
		if istoday and isnight
			icon = "#{moon($dt)} #{OCCASIONAL} #{SNOW}"
		else
			icon = "#{FINE} #{OCCASIONAL} #{SNOW}"
		end
	when "晴一時雪"
		if istoday and isnight
			icon = "#{moon($dt)} #{ONCE} #{SNOW}"
		else
			icon = "#{FINE} #{ONCE} #{SNOW}"
		end
	when "晴後曇"
		if istoday and isnight
			icon = "#{moon($dt)} #{THEN} #{CLOUDY}"
		else
			icon = "#{FINE} #{THEN} #{CLOUDY}"
		end
	when "晴後時々曇"
		icon = "#{FINE} #{THEN} #{FINECLOUD}"
	when "晴後雨"
		if strongrain(details)
			if istoday and isnight
				icon = "#{moon($dt)} #{THEN} #{HEAVYRAIN}"
			else
				icon = "#{FINE} #{THEN} #{HEAVYRAIN}"
			end
		elsif lightning(details)
			if istoday and isnight
				icon = "#{moon($dt)} #{THEN} #{LIGHTNING}"
			else
				icon = "#{FINE} #{THEN} #{LIGHTNING}"
			end
 		else
			if istoday and isnight
				icon = "#{moon($dt)} #{THEN} #{RAIN}"
			else
				icon = "#{FINE} #{THEN} #{RAIN}"
			end
		end
	when "晴後雪"
		if istoday and isnight
			icon = "#{moon($dt)} #{THEN} #{SNOW}"
		else
			icon = "#{FINE} #{THEN} #{SNOW}"
		end
	when "曇"
		icon = "#{CLOUDY}"
	when "曇時々晴"
		if istoday and isnight
			icon = "#{CLOUDY} #{OCCASIONAL} #{moon($dt)}"
		else
			icon = "#{CLOUDY} #{OCCASIONAL} #{FINE}"
		end
	when "曇後時々晴"
		icon = "#{CLOUDY} #{THEN} #{CLOUDFINE}"
	when "曇一時晴"
		if istoday and isnight
			icon = "#{CLOUDY} #{ONCE} #{moon($dt)}"
		else
			icon = "#{CLOUDY} #{ONCE} #{FINE}"
		end
	when "曇時々雨"
		if strongrain(details)
			icon = "#{CLOUDY} #{OCCASIONAL} #{HEAVYRAIN}"
		elsif lightning(details)
			icon = "#{CLOUDY} #{OCCASIONAL} #{LIGHTNING}"
 		else
			icon = "#{CLOUDY} #{OCCASIONAL} #{RAIN}"
		end
	when "曇一時雨"
		if strongrain(details)
			icon = "#{CLOUDY} #{ONCE} #{HEAVYRAIN}"
		elsif lightning(details)
			icon = "#{CLOUDY} #{ONCE} #{LIGHTNING}"
 		else
			icon = "#{CLOUDY} #{ONCE} #{RAIN}"
		end
	when "曇時々雪"
		icon = "#{CLOUDY} #{OCCASIONAL} #{SNOW}"
	when "曇一時雪"
		icon = "#{CLOUDY} #{ONCE} #{SNOW}"
	when "曇後晴"
		if istoday and isnight
			icon = "#{CLOUDY} #{THEN} #{moon($dt)}"
		else
			icon = "#{CLOUDY} #{THEN} #{FINE}"
		end
	when "曇後雨"
		if strongrain(details)
			icon = "#{CLOUDY} #{THEN} #{HEAVYRAIN}"
		elsif lightning(details)
			icon = "#{CLOUDY} #{THEN} #{LIGHTNING}"
 		else
			icon = "#{CLOUDY} #{THEN} #{RAIN}"
		end
	when "曇後時々雨"
		if strongrain(details)
			icon = "#{CLOUDY} #{OCCASIONAL} #{HEAVYRAIN}"
		elsif lightning(details)
			icon = "#{CLOUDY} #{OCCASIONAL} #{LIGHTNING}"
 		else
			icon = "#{CLOUDY} #{OCCASIONAL} #{RAIN}"
		end
	when "曇後一時雨"
		if strongrain(details)
			icon = "#{CLOUDY} #{ONCE} #{HEAVYRAIN}"
		elsif lightning(details)
			icon = "#{CLOUDY} #{ONCE} #{LIGHTNING}"
 		else
			icon = "#{CLOUDY} #{ONCE} #{RAIN}"
		end
	when "曇後雪"
		icon = "#{CLOUDY} #{THEN} #{SNOW}"
	when "雨"
		if strongrain(details)
			icon = "#{HEAVYRAIN}"
		elsif lightning(details)
			icon = "#{LIGHTNING}"
		else
			icon = "#{RAIN}"
		end
	when "雨時々晴"
		if strongrain(details)
			if istoday and isnight
				icon = "#{HEAVYRAIN} #{OCCASIONAL} #{moon($dt)}"
			else
				icon = "#{HEAVYRAIN} #{OCCASIONAL} #{FINE}"
			end
		elsif lightning(details)
			if istoday and isnight
				icon = "#{LIGHTNING} #{OCCASIONAL} #{moon($dt)}"
			else
				icon = "#{LIGHTNING} #{OCCASIONAL} #{FINE}"
			end
		else
			if istoday and isnight
				icon = "#{RAIN} #{OCCASIONAL} #{moon($dt)}"
			else
				icon = "#{RAIN} #{OCCASIONAL} #{FINE}"
			end
		end
	when "雨一時晴"
		if strongrain(details)
			if istoday and isnight
				icon = "#{HEAVYRAIN} #{ONCE} #{moon($dt)}"
			else
				icon = "#{HEAVYRAIN} #{ONCE} #{FINE}"
			end
		elsif lightning(details)
			if istoday and isnight
				icon = "#{LIGHTNING} #{ONCE} #{moon($dt)}"
			else
				icon = "#{LIGHTNING} #{ONCE} #{FINE}"
			end
		else
			if istoday and isnight
				icon = "#{RAIN} #{ONCE} #{moon($dt)}"
			else
				icon = "#{RAIN} #{ONCE} #{FINE}"
			end
		end
	when "雨時々曇"
		if strongrain(details)
			icon = "#{HEAVYRAIN} #{OCCASIONAL} #{CLOUDY}"
		elsif lightning(details)
			icon = "#{LIGHTNING} #{OCCASIONAL} #{CLOUDY}"
		else
			icon = "#{RAIN} #{OCCASIONAL} #{CLOUDY}"
		end
	when "雨時々止む"
		if strongrain(details)
			icon = "#{HEAVYRAIN} #{OCCASIONAL} #{CLOUDY}"
		elsif lightning(details)
			icon = "#{LIGHTNING} #{OCCASIONAL} #{CLOUDY}"
		else
			icon = "#{RAIN} #{OCCASIONAL} #{CLOUDY}"
		end
	when "雨一時曇"
		if strongrain(details)
			icon = "#{HEAVYRAIN} #{ONCE} #{CLOUDY}"
		elsif lightning(details)
			icon = "#{LIGHTNING} #{ONCE} #{CLOUDY}"
		else
			icon = "#{RAIN} #{ONCE} #{CLOUDY}"
		end
	when "雨時々雪"
		if strongrain(details)
			icon = "#{HEAVYRAIN} #{OCCASIONAL} #{SNOW}"
		elsif lightning(details)
			icon = "#{LIGHTNING} #{OCCASIONAL} #{SNOW}"
		else
			icon = "#{RAIN} #{OCCASIONAL} #{SNOW}"
		end
	when "雨一時雪"
		if strongrain(details)
			icon = "#{HEAVYRAIN} #{ONCE} #{SNOW}"
		elsif lightning(details)
			icon = "#{LIGHTNING} #{ONCE} #{SNOW}"
		else
			icon = "#{RAIN} #{ONCE} #{SNOW}"
		end
	when "雨後晴"
		if strongrain(details)
			if istoday and isnight
				icon = "#{HEAVYRAIN} #{THEN} #{moon($dt)}"
			else
				icon = "#{HEAVYRAIN} #{THEN} #{FINE}"
			end
		elsif lightning(details)
			if istoday and isnight
				icon = "#{LIGHTNING} #{THEN} #{moon($dt)}"
			else
				icon = "#{LIGHTNING} #{THEN} #{FINE}"
			end
		else
			if istoday and isnight
				icon = "#{RAIN} #{THEN} #{moon($dt)}"
			else
				icon = "#{RAIN} #{THEN} #{FINE}"
			end
		end
	when "雨後曇"
		if strongrain(details)
			icon = "#{HEAVYRAIN} #{THEN} #{CLOUDY}"
		elsif lightning(details)
			icon = "#{LIGHTNING} #{THEN} #{CLOUDY}"
		else
			icon = "#{RAIN} #{THEN} #{CLOUDY}"
		end
	when "雨後雪"
		if strongrain(details)
			icon = "#{HEAVYRAIN} #{THEN} #{SNOW}"
		elsif lightning(details)
			icon = "#{LIGHTNING} #{THEN} #{SNOW}"
		else
			icon = "#{RAIN} #{THEN} #{SNOW}"
		end
	when "雪"
		icon = "#{SNOW}"
	when "雪時々晴"
		icon = "#{SNOW} #{OCCASIONAL} #{FINE}"
	when "雪一時晴"
		icon = "#{SNOW} #{ONCE} #{FINE}"
	when "雪時々曇"
		icon = "#{SNOW} #{OCCASIONAL} #{CLOUDY}"
	when "雪一時曇"
		icon = "#{SNOW} #{ONCE} #{CLOUDY}"
	when "雪時々雨"
		if strongrain(details)
			icon = "#{SNOW} #{OCCASIONAL} #{HEAVYRAIN}"
		elsif lightning(details)
			icon = "#{SNOW} #{OCCASIONAL} #{LIGHTNING}"
		else
			icon = "#{SNOW} #{OCCASIONAL} #{RAIN}"
		end
	when "雪一時雨"
		if strongrain(details)
			icon = "#{SNOW} #{ONCE} #{HEAVYRAIN}"
		elsif lightning(details)
			icon = "#{SNOW} #{ONCE} #{LIGHTNING}"
		else
			icon = "#{SNOW} #{ONCE} #{RAIN}"
		end
	when "雪後晴"
		if istoday and isnight
			icon = "#{SNOW} #{THEN} #{moon($dt)}"
		else
			icon = "#{SNOW} #{THEN} #{FINE}"
		end
	when "雪後曇"
		icon = "#{SNOW} #{THEN} #{CLOUDY}"
	when "雪後雨"
		if strongrain(details)
			icon = "#{SNOW} #{THEN} #{HEAVYRAIN}"
		elsif lightning(details)
			icon = "#{SNOW} #{THEN} #{LIGHTNING}"
		else
			icon = "#{SNOW} #{ONCE} #{RAIN}"
		end
	else
		icon = "❓"
	end
	if strongwind(details)
		icon.concat("・#{WIND}")
	end
	return icon
end

def darkskyicon(text)
	case text
	when "clear-day"
		icon = "☀️"
	when "clear-night"
		# icon = "🌙"
		icon = moon($dt)
	when "rain"
		icon = "☔️"
	when "snow"
		icon = "❄️"
	when "sleet"
		icon = "💦"
	when "wind"
		icon = "💨"
	when "fog"
		icon = "🌫"
	when "cloudy"
		icon = "☁️"
	when "partly-cloudy-day"
		icon = "⛅️"
	when "partly-cloudy-night"
		icon = "⛅️"
	end
end

def formatyoho(text)
	text.gsub!(/くもり/, '曇り')
	text.gsub!(/波/, '\n\0')
	text.gsub!(/ただし/, '\n\0')
	text.gsub!(/所により/, '\n\0')
	text.gsub!(/(所により)(.+)(から)[　]{,1}/, '\1\2\3\n')
	text.gsub!(/([[:word:]]+?)[　]{1}では/, '\n\1　では')
	# text.gsub!(/２３区/, '\n\0')
	text.gsub!(/(風)([^晴曇雨雪]{,10})([晴曇雨雪]{1})/, '\1\2\n\3')
	text.gsub!('メートル',' m/s')
	text.gsub!(/^　+/, "")
	text.gsub!(/\\n/, "\n")
	text.gsub!(/\n^　+$\n/, "\n")
	text.gsub!(/\n\n/, "\n")
	text = NKF.nkf('-X -w', text).tr('０-９．', '0-9.')
end

def formatweekrain(text)
	a = text.split('/').map do |e|
		if e == '-'
			' '
		else
			e.concat('%')
		end
	end
end

def formatweektemp(text) # only [>=2]
	[text[/^(\d+)/],text[/(\(\d+)～/],text[/(\d+)\)/]]
end

def winddirconv(degree)
	cardinals = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW']
	dir = ((degree * 16) / 360).round(0)
	cardinals[dir]
end

def adjustpadding(string)
	text = Magick::Draw.new
	text.font = "Menlo"
	text.text_antialias(true)
	text.font_style=Magick::NormalStyle
	text.font_weight=Magick::NormalWeight
	text.gravity=Magick::CenterGravity
	width = text.get_type_metrics(string).width
	if width < 7
		return 1
	elsif width > 18
		return -1
	else
		return 0
	end
end

def adjustspacing(string, length)
	text = Magick::Draw.new
	text.font = "Menlo"
	text.text_antialias(true)
	text.font_style=Magick::NormalStyle
	text.font_weight=Magick::NormalWeight
	text.gravity=Magick::CenterGravity
	width = text.get_type_metrics(string).width
	if width < 7
		adjust = 1
	elsif width > 18
		adjust = 1
	else
		adjust = 0
	end
	padding = ''
	i = 0
	while i < (length + adjust)
		padding += ' '
		i += 1
	end
	return padding
end

begin
	radar = URI.open("https://www.jma.go.jp/jp/radnowc/imgs/radar/#{$region}/#{$d}#{$tr}-00.png").read
	r64 = "| refresh=true image=#{Base64.encode64(radar).gsub(/\n/, '')}"
rescue
	r64 = '⚠️'
end

begin
	u = "http://www.jma.go.jp/jp/#{$satfreq}/imgs/0/#{$sattype}/1/#{$d}#{$ts}-00.png"
	if Faraday.head(u).status != 200
		u = "http://www.jma.go.jp/jp/#{$satfreq}/imgs/0/infrared/1/#{$d}#{$ts}-00.png"
	end
	satellite = URI.open(u).read
	s64 = "| refresh=true image=#{Base64.encode64(satellite).gsub(/\n/, '')}"
rescue
	s64 = '⚠️'
end

rain = Nokogiri::HTML(open("http://www.jma.go.jp/jp/amedas_h/today-#{$local}.html"))

rainfall = 0
rain.css('td').select{|text| text['class'] == "block middle"}[0..$h-1].each do |line|
	rainfall += line.text.to_f end


if ifdarkmode
	$textcolor = 'lightgray'
	$advcolor = 'yellow'
	$wrncolor = 'orange'
	$textansi = '37'
	$rainansi = '36'
else
	$textcolor = 'darkslategray'
	$advcolor = 'orange red'
	$wrncolor = 'red'
	$textansi = '39' # 30 too dark, 39 too light
	$rainansi = '1;36'
end

### warning

if gaikyo.match?(/注意|警報/)
	warningtoday,warningtomorrow = warning(Nokogiri::HTML(open("http://www.jma.go.jp/jp/warn/f_#{$warnlocal}.html")))
	
else
	warningtoday = warningtomorrow = nil
end
###

darksky = JSON.parse(URI.open("https://api.darksky.net/forecast/#{$darkskyapi}/#{$latlon}?units=si").read)

temp = darksky['currently']['temperature'].to_f.round(1)
apptemp = darksky['currently']['apparentTemperature'].to_f.round(1)
dewpoint = darksky['currently']['dewPoint'].to_f.round(1)
humidity = (darksky['currently']['humidity'].to_f * 100).round(0) # %
pressure = darksky['currently']['pressure'] # hectopascal
windspeed = darksky['currently']['windSpeed'].to_f.round(1) # m/s
gust = darksky['currently']['windGust'].to_f.round(1) # m/s
winddir = darksky['currently']['windBearing'].to_i # deg
uv = darksky['currently']['uvIndex']
precip = darksky['currently']['precipIntensity'].to_f.round(1) # mm/h
precipprob = darksky['currently']['precipProbability'].to_f.round(1)
clouds = (darksky['currently']['cloudCover'] * 100).round(0) # %
visibility = darksky['currently']['visibility'].to_f.round(0) # km
icon = darksky['currently']['icon']

######

puts "#{darkskyicon(icon)} #{temp}°"
puts "---"
puts "#{$place} | color=lightslategray"
puts "---"
puts "温  #{temp}° (#{apptemp}°) | color=#{$textcolor}"
puts "湿  #{humidity}% (#{dewpoint}°) | color=#{$textcolor}"
puts "圧  #{pressure} hPa | color=#{$textcolor}"
puts "風  #{windspeed} m/s (#{gust} m/s) #{winddirconv(winddir)} | color=#{$textcolor}"
puts "雲  #{clouds}% | color=#{$textcolor}"
puts "雨  #{precip} mm/h (#{precipprob} mm/h) #{rainfall if rainfall > 0} #{'mm' if rainfall > 0} | color=#{$textcolor}"
puts "視  #{visibility} km | color=#{$textcolor}"
puts "紫  #{uv} | color=#{$textcolor}"

# image forecast icon
# puts "---"
# puts "#{yohodate[0]} | color=#{$textcolor}"
# formatyoho(yohotext[0]).each_line do |line|
# 	puts "--#{line.strip} | color=#{$textcolor}"
# end
# puts "#{yohorain[0]} #{yohorain[1]} #{yohorain[2]} #{yohorain[3]} | color=#{$textcolor} | #{forecasticon(yohoicon[0])}"
# puts "#{yohodate[1]} | color=#{$textcolor}"
# formatyoho(yohotext[1]).each_line do |line|
# 	puts "--#{line.strip} | color=#{$textcolor}"
# end
# puts "#{yohorain[4]} #{yohorain[5]} #{yohorain[6]} #{yohorain[7]} | color=#{$textcolor} | #{forecasticon(yohoicon[1])}"
# puts "#{yohodate[2]} | color=#{$textcolor}"

if weekdate[0].include? $today
	w = 2
else
	w = 1
end

puts "---"

# today
if warningtoday != []
	if warningtoday.any? {|line| line.match("警報")}
		puts "#{yohodate[0]} | color=#{$wrncolor}"
	else
		puts "#{yohodate[0]} | color=#{$advcolor}"
	end
	formatyoho(yohotext[0]).each_line do |line|
		puts "--#{line.strip} | color=#{$textcolor}"
	end
	warningtoday.each do |line|
		if line.match("警報")
			puts "--#{line.strip} | color=#{$wrncolor}"
		else
			puts "--#{line.strip} | color=#{$advcolor}"
		end
	end
else
	puts "#{yohodate[0]} | color=#{$textcolor}"
	formatyoho(yohotext[0]).each_line do |line|
		puts "--#{line.strip} | color=#{$textcolor}"
	end
end

if $t.hour >= 18
	puts "\033[#{$textansi}m#{forecastdetailsicon(yohoicon[0],yohotext[0],true).center(ICONLENGTH+adjustpadding(forecastdetailsicon(yohoicon[0],yohotext[0],true)))}#{adjustspacing(forecastdetailsicon(yohoicon[0],yohotext[0],true),1)}\033[34m#{" ".rjust(4)}\033[31m#{" ".rjust(5)}   \033[#{$rainansi}m#{yohorain[0].rjust(3)} #{yohorain[1].rjust(3)} #{yohorain[2].rjust(3)} #{yohorain[3].rjust(3)} | color=#{$textcolor} font=Menlo ansi=true"
else
	puts "\033[#{$textansi}m#{forecastdetailsicon(yohoicon[0],yohotext[0],true).center(ICONLENGTH+adjustpadding(forecastdetailsicon(yohoicon[0],yohotext[0],true)))}#{adjustspacing(forecastdetailsicon(yohoicon[0],yohotext[0],true),1)}\033[34m#{yohotemp[0].rjust(4)}\033[31m#{yohotemp[1].rjust(5)}   \033[#{$rainansi}m#{yohorain[0].rjust(3)} #{yohorain[1].rjust(3)} #{yohorain[2].rjust(3)} #{yohorain[3].rjust(3)} | color=#{$textcolor} font=Menlo ansi=true"
end

# tomorrow
if warningtomorrow != []
	if warningtomorrow.any? {|line| line.match("警報")}
		puts "#{yohodate[0]} | color=#{$wrncolor}"
	else
		puts "#{yohodate[0]} | color=#{$advcolor}"
	end
	formatyoho(yohotext[1]).each_line do |line|
		puts "--#{line.strip} | color=#{$textcolor} ansi=true"
	end
	warningtomorrow.each do |line|
		if line.match("警報")
			puts "--#{line.strip} | color=#{$wrncolor}"
		else
			puts "--#{line.strip} | color=#{$advcolor}"
		end
	end
else
	puts "#{yohodate[1]} | color=#{$textcolor}"
	formatyoho(yohotext[1]).each_line do |line|
		puts "--#{line.strip} | color=#{$textcolor} ansi=true"
	end
end
if $t.hour >= 18
	puts "\033[#{$textansi}m#{forecastdetailsicon(yohoicon[1],yohotext[1],false).center(ICONLENGTH+adjustpadding(forecastdetailsicon(yohoicon[1],yohotext[1],false)))}#{adjustspacing(forecastdetailsicon(yohoicon[1],yohotext[1],true),1)}\033[34m#{yohotemp[0].rjust(4)}\033[31m#{yohotemp[1].rjust(5)}   \033[#{$rainansi}m#{yohorain[4].rjust(3)} #{yohorain[5].rjust(3)} #{yohorain[6].rjust(3)} #{yohorain[7].rjust(3)} | color=#{$textcolor} font=Menlo ansi=true"
else
	puts "\033[#{$textansi}m#{forecastdetailsicon(yohoicon[1],yohotext[1],false).center(ICONLENGTH+adjustpadding(forecastdetailsicon(yohoicon[1],yohotext[1],false)))}#{adjustspacing(forecastdetailsicon(yohoicon[1],yohotext[1],true),1)}\033[34m#{yohotemp[2].rjust(4)}\033[31m#{yohotemp[3].rjust(5)}   \033[#{$rainansi}m#{yohorain[4].rjust(3)} #{yohorain[5].rjust(3)} #{yohorain[6].rjust(3)} #{yohorain[7].rjust(3)} | color=#{$textcolor} font=Menlo ansi=true"
end

while w < 7
	puts "#{weekdate[w]} | color=#{$textcolor}"
	if w == 1
		formatyoho(yohotext[2]).each_line do |line|
			puts "--#{line.strip} | color=#{$textcolor} ansi=true"
		end
	end
	puts "\033[#{$textansi}m#{forecasticon(weekicon[w]).center(ICONLENGTH+adjustpadding(forecasticon(weekicon[w])))}#{adjustspacing(forecasticon(weekicon[w]),2)}\033[34m#{formatweektemp(weekmin[w])[0].rjust(2)} #{formatweektemp(weekmin[w])[1].rjust(4)}#{formatweektemp(weekmin[w])[2].rjust(3)} \033[31m#{formatweektemp(weekmax[w])[0].rjust(2)} #{formatweektemp(weekmax[w])[1].rjust(4)}#{formatweektemp(weekmax[w])[2].rjust(3)} \033[#{$rainansi}m#{weekrain[w].rjust(3)} | color=#{$textcolor} font=Menlo ansi=true"
	w += 1
end

puts "---"
puts "天気概況 | ansi=false color=#{$textcolor}"
gaikyo.each_line do |line|
	puts "--#{line.strip} | color=#{$textcolor} ansi=true"
end
puts "レーダー | ansi=false color=#{$textcolor}"
puts "--#{r64}"
puts "衛星 | color=#{$textcolor}"
puts "--#{s64}"
if $dt.month > 7 and $dt.month < 11
	puts "台風情報 | ansi=false color=#{$textcolor}"
	typhoonout = typhooninfo
	if typhoonout.match?(/\d/)
		puts "--#{typhoonimg}"
		puts typhooninfo
	end
end
puts "---"

puts "---"
puts "更新 | refresh=true ansi=false color=green"
puts "気象庁…|href=http://www.jma.go.jp/jp/yoho/#{$area}.html ansi=false color=lightslategray"
