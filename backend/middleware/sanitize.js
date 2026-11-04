/**
 * Recursive sanitizer for request payloads
 * Strips keys containing '$' or '.' to prevent NoSQL query operator injection.
 */
const sanitizeValue = (val) => {
  if (val === null || val === undefined) return val;

  if (Array.isArray(val)) {
    return val.map(sanitizeValue);
  }

  if (typeof val === 'object') {
    const clean = {};
    for (const [key, value] of Object.entries(val)) {
      // Reject / strip any Mongo query operators ($gt, $ne, $where, etc.) and dot notation paths
      if (!key.startsWith('$') && !key.includes('.')) {
        clean[key] = sanitizeValue(value);
      }
    }
    return clean;
  }

  return val;
};

/**
 * Express middleware to sanitize req.body, req.query, and req.params
 */
const sanitizeInput = (req, res, next) => {
  if (req.body && typeof req.body === 'object') {
    req.body = sanitizeValue(req.body);
  }
  if (req.query && typeof req.query === 'object') {
    req.query = sanitizeValue(req.query);
  }
  if (req.params && typeof req.params === 'object') {
    req.params = sanitizeValue(req.params);
  }
  next();
};

module.exports = {
  sanitizeInput,
  sanitizeValue
};
