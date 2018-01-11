class WeatherGov
    def initialize(config)
        @config = config
        @config["coords"] = @config["coords"].strip.split(',').map{ |x| Float(x).round(4) }
    end

    def get_http(url)
        http = Net::HTTP.new(URI.parse(url).host, URI.parse(url).port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(url)
        request['User-Agent'] = 'sail-alert/0.1'
        response = http.request(request)
        return JSON.parse(response.body)
    end

    def get_hourly_forecast()
        # curl https://api.weather.gov/points/33.9556,-118.4548 | jq -r '.["properties"]["forecastHourly"]'
        # http://api.weather.gov/gridpoints/LOX/146,41/forecast/hourly
        # curl -L http://api.weather.gov/gridpoints/LOX/146,41/forecast/hourly | jq '.properties.periods'
        #
        # For some reason, their service returns the forecast url from the points api as http, then redirects you to https
        url = get_http("https://api.weather.gov/points/#{@config['coords'][0]},#{@config['coords'][1]}")["properties"]["forecastHourly"].gsub(/^http:/, "https:")
        return get_http(url)["properties"]["periods"]
    end

    def check_filters(conditions)
        # check_filters method checks filter on each period of weather condition
        # In the case of api.weather.gov that's a 1hr period
        #
        # check temperatures
        if conditions["temperature"] < @config["temperature"]["max"] and conditions["temperature"] > @config["temperature"]["min"]
            # check wind speed
            ## possible input values
            ### 10 to 15 mph
            ### 10 mph
            # check if wind speed is a range
            if /[0-9]+ to [0-9]+ mph/.match?(conditions["windSpeed"])
                windspeeds = conditions["windSpeed"].split(' to ').map{ |x| x.gsub(/mph/, '').strip.to_i }
                if windspeeds[0] >= @config["wind"]["min"] and windspeeds[1] <= @config["wind"]["max"]
                    return true
                end
            else
                windspeed = conditions["windSpeed"].gsub(/ mph$/, '').to_i
                if windspeed <= @config["wind"]["max"] and windspeed >= @config["wind"]["min"]
                    return true
                end
            end
        end
        return false
    end

    def get_acceptable_dates()
        hourly_forecast = get_hourly_forecast()
        acceptable_dates = Hash.new
        hourly_forecast.each_with_index { |v, i|
            # Check if current conditions are good
            if check_filters(v)
                # current conditions are good, check next couple hours (configured with duration)
                good_conditions = 0
                (1..@config["duration"]).each do |x|
                    # check if we should continue looking
                    if i+x > hourly_forecast.length-1
                        break
                    end
                    if check_filters(hourly_forecast[i+x])
                        good_conditions += 1
                    end
                end
                if good_conditions.eql?(@config["duration"])
                    if ! acceptable_dates.keys.include? DateTime.parse(v['startTime']).to_date.to_s
                        acceptable_dates[DateTime.parse(v['startTime']).to_date.to_s] = Array.new
                    end
                    result_hash = Hash.new
                    result_hash['timestamp'] = v['startTime']
                    result_hash['temperature'] = v['temperature']
                    result_hash['wind_speed'] = v['windSpeed']
                    result_hash['wind_direction'] = v['windDirection']
                    acceptable_dates[DateTime.parse(v['startTime']).to_date.to_s].push(result_hash)
                end
            end
        }
        return acceptable_dates
    end

end
