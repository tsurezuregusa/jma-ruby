#!/usr/bin/env ruby

# <bitbar.title>Japan Weather</bitbar.title>
# <bitbar.version>0.6</bitbar.version>
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
require 'active_support'
require 'active_support/core_ext/numeric'
require 'nokogiri'
require 'rmagick'

$darkskyapi = 'x'
$latlon = '35.6895,139.6917'
$place = '東京'

# $openweatherapi = 'x'
$openweatherloc = '1850147'
$visualcrossingapi = 'x'
$climacellapi = 'x'

$pref = '130000' # 東京都
$subarea = '1311300' # 渋谷区
$area = '130010'
$quakearea = '1310100' # 千代田区
# http://www.jma.go.jp/jp/amedas/000.html
$amedas = '44132'
# http://www.jma.go.jp/jp/warn/
$local = '1311300'

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
$dymd = $dt.strftime("%Y%m%d")
$dy = $dt.strftime("%j").to_i
$dw = Time.now.strftime("%-d")
$d0 = Time.parse("#{$dymd} 00:00:00 +0900")
$d24 = $d0 + 24.hours
$d48 = $d0 + 48.hours
$dtame = "#{($dt-20.minutes).floor(10.minutes).strftime('%Y%m%d')}_#{($dt-20.minutes).floor(3.hours).strftime('%H')}"
$dh = ($dt-6.minutes).strftime("%H").to_i
$dtr = $dt.utc.floor(5.minutes).strftime("%Y%m%d%H%M")
$dts = ($dt.utc-8.minutes).floor(10.minutes).strftime("%Y%m%d%H%M")

begin
	$koyomi = Nokogiri::HTML(URI.open("http://eco.mtk.nao.ac.jp/cgi-bin/koyomi/sunmoon.cgi"))
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
rescue
	$koyomi = Nokogiri::HTML(URI.open("http://www.hinode-hinoiri.com/131130.html"))
	$sunrise = Time.parse($koyomi.css('td').select{|text| text['table_line'] != 'left'}[1].text.sub('時',':').sub('分','').strip)
	$sunset = Time.parse($koyomi.css('td').select{|text| text['table_line'] != 'left'}[3].text.sub('時',':').sub('分','').strip)
	# TODO moonrise/set
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
FOG = '🌫'

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

FINECLOUD = '🌤'
CLOUDFINE = '⛅️'
MOSTCLOUD = '🌥'
LIGHTNING = '⚡️'
LIGHTNINGRAIN = '⛈'
WIND = '💨'
ICE = '🧊'
UNKNOWN = '❓'

ICONLENGTH = 7.5

WEEK = {
	"1" => "月",
	"2" => "火",
	"3" => "水",
	"4" => "木",
	"5" => "金",
	"6" => "土",
	"7" => "日"
}

WEATHERCODE = {
	100 => "晴",
	101 => "晴時々曇",
	102 => "晴一時雨",
	103 => "晴時々雨",
	104 => "晴一時雪",
	105 => "晴時々雪",
	106 => "晴一時雨か雪",
	107 => "晴時々雨か雪",
	108 => "晴一時雨か雷雨",
	110 => "晴後時々曇",
	111 => "晴後曇",
	112 => "晴後一時雨",
	113 => "晴後時々雨",
	114 => "晴後雨",
	115 => "晴後一時雪",
	116 => "晴後時々雪",
	117 => "晴後雪",
	118 => "晴後雨か雪",
	119 => "晴後雨か雷雨",
	120 => "晴朝夕一時雨",
	121 => "晴朝の内一時雨",
	122 => "晴夕方一時雨",
	123 => "晴山沿い雷雨",
	124 => "晴山沿い雪",
	125 => "晴午後は雷雨",
	126 => "晴昼頃から雨",
	127 => "晴夕方から雨",
	128 => "晴夜は雨",
	130 => "朝の内霧後晴",
	131 => "晴明け方霧",
	132 => "晴朝夕曇",
	140 => "晴時々雨で雷を伴う",
	160 => "晴一時雪か雨",
	170 => "晴時々雪か雨",
	181 => "晴後雪か雨",
	200 => "曇",
	201 => "曇時々晴",
	202 => "曇一時雨",
	203 => "曇時々雨",
	204 => "曇一時雪",
	205 => "曇時々雪",
	206 => "曇一時雨か雪",
	207 => "曇時々雨か雪",
	208 => "曇一時雨か雷雨",
	209 => "霧",
	210 => "曇後時々晴",
	211 => "曇後晴",
	212 => "曇後一時雨",
	213 => "曇後時々雨",
	214 => "曇後雨",
	215 => "曇後一時雪",
	216 => "曇後時々雪",
	217 => "曇後雪",
	218 => "曇後雨か雪",
	219 => "曇後雨か雷雨",
	220 => "曇朝夕一時雨",
	221 => "曇朝の内一時雨",
	222 => "曇夕方一時雨",
	223 => "曇日中時々晴",
	224 => "曇昼頃から雨",
	225 => "曇夕方から雨",
	226 => "曇夜は雨",
	228 => "曇昼頃から雪",
	229 => "曇夕方から雪",
	230 => "曇夜は雪",
	231 => "曇海上海岸は霧か霧雨",
	240 => "曇時々雨で雷を伴う",
	250 => "曇時々雪で雷を伴う",
	260 => "曇一時雪か雨",
	270 => "曇時々雪か雨",
	281 => "曇後雪か雨",
	300 => "雨",
	301 => "雨時々晴",
	302 => "雨時々止む",
	303 => "雨時々雪",
	304 => "雨か雪",
	306 => "大雨",
	308 => "雨で暴風を伴う",
	309 => "雨一時雪",
	311 => "雨後晴",
	313 => "雨後曇",
	314 => "雨後時々雪",
	315 => "雨後雪",
	316 => "雨か雪後晴",
	317 => "雨か雪後曇",
	320 => "朝の内雨後晴",
	321 => "朝の内雨後曇",
	322 => "雨朝晩一時雪",
	323 => "雨昼頃から晴",
	324 => "雨夕方から晴",
	325 => "雨夜は晴",
	326 => "雨夕方から雪",
	327 => "雨夜は雪",
	328 => "雨一時強く降る",
	329 => "雨一時霙",
	340 => "雪か雨",
	350 => "雨で雷を伴う",
	361 => "雪か雨後晴",
	371 => "雪か雨後曇",
	400 => "雪",
	401 => "雪時々晴",
	402 => "雪時々止む",
	403 => "雪時々雨",
	405 => "大雪",
	406 => "風雪強い",
	407 => "暴風雪",
	409 => "雪一時雨",
	411 => "雪後晴",
	413 => "雪後曇",
	414 => "雪後雨",
	420 => "朝の内雪後晴",
	421 => "朝の内雪後曇",
	422 => "雪昼頃から雨",
	423 => "雪夕方から雨",
	425 => "雪一時強く降る",
	426 => "雪後霙",
	427 => "雪一時霙",
	450 => "雪で雷を伴う"
}

