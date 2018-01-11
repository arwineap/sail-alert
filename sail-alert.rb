require 'net/http'
require 'date'
require 'json'
require 'pry'

config = JSON.parse(File.read('./config.json').strip)
if config['source']['type'].strip == 'openweather'
    require_relative 'openweather/forecast'
    forecaster = OpenWeather.new( config )
else
    require_relative 'weathergov/forecast'
    forecaster = WeatherGov.new( config )
end

acceptable_dates = forecaster.get_acceptable_dates()
acceptable_dates.keys.each do |k|
    puts k
    acceptable_dates[k].each do |x|
        puts "  #{x['timestamp']} #{x['temperature']}F #{x['wind_speed']} #{x['wind_direction']}"
    end
    puts "---"
end
