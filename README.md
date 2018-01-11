# sail-alert

An attempt to automate finding good days for day sails

*Features*
* min/max temps
* min/max wind speed
* NOAA weather forecasts
* openweathermap support


## NOAA backend config
Example NOAA config:
```
{
    "source": {
        "type": "weathergov",
    },
    "coords": "33.9392946,-118.4993662",
    "wind": {
        "min": 10,
        "max": 20
    },
    "temperature": {
        "min": 40,
        "max": 100
    },
    "duration": 3
}
```
The period that NOAA returns is in 1hr intervals, so with duration of 3 we are looking for 3 consequetive hours with favorable conditions on the water.
The wind speeds that NOAA returns are in 5mph increments, so a filter of 11-14mph will never return results
NOAA forecasts are for whole grids, and thus the coordinates are truncated to 4 decimal places (the highest resolution they support)


## openweathermap backend config
Example openweathermap config:
```
{
    "source": {
        "type": "openweather",
        "key": "XXXXXXXXXXX API KEY XXXXXXXXXXXX"
    },
    "coords": "33.9392946,-118.4993662",
    "wind": {
        "min": 5,
        "max": 20
    },
    "temperature": {
        "min": 40,
        "max": 100
    },
    "duration": 2
}
```
The period that openweathermaps returns is 3 hours; so duration of 2 with openweathermap is looking for a good 6 hour window
The wind speeds in openweathermaps are returned as integers, so you can use any integers for your min/max wind speed
You can get your openweathermap api from here: https://openweathermap.org/appid