WARNINGCODE = {
	"02" => {:name => "暴風雪", :type => "警報"},
	"03" => {:name => "大雨", :type => "警報"},
	"04" => {:name => "洪水", :type => "警報"},
	"05" => {:name => "暴風", :type => "警報"},
	"06" => {:name => "大雪", :type => "警報"},
	"07" => {:name => "波浪", :type => "警報"},
	"08" => {:name => "高潮", :type => "警報"},
	"10" => {:name => "大雨", :type => "注意報"},
	"12" => {:name => "大雪", :type => "注意報"},
	"13" => {:name => "風雪", :type => "注意報"},
	"14" => {:name => "雷", :type => "注意報"},
	"15" => {:name => "強風", :type => "注意報"},
	"16" => {:name => "波浪", :type => "注意報"},
	"17" => {:name => "融雪", :type => "注意報"},
	"18" => {:name => "洪水", :type => "注意報"},
	"19" => {:name => "高潮", :type => "注意報"},
	"20" => {:name => "濃霧", :type => "注意報"},
	"21" => {:name => "乾燥", :type => "注意報"},
	"22" => {:name => "雪崩", :type => "注意報"},
	"23" => {:name => "低温", :type => "注意報"},
	"24" => {:name => "霜", :type => "注意報"},
	"25" => {:name => "着氷", :type => "注意報"},
	"26" => {:name => "着雪", :type => "注意報"},
	"32" => {:name => "暴風雪", :type => "特別警報"},
	"33" => {:name => "大雨", :type => "特別警報"},
	"35" => {:name => "暴風", :type => "特別警報"},
	"36" => {:name => "大雪", :type => "特別警報"},
	"37" => {:name => "波浪", :type => "特別警報"},
	"38" => {:name => "高潮", :type => "特別警報"}
}

$forecast = JSON.parse(URI.open("https://www.jma.go.jp/bosai/forecast/data/forecast/#{$pref}.json").read)

def forecastdays
	fcarea = $forecast.first['timeSeries'][0]['areas'].select {|x| x['area']['code'] == $area }.first
	fctime = $forecast.first['timeSeries'][0]['timeDefines']
	
	tmarea = $forecast.first['timeSeries'][2]['areas'].select {|x| x['area']['code'] == $amedas }.first['temps']
	tmtime = $forecast.first['timeSeries'][2]['timeDefines']
	
	pparea = $forecast.first['timeSeries'][1]['areas'].select {|x| x['area']['code'] == $area }.first['pops']
	pptime = $forecast.first['timeSeries'][1]['timeDefines']
	
	temp = [[],[],[]]
	pop = [[],[],[]]
	
	tmtime.each_with_index do |t,i|
		if Time.parse(t) - Time.parse("#{$dymd}T00:00:00+09:00") < 24.hours
			temp[0].push(tmarea[i])
		elsif Time.parse(t) - Time.parse("#{$dymd}T00:00:00+09:00") >= 24.hours and Time.parse(t) - Time.parse("#{$dymd}T00:00:00+09:00") <= 48.hours
			temp[1].push(tmarea[i])
		elsif Time.parse(t) - Time.parse("#{$dymd}T00:00:00+09:00") > 48.hours
			temp[2].push(tmarea[i])
		end
	end
	
	pptime.each_with_index do |t,i|
		if Time.parse(t) - Time.parse("#{$dymd}T00:00:00+09:00") < 24.hours
			pop[0].push(pparea[i])
		elsif Time.parse(t) - Time.parse("#{$dymd}T00:00:00+09:00") >= 24.hours and Time.parse(t) - Time.parse("#{$dymd}T00:00:00+09:00") <= 48.hours
			pop[1].push(pparea[i])
		elsif Time.parse(t) - Time.parse("#{$dymd}T00:00:00+09:00") > 48.hours
			pop[2].push(pparea[i])
		end
	end
	out = []
	for i in 0..fctime.length-1
		out.push({
			:date => Time.parse(fctime[i]),
			:weather => fcarea['weatherCodes'][i].to_i,
			:wind => fcarea['winds'][i],
			:wave => fcarea['waves'][i],
			:temp => temp[i],
			:pop => pop[i]
		})
	end
	return out
end

def forecastweek
	fcarea = $forecast.last['timeSeries'][0]['areas'].select {|x| x['area']['code'] == $area }.first
	fctime = $forecast.last['timeSeries'][0]['timeDefines']
	
	tmarea = $forecast.last['timeSeries'][1]['areas'].select {|x| x['area']['code'] == $amedas }.first
	tmtime = $forecast.last['timeSeries'][1]['timeDefines']
	
	temp = []
	tmtime.each_with_index do |t,i|
		temp.push({
			:min => tmarea['tempsMin'][i],
			:minup => tmarea['tempsMinUpper'][i],
			:minlo => tmarea['tempsMinLower'][i],
			:max => tmarea['tempsMax'][i],
			:maxup => tmarea['tempsMaxUpper'][i],
			:maxlo => tmarea['tempsMaxLower'][i]
		})
	end
	out = []
	for i in 0..fctime.length-1
		out.push({
			:date => Time.parse(fctime[i]),
			:weather => fcarea['weatherCodes'][i].to_i,
			:temp => temp[i],
			:pop => fcarea['pops'][i]
		})
	end
	return out
