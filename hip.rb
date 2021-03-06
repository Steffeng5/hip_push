#!/usr/bin/env ruby -wKU
$VERBOSE = false

require 'rubygems'
require 'mechanize'
require 'yaml'

@config = YAML.load_file(File.dirname(__FILE__) + '/config.yaml')

def login_and_return_gradespage
  a = Mechanize.new
  a.get(@config['hip_url'])

  # Submit the login form
  dashboard = a.current_page.form_with(name: 'loginform') do |f|

    f['asdf'] = @config['user']
    f['fdsa'] = @config['password']

  end.submit

  dashboard   = a.click(dashboard.link_with(text: /fungsverwaltung/))
  dashboard   = a.click(dashboard.link_with(text: /Notenspiegel/))
  dashboard   = a.click(dashboard.link_with(text: /Abschluss: Bachelor/))
  a.click(dashboard.link_with(text: /dualer Bachelor-Studiengang/))
end


def check_for_updates(html_content)
  document     = Nokogiri::HTML(html_content)
  all_modules   = document.xpath('//form/table[2]').search('tr')
  known_modules = File.read(File.dirname(__FILE__) + '/module.txt', {encoding: "UTF-8"})

  all_modules.each do |line|
    status = line.at_xpath('td[5]/text()').to_s.strip

    if (status != "angemeldet")
      modul = line.at_xpath('td[2]/text()').to_s.strip
      unless (modul.empty? or known_modules.include?(modul))
        open(File.dirname(__FILE__) + '/module.txt', 'a:UTF-8') do |file|
          file.puts modul
        end

        a = Mechanize.new
        #Pushover
        a.post('https://api.pushover.net/1/messages.json', {
                 "token" => @config['pushover_token'],
                 "user" => @config['pushover_user'],
                 "title" => "Neue Noten!",
                 "message" => modul
        })


        if (@config['notify_all'] == 'true')
          #Notify others
          IO.foreach @config['access_token_file_path'] do |access_token|
            a.add_auth('https://api.pushbullet.com', access_token.strip, '')
            a.post('https://api.pushbullet.com/v2/pushes', {
                     "type" => "note",
                     "title" => "Neue Noten!",
                     "body" => modul
            })
          end
        end
      end
    end
  end
end

begin
  tries ||= 0
  document = login_and_return_gradespage()
  check_for_updates(document.content)
rescue Exception => e
  tries += 1

  if tries < 3
    retry
  else
    raise Exception.new(e.inspect + "\n-------------------------\n" + e.backtrace.join(" -> "))
  end
end
