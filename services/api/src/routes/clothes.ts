import { Router } from 'express';
import prisma from '../lib/prisma.js';
import { authMiddleware, AuthRequest } from '../middleware/auth.js';

type ClothType = 'top' | 'bottom' | 'shoes' | 'accessory';
type SubClothType = 'tshirt' | 'shirt' | 'polo' | 'sweater' | 'jacket' | 'coat' | 'jeans' | 'pants' | 'shorts' | 'sneakers' | 'boots' | 'leather_shoes' | 'watch' | 'bracelet' | 'necklace' | 'hat' | 'belt';
type FitType = 'slim' | 'standard' | 'loose' | 'oversize';

const router = Router();

router.use(authMiddleware);

router.get('/', async (req: AuthRequest, res) => {
  try {
    const { type, subType } = req.query;
    const userId = req.userId!;

    const where: any = { userId };
    if (type) where.type = type as ClothType;
    if (subType) where.subType = subType as SubClothType;

    const clothes = await prisma.cloth.findMany({
      where,
      orderBy: { createdAt: 'desc' }
    });

    res.json({ clothes, total: clothes.length });
  } catch (error) {
    console.error('Fetch clothes error:', error);
    res.status(500).json({ error: 'Failed to fetch clothes' });
  }
});

router.post('/', async (req: AuthRequest, res) => {
  try {
    const userId = req.userId!;
    const { type, subType, size, fit, imageUrl, removedBgUrl } = req.body;

    if (!type || !imageUrl) {
      return res.status(400).json({ error: 'Type and imageUrl are required' });
    }

    const cloth = await prisma.cloth.create({
      data: {
        userId,
        type: type as ClothType,
        subType: (subType || 'tshirt') as SubClothType,
        size: size || 'M',
        fit: (fit || 'standard') as FitType,
        imageUrl,
        removedBgUrl: removedBgUrl || null
      }
    });

    res.json({ success: true, cloth });
  } catch (error) {
    console.error('Create cloth error:', error);
    res.status(500).json({ error: 'Failed to add cloth' });
  }
});

router.put('/:id', async (req: AuthRequest, res) => {
  try {
    const { id } = req.params;
    const userId = req.userId!;
    const updates = req.body;

    const existing = await prisma.cloth.findFirst({ where: { id, userId } });
    if (!existing) {
      return res.status(404).json({ error: 'Cloth not found' });
    }

    const cloth = await prisma.cloth.update({
      where: { id },
      data: {
        ...(updates.type && { type: updates.type as ClothType }),
        ...(updates.subType && { subType: updates.subType as SubClothType }),
        ...(updates.size && { size: updates.size }),
        ...(updates.fit && { fit: updates.fit as FitType }),
        ...(updates.imageUrl && { imageUrl: updates.imageUrl }),
        ...(updates.removedBgUrl !== undefined && { removedBgUrl: updates.removedBgUrl })
      }
    });

    res.json({ success: true, cloth });
  } catch (error) {
    console.error('Update cloth error:', error);
    res.status(500).json({ error: 'Failed to update cloth' });
  }
});

router.delete('/:id', async (req: AuthRequest, res) => {
  try {
    const { id } = req.params;
    const userId = req.userId!;

    const existing = await prisma.cloth.findFirst({ where: { id, userId } });
    if (!existing) {
      return res.status(404).json({ error: 'Cloth not found' });
    }

    await prisma.cloth.delete({ where: { id } });

    res.json({ success: true });
  } catch (error) {
    console.error('Delete cloth error:', error);
    res.status(500).json({ error: 'Failed to delete cloth' });
  }
});

router.post('/remove-bg', async (req: AuthRequest, res) => {
  try {
    const { imageUrl } = req.body;

    const processedUrl = await processBackgroundRemoval(imageUrl);

    res.json({
      success: true,
      resultUrl: processedUrl,
      segments: []
    });
  } catch (error) {
    console.error('Remove background error:', error);
    res.status(500).json({ error: 'Failed to remove background' });
  }
});

async function processBackgroundRemoval(imageUrl: string): Promise<string> {
  const apiKey = process.env.BAIDU_AK_ID;
  const secretKey = process.env.BAIDU_SECRET_KEY;

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

    if (!accessToken) return imageUrl;

    const apiUrl = `https://aip.baidubce.com/rest/2.0/image-classify/v1/body_segment?access_token=${accessToken}`;

    const formData = new URLSearchParams();
    formData.append('image', imageUrl);

    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: formData
    });

    const data = await response.json() as { results?: Array<{ foreground?: string }> };

    if (data.results && data.results[0]?.foreground) {
      return data.results[0].foreground;
    }

    return imageUrl;
  } catch (error) {
    console.error('[AI] Baidu API error:', error);
    return imageUrl;
  }
}

export default router;