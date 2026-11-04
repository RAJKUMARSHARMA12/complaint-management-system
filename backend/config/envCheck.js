/**
 * Environment & Security Credentials Validator
 * Ensures required secrets exist and prevents running with unsafe defaults in production.
 */
const validateEnvironment = () => {
  const isProduction = process.env.NODE_ENV === 'production';
  const warnings = [];
  const errors = [];

  // Check JWT Secret
  const jwtSecret = process.env.JWT_SECRET;
  if (!jwtSecret) {
    if (isProduction) {
      errors.push('JWT_SECRET environment variable is missing.');
    } else {
      warnings.push('JWT_SECRET is not set in .env. Using fallback dev secret.');
    }
  } else if (jwtSecret.includes('super_secret_jwt_key') && isProduction) {
    errors.push('Insecure development JWT_SECRET placeholder used in production mode!');
  }

  // Check Database URI
  if (!process.env.MONGO_URI) {
    if (isProduction) {
      errors.push('MONGO_URI is missing in production environment.');
    } else {
      warnings.push('MONGO_URI not specified; falling back to local Docker defaults.');
    }
  }

  // Log warnings in development
  if (warnings.length > 0 && !isProduction && process.env.NODE_ENV !== 'test') {
    warnings.forEach((warn) => console.warn(`[Security Warning] ${warn}`));
  }

  // In production, reject startup if critical security variables are invalid
  if (errors.length > 0) {
    errors.forEach((err) => console.error(`[Security Fatal] ${err}`));
    if (isProduction) {
      throw new Error(`Security Configuration Failure: ${errors.join(', ')}`);
    }
  }

  return { isValid: errors.length === 0, warnings, errors };
};

module.exports = { validateEnvironment };
