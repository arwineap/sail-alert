class OpenWeather
    def initialize(config)
        @config = config
    end

    def get_http(url)
        http = Net::HTTP.new(URI.parse(url).host, URI.parse(url).port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(url)
        request['User-Agent'] = 'sail-alert/0.1'
        response = http.request(request)
        return JSON.parse(response.body)
    end

    def convert_kelvin_to_fahrenheit(kelvin)
        fahrenheit = kelvin * 9 / 5 - 459.67
        return fahrenheit
    end

    def convert_meters_to_knots(meters)
        # converts meters per hour to knots
        return meters*1.94384
    end

    def convert_meters_to_mph(meters)
        return meters*2.23694
    end

    def get_forecast()
        # curl "https://api.openweathermap.org/data/2.5/forecast?lat=35&lon=139&appid=APPID"
        #puts "https://api.openweathermap.org/data/2.5/forecast?lat=#{@config['coords'][0]}&lon=#{@config['coords'][1]}&appid=#{@config['source']['key']}"
        return get_http("https://api.openweathermap.org/data/2.5/forecast?lat=#{@config['coords'][0]}&lon=#{@config['coords'][1]}&appid=#{@config['source']['key']}")['list']
    end

    def check_filters(conditions)
        # check_filters method checks filters on each period of weather condition
        # In the case of openweather that's a 3hr period
        #
        # check temperatures
        if convert_kelvin_to_fahrenheit(conditions["main"]["temp_max"]) < @config["temperature"]["max"] and convert_kelvin_to_fahrenheit(conditions["main"]["temp_min"]) > @config["temperature"]["min"]
            # check wind speed
            if convert_meters_to_mph(conditions["wind"]["speed"]) <= @config["wind"]["max"] and convert_meters_to_mph(conditions["wind"]["speed"]) >= @config["wind"]["min"]
                return true
            end
        end
        return false
    end

    def get_acceptable_dates()
        period_forecast = get_forecast()
        acceptable_dates = Hash.new
        period_forecast.each_with_index { |v, i|
            # check if current conditions are good
            if check_filters(v)
                # current conditions are good, check next couple periods (configured with duration)
                good_conditions = 0
                (1..@config["duration"]).each do |x|
                    # check if we should continue looking
                    if i+x > period_forecast.length-1
                        break
                    end
                    if check_filters(period_forecast[i+x])
                        good_conditions += 1
                    end
                end
                if good_conditions.eql?(@config["duration"])
                    if ! acceptable_dates.keys.include? DateTime.parse(v['dt_txt']).to_date.to_s
                        acceptable_dates[DateTime.parse(v['dt_txt']).to_date.to_s] = Array.new
                    end
                    # convert units before sending back to sail-alert
                    result_hash = Hash.new
                    result_hash['timestamp'] = v['dt_txt']
                    result_hash['temperature'] = convert_kelvin_to_fahrenheit(v['main']['temp'])
                    result_hash['wind_speed'] = convert_meters_to_knots(v['wind']['speed'])
                    result_hash['wind_direction'] = v['wind']['direction']
                    acceptable_dates[DateTime.parse(v['dt_txt']).to_date.to_s].push(result_hash)
                end
            end
        }
        return acceptable_dates
    end

end
