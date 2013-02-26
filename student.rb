require 'open-uri'
require 'nokogiri'
require 'data_mapper'
require 'dm-sqlite-adapter'

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
    doc = self.get_page(url)
    self.create(self.get_content(doc))
  end

  def self.get_content(doc)
    content_paths = {
      :name => '#about h1',
      :image => '#about img',
      :tagline => '#about h2',
      :short => '#about h2 + p',
      :aspirations => '#about h3 + p',
      :interests => '#about h3 + p + h3 + p'
    }
    result = {}
    content_paths.each do |key, value|
      begin
        # ("#{key}=",doc.css(value).text)
        if key == :image
          result[key] = doc.css(value)[0]['src']
        else
          result[key] = doc.css(value).text
        end

      rescue Exception => e
       puts "Scrape error for content key: #{key} error: #{e}"
      end
    end
    result
  end

  def self.find_by_name(name)
    self.first(:name=>name)
  end

  def self.find(id)
    self.get(id)
  end

end

binding.pry

DataMapper.finalize
DataMapper.auto_upgrade!
