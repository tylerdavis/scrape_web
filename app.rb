require 'pry'
require 'sinatra'
require 'sinatra/base'
require 'sinatra/reloader'
require 'json'
require './student'


get '/' do
  @students = Student.all
  erb :list_view
end

get '/:slug' do
  @student = Student.first(:slug => params[:slug])
  erb :detail_view
end

get '/migrate' do
  DataMapper.auto_migrate!
  redirect '/'
end

get '/new_date' do
  Student.pull_all_student_profiles
  redirect '/'
end

