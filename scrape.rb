require 'open-uri'
require 'nokogiri'
require 'sqlite3'
require 'pry'

class Student
 
  ATTRIBUTES = {
    :id => :integer,
    :name => :text,
    :tagline => :text,
    :short => :text,
    :aspirations => :text,
    :interests => :text
  }
 
  @hella_students = []

  def self.all
    @hella_students
  end

  @@db = SQLite3::Database.new('scrape.db')
 
  ATTRIBUTES.each do |attribute, type|
    attr_accessor attribute
  end
 
  def self.attributes
    ATTRIBUTES.keys
  end
 
  def self.attributes_hash
    ATTRIBUTES
  end
 
  def self.table_name
    "students"
  end
 
  @tableName = self.table_name
 
  def self.columns_for_sql
    self.attributes_hash.collect { |k, v| "#{k.to_s.downcase} #{v.to_s.upcase}" }.join(",")
  end
 
  def initialize(options={})
    if options.class == Hash
      options.each { |key, value| instance_variable_set("@#{key}", value) }
    elsif options.class == String
      create_from_url(options)
    end
  end

  def get_page(link)
    begin
      html = open(link) 
      Nokogiri::HTML(html)
    rescue => e
      puts "Failed open #{link} because of #{e}"
    end
  end

  def create_from_url(url)
    @doc = get_page(url)
    get_content()
    self.class.all << self
  end

  def get_content()
    content_paths = {
      :name => '#about h1',
      :tagline => '#about h2',
      :short => '#about p:nth-child(0)',
      :aspirations => '#about p:nth-child(1)',
      :interests => '#about p:nth-child(2)'
    }   

    content_paths.each do |key, value| 
      begin
        # puts key + " " + value
       self.send("#{key}=",@doc.css(value).text) 
      rescue Exception => e
       puts "Scrape error for content key: #{key} error: #{e}"
      end        
    end

  end

  def self.query_count_id_by_name(name)
    query = @@db.execute("SELECT COUNT(*) FROM ? WHERE name = ?", [@tableName, name])
  end

  def self.query_id_by_name(name)
    query = @@db.execute("SELECT id FROM ? WHERE name = ?", [@tableName, name])
    if query[0].length > 0
      return query[0][0]
    end
  end

  def sql_question_marks
    marks = []
    self.attributes.length.times do
      marks << '?'
    end
    marks.join(',')
  end

  def save
    if self.query_count_id_by_name(@name) > 0
      @db.execute(" UPDATE #{@tableName} (#{self.attributes}) VALUES (#{self.sql_question_marks})",
                        [@name, @tagline, @short, @aspirations, @interests, self.query_id_by_name(@name)])
    else # If there's no id, then create a new record
      @db.execute("INSERT INTO students (name, tagline, short, aspirations, interests)
                              VALUES (?, ?, ?, ?, ?);", self.attributes)
      @id = self.query_count_id_by_name(@name) # Once created, set the local id to the db's id
    end
  end
end

binding.pry
 