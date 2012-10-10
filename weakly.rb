require 'rest_client'
require 'rainbow'
require 'uri'
require 'ap'

def get_respone url
	code = RestClient.head(url){ |response, request, result, &block|
			if [301, 302, 307].include? response.code
				response.follow_redirection(request, result, &block)
  			else
    			response.code
  			end
  		}
	
	case code
  	when 200
  		code.to_s.color :green
  	when 301
  		code.to_s.color :yellow
  	else
  		code.to_s.color :red
  	end	
end

def normalize url
	url = "http://" + url if !url.start_with? "http"
	uri = URI url
	uri.scheme + "://" + uri.host
end

def get_robots site
	url = site + "/robots.txt"
	
	code = get_respone url

	if code != "\e[32m200\e[0m"
		puts "robots.txt #{code}"
		return
	end
	
	res = RestClient.get url, {"User-Agent" => "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"}
	disallow = res.scan(/Disallow:\s+(.*?)\s+/).flatten
	allow = res.scan(/Allow:\s+(.*?)\s+/).flatten
	#sitemap = res.scan(/Sitemap:\s(.*?)\s/).flatten
	urls = allow + disallow #+ sitemap
	if urls.empty? # robots have special symbols
		puts "robots.txt #{code}, but empty"
	else
		puts "robots.txt #{code}:"
		urls.map { |r|
			puts "#{site}#{r} #{get_respone site+r}"
		}
	end
end

def get_hypertext_access site
	url = site + "/.htaccess"
	code = get_respone url
	puts ".htaccess #{code}"
	if code == "\e[32m200\e[0m"
		res = RestClient.get(url){ |response, request, result, &block|
			if [301, 302, 307].include? response.code
				response.follow_redirection(request, result, &block)
  			else
    			response
  			end
  		}
  		puts "\t"+res.gsub("\n", "\n\t").slice(0,137) + "... "
	end
end

def allow_put_method site
	begin
		RestClient.put site + "/pt_test.txt", "PTEST"
	rescue => e
		puts "PUT not allowed " + "405".color(:red)
		return
	end
	code = get_respone site + "/pt_test.txt"
	puts "PUT allowed " + code

end

#add htpasswd
# .svn
# .git
u = normalize ARGV[0]

allow_put_method u
get_hypertext_access u
get_robots u

