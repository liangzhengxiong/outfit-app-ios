import { Router } from 'express';
import prisma from '../lib/prisma.js';
import { authMiddleware, AuthRequest } from '../middleware/auth.js';

type OutfitStyle = 'korean' | 'japanese' | 'business' | 'sweet_cool' | 'vintage' | 'minimalist' | 'sporty';

const router = Router();

router.use(authMiddleware);

router.get('/', async (req: AuthRequest, res) => {
  try {
    const userId = req.userId!;
    const { limit = 20 } = req.query;

    const outfits = await prisma.outfit.findMany({
      where: { userId },
      include: {
        clothes: {
          include: { cloth: true }
        }
      },
      take: Number(limit),
      orderBy: { createdAt: 'desc' }
    });

    const formatted = outfits.map(o => ({
      id: o.id,
      name: o.name,
      style: o.style,
      weather: o.weather,
      occasion: o.occasion,
      clothes: o.clothes.map(oc => oc.cloth),
      createdAt: o.createdAt
    }));

    res.json({ outfits: formatted, total: formatted.length });
  } catch (error) {
    console.error('Fetch outfits error:', error);
    res.status(500).json({ error: 'Failed to fetch outfits' });
  }
});

router.post('/generate', async (req: AuthRequest, res) => {
  try {
    const userId = req.userId!;
    const { style, weather, occasion } = req.body;

    const userClothes = await prisma.cloth.findMany({
      where: { userId },
      include: { outfits: true }
    });

    const tops = userClothes.filter((c: any) => c.type === 'top');
    const bottoms = userClothes.filter((c: any) => c.type === 'bottom');
    const shoes = userClothes.filter((c: any) => c.type === 'shoes');

    const matchedTop = tops.length > 0 ? tops[Math.floor(Math.random() * tops.length)] : null;
    const matchedBottom = bottoms.length > 0 ? bottoms[Math.floor(Math.random() * bottoms.length)] : null;
    const matchedShoes = shoes.length > 0 ? shoes[Math.floor(Math.random() * shoes.length)] : null;

    const selectedClothes = [matchedTop, matchedBottom, matchedShoes].filter((c: any): c is NonNullable<typeof c> => c !== null);

    if (selectedClothes.length === 0) {
      return res.json({
        success: true,
        outfit: {
          id: null,
          name: '智能穿搭方案',
          style: style || 'korean',
          weather,
          occasion,
          clothes: [],
          message: '请先添加衣物到衣橱'
        }
      });
    }

    const outfit = await prisma.outfit.create({
      data: {
        userId,
        name: `${style === 'korean' ? '韩系' : style === 'japanese' ? '日系' : style === 'business' ? '通勤' : '时尚'}穿搭`,
        style: (style || 'korean') as OutfitStyle,
        weather: weather || null,
        occasion: occasion || null,
        clothes: {
          create: selectedClothes.map((cloth, index) => ({
            clothId: cloth.id,
            position: index
          }))
        }
      },
      include: {
        clothes: {
          include: { cloth: true }
        }
      }
    });

    const formatted = {
      id: outfit.id,
      name: outfit.name,
      style: outfit.style,
      weather: outfit.weather,
      occasion: outfit.occasion,
      clothes: outfit.clothes.map(oc => oc.cloth)
    };

    res.json({ success: true, outfit: formatted });
  } catch (error) {
    console.error('Generate outfit error:', error);
    res.status(500).json({ error: 'Failed to generate outfit' });
  }
});

router.post('/', async (req: AuthRequest, res) => {
  try {
    const userId = req.userId!;
    const { name, style, weather, occasion, clothIds } = req.body;

    if (!name || !style || !clothIds || !Array.isArray(clothIds)) {
      return res.status(400).json({ error: 'Name, style, and clothIds are required' });
    }

    const outfit = await prisma.outfit.create({
      data: {
        userId,
        name,
        style: style as OutfitStyle,
        weather: weather || null,
        occasion: occasion || null,
        clothes: {
          create: clothIds.map((clothId: string, index: number) => ({
            clothId,
            position: index
          }))
        }
      },
      include: {
        clothes: {
          include: { cloth: true }
        }
      }
    });

    const formatted = {
      id: outfit.id,
      name: outfit.name,
      style: outfit.style,
      weather: outfit.weather,
      occasion: outfit.occasion,
      clothes: outfit.clothes.map(oc => oc.cloth)
    };

    res.json({ success: true, outfit: formatted });
  } catch (error) {
    console.error('Create outfit error:', error);
    res.status(500).json({ error: 'Failed to save outfit' });
  }
});

router.delete('/:id', async (req: AuthRequest, res) => {
  try {
    const { id } = req.params;
    const userId = req.userId!;

    const existing = await prisma.outfit.findFirst({ where: { id, userId } });
    if (!existing) {
      return res.status(404).json({ error: 'Outfit not found' });
    }

    await prisma.outfit.delete({ where: { id } });

    res.json({ success: true });
  } catch (error) {
    console.error('Delete outfit error:', error);
    res.status(500).json({ error: 'Failed to delete outfit' });
  }
});

router.get('/calendar', async (req: AuthRequest, res) => {
  try {
    const userId = req.userId!;
    const { startDate, endDate } = req.query;

    const where: any = { userId };
    if (startDate && endDate) {
      where.date = {
        gte: new Date(startDate as string),
        lte: new Date(endDate as string)
      };
    }

    const records = await prisma.calendarRecord.findMany({
      where,
      include: {
        outfit: {
          include: {
            clothes: {
              include: { cloth: true }
            }
          }
        }
      },
      orderBy: { date: 'desc' }
    });

    const formatted = records.map(r => ({
      id: r.id,
      date: r.date.toISOString().split('T')[0],
      note: r.note,
      outfit: r.outfit ? {
        id: r.outfit.id,
        name: r.outfit.name,
        style: r.outfit.style,
        clothes: r.outfit.clothes.map(oc => oc.cloth)
      } : null
    }));

    res.json({ records: formatted, total: formatted.length });
  } catch (error) {
    console.error('Fetch calendar error:', error);
    res.status(500).json({ error: 'Failed to fetch calendar records' });
  }
});

router.post('/calendar', async (req: AuthRequest, res) => {
  try {
    const userId = req.userId!;
    const { date, outfitId, note } = req.body;

    if (!date) {
      return res.status(400).json({ error: 'Date is required' });
    }

    const record = await prisma.calendarRecord.create({
      data: {
        userId,
        date: new Date(date),
        outfitId: outfitId || null,
        note: note || null
      },
      include: {
        outfit: {
          include: {
            clothes: {
              include: { cloth: true }
            }
          }
        }
      }
    });

    res.json({
      success: true,
      record: {
        id: record.id,
        date: record.date.toISOString().split('T')[0],
        note: record.note,
        outfit: record.outfit ? {
          id: record.outfit.id,
          name: record.outfit.name,
          style: record.outfit.style,
          clothes: record.outfit.clothes.map(oc => oc.cloth)
        } : null
      }
    });
  } catch (error) {
    console.error('Create calendar record error:', error);
    res.status(500).json({ error: 'Failed to add calendar record' });
  }
});

export default router;