end

def overviewdays
	json = JSON.parse(URI.open("https://www.jma.go.jp/bosai/forecast/data/overview_forecast/#{$pref}.json").read)
	
	text = "#{json['headlineText']}\n\n"
	text += "#{json['text']}"
	text.gsub!(/([\p{Hiragana}\p{Katakana}])\s*$\n/, '\1')
	text.gsub!(/^　/, '')
	text.gsub!(/[＞】）]/, '\0\n')
	text.gsub!(/[（]/, '\n\0')
	text.gsub!(/[^線][しりが]、/, '\0\n')
	text.gsub!(/[^の]ため、/, '\0\n')
	text.gsub!(/。/, '\0\n')
	text.gsub!(/\\n/, "\n")
	text.gsub!(/\n^　+$\n/, "\n")
	text.gsub!(/\n\s*\n\s*\n/, "\n\n")
	text = "#{Time.parse(json['reportDatetime']).strftime("%Y年%m月%d日 %H時%M分")}\n\n" + text
	text = NKF.nkf('-X -w', text).tr('０-９．', '0-9.')
	return text
end

def overviewweek
	json = JSON.parse(URI.open("https://www.jma.go.jp/bosai/forecast/data/overview_week/#{$pref}.json").read)
	
	text = "#{json['headTitle']}\n\n"
	text += "#{json['text']}"
	date = "#{text.lines.first.strip}　#{Time.parse(json['reportDatetime']).strftime("%Y年%m月%d日 %H時%M分")}"
	a = [date] + text.lines[1..-1]
	text = a.join("\n\n")
	text.gsub!(/([\p{Hiragana}\p{Katakana}])\s*$\n/, '\1')
	text.gsub!(/^　/, '')
	text.gsub!(/[＞】）]/, '\0\n')
	text.gsub!(/[（]/, '\n\0')
	text.gsub!(/[^線][くしりが]、/, '\0\n')
	text.gsub!(/[^の]ため、/, '\0\n')
	text.gsub!(/まで　/, '\0\n\n')
	text.gsub!(/。/, '\0\n\n')
	text.gsub!(/\\n/, "\n")
	text.gsub!(/\n^　+$\n/, "\n")
	text.gsub!(/\n\s*\n\s*\n/, "\n\n")
	text = NKF.nkf('-X -w', text).tr('０-９．', '0-9.')
	return text.strip
end

def minmax(list,st,et)
	a = list.map {|date,val| val if date >= st and date <= et }.reject(&:blank?)
	if a.min == a.max
		return "#{a.min}"
	else
		return "#{a.min}〜#{a.max}"
	end
end

def windwarn(a)
	if a.length > 1
		dir = a.map {|d,s| d}.uniq
		spd = a.map {|d,s| s}.uniq
		min = a.map{|d,s|s}.min
		max = a.map{|d,s|s}.max
		if dir.length > 1 and spd.length == 1
			return "#{dir.join('〜')} #{spd.join('')} m/s"
		elsif dir.length > 1 and spd.length > 2
			return "#{dir.join('〜')} #{min}〜#{max} m/s"
		elsif dir.length > 1 and spd.length > 1
			return "#{dir.join('〜')} #{spd.join('〜')} m/s"
		else
			return "#{dir.join('')} #{min}〜#{max} m/s"
		end
	else
		return "#{a[0][0]} #{a[0][1]} m/s"
	end
end

def warningtimes(t,l,s,i)
	v = l.select {|x| x['type'] == s }.map {|x| x['localAreas'][i]['values'] }
	return Hash[t.zip(v.flatten)]
end

