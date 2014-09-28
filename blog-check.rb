require 'twilio-ruby'
require 'rss'
require 'yaml'

config = YAML.load_file('blog-check.yaml')

link = nil
rss = RSS::Parser.parse(config['url'], false)
links = rss.items.first.links
links.each do |l|
  if l.rel == "alternate"
    link = l.href
  end
end


while true
  begin
    latest_link = nil  
    rss = RSS::Parser.parse(config['url'], false)
    t = Time.now.to_s + " "
    links = rss.items.first.links
    links.each do |l|
      if l.rel == 'alternate'
        latest_link = l.href
      end
    end
    puts t + latest_link
    if latest_link != link
      link = latest_link
      puts "Blog updated - sending notifications"
      @client = Twilio::REST::Client.new config['account_sid'], config['auth_token']
      config['recipients'].each do |num|
        @client.account.messages.create({
          :to => num,
          :from => config['from'],
          :body => latest_link
        })
      end
    end
  rescue OpenURI::HTTPError => error
    response = error.io
    puts response.status
    puts response.string
  rescue Net::ReadTimeout => error
    response = error.io
    puts response.status
    puts response.string  
  end
  sleep config['sleep']
end
