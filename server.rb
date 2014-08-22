require 'sinatra'
require 'redis'
require 'json'
require 'csv'
enable :sessions

set :views_dir, File.dirname(__FILE__) + '/views'
set :public_dir, File.dirname(__FILE__) + '/public'

####################################################
#                   METHODS
####################################################

def read(filename)
  data = []
  CSV.foreach(filename, headers: true) do |row|
    data << row.to_hash
  end
  data
end


 def validate_url(filename, url)
  checked_urls = filename.select do |row|
     row['url'] == url
    end
  checked_urls
end

def get_connection
  if ENV.has_key?("REDISCLOUD_URL")
    Redis.new(url: ENV["REDISCLOUD_URL"])
  else
    Redis.new
  end
end

def find_articles
    redis = get_connection
    serialized_articles = redis.lrange("slacker:articles", 0, -1)

    articles = []

    serialized_articles.each do |article|
      articles << JSON.parse(article, symbolize_names: true)
    end

    articles
end

def save_article(url, title, description)
  article = {url: url, title: title, description: description}

  redis = get_connection
  redis.rpush("slacker:articles", article.to_json)
end

####################################################
#                   ROUTES
####################################################

before do
  @articles = read('public/articles.csv')
end

get '/index' do
   erb :rachel_index
 end

get '/new' do
  erb :new
end

post '/new' do
   @title = params['article_title']
   @url = params['article_url']
   @description = params['article_description']
   @checked_urls = validate_url(@articles, @url)
    if @checked_urls.empty?
      CSV.open('public/articles.csv', 'a') do |csv|
        csv << [@title, @url, @description]
      end
      redirect '/index'
    else
      session[:message]="We already know about this link. Try a different url."
      erb :new
    end
end
