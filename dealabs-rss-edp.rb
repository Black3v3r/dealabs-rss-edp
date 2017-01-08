require 'xmlsimple'
require 'net/http'
require 'fileutils'
require 'json'

path = File.dirname __FILE__

uri = URI('https://www.dealabs.com/forums/les-deals/produits-intressants--bons-prix/le-topic-des-erreurs-de-prix-/641.xml')
response = nil
Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
  request = Net::HTTP::Get.new uri
  response = http.request request # Net::HTTPResponse object
end
xml = XmlSimple.xml_in(response.body)

unless File.exist? File.join path, 'config.json'
  FileUtils.copy File.join(path, 'config.json.default'), File.join(path, 'config.json')
end

config = JSON.parse IO.read(File.join path, 'config.json').strip

Autoremote_api_key = config['autoremote-api-key']

def notify(guid, title, text, url)
  uri = URI('https://autoremotejoaomgcd.appspot.com/sendnotification')
  params = {
      :key => Autoremote_api_key,
      :icon => 'https://pbs.twimg.com/profile_images/479273552596574209/Udxh8Fq-.png',
      :led => '#FFA500',
      :id => guid,
      :title => title,
      :text => text,
      :url => url,
      :statusbaricon => 'collections_label'
  }
  uri.query = URI.encode_www_form(params)
  Net::HTTP.get_response(uri)
end

unless File.exist? File.join(path, 'last.txt')
  IO.write(File.join(path, 'last.txt'), '0')
end

last = IO.read(File.join path, 'last.txt').strip.to_i
puts "last: #{last}"

items = xml['channel'][0]['item']
max = last
items.each do |item|
  guid = item['guid'][0]['content'].scan(/\/([0-9]+)$/)[0][0].to_i
  desc = item['description'][0].gsub(' (lien sur le site)', '').gsub(/\[img.+?\]/, '').gsub(/\n+/, ' ')[0, 150].strip
  # puts desc[0]
  if desc[0] != '[' and guid > last
    url = item['link']
    puts '======================================='
    puts guid
    puts desc
    puts url
    notify(guid, 'Nouvelle erreur de prix', desc, url)
    max = [guid, max].max
  end
end

IO.write(File.join(path, 'last.txt'), max.to_s)