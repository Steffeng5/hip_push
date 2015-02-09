#!/usr/bin/env ruby -wKU
require 'rubygems'
require 'mechanize'
require 'yaml'

config = YAML.load_file(File.dirname(__FILE__ + '/config.yaml'))

a = Mechanize.new
a.get(config['hip_url']) do |page|
  # Submit the login form
  dashboard = a.current_page.form_with(name: 'loginform') do |f|
  
  	f['asdf'] = config['user']
    f['fdsa'] = config['password']
  	
  end.submit

  dashboard   = a.click(dashboard.link_with(text: /fungsverwaltung/))
  dashboard   = a.click(dashboard.link_with(text: /Notenspiegel/))
  dashboard   = a.click(dashboard.link_with(text: /Abschluss: Bachelor/))
  grades_page = a.click(dashboard.link_with(text: /dualer Bachelor-Studiengang/))

  document      = Nokogiri::HTML(grades_page.content)
  all_modules   = document.xpath('//form/table[2]').search('tr')
  known_modules = File.read('module.txt', {encoding: "UTF-8"})

  all_modules.each do |line|
    status = line.at_xpath('td[5]/text()').to_s.strip
    
    if (status != "angemeldet")
      modul = line.at_xpath('td[2]/text()').to_s.strip
      unless (modul.empty? or known_modules.include?(modul))
        open('module.txt', 'a:UTF-8') do |file|
          file.puts modul
        end

        # Notify students
        ausgabe = "Neue Noten im HIP: " + modul
        #Pushover
        a.post('https://api.pushover.net/1/messages.json', {
          "token" => config['pushover_token'],
          "user" => config['pushover_user'],
          "title" => "Neue Noten!",
          "message" => modul
        })

        #Notify others
        IO.foreach config['access_token_file_path'] do |access_token|
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
