import { Router } from 'express';

const router = Router();

interface WeatherResponse {
  temp: number;
  condition: string;
  humidity: number;
  wind: number;
  description: string;
}

const MOCK_WEATHER_DB: Record<string, WeatherResponse> = {
  'beijing': { temp: 18, condition: 'sunny', humidity: 45, wind: 12, description: '晴朗' },
  'shanghai': { temp: 22, condition: 'cloudy', humidity: 65, wind: 8, description: '多云' },
  'guangzhou': { temp: 28, condition: 'rainy', humidity: 80, wind: 15, description: '小雨' },
  'shenzhen': { temp: 27, condition: 'thunderstorm', humidity: 85, wind: 20, description: '雷阵雨' },
  'chengdu': { temp: 20, condition: 'cloudy', humidity: 70, wind: 6, description: '阴天' },
  'hangzhou': { temp: 24, condition: 'rainy', humidity: 75, wind: 10, description: '中雨' },
  'default': { temp: 22, condition: 'sunny', humidity: 55, wind: 10, description: '晴朗' }
};

router.get('/weather', async (req, res) => {
  try {
    const { lat, lon, city } = req.query;

    let weatherData: WeatherResponse;

    if (city && typeof city === 'string') {
      const cityKey = city.toLowerCase();
      weatherData = MOCK_WEATHER_DB[cityKey] || MOCK_WEATHER_DB['default'];
    } else {
      const latNum = parseFloat(lat as string);
      const lonNum = parseFloat(lon as string);

      if (isNaN(latNum) || isNaN(lonNum)) {
        weatherData = MOCK_WEATHER_DB['default'];
      } else {
        const mockCity = getMockCityFromCoords(latNum, lonNum);
        weatherData = MOCK_WEATHER_DB[mockCity] || MOCK_WEATHER_DB['default'];
      }
    }

    const recommendations = getClothingRecommendations(weatherData);

    res.json({
      success: true,
      weather: {
        ...weatherData,
        recommendations,
        timestamp: new Date().toISOString()
      }
    });
  } catch (error) {
    console.error('Weather API error:', error);
    res.status(500).json({ error: 'Failed to fetch weather data' });
  }
});

function getMockCityFromCoords(lat: number, lon: number): string {
  if (lat >= 39 && lat <= 41 && lon >= 115 && lon <= 118) return 'beijing';
  if (lat >= 30 && lat <= 32 && lon >= 120 && lon <= 123) return 'shanghai';
  if (lat >= 22 && lat <= 25 && lon >= 112 && lon <= 115) return 'guangzhou';
  if (lat >= 22 && lat <= 24 && lon >= 113 && lon <= 116) return 'shenzhen';
  return 'default';
}

function getClothingRecommendations(weather: WeatherResponse): string[] {
  const recommendations: string[] = [];
  const temp = weather.temp;

  if (temp < 10) {
    recommendations.push('coat', 'sweater', 'scarf', 'gloves');
  } else if (temp < 18) {
    recommendations.push('jacket', 'hoodie', 'long_sleeve');
  } else if (temp < 26) {
    recommendations.push('tshirt', 'polo', 'light_jacket');
  } else {
    recommendations.push('tshirt', 'shorts', 'sandal');
  }

  if (weather.condition === 'rainy' || weather.condition === 'thunderstorm') {
    recommendations.push('raincoat', 'waterproof_shoes');
  }

  if (weather.wind > 20) {
    recommendations.push('windbreaker');
  }

  return recommendations;
}

export default router;