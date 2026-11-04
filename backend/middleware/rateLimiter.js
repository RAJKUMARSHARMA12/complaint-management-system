const rateLimit = require('express-rate-limit');

/**
 * Authentication rate limiter
 * Enforces strict limits on login endpoint to prevent brute-force credential stuffing.
 * Default: 5 requests per 15-minute window per IP.
 */
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: process.env.LOGIN_RATE_LIMIT_MAX ? parseInt(process.env.LOGIN_RATE_LIMIT_MAX, 10) : 5,
  standardHeaders: true, // Return standard `RateLimit-*` headers
  legacyHeaders: false, // Disable legacy `X-RateLimit-*` headers
  statusCode: 429,
  validate: false,
  message: {
    success: false,
    message: 'Too many login attempts from this IP. Please try again after 15 minutes.'
  },
  skip: (req) => {
    if (process.env.SKIP_RATE_LIMIT === 'true') {
      return true;
    }
    // In automated testing, only apply when ENABLE_TEST_RATE_LIMIT is enabled
    if (process.env.NODE_ENV === 'test' && process.env.ENABLE_TEST_RATE_LIMIT !== 'true') {
      return true;
    }
    return false;
  }
});

/**
 * General API rate limiter for write/sensitive endpoints.
 */
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: process.env.API_RATE_LIMIT_MAX ? parseInt(process.env.API_RATE_LIMIT_MAX, 10) : 100,
  standardHeaders: true,
  legacyHeaders: false,
  statusCode: 429,
  validate: false,
  message: {
    success: false,
    message: 'Too many requests from this IP. Please try again later.'
  },
  skip: (req) => {
    if (process.env.SKIP_RATE_LIMIT === 'true') return true;
    if (process.env.NODE_ENV === 'test' && process.env.ENABLE_TEST_RATE_LIMIT !== 'true') {
      return true;
    }
    return false;
  }
});

module.exports = {
  loginLimiter,
  apiLimiter
};
