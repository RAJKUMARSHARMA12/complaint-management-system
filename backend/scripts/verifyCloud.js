/**
 * Cloud Deployment & Database Verification Utility
 * Connects to MongoDB Atlas / Cloud DB, pings the server, checks collections & indexes,
 * and outputs structured diagnostic health metrics.
 */
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config();

const verifyCloudConnection = async () => {
  console.log('\n=============================================');
  console.log('☁️  CampusVoice Cloud & MongoDB Atlas Verifier');
  console.log('=============================================\n');

  const uri = process.env.MONGO_URI;
  if (!uri) {
    console.error('❌ FAIL: MONGO_URI environment variable is missing.');
    return { success: false, error: 'MONGO_URI missing' };
  }

  // Mask credentials for display
  const maskedUri = uri.replace(/\/\/([^:]+):([^@]+)@/, '//$1:****@');
  console.log(`[Cloud Diagnostics] Connecting to: ${maskedUri}`);

  const startTime = Date.now();
  try {
    const conn = await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 8000,
      autoIndex: true
    });

    const latencyMs = Date.now() - startTime;
    console.log(`  ✅ Database Connected: ${conn.connection.host}/${conn.connection.name}`);
    console.log(`  ✅ Connection Latency: ${latencyMs} ms`);

    // Ping admin database
    const adminDb = conn.connection.db.admin();
    const pingResult = await adminDb.ping();
    console.log(`  ✅ Admin Ping: ${JSON.stringify(pingResult)}`);

    // Inspect Collections
    const collections = await conn.connection.db.listCollections().toArray();
    const collectionNames = collections.map((c) => c.name);
    console.log(`  ✅ Collections Available (${collectionNames.length}): ${collectionNames.join(', ') || '(none yet)'}`);

    console.log('\n---------------------------------------------');
    console.log('🎉 Cloud Database Health Verification Passed!');
    console.log('=============================================\n');

    return {
      success: true,
      host: conn.connection.host,
      database: conn.connection.name,
      latencyMs,
      collections: collectionNames
    };
  } catch (error) {
    console.error(`\n❌ Cloud Database Connection Failed: ${error.message}`);
    console.log('\nTroubleshooting Hints:');
    console.log('1. Verify your IP is added to the MongoDB Atlas Network Access whitelist (or allow 0.0.0.0/0).');
    console.log('2. Confirm the database user credentials in MONGO_URI.');
    console.log('3. Ensure SSL/TLS connectivity is permitted by your outbound network.');
    return { success: false, error: error.message };
  } finally {
    if (mongoose.connection.readyState !== 0) {
      await mongoose.disconnect();
    }
  }
};

if (require.main === module) {
  verifyCloudConnection().then((res) => {
    process.exit(res.success ? 0 : 1);
  });
}

module.exports = { verifyCloudConnection };
