require 'open-uri'
require 'nokogiri'
require 'sqlite3'
require 'pry'
 
# DB Init
db = SQLite3::Database.new 'scrape.db'

students_table = db.execute_batch <<-SQL
  create table students(
    id INTEGER PRIMARY KEY,
    name TEXT,
    tagline TEXT,
    short TEXT,
    aspirations TEXT,
    interests TEXT
  );
  create table social (
    id INTEGER PRIMARY KEY,
    student_id INTEGER,
    name TEXT,
    href TEXT
  );
  create table work (
    id INTEGER PRIMARY KEY,
    student_id INTEGER,
    link TEXT
  );
  create table education (
    id INTEGER PRIMARY KEY,
    student_id INTEGER,
    name TEXT,
    href TEXT
  );
  create table cred (
    id INTEGER PRIMARY KEY,
    student_id INTEGER,
    href TEXT
  );
SQL
 
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
 
  # def self.create_table
  #   @@db.execute "CREATE TABLE #{@tableName} (#{self.columns_for_sql});"
  # end
 


  # self.create_table
  rows = @@db.execute( "select * from students" )
 
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

end

binding.pry
 
url = 'http://students.flatironschool.com/'
 
doc = Nokogiri::HTML(open("#{url}"))
 
front_page = doc.css('.name-position').collect { |s| s.parent['href'] }
 
hella_students = []
 