def warning
	json = JSON.parse(URI.open("https://www.jma.go.jp/bosai/warning/data/warning/#{$pref}.json").read)
	
	warnings = json['areaTypes'].last['areas'].select {|x| x['warnings'] if x['code'] == $local and not x['warnings'].any?{|y| y['status'] == "解除"}}.map {|x| x['warnings']}.flatten
	
	times = []
	json['timeSeries'].each do |x|
		h = {
			:times => x['timeDefines'],
			:warnings => x['areaTypes'].last['areas'].select {|y| y['code'] == $local}.map {|x| x['warnings']}.flatten
		}
		times.push(h)
	end
	
	sort = Hash.new{|h,k| h[k] = [] }
	warnings.each do |x|
		name = WARNINGCODE[x['code']][:name]
		time = times.select {|y| y[:warnings].any? {|z| z['code'] == x['code']}}.first
		warning = time[:warnings].select {|y| y['code'] == x['code']}.first
		# ['status'] 発表 継続 発表警報・注意報はなし
		sort[name].push({:time=>time[:times],:warning=>warning}) unless x['status'].match? /なし$/
	end
	# puts sort.pretty_inspect
	listtoday = []
	listtomorrow = []
	sort.each do |k,v|
		today = []
		tomorrow = []
		v.each do |t|
			times = t[:time].map {|x| Time.parse(x)}
			
			if local = t[:warning]['levels'][0]['localAreas'].find_index {|x| x['localAreaName'] == "陸上"}
			else
				local = 0
			end
			data = t[:warning]['levels'][0]['localAreas']
			unless data.first['localAreaName'].nil?
				areas = data.map {|x| "#{x['localAreaName']} "}
			else
				areas = [""]
			end
			
			i = data[0]['values'].each_index.select {|y| data[0]['values'][y] != "" and data[0]['values'][y] != "00"}[0]
			j = data[0]['values'].each_index.select {|y| data[0]['values'][y] != "" and data[0]['values'][y] != "00"}[-1]
			
			warning = WARNINGCODE[t[:warning]['code']][:type]
			
			if k == "雷" or k == "融雪" or k == "霜" or k == "雪崩" or k == "着氷" or k == "着雪"
				unless data[0]['additions'].nil?
					details = " #{data[0]['additions'].join('　')}"
				else
					details = ''
				end
				if times[i] >= $d24
					tomorrow.push("#{warning}　#{details}")
				elsif times[i] < $d24 and times[j] >= $d24
					today.push("#{warning}　#{details}")
					tomorrow.push("#{warning}　#{details}")
				else
					today.push("#{warning}　#{details}")
				end
			elsif k == "乾燥"
				effhum = warningtimes(times,t[:warning]['properties'],"実効湿度",local)
				minhum = warningtimes(times,t[:warning]['properties'],"最小湿度",local)
				if times[i] >= $d24
					tomorrow.push("#{warning}　実効湿度 #{minmax(effhum,$d24,$d48)}% 最小湿度 #{minmax(minhum,$d24,$d48)}%")
				elsif times[i] < $d24 and times[j] >= $d24
					today.push("#{warning}　実効湿度 #{minmax(effhum,$d0,$d24)}%　最小湿度 #{minmax(minhum,$d24,$d48)}%")
					tomorrow.push("#{warning}　実効湿度 #{minmax(effhum,$d24,$d48)}%  最小湿度 #{minmax(minhum,$d24,$d48)}%")
				else
					today.push("#{warning}　実効湿度 #{minmax(effhum,$d0,$d24)}%  最小湿度 #{minmax(minhum,$d0,$d24)}%")
				end
			elsif k == "低温"
				if times[i] >= $d24
					tomorrow.push("#{warning}")
				elsif times[i] < $d24 and times[j] >= $d24
					today.push("#{warning}")
					tomorrow.push("#{warning}")
				else
					today.push("#{warning}")
				end
			elsif k == "大雨"
				if times[i] >= $d24
					tomorrow.push("#{warning}")
				elsif times[i] < $d24 and times[j] >= $d24
					today.push("#{warning}")
					tomorrow.push("#{warning}")
				else
					today.push("#{warning}")
				end
			elsif k == "大雪"
				if times[i] >= $d24
					tomorrow.push("#{warning}")
				elsif times[i] < $d24 and times[j] >= $d24
					today.push("#{warning}")
					tomorrow.push("#{warning}")
				else
					today.push("#{warning}")
				end
			elsif k == "強風" or k == "暴風" or k == "風雪" or k == "暴風雪"
				todayarea = []
				tomorrowarea = []
				for area in 0..data.length-1
					speed = []
					dir = []
					t[:warning]['properties'].select {|x| x['type'] == "最大風速" }.each do |x|
						speed += x['localAreas'][area]['values']
					end
					t[:warning]['properties'].select {|x| x['type'] == "風向" }.each do |x|
						dir += x['localAreas'][area]['windDirections'].map {|y| y['value']}
					end
					h = Hash[times.zip(dir.zip(speed))]
					if times[i] >= $d24
						a = h.select {|k,v| k >= $d24 and not v.join('').empty? }.map {|k,v| v}.uniq
						tomorrowarea.push("#{areas[area]}#{windwarn(a)}")
					elsif times[i] < $d24 and times[j] >= $d24
						a = h.select {|k,v| k >= $d0 and k <= $d24 and not v.join('').empty? }.map {|k,v| v}.uniq
						todayarea.push("#{areas[area]}#{windwarn(a)}")
						b = h.select {|k,v| k >= $d24 and not v.join('').empty? }.map {|k,v| v}.uniq
						tomorrowarea.push("#{areas[area]}#{windwarn(b)}")
					else
						a = h.select {|k,v| k >= $d0 and k <= $d24 and not v.join('').empty? }.map {|k,v| v}.uniq
						todayarea.push("#{areas[area]}#{windwarn(a)}")
					end
				end
				today.push("#{warning}　#{todayarea.join('　')}") if todayarea.length > 0
				tomorrow.push("#{warning}　#{tomorrowarea.join('　')}") if tomorrowarea.length > 0
			elsif k == "波浪"
				wave = warningtimes(times,t[:warning]['properties'],"波高",0)
				if times[i] >= $d24
					tomorrow.push("#{warning}　#{minmax(wave,$d24,$d48)}m")
				elsif times[i] < $d24 and times[j] >= $d24
					today.push("#{warning}　#{minmax(wave,$d0,$d24)}m")
					tomorrow.push("#{warning}　#{minmax(wave,$d24,$d48)}m")
				else
					today.push("#{warning}　#{minmax(wave,$d0,$d24)}m")
				end
			elsif k == "洪水"
				if times[i] >= $d24
					tomorrow.push("#{warning}")
				elsif times[i] < $d24 and times[j] >= $d24
					today.push("#{warning}")
					tomorrow.push("#{warning}")
				else
					today.push("#{warning}")
				end
			elsif k == "濃霧"
				if times[i] >= $d24
					tomorrow.push("#{warning}")
				elsif times[i] < $d24 and times[j] >= $d24
					today.push("#{warning}")
					tomorrow.push("#{warning}")
				else
					today.push("#{warning}")
				end
			elsif k == "高潮"
				if times[i] >= $d24
					tomorrow.push("#{warning}")
				elsif times[i] < $d24 and times[j] >= $d24
					today.push("#{warning}")
					tomorrow.push("#{warning}")
				else
					today.push("#{warning}")
				end
			end
			
			if times[i] >= $d24 and times[j] >= $d48
				tomorrow[-1] += "　 #{times[i].strftime('%k').strip}〜"
			elsif times[i] >= $d24
				tomorrow[-1] += "　 #{times[i].strftime('%k').strip}〜#{(times[j]+3.hours).strftime('%k').strip}時"
			elsif times[j] >= $d48
				today[-1] += "　#{times[i].strftime('%k').strip}時〜"
				tomorrow[-1] += "　今後も"
			elsif times[j] >= $d24
				today[-1] += "　#{times[i].strftime('%k').strip}時〜"
				tomorrow[-1] += "　〜#{(times[j]+3.hours).strftime('%k').strip}時"
			else
				today[-1] += "  #{times[i].strftime('%k').strip}〜#{(times[j]+3.hours).strftime('%k').strip}時"
			end
		end
		listtoday.push("#{k}　#{today.join(' ')}") if today.length > 0
		listtomorrow.push("#{k}　#{tomorrow.join(' ')}") if tomorrow.length > 0
	end
	return listtoday,listtomorrow
