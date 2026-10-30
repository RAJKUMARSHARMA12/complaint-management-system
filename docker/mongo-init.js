// MongoDB initialization script for CampusVoice
db = db.getSiblingDB('college_cms');

// Create application user with readWrite permissions
db.createUser({
  user: 'college_user',
  pwd: 'college_password123',
  roles: [
    {
      role: 'readWrite',
      db: 'college_cms'
    }
  ]
});

// Initialize collections
db.createCollection('users');
db.createCollection('categories');
db.createCollection('complaints');
db.createCollection('notifications');

print('CampusVoice: college_cms database and collections initialized successfully.');
