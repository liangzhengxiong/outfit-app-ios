import { Router } from 'express';
import prisma from '../lib/prisma.js';
import { authMiddleware, AuthRequest } from '../middleware/auth.js';

const router = Router();

router.use(authMiddleware);

router.get('/me', async (req: AuthRequest, res) => {
  try {
    const userId = req.userId!;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        member: true,
        bodyModel: true
      }
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      id: user.id,
      phone: user.phone,
      nickname: user.nickname,
      avatar: user.avatar,
      height: user.height,
      weight: user.weight,
      bodyType: user.bodyType,
      member: user.member ? {
        level: user.member.level,
        expireAt: user.member.expireAt?.toISOString()
      } : null,
      bodyModel: user.bodyModel ? {
        type: user.bodyModel.type,
        modelId: user.bodyModel.modelId
      } : null
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ error: 'Failed to get user info' });
  }
});

router.put('/me', async (req: AuthRequest, res) => {
  try {
    const userId = req.userId!;
    const { nickname, avatar, height, weight, bodyType } = req.body;

    const user = await prisma.user.update({
      where: { id: userId },
      data: {
        ...(nickname !== undefined && { nickname }),
        ...(avatar !== undefined && { avatar }),
        ...(height !== undefined && { height }),
        ...(weight !== undefined && { weight }),
        ...(bodyType !== undefined && { bodyType })
      }
    });

    res.json({
      success: true,
      user: {
        id: user.id,
        phone: user.phone,
        nickname: user.nickname,
        avatar: user.avatar,
        height: user.height,
        weight: user.weight,
        bodyType: user.bodyType
      }
    });
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({ error: 'Update failed' });
  }
});

router.post('/body-model', async (req: AuthRequest, res) => {
  try {
    const userId = req.userId!;
    const { type, height, weight, chest, waist, hip, modelId } = req.body;

    const bodyModel = await prisma.bodyModel.upsert({
      where: { userId },
      update: {
        type: type || 'template',
        height: height || null,
        weight: weight || null,
        chest: chest || null,
        waist: waist || null,
        hip: hip || null,
        modelId: modelId || 'model-1'
      },
      create: {
        userId,
        type: type || 'template',
        height: height || null,
        weight: weight || null,
        chest: chest || null,
        waist: waist || null,
        hip: hip || null,
        modelId: modelId || 'model-1'
      }
    });

    const matchedModels = await findMatchedModels(bodyModel);

    res.json({
      success: true,
      modelId: bodyModel.modelId,
      matchedModels
    });
  } catch (error) {
    console.error('Create body model error:', error);
    res.status(500).json({ error: 'Failed to create body model' });
  }
});

async function findMatchedModels(bodyModel: any): Promise<string[]> {
  const allModels = await prisma.bodyModel3D.findMany();

  const userBMI = bodyModel.weight && bodyModel.height
    ? bodyModel.weight / Math.pow(bodyModel.height / 100, 2)
    : 22;

  const matched: { modelId: string; score: number }[] = [];

  for (const model of allModels) {
    let score = 0;

    if (model.bodyType === 'lean' && userBMI < 20) score += 2;
    else if (model.bodyType === 'standard' && userBMI >= 18.5 && userBMI < 24) score += 2;
    else if (model.bodyType === 'athletic' && userBMI >= 24 && userBMI < 28) score += 2;
    else if (model.bodyType === 'heavy' && userBMI >= 28) score += 2;

    if (bodyModel.height && model.heightRange) {
      const [min, max] = model.heightRange.split('-').map(Number);
      if (bodyModel.height >= min && bodyModel.height <= max) score += 1;
    }

    matched.push({ modelId: model.modelId, score });
  }

  matched.sort((a, b) => b.score - a.score);
  return matched.slice(0, 3).map(m => m.modelId);
}

export default router;