const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const helmet = require('helmet');
const connectDB = require('./config/db');
const { validateEnvironment } = require('./config/envCheck');
const errorHandler = require('./middleware/error');
const { sanitizeInput } = require('./middleware/sanitize');

// Load environment variables
dotenv.config();

// Validate critical security credentials
validateEnvironment();

// Initialize MongoDB connection
connectDB();

const app = express();

// Trust reverse proxy (Render, Cloudflare, load balancers) for accurate client IP rate limiting
app.set('trust proxy', true);

// Security HTTP headers with cross-origin resource policy enabled
app.use(
  helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' },
    contentSecurityPolicy: process.env.NODE_ENV === 'production' ? undefined : false
  })
);

// Strict CORS Origins
const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',').map((o) => o.trim())
  : ['http://localhost:3000', 'http://localhost:5001', 'http://127.0.0.1:5001'];

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow mobile apps, native curl/Postman, or same-origin requests with no origin header
      if (!origin) return callback(null, true);
      if (
        allowedOrigins.includes('*') ||
        allowedOrigins.includes(origin) ||
        process.env.NODE_ENV !== 'production'
      ) {
        return callback(null, true);
      }
      return callback(new Error(`CORS policy violation: Origin ${origin} not permitted.`));
    },
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
    credentials: true,
    maxAge: 86400
  })
);

// Body parser
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// NoSQL query operator sanitizer
app.use(sanitizeInput);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'CampusVoice API',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// Mount Routes
app.use('/api/auth', require('./routes/auth.routes'));
app.use('/api/users', require('./routes/user.routes'));
app.use('/api/categories', require('./routes/category.routes'));
app.use('/api/complaints', require('./routes/complaint.routes'));
app.use('/api/notifications', require('./routes/notification.routes'));
app.use('/api/dashboard', require('./routes/dashboard.routes'));
app.use('/api/jobs', require('./routes/job.routes'));

// Catch-all for undefined routes
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Cannot ${req.method} ${req.originalUrl} - Route not found`
  });
});

// Centralized error handler
app.use(errorHandler);

const PORT = process.env.PORT || 5001;

let server;
if (process.env.NODE_ENV !== 'test') {
  server = app.listen(PORT, () => {
    console.log(`[CampusVoice API] Server running in ${process.env.NODE_ENV || 'development'} mode on port ${PORT}`);
    // Initialize background cron jobs
    const { initEscalationJob } = require('./jobs/escalation.job');
    initEscalationJob();
  });
}

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  console.error(`[Unhandled Rejection] ${err.message}`);
  if (server) {
    server.close(() => process.exit(1));
  } else {
    process.exit(1);
  }
});

module.exports = app;