end

def typhoonimg
	begin
		img = Magick::Image::from_blob(URI.open('http://www.jma.go.jp/jp/typh/images/wide/all-00.png').read).first.crop(0,0,480,335,true)
		return "| refresh=true image=#{Base64.encode64(img.to_blob).gsub(/\n/, '')}"
	rescue
		return '❌'
	end
end

def typhooninfo(list)
	info = []
	list.each do |id|
		data  = JSON.parse(URI.open("https://www.jma.go.jp/bosai/typhoon/data/#{id}/specifications.json").read)
		analysis = data.select{|x|x['part']['jp']=='実況'}.first
		name = analysis['category']['jp']
		if name == "台風"
			info.push("#{name} 第#{id[-2..-1].to_i}号  #{analysis['location']}  #{analysis['course']}  #{analysis['speed']['km/h']} km/h  #{analysis['pressure']} hPa  #{analysis['maximumWind']['sustained']['m/s']} m/s (#{analysis['maximumWind']['gust']['m/s']} m/s)")
		else
			info.push("--#{name} 第#{id[-2..-1].to_i}号  #{analysis['location']}  #{analysis['course']}  #{analysis['speed']['km/h']} km/h  #{analysis['pressure']} hPa | color=#{$textcolor}")
		end
	end
	return info
end

def earthquake
	# json = JSON.parse(URI.open("https://www.jma.go.jp/bosai/quake/data/list.json").read)
	
	json = JSON.parse(URI.open("#{Dir.home}/src/bitbar-plugins/jma/quake.json").read)
	
	list = json.select do |x|
		x['int'].any? {|y| y['city'].any? {|z| z['code'] == $quakearea and z['maxi'].to_i > 1} }
	end
	if list.length > 0
		q = list.first
		mag = q['int'].select {|x| x['city'].any? {|y| y['code'] == $quakearea}}[0]['city'].select {|x| x['code'] == $quakearea}[0]['maxi']
		dep = (q['acd'].to_i / 5)#.round(-1)
	
		return "#{q['mag']} (#{mag})  #{q['anm']} #{dep} km  #{Time.parse(q['at']).strftime('%-m/%-d %H:%M')}"
	else
		return nil
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
	if ENV["SWIFTBAR"]
		if ENV["OS_APPEARANCE"] == "Light"
			return false
		else
			return true
		end
	else
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

def forecasticon(forecast,istoday)
	icon = WEATHERCODE[forecast].clone
	
	icon = "#{SNOW}#{WIND}" if icon == "暴風雪" or icon == "風雪強い"
	icon = HEAVYRAIN if icon == "雨一時強く降る" or icon == "大雨"
	icon = HEAVYSNOW if icon == "雪一時強く降る"
	
	icon.sub!(/山沿い.+/,'')
	icon.sub!("晴明け方霧","#{FOG} #{THEN} 晴")
	icon.sub!("曇海上海岸は霧か霧雨",CLOUDY)
	
	if istoday and isnight
		icon.sub!("晴",moon($dt))
	else
		icon.sub!("晴",FINE)
	end
	
	icon.sub!("で雷を伴う",LIGHTNING)
	icon.sub!("雨か雷雨","#{RAIN}#{LIGHTNING}")
	icon.sub!("雷雨",LIGHTNINGRAIN)
	icon.sub!("で暴風を伴う",WIND)
	
	icon.sub!(/^朝の内/,'')
	icon = icon.sub("朝の内一時",'').reverse.insert(1,"一時") if icon.match?("朝の内一時")
		
	icon.sub!("後"," #{THEN} ")
	icon.sub!("一時"," #{ONCE} ")
	icon.sub!("夜は"," #{THEN} ")
	icon.sub!("時々"," #{OCCASIONAL} ")
	icon.sub!("朝夕"," #{OCCASIONAL} ")
	icon.sub!("後一時"," #{ONCE} ")
	icon.sub!("後時々"," #{OCCASIONAL} ")
	icon.sub!("時々止む"," #{OCCASIONAL} ")
	icon.sub!("午後は"," #{THEN} ")
	icon.sub!("昼頃から"," #{THEN} ")
	icon.sub!("夕方一時"," #{ONCE} ")
	icon.sub!("日中時々"," #{OCCASIONAL} ")
	icon.sub!("朝夕一時"," #{ONCE} ")
	icon.sub!("朝晩一時"," #{ONCE} ")
	
	icon.sub!("曇",CLOUDY)
	icon.sub!("雨",RAIN)
	icon.sub!("雪",SNOW)
	icon.sub!("霧",FOG)
	icon.sub!("霙",ICE)
	
	icon.sub!("か",'')
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

def climacellicon(code)
	case code
	when 0 # Unknown
		icon = "#{UNKNOWN}"
	when 1000 # Clear
		isnight ? (icon = moon($dt)) : (icon = "#{FINE}")
	when 1001 # Cloudy
		icon = "#{CLOUDY}"
	when 1100 # Mostly Clear
		isnight ? (icon = moon($dt)) : (icon = "#{FINECLOUD}")
	when 1101 # Partly Cloudy
		icon = "#{CLOUDFINE}"
	when 1102 # Mostly Cloudy
		icon = "#{MOSTCLOUD}"
	when 2000 # Fog
		icon = "#{FOG}"
	when 2100 # Light Fog
		icon = "#{FOG}"
	when 3000 # Light Wind
		icon = "#{WIND}"
	when 3001 # Wind
		icon = "#{WIND}"
	when 3002 # Strong Wind
		icon = "#{WIND}"
	when 4000 # Drizzle
		icon = "#{RAIN}"
	when 4001 # Rain
		icon = "#{RAIN}"
	when 4200 # Light Rain
		icon = "#{RAIN}"
	when 4201 # Heavy Rain
		icon = "#{HEAVYRAIN}"
	when 5000 # Snow
		icon = "#{SNOW}"
	when 5001 # Flurries
		icon = "#{SNOW}"
	when 5100 # Light Snow
		icon = "#{SNOW}"
	when 5101 # Heavy Snow
		icon = "#{HEAVYSNOW}"
	when 6000 # Freezing Drizzle
		icon = "#{RAIN}"
	when 6001 # Freezing Rain
		icon = "#{HEAVYRAIN}"
	when 6200 # Light Freezing Rain
		icon = "#{ICE}"
	when 6201 # Heavy Freezing Rain
		icon = "#{ICE}"
	when 7000 # Ice Pellets
		icon = "#{ICE}"
	when 7101 # Heavy Ice Pellets
		icon = "#{ICE}"
	when 7102 # Light Ice Pellets
		icon = "#{ICE}"
	when 8000 # Thunderstorm
		icon = "#{LIGHTNING}"
	end
