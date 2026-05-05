import { Router } from 'express';
import prisma from '../lib/prisma.js';
import { authMiddleware, AuthRequest } from '../middleware/auth.js';

const router = Router();

router.post('/remove-bg', authMiddleware, async (req: AuthRequest, res) => {
  try {
    const { imageUrl } = req.body;
    const resultUrl = await processBackgroundRemoval(imageUrl);
    res.json({
      success: true,
      resultUrl,
      segments: []
    });
  } catch (error) {
    console.error('Remove background error:', error);
    res.status(500).json({ error: 'AI processing failed' });
  }
});

router.post('/classify-body', authMiddleware, async (req: AuthRequest, res) => {
  try {
    const { height, weight } = req.body;

    if (!height || !weight) {
      return res.status(400).json({ error: 'Height and weight are required' });
    }

    const bmi = weight / Math.pow(height / 100, 2);
    let bodyType = 'standard';
    let confidence = 0.85;

    if (bmi < 18.5) {
      bodyType = 'lean';
      confidence = bmi < 16 ? 0.92 : 0.85;
    } else if (bmi < 24) {
      bodyType = 'standard';
      confidence = bmi >= 20 && bmi <= 23 ? 0.91 : 0.82;
    } else if (bmi < 28) {
      bodyType = 'athletic';
      confidence = 0.87;
    } else {
      bodyType = 'heavy';
      confidence = bmi >= 30 ? 0.93 : 0.84;
    }

    res.json({
      success: true,
      bodyType,
      confidence,
      bmi: Math.round(bmi * 10) / 10
    });
  } catch (error) {
    console.error('Classify body error:', error);
    res.status(500).json({ error: 'AI classification failed' });
  }
});

router.get('/weather', async (req, res) => {
  try {
    const { lat, lon, city } = req.query;

    let weatherData = getMockWeatherData(city as string || 'default');
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
    res.status(500).json({ error: 'Failed to fetch weather' });
  }
});

router.post('/match-outfit', authMiddleware, async (req: AuthRequest, res) => {
  try {
    const userId = req.userId!;
    const { weather, occasion, clothes } = req.body;

    const userClothes = await prisma.cloth.findMany({ where: { userId } });

    const tops = userClothes.filter((c: any) => c.type === 'top');
    const bottoms = userClothes.filter((c: any) => c.type === 'bottom');
    const shoes = userClothes.filter((c: any) => c.type === 'shoes');

    const recommendations = getOutfitRecommendations(weather, occasion, tops, bottoms, shoes);

    res.json({
      success: true,
      matchedOutfit: recommendations
    });
  } catch (error) {
    console.error('Match outfit error:', error);
    res.status(500).json({ error: 'AI matching failed' });
  }
});

interface WeatherData {
  temp: number;
  condition: string;
  humidity: number;
  wind: number;
  description: string;
}

function getMockWeatherData(city: string): WeatherData {
  const weatherMap: Record<string, WeatherData> = {
    beijing: { temp: 18, condition: 'sunny', humidity: 45, wind: 12, description: '晴朗' },
    shanghai: { temp: 22, condition: 'cloudy', humidity: 65, wind: 8, description: '多云' },
    guangzhou: { temp: 28, condition: 'rainy', humidity: 80, wind: 15, description: '小雨' },
    shenzhen: { temp: 27, condition: 'thunderstorm', humidity: 85, wind: 20, description: '雷阵雨' },
    chengdu: { temp: 20, condition: 'cloudy', humidity: 70, wind: 6, description: '阴天' },
    hangzhou: { temp: 24, condition: 'rainy', humidity: 75, wind: 10, description: '中雨' }
  };
  return weatherMap[city.toLowerCase()] || { temp: 22, condition: 'sunny', humidity: 55, wind: 10, description: '晴朗' };
}

function getClothingRecommendations(weather: WeatherData): string[] {
  const recommendations: string[] = [];
  const { temp, condition, wind } = weather;

  if (temp < 10) {
    recommendations.push('coat', 'sweater', 'scarf', 'gloves');
  } else if (temp < 18) {
    recommendations.push('jacket', 'hoodie', 'long_sleeve');
  } else if (temp < 26) {
    recommendations.push('tshirt', 'polo', 'light_jacket');
  } else {
    recommendations.push('tshirt', 'shorts', 'sandal');
  }

  if (condition === 'rainy' || condition === 'thunderstorm') {
    recommendations.push('raincoat', 'waterproof_shoes');
  }

  if (wind > 20) {
    recommendations.push('windbreaker');
  }

  return recommendations;
}

interface OutfitRecommendation {
  clothes: any[];
  style: string;
  score: number;
}

function getOutfitRecommendations(
  weather: string | undefined,
  occasion: string | undefined,
  tops: any[],
  bottoms: any[],
  shoes: any[]
): OutfitRecommendation {
  if (tops.length === 0 || bottoms.length === 0) {
    return { clothes: [], style: 'casual', score: 0 };
  }

  let style = 'korean';
  if (occasion === 'business') style = 'business';
  else if (occasion === 'sport') style = 'sporty';
  else if (weather === 'rainy') style = 'casual';

  const selectedTop = tops[Math.floor(Math.random() * tops.length)];
  const selectedBottom = bottoms[Math.floor(Math.random() * bottoms.length)];
  const selectedShoes = shoes.length > 0 ? shoes[Math.floor(Math.random() * shoes.length)] : null;

  const clothes = selectedShoes
    ? [selectedTop, selectedBottom, selectedShoes]
    : [selectedTop, selectedBottom];

  return {
    clothes,
    style,
    score: 0.85 + Math.random() * 0.1
  };
}

async function processBackgroundRemoval(imageUrl: string): Promise<string> {
  const apiKey = process.env.BAIDU_AK_ID;
  const secretKey = process.env.BAIDU_AK_SECRET;

  if (!apiKey || !secretKey) {
    console.log('[AI] Baidu API not configured, returning original URL');
    return imageUrl;
  }

  try {
    const tokenResponse = await fetch(
      `https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials&client_id=${apiKey}&client_secret=${secretKey}`
    );
    const tokenData = await tokenResponse.json() as { access_token?: string };
    const accessToken = tokenData.access_token;

    if (!accessToken) {
      console.log('[AI] Failed to get access token');
      return imageUrl;
    }

    const apiUrl = `https://aip.baidubce.com/rest/2.0/image-classify/v1/body_segment?access_token=${accessToken}`;

    const imageData = imageUrl.startsWith('data:') ? imageUrl : await fetch(imageUrl).then(r => r.arrayBuffer()).then(buffer => Buffer.from(buffer).toString('base64'));

    const formData = new URLSearchParams();
    formData.append('image', imageData);

    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: formData
    });

    const data = await response.json() as { results?: Array<{ foreground?: string }> };

    if (data.results && data.results[0]?.foreground) {
      return data.results[0].foreground;
    }

    console.log('[AI] Baidu API returned no result');
    return imageUrl;
  } catch (error) {
    console.error('[AI] Baidu API error:', error);
    return imageUrl;
  }
}

export default router;