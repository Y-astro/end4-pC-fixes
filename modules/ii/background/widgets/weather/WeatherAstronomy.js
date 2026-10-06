// WeatherAstronomy.js - Solar time-of-day brightness, temperature attenuation, and lunar phase calculation

.pragma library

function getMoonPhase(date) {
    var now = date || new Date();
    // Reference new moon: 2000-01-06T18:14:00Z
    var ref = Date.UTC(2000, 0, 6, 18, 14, 0);
    var days = (now.getTime() - ref) / 86400000;
    var synodic = 29.53058867;
    var phase = (days % synodic) / synodic;
    if (phase < 0) phase += 1;

    // Illumination fraction (0 = new moon, 1 = full moon)
    var illum = (1 - Math.cos(2 * Math.PI * phase)) / 2;
    var idx = Math.round(phase * 8) % 8;
    var waxing = phase < 0.5;

    var names = [
        "New Moon", "Waxing Crescent", "First Quarter", "Waxing Gibbous",
        "Full Moon", "Waning Gibbous", "Last Quarter", "Waning Crescent"
    ];

    return {
        index: idx,
        name: names[idx],
        fraction: illum,
        waxing: waxing,
        illumPercent: Math.round(illum * 100),
        cycleFraction: phase
    };
}

function parseTimeString(str) {
    if (!str || str === "0") return null;
    var m = str.match(/(\d+):(\d+)\s*(am|pm)?/i);
    if (!m) return null;
    var h = parseInt(m[1]);
    var min = parseInt(m[2]);
    var meridiem = (m[3] || "").toLowerCase();
    if (meridiem === "pm" && h < 12) h += 12;
    if (meridiem === "am" && h === 12) h = 0;
    return h * 60 + min;
}

function getSolarTimes(weatherData, date, simulatedHour) {
    var now = date || new Date();
    var riseMinutes = 6 * 60; // 6:00 AM default
    var setMinutes = 18 * 60 + 15; // 6:15 PM default

    if (weatherData) {
        if (weatherData.sunriseUnix && weatherData.sunsetUnix) {
            var rDate = new Date(weatherData.sunriseUnix * 1000);
            var sDate = new Date(weatherData.sunsetUnix * 1000);
            riseMinutes = rDate.getHours() * 60 + rDate.getMinutes();
            setMinutes = sDate.getHours() * 60 + sDate.getMinutes();
        } else if (weatherData.sunrise && weatherData.sunset) {
            var r = parseTimeString(weatherData.sunrise);
            var s = parseTimeString(weatherData.sunset);
            if (r !== null) riseMinutes = r;
            if (s !== null) setMinutes = s;
        }
    }

    var nowMinutes = (simulatedHour !== undefined && simulatedHour !== null && simulatedHour >= 0)
        ? (simulatedHour * 60)
        : (now.getHours() * 60 + now.getMinutes() + now.getSeconds() / 60);

    var isDay = (nowMinutes >= riseMinutes && nowMinutes < setMinutes);

    if (!isDay) {
        return {
            isDay: false,
            brightness: 0.0,
            riseMinutes: riseMinutes,
            setMinutes: setMinutes,
            nowMinutes: nowMinutes
        };
    }

    // Solar peak: between 12:00 PM and 1:00 PM (12:30 PM = 750 min)
    var peakMinutes = 12.5 * 60;
    var brightness = 0.25;

    if (nowMinutes <= peakMinutes) {
        // Sunrise -> Noon/1 PM: gradually climbs from 0.25 to 1.0
        var pRise = Math.max(0, Math.min(1, (nowMinutes - riseMinutes) / (peakMinutes - riseMinutes)));
        brightness = 0.25 + 0.75 * Math.sin(pRise * (Math.PI / 2));
    } else {
        // Noon/1 PM -> Sunset: gradually decreases from 1.0 to 0.25
        var pSet = Math.max(0, Math.min(1, (nowMinutes - peakMinutes) / (setMinutes - peakMinutes)));
        brightness = 1.0 - 0.75 * Math.sin(pSet * (Math.PI / 2));
    }

    return {
        isDay: true,
        brightness: Math.max(0.20, Math.min(1.0, brightness)),
        riseMinutes: riseMinutes,
        setMinutes: setMinutes,
        nowMinutes: nowMinutes
    };
}

function getTemperatureFactor(tempNum, useUSCS) {
    if (tempNum === undefined || tempNum === null || isNaN(tempNum)) return 1.0;
    var c = tempNum;
    if (useUSCS) c = (c - 32) * 5 / 9; // convert °F to °C

    // Cool temperature attenuation:
    // >= 30°C: 1.0 (full radiance)
    // ~20°C: ~0.67 (noticeably dimmer)
    // <= 12°C: 0.40 (faint winter rays)
    if (c >= 30) return 1.0;
    if (c <= 12) return 0.40;
    return 0.40 + 0.60 * ((c - 12) / 18);
}
