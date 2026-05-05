import { Router } from 'express';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { v4 as uuidv4 } from 'uuid';

const router = Router();

const UPLOAD_DIR = path.join(process.cwd(), 'uploads');
const IMAGE_DIR = path.join(UPLOAD_DIR, 'images');

if (!fs.existsSync(UPLOAD_DIR)) {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}
if (!fs.existsSync(IMAGE_DIR)) {
  fs.mkdirSync(IMAGE_DIR, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, IMAGE_DIR);
  },
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname);
    const filename = `${uuidv4()}${ext}`;
    cb(null, filename);
  }
});

const upload = multer({
  storage,
  limits: {
    fileSize: 10 * 1024 * 1024
  },
  fileFilter: (_req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only JPEG, PNG, WebP, and GIF are allowed.'));
    }
  }
});

router.post('/image', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    const imageUrl = `/uploads/images/${req.file.filename}`;

    res.json({
      success: true,
      url: imageUrl,
      filename: req.file.filename,
      size: req.file.size,
      mimetype: req.file.mimetype
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ error: 'Failed to upload image' });
  }
});

router.post('/image/base64', async (req, res) => {
  try {
    const { image, format } = req.body;

    if (!image) {
      return res.status(400).json({ error: 'No image data provided' });
    }

    const base64Data = image.replace(/^data:image\/\w+;base64,/, '');
    const buffer = Buffer.from(base64Data, 'base64');

    const ext = format === 'png' ? 'png' : format === 'webp' ? 'webp' : 'jpg';
    const filename = `${uuidv4()}.${ext}`;
    const filepath = path.join(IMAGE_DIR, filename);

    fs.writeFileSync(filepath, buffer);

    const imageUrl = `/uploads/images/${filename}`;

    res.json({
      success: true,
      url: imageUrl,
      filename,
      size: buffer.length
    });
  } catch (error) {
    console.error('Base64 upload error:', error);
    res.status(500).json({ error: 'Failed to process image' });
  }
});

router.delete('/image/:filename', async (req, res) => {
  try {
    const { filename } = req.params;
    const filepath = path.join(IMAGE_DIR, filename);

    if (fs.existsSync(filepath)) {
      fs.unlinkSync(filepath);
      res.json({ success: true, message: 'Image deleted' });
    } else {
      res.status(404).json({ error: 'Image not found' });
    }
  } catch (error) {
    console.error('Delete error:', error);
    res.status(500).json({ error: 'Failed to delete image' });
  }
});

router.use('/uploads', (_req, _res, next) => {
  next();
}, (_req, res) => {
  const files = fs.readdirSync(IMAGE_DIR);
  res.json({ files, count: files.length });
});

export { IMAGE_DIR };
export default router;