end

def formatnum(s)
	return NKF.nkf('-X -w', s).tr('０-９．', '0-9.')
end

def formatdaysmenu(h)
	wind = h[:wind].split('　')[0].gsub('メートル',' m/s')
	if h[:wind].split('　').length > 1
		wind += "\n" + h[:wind].split('　')[1..-1].join('　').gsub('メートル',' m/s')
	end
	wave = h[:wave].gsub('メートル',' m/s')
	text = "#{WEATHERCODE[h[:weather]]}\n#{wind}\n波　#{wave}"
	return formatnum(text)
end

def winddirconv(degree)
	cardinals = ['北', '北北東', '北東', '東北東', '東', '東南東', '南東', '南南東', '南', '南南西', '南西', '西南西', '西', '西北西', '北西', '北北西']
	dir = ((degree * 16) / 360).round(0)
	cardinals[dir]
end

def hourcircle(i)
	i = (i.to_i + 9) % 24
	case i
	when 0
		return '⓪'
	when 1
		return '①'
	when 2
		return '②'
	when 3
		return '③'
	when 4
		return '④'
	when 5
		return '⑤'
	when 6
		return '⑥'
	when 7
		return '⑦'
	when 8
		return '⑧'
	when 9
		return '⑨'
	when 10
		return '⑩'
	when 11
		return '⑪'
	when 12
		return '⑫'
	when 13
		return '⑬'
	when 14
		return '⑭'
	when 15
		return '⑮'
	when 16
		return '⑯'
	when 17
		return '⑰'
	when 18
		return '⑱'
	when 19
		return '⑲'
	when 20
		return '⑳'
	when 21
		return '㉑'
	when 22
		return '㉒'
	when 23
		return '㉓'
	when 24
		return '㉔'
	else
		return '〇'
	end
end

def adjustpadding(string)
	unless string.nil?
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
	radar = URI.open("https://www.jma.go.jp/jp/radnowc/imgs/radar/#{$region}/#{$dymd}#{$tr}-00.png").read
	r64 = "| refresh=true image=#{Base64.encode64(radar).gsub(/\n/, '')}"
rescue
	r64 = '⚠️'
end

begin
	u = "http://www.jma.go.jp/jp/#{$satfreq}/imgs/0/#{$sattype}/1/#{$dymd}#{$ts}-00.png"
	if Faraday.head(u).status != 200
		u = "http://www.jma.go.jp/jp/#{$satfreq}/imgs/0/infrared/1/#{$dymd}#{$ts}-00.png"
	end
	satellite = URI.open(u).read
	s64 = "| refresh=true image=#{Base64.encode64(satellite).gsub(/\n/, '')}"
rescue
	s64 = '⚠️'
end


if ifdarkmode
	$textcolor = 'lightgray'
	$advcolor = 'yellow'
	$wrncolor = 'orange'
	$textansi = '97'
	$rainansi = '36'
else
	$textcolor = 'darkslategray'
	$advcolor = 'orange red'
	$wrncolor = 'red'
	$textansi = '39' # 30 too dark, 39 too light
	$rainansi = '1;36'
end

###

# darksky = JSON.parse(URI.open("https://api.darksky.net/forecast/#{$darkskyapi}/#{$latlon}?units=si").read)
#
# temp = darksky['currently']['temperature'].to_f.round(1)
# apptemp = darksky['currently']['apparentTemperature'].to_f.round(1)
# dewpoint = darksky['currently']['dewPoint'].to_f.round(1)
# humidity = (darksky['currently']['humidity'].to_f * 100).round(0) # %
# pressure = darksky['currently']['pressure'] # hectopascal
# windspeed = darksky['currently']['windSpeed'].to_f.round(1) # m/s
# gust = darksky['currently']['windGust'].to_f.round(1) # m/s
# winddir = darksky['currently']['windBearing'].to_i # deg
# uv = darksky['currently']['uvIndex']
# precip = darksky['currently']['precipIntensity'].to_f.round(1) # mm/h
# precipprob = darksky['currently']['precipProbability'].to_f.round(1)
# clouds = (darksky['currently']['cloudCover'] * 100).round(0) # %
# visibility = darksky['currently']['visibility'].to_f.round(0) # km
# icon = darkskyicon(darksky['currently']['icon'])

# openweather =  JSON.parse(URI.open("https://api.openweathermap.org/data/2.5/weather?id=#{$location}&units=metric&lang=ja&appid=#{$openweatherapi}").read)
#
# temp = openweather['main']['temp'].to_f.round(1)
# apptemp = openweather['main']['feels_like'].to_f.round(1)
# # dewpoint =
# humidity = (openweather['main']['humidity'].to_f * 100).round(0) # %
# pressure = openweather['main']['pressure'] # hectopascal
# windspeed = openweather['wind']['speed'].to_f.round(1) # m/s
# # gust = openweather['wind']['gust'].to_f.round(1) # m/s
# winddir = openweather['wind']['deg'].to_i # deg
# # uv =
# precip = openweather['rain']['rain.1h'].to_f.round(1) # mm last hour
# precip = openweather['snow']['snow.1h'].to_f.round(1) # mm last hour
# # precipprob =
# clouds = (openweather['clouds']['all']).round(0) # %
# visibility = openweather['visibility'].to_f.round(0) # km
# icon = openweather['weather']['main']
# # TODO
# # icon, missing token

