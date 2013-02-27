require 'open-uri'
require 'nokogiri'
require 'data_mapper'
require 'dm-sqlite-adapter'
require 'pry'

ENV['DATABASE_URL'] ||= "sqlite://#{Dir.pwd}/students.db"

DataMapper.setup(:default, ENV['DATABASE_URL'])

DataMapper.auto_migrate!

class Student
  include DataMapper::Resource

  property :id, Serial
  property :image, String
  property :name, String
  property :tagline, String
  property :short, Text
  property :aspirations, Text
  property :interests, Text
  property :slug, String
  property :social, Text
  property :coder_cred, Text

  def self.slugify_students
    Student.all.each do |student|
      if student.name
        student.slugify!
        puts "Slugified #{student.name} into #{student.slug}"
      end
    end
  end

  def slugify!
    self.slug = name.downcase.gsub(" ", "-")
    self.save
  end

  @@url = 'http://students.flatironschool.com/'
  @@root_doc = Nokogiri::HTML(open(@@url))

  def self.pull_student_links
    @@links = @@root_doc.css('.columns').css('a').collect { |s| s['href'] }
  end

  def self.pull_all_student_profiles
    self.pull_student_links
    @@links.each { |link| self.new_from_url(@@url + link) }
  end

  def self.get_page(link)
    begin
      html = open(link)
      Nokogiri::HTML(html)
    rescue => e
      puts "Failed to open #{link} because of #{e}"
    end
  end

  def self.new_from_url(url)
    begin
      doc = self.get_page(url)
      self.create(self.get_text_content(doc))
    rescue => e 
      puts "new_from_url error because of #{e}"
    end
  end

  def self.get_text_content(doc)
    content_paths = {
      :name => '#about h1',
      :tagline => '#about h2',
      :short => '#about h2 + p',
      :aspirations => '#about h3 + p',
      :interests => '#about h3 + p + h3 + p'
    }  
    result = {}
    content_paths.each do |key, value|
      begin
        # ("#{key}=",doc.css(value).text)
        result[key] = doc.css(value).text

      rescue Exception => e
       puts "Scrape error for content key: #{key} error: #{e}"
      end 
    end
    result[:image] ||= get_image_content(doc)
    result[:social] ||= get_social_content(doc)
    result[:coder_cred] ||= get_coder_cred_content(doc)
    result
  end

  def self.get_image_content(doc)
    begin
      image = doc.css("#about img")[0]['src']
    rescue Exception => e
      puts "Scrape error for image error: #{e}" 
    end    
  end
  
  def self.get_social_content(doc)
    social_link_elements = doc.css("div.social_icons i")
    social_links = Hash.new
    social_link_elements.each do|i_element|
      begin
        link_type = i_element['class'].gsub("icon-", "")
        link_href = i_element.parent['href']
        social_links[link_type.to_sym] = link_href
      rescue Exception => e
        puts "Scrape error for social error: #{e}" 
      end   
    end    
    social_links  
  end
  
  def self.get_coder_cred_content(doc)
    begin
    coder_cred = {
      :github => doc.css('section#coder-cred table a')[0]['href'], 
      :treehouse => doc.css('section#coder-cred table a')[1]['href'],
      :codeschool => doc.css('section#coder-cred table a')[3]['href'],
      :coderwall => doc.css('section#coder-cred table a')[4]['href'],
      :blog => doc.css('section#coder-cred div p a')[0]['href'],
      :presentation => doc.css("section#coder-cred iframe")[0]["src"]
    }
    rescue Exception => e
      puts "Scrape error for coder cred error: #{e}"
    end  
  end       

  def self.find_by_name(name)
    self.first(:name=>name)
  end

  def self.find(id)
    self.get(id)
  end

end

DataMapper.finalize
DataMapper.auto_upgrade!

binding.pry
