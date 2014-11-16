require 'twilio-ruby'
require 'rss'
require 'yaml'

config = YAML.load_file('blog-check.yaml')
link_file = '.blog-check'

# what's the last link we recorded
link = nil
if File.exist?(link_file)
  File.open(link_file, 'r') do |file|  
    file.each_line do |line|
      link = line
    end
  end
end

# what's the latest link in the RSS feed
latest_link = nil
rss = RSS::Parser.parse(config['url'], false)
links = rss.items.first.links
links.each do |l|
  if l.rel == 'alternate'
    latest_link = l.href
  end
end

if latest_link != link
  # notify
  @client = Twilio::REST::Client.new config['account_sid'], config['auth_token']
  config['recipients'].each do |num|
    @client.account.messages.create({
      :to => num,
      :from => config['from'],
      :body => latest_link
    })
  end

  # update link file  
  File.open(link_file, 'w') do |file|
    puts "updating link"
    file.write(latest_link)  
  end
end