visualcrossing = JSON.parse(URI.open("https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/#{$latlon}?unitGroup=metric&key=#{$visualcrossingapi}&include=alerts%2Ccurrent").read)

# temp = visualcrossing['currentConditions']['temp'].to_f.round(1)
apptemp = visualcrossing['currentConditions']['feelslike'].to_f.round(1)
# dewpoint = visualcrossing['currentConditions']['dew'].to_f.round(1)
# humidity = visualcrossing['currentConditions']['humidity'].to_f.round(0) # %
# pressure = visualcrossing['currentConditions']['pressure'] # hectopascal
# windspeed = visualcrossing['currentConditions']['windspeed'].to_f.round(1) # m/s
# gust = visualcrossing['currentConditions']['windgust'].to_f.round(1) # m/s
# winddir = visualcrossing['currentConditions']['winddir'].to_i # deg
# if gust.nil?
# 	wind = "#{windspeed} m/s #{winddirconv(winddir)}"
# else
# 	wind = "#{windspeed} m/s (#{gust} m/s) #{winddirconv(winddir)}"
# end
# uv = nil
unless visualcrossing['currentConditions']['cloudcover'].nil?
	cloudcover = visualcrossing['currentConditions']['cloudcover'].round(0) # %
else
	cloudcover = 0
end
clouds = "#{cloudcover}%"
visibility = visualcrossing['currentConditions']['visibility'].to_f.round(0) # km
icon = darkskyicon(visualcrossing['currentConditions']['icon'])
# TODO ['alerts']
# if null = 0
# 2021/02/02 wind, pressure, precip null

# climacell = JSON.parse(URI.open("https://data.climacell.co/v4/timelines?location=#{$latlon}&timesteps=1m&timezone=Asia/Tokyo&fields=temperature,temperatureApparent,dewPoint,humidity,windSpeed,windDirection,windGust,pressureSurfaceLevel,precipitationIntensity,precipitationProbability,precipitationType,visibility,cloudCover,cloudBase,cloudCeiling,weatherCode,epaIndex,epaPrimaryPollutant,epaHealthConcern", 'content-type' => 'application/json', 'apikey' => $climacellapi).read)
#
# cccurrent = climacell['data']['timelines'][0]['intervals'][0]['values']
#
# temp = cccurrent['temperature'].to_f.round(1)
# apptemp = cccurrent['temperatureApparent'].to_f.round(1)
# dewpoint = cccurrent['dewPoint'].to_f.round(1)
# humidity = cccurrent['humidity'].to_f.round(0) # %
# pressure = cccurrent['pressureSurfaceLevel'] # hectopascal
# windspeed = cccurrent['windSpeed'].to_f.round(1) # m/s
# gust = cccurrent['windGust'].to_f.round(1) # m/s
# winddir = cccurrent['windDirection'].to_i # deg
# wind = "#{windspeed} m/s (#{gust} m/s) #{winddirconv(winddir)}"
# # uv = cccurrent['uvIndex']
# precip = cccurrent['precipitationIntensity'].to_f.round(1) # mm/h
# precipprob = cccurrent['precipitationProbability'].to_f.round(1)
# preciptype = cccurrent['precipitationType'].to_i
# # 0: N/A, 1: Rain, 2: Snow, 3: Freezing Rain, 4: Ice Pellets
# cloudcover = (cccurrent['cloudCover']).round(0) # %
# cloudbase = cccurrent['cloudBase'] # km
# cloudceiling = cccurrent['cloudCeiling'] # km
# clouds = "#{cloudcover}% (#{cloudbase}→#{cloudceiling} km)"
# visibility = cccurrent['visibility'].to_f.round(0) # km
# cccode = cccurrent['weatherCode'].to_i
# icon = climacellicon(cccode)
# epaindex = cccurrent['epaIndex'].to_i
# epapol = cccurrent['epaPrimaryPollutant'].to_i
# # 0: PM2.5, 1: PM10, 2: O3, 3: NO2, 4: CO, 5: SO2
# epaconcern = cccurrent['epaHealthConcern'].to_i
# # 0: Good (0-50), 1: Moderate (51-100), 2: Unhealthy for Sensitive Groups (101-150)
# # 3: Unhealthy (151-200), 4: Very Unhealthy (201-300), 5: Hazardous (>301)

jma = JSON.parse(URI.open("https://www.jma.go.jp/bosai/amedas/data/point/#{$amedas}/#{$dtame}.json").read)

temp = humidity = pressure = precip = 0
wind = gust = mintemp = maxtemp = ''

current = jma.map {|k,v| v}.last
update = Time.parse(jma.map {|k,v| k}.last).strftime("%H:%M")
temp = windspeed = humidity = pressure = snow = 0
winddir = ''

temp = current['temp'].first
wind = "#{winddirconv(current['windDirection'].first)} #{current['wind'].first} m/s"
gust = "#{winddirconv(current['gustDirection'].first)} #{current['gust'].first} m/s #{hourcircle(current['gustTime']['hour'])}"
humidity = current['humidity'].first
pressure = current['normalPressure'].first
precip = current['precipitation1h'].first
precipday = current['precipitation24h'].first
snow = current['snow1h'].first unless current['snow1h'].nil?
snowday = current['snow24h'].first unless current['snow24h'].nil?
mintemp = "#{current['minTemp'].first}° #{hourcircle(current['minTempTime']['hour'])}"
maxtemp = "#{current['maxTemp'].first}° #{hourcircle(current['maxTempTime']['hour'])}"

dewpoint = (temp - (100 - humidity)/5).round(1)
capptemp = (temp + 0.33 * (6.105 * humidity/100 * Math::E**((17.27*temp)/(237.7+temp))) - 0.7 * windspeed - 4).round(1)
# http://www.bom.gov.au/info/thermal_stress/#atapproximation

lastquake = earthquake

######

puts "#{icon} #{temp}°"
puts "---"
puts "#{$place} | color=lightslategray"
puts "---"
# puts "温  #{temp}° (#{apptemp}°) | color=#{$textcolor}"
puts "\033[#{$textansi}m温  #{temp}° (#{apptemp}/#{capptemp}°)  \033[34m#{mintemp}  \033[31m#{maxtemp} | color=#{$textcolor} ansi=true"
puts "湿  #{humidity}% (#{dewpoint}°) | color=#{$textcolor}"
puts "圧  #{pressure} hPa | color=#{$textcolor}" if defined?(pressure)
puts "風  #{wind} (#{gust})| color=#{$textcolor}"
puts "雨  #{precip} mm/h (#{precipday} mm/d) | color=#{$textcolor}" if precip > 0
puts "雪  #{precip} mm/h (#{snowday} mm/d) | color=#{$textcolor}" if not snow.nil? and snow > 0
# puts "雨  #{precip} mm/h (#{precipprob} mm/h) #{rainfall if rainfall > 0} #{'mm' if rainfall > 0} | color=#{$textcolor}" if precip > 0 or precipprob > 0
puts "雲  #{clouds} | color=#{$textcolor}"
puts "視  #{visibility} km | color=#{$textcolor}" if defined?(visibility)
puts "紫  #{uv} | color=#{$textcolor}" if defined?(uv)
puts "時  #{update} | color=lightslategray"
puts "震  #{lastquake} | color=#{$textcolor}" unless lastquake.nil?

puts "---"

# forecastdays today & tomorrow

days = forecastdays
week = forecastweek

warnings = warning

for i in 0..1
	icon = ''
	case i
	when 0
		date = "今日#{days[0][:date].strftime('%-d')}日"
		istoday = true
	when 1
		date = "明日#{days[1][:date].strftime('%-d')}日"
		istoday = false
	end
	unless warnings[i].blank?
		if warnings[i].any? {|line| line.match("警報")}
			puts "#{date} | color=#{$wrncolor}"
		else
			puts "#{date} | color=#{$advcolor}"
		end
		"#{formatdaysmenu(days[i])}".each_line do |line|
			puts "--#{line.strip} | color=#{$textcolor}"
		end
		warnings[i].each do |line|
			if line.match("警報")
				puts "--#{line.strip} | color=#{$wrncolor}"
			else
				puts "--#{line.strip} | color=#{$advcolor}"
			end
		end
	else
		puts "#{date} | color=#{$textcolor}"
		"#{formatdaysmenu(days[i])}".each_line do |line|
			puts "--#{line.strip} | color=#{$textcolor}"
		end
	end
	
	icon = forecasticon(days[i][:weather],istoday)
	print "\033[#{$textansi}m"
	print "#{icon.center(ICONLENGTH+adjustpadding(icon))}"
	
	if days[i][:temp].empty?
		print " ".rjust(9)
	elsif days[i][:temp][0] == days[i][:temp][1]
		print "\033[31m#{days[i][:temp][1].rjust(9)}˚"
	else
		print "\033[34m#{days[i][:temp][0].rjust(4)}˚"
		print "\033[31m#{days[i][:temp][1].rjust(4)}˚"
	end
	
	print "\033[#{$rainansi}m    "
	print days[i][:pop].map {|x| "#{x.rjust(2)}%"}.join(' ').rjust(16)
	print "| color=#{$textcolor} font=Menlo ansi=true\n"
end

# forecastweek

week[1][:date] - $dt < 24.hours ? (w = 2) : (w = 1)

for i in w..6
	date = "#{week[i][:date].strftime('%-d')}日（#{WEEK[week[i][:date].strftime('%u')]}）"
	puts "#{date} | color=#{$textcolor}"

	if i == 1 and not days[2].nil?
		"#{formatdaysmenu(days[2])}".each_line do |line|
			puts "--#{line.strip} | color=#{$textcolor}"
		end
	end
	
	icon = forecasticon(week[i][:weather],false)
	print "\033[#{$textansi}m"
	print "#{icon.center(ICONLENGTH+adjustpadding(icon))}"
	
	print "\033[34m#{week[i][:temp][:min].rjust(4)} "
	print "#{('('+week[i][:temp][:minlo]).rjust(3)}"
	print "〜#{week[i][:temp][:minup].rjust(2)})"
	
	print "\033[31m#{week[i][:temp][:max].rjust(4)} "
	print "#{('('+week[i][:temp][:maxlo]).rjust(3)}"
	print "〜#{week[i][:temp][:maxup].rjust(2)})"
	
	print "\033[#{$rainansi}m"
	print week[i][:pop].rjust(4)
	print "| color=#{$textcolor} font=Menlo ansi=true\n"
end


puts "---"
puts "天気概況 | ansi=false color=#{$textcolor}"
overviewdays.each_line do |line|
	puts "--#{line.strip} | color=#{$textcolor} ansi=false"
end
puts "二週間気温予報 | ansi=false color=#{$textcolor}"
overviewweek.each_line do |line|
	puts "--#{line.strip} | color=#{$textcolor} ansi=false"
end
puts "レーダー | ansi=false color=#{$textcolor}"
puts "--#{r64}"
puts "衛星 | color=#{$textcolor}"
puts "--#{s64}"

typhoontarget = JSON.parse(URI.open("https://www.jma.go.jp/bosai/typhoon/data/targetTc.json").read)

if typhoontarget.length > 0
	puts "台風情報 | ansi=false color=#{$textcolor} href=https://www.jma.go.jp/bosai/map.html#elem=root&typhoon=all&contents=typhoon"
	puts "--#{typhoonimg}"
	puts typhooninfo(typhoontarget.map {|x| x['tropicalCyclone']})
	# >= 44 color=#{$advcolor} >= 54 color=#{$wrncolor}
end

puts "---"
puts "更新 | refresh=true ansi=false color=green"
puts "気象庁…|href=https://www.jma.go.jp/bosai/forecast/#area_type=offices&area_code=#{$subarea} ansi=false color=lightslategray"
