require "net/http"
require "uri"
require "json"
require "nokogiri"
require "date"

$host = "http://www.jianshu.com"

END {
	case ARGV.length
	when 1
		puts getUUID(ARGV[0])
	when 2
		if ARGV[1] == "*"
			articles = getLatestArticles(ARGV[0])
			printArticle(articles)
		elsif testDate(ARGV[1])
			dateStrat, dateEnd = testDate(ARGV[1])
			dateStrat = DateTime.parse(dateStrat)
			dateEnd = DateTime.parse(dateEnd)
			articles = getLatestArticles(ARGV[0])
			articles.delete_if do |article|
				time = DateTime.parse(article["time"])
				!(time >= dateStrat && time <= dateEnd)
			end
			printArticle(articles)
		else
			puts "参数错误-_-"
		end
	else
		puts "你别乱输啊-_-"
	end
}

# 获取用户名的UUID
def getUUID(userName)
	puts "正在查询..."
	url = URI.escape("#{$host}/search/do?q=#{userName}&page=1&type=users")
	authorsJSON = Net::HTTP.get(URI(url))
	authorsOBJ = JSON.parse(authorsJSON)
	name = authorsOBJ["entries"][0]["nickname"]
	if name !=userName
		return "未找到此用户"
	end
	return authorsOBJ["entries"][0]["slug"]
end
#获取用户的所有文章并且按照时间排名
def getLatestArticles(userName)
	uuid = getUUID(userName)
	i = 1
	arr = Array.new
	loop do
		url = URI.escape("#{$host}/users/#{uuid}/latest_articles?page=#{i}")
		articlesHTML = Net::HTTP.get(URI(url))
		dom = Nokogiri::HTML(articlesHTML)
		if dom.css("ul.article-list").children.to_s.strip == ""
			break
		end
		dom.css("ul.article-list").css("li").each do |li|
			# 时间
			time = DateTime.parse(li.css("span.time").attr("data-shared-at").to_s).strftime('%Y-%m-%d')
			# 标题
			title = li.css("h4.title").css("a").text.to_s
			# 文章地址
			link = li.css("h4.title").css("a").attr("href").to_s
			# 阅读量
			readedStr = li.css("div.list-footer").css("a")[0].text.to_s.strip
			readedNumber = readedStr[3..readedStr.length]
			# 评论
			commentStr = li.css("div.list-footer").css("a")[1].text.to_s.strip
			commentNumber = commentStr[5..commentStr.length]
			# 喜欢
			likeStr = li.css("div.list-footer").css("span").text.to_s.strip
			likeNumber = likeStr[5..likeStr.length]
			articleObj = Hash.new
			articleObj = {
				"title" => "#{title}",
				"time" => "#{time}",
				"link" => "#{$host + link}",
				"readed" => "#{readedNumber}",
				"comment" => "#{commentNumber}",
				"like" => "#{likeNumber}"
			}
			arr.push(articleObj)
		end
		i +=1
	end
	return arr
end
# 测试用户输入日期
def testDate(str)
	dateReg = /\d{4}-\d{2}-\d{2}/
	datelist = str.split(" ")
	if datelist.length < 2
		return nil
	end
	dateStrat = datelist[0]
	dateEnd = datelist[1]
	if dateStrat =~ dateReg && dateEnd =~ dateReg
		return dateStrat, dateEnd
	else
		return nil
	end
end
# 打印数据
def printArticle(articles)
	puts "一共有#{articles.length}篇文章"
	articles.each do |article|
		article.each do |key, val|
			case key
			when "title"
				puts "标题: #{val}"
			when "time"
				puts "时间: #{val}"
			when "link"
				puts "文章地址: #{val}"
			when "readed"
				puts "阅读: #{val}"
			when "comment"
				puts "评论: #{val}"
			when "like"
				print "喜欢: #{val}\n\n"
			end
		end
	end
end
