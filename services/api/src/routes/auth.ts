import { Router } from 'express';
import { z } from 'zod';
import { generateToken } from '../middleware/auth.js';
import prisma from '../lib/prisma.js';
import { v4 as uuidv4 } from 'uuid';

const router = Router();

const loginSchema = z.object({
  phone: z.string().regex(/^1[3-9]\d{9}$/),
  code: z.string().length(6).optional()
});

const SMS_CODES = new Map<string, { code: string; expireAt: Date }>();

function sendSMSCode(phone: string): string {
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  const expireAt = new Date(Date.now() + 5 * 60 * 1000);
  SMS_CODES.set(phone, { code, expireAt });
  console.log(`[SMS] Code for ${phone}: ${code}`);
  return code;
}

function verifyCode(phone: string, code: string): boolean {
  const record = SMS_CODES.get(phone);
  if (!record) return false;
  if (new Date() > record.expireAt) {
    SMS_CODES.delete(phone);
    return false;
  }
  if (record.code !== code) return false;
  SMS_CODES.delete(phone);
  return true;
}

router.post('/send-code', async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone || !/^1[3-9]\d{9}$/.test(phone)) {
      return res.status(400).json({ error: 'Invalid phone number' });
    }
    sendSMSCode(phone);
    res.json({ success: true, message: 'Verification code sent' });
  } catch (error) {
    console.error('Send code error:', error);
    res.status(500).json({ error: 'Failed to send code' });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { phone, code } = req.body;
    if (!phone || !code) {
      return res.status(400).json({ error: 'Phone and code are required' });
    }

    if (!verifyCode(phone, code)) {
      return res.status(400).json({ error: 'Invalid or expired verification code' });
    }

    let user = await prisma.user.findUnique({ where: { phone } });

    if (!user) {
      user = await prisma.user.create({
        data: {
          id: uuidv4(),
          phone,
          nickname: '',
          avatar: ''
        }
      });
    }

    const token = generateToken(user.id);

    res.json({
      success: true,
      token,
      user: {
        id: user.id,
        phone: user.phone,
        nickname: user.nickname,
        avatar: user.avatar
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

router.post('/wechat', async (req, res) => {
  try {
    const { code } = req.body;
    if (!code) {
      return res.status(400).json({ error: 'Code is required' });
    }

    const wechatOpenid = await exchangeCodeForOpenid(code);
    if (!wechatOpenid) {
      return res.status(400).json({ error: 'Invalid WeChat code' });
    }

    let user = await prisma.user.findUnique({ where: { wechatOpenid } });

    if (!user) {
      user = await prisma.user.create({
        data: {
          id: uuidv4(),
          phone: '',
          wechatOpenid,
          nickname: '微信用户',
          avatar: ''
        }
      });
    }

    const token = generateToken(user.id);

    res.json({
      success: true,
      token,
      user: {
        id: user.id,
        nickname: user.nickname,
        avatar: user.avatar
      }
    });
  } catch (error) {
    console.error('WeChat login error:', error);
    res.status(500).json({ error: 'WeChat login failed' });
  }
});

async function exchangeCodeForOpenid(code: string): Promise<string | null> {
  const appId = process.env.WECHAT_APP_ID;
  const appSecret = process.env.WECHAT_SECRET;

  if (!appId || !appSecret) {
    console.log('[WeChat] App ID or Secret not configured, using mock openid');
    return `mock_openid_${code}`;
  }

  try {
    const response = await fetch(
      `https://api.weixin.qq.com/sns/jscode2session?appid=${appId}&secret=${appSecret}&js_code=${code}&grant_type=authorization_code`
    );
    const data = await response.json() as { openid?: string };
    return data.openid || null;
  } catch (error) {
    console.error('[WeChat] Code exchange failed:', error);
    return null;
  }
}

export default router;