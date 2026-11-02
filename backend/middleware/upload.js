const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Determine storage directory for local/Docker media server
const uploadDir = path.resolve(process.env.MEDIA_UPLOAD_DIR || './uploads');

// Ensure upload directory exists
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Local disk storage for Docker media server delivery
const localStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname).toLowerCase();
    const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, `proof-${uniqueSuffix}${ext}`);
  }
});

// File filter enforcing JPEG and PNG formats only
const fileFilter = (req, file, cb) => {
  const allowedMimes = ['image/jpeg', 'image/jpg', 'image/png'];
  if (allowedMimes.includes(file.mimetype.toLowerCase())) {
    cb(null, true);
  } else {
    cb(new Error('Invalid file type. Only JPEG and PNG images are allowed.'), false);
  }
};

// Multer upload middleware enforcing max 3 files and 5 MB per file limit
const upload = multer({
  storage: localStorage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5 MB
    files: 3
  }
});

module.exports = upload;
