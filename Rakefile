require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "httparty"
require "nokogiri"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :scrape do
  DEFAULT_PASSWORDS_BASE_URI = "https://cirt.net/passwords"
  print "[*] Requesting #{DEFAULT_PASSWORDS_BASE_URI}... "
  response = HTTParty.get(DEFAULT_PASSWORDS_BASE_URI)
  if response.code != 200
    puts "Failed"
    puts "[-] #{DEFAULT_PASSWORDS_BASE_URI} returned: #{response.code} #{response.message}"
    exit(1)
  end
  puts "Done"

  doc = Nokogiri::HTML(response.body)
  vendors = doc.css("table td a")
  credentials = []
  puts "[*] Found #{vendors.count} vendors on page."

  vendors.each do |vendor|
    url, name = "#{DEFAULT_PASSWORDS_BASE_URI}#{vendor.attr("href")}", vendor.text
    print "[*] Requesting #{url}... "
    response = HTTParty.get(url)
    if response.code != 200
      puts "Failed"
      puts "[-] #{url} returned: #{response.code} #{response.message}"
      exit(1)
    end
    puts "Done"

    doc = Nokogiri::HTML(response.body)
    count = doc.css("table").count
    if count.zero?
      "[-] No credentials for #{name}"
      next
    end
    print "[*] Collecting #{count} #{count == 1 ? 'credential' : 'credentials'} for #{name}... "
    doc.css("table").each do |cred_table|
      cred_name  = cred_table.css("h3").text.split(" - ", 2).last
      credential = {"Vendor" => name, "Name" => cred_name}
      cred_table.css("tr").each do |tr|
        tds = tr.css("td")
        next unless tds.count == 2
        attribute = tds.first.text
        value     = tds.last.text
        credential[attribute] = value
      end
      credentials << credential
    end
    puts "Done"
    sleep 0.5
  end

  print "[*] Writing credentials to credentials.json... "
  File.open("credentials.json", "w") do |f|
    f.write(JSON.pretty_generate(credentials))
  end
  puts "Done"
  puts "[*] Scraping complete!"
end
