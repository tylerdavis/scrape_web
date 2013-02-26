require 'sinatra'
require 'json'
require './student'

get '/' do
  @students = Student.all
  erb :list_view
end

get '/student/:id' do
  @student = Student.get(params['id'])
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
