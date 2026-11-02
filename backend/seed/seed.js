const mongoose = require('mongoose');
const dotenv = require('dotenv');
const User = require('../models/User');
const Category = require('../models/Category');
const Complaint = require('../models/Complaint');
const Counter = require('../models/Counter');

dotenv.config();

const users = [
  // 1 Super Admin
  {
    name: 'Dr. Rajesh Sharma (Dean)',
    email: 'admin@college.edu',
    password: 'AdminPassword@123',
    role: 'admin',
    phone: '9876543210',
    department: 'Administration',
    isActive: true
  },
  // 4 Authorities
  {
    name: 'Mr. Vikram Singh (Hostel Warden)',
    email: 'warden.hostel@college.edu',
    password: 'WardenPassword@123',
    role: 'authority',
    phone: '9876543211',
    department: 'Hostel & Residential Life',
    isActive: true
  },
  {
    name: 'Mrs. Sunita Verma (Mess Manager)',
    email: 'mess.manager@college.edu',
    password: 'MessPassword@123',
    role: 'authority',
    phone: '9876543212',
    department: 'Dining & Mess Services',
    isActive: true
  },
  {
    name: 'Prof. Anil Gupta (Lab In-charge)',
    email: 'lab.incharge@college.edu',
    password: 'LabPassword@123',
    role: 'authority',
    phone: '9876543213',
    department: 'Computer Science & Labs',
    isActive: true
  },
  {
    name: 'Mr. Ramesh Kumar (Campus Electrician)',
    email: 'electrician@college.edu',
    password: 'SparkPassword@123',
    role: 'authority',
    phone: '9876543214',
    department: 'Electrical Maintenance',
    isActive: true
  },
  // 3 Students
  {
    name: 'Aarav Mehta',
    email: 'aarav.mehta@college.edu',
    password: 'StudentPassword@123',
    role: 'student',
    phone: '9876543220',
    studentId: 'CS2023045',
    department: 'Computer Science & Engineering',
    isActive: true
  },
  {
    name: 'Priya Sharma',
    email: 'priya.sharma@college.edu',
    password: 'StudentPassword@123',
    role: 'student',
    phone: '9876543221',
    studentId: 'EC2023012',
    department: 'Electronics & Communication',
    isActive: true
  },
  {
    name: 'Rohan Verma',
    email: 'rohan.verma@college.edu',
    password: 'StudentPassword@123',
    role: 'student',
    phone: '9876543222',
    studentId: 'ME2023089',
    department: 'Mechanical Engineering',
    isActive: true
  }
];

const seedData = async () => {
  try {
    const connStr =
      process.env.MONGO_URI ||
      'mongodb://admin:password123@localhost:27017/college_cms?authSource=admin';
    await mongoose.connect(connStr);
    console.log(`[Seeder] Connected to MongoDB at ${connStr}`);

    // Clear existing collections
    await User.deleteMany({});
    await Category.deleteMany({});
    await Complaint.deleteMany({});
    await Counter.deleteMany({});
    console.log('[Seeder] Cleared collections (users, categories, complaints, counters).');

    // Create users individually so pre('save') bcrypt hashing fires
    const createdUsers = {};
    for (const userData of users) {
      const u = await User.create(userData);
      createdUsers[u.email] = u;
      console.log(`[Seeder] Created ${u.role}: ${u.email}`);
    }

    // Pre-populate campus categories
    const categories = [
      {
        name: 'Hostel Maintenance',
        description: 'Plumbing, carpentry, and room infrastructure issues in hostel blocks',
        defaultAuthority: createdUsers['warden.hostel@college.edu']._id,
        slaDays: 2,
        icon: 'hotel',
        isActive: true
      },
      {
        name: 'Mess & Food Services',
        description: 'Meal quality, drinking water, cafeteria hygiene, and cutlery sanitation',
        defaultAuthority: createdUsers['mess.manager@college.edu']._id,
        slaDays: 1,
        icon: 'restaurant',
        isActive: true
      },
      {
        name: 'Computer & Lab Equipment',
        description: 'Hardware defects, lab PCs, internet access, software licenses, projectors',
        defaultAuthority: createdUsers['lab.incharge@college.edu']._id,
        slaDays: 3,
        icon: 'computer',
        isActive: true
      },
      {
        name: 'Electrical & Power Supply',
        description: 'Power outages, tube lights, ceiling fans, ACs, switchboards, wiring',
        defaultAuthority: createdUsers['electrician@college.edu']._id,
        slaDays: 1,
        icon: 'bolt',
        isActive: true
      },
      {
        name: 'Sanitation & Campus Cleanliness',
        description: 'Corridor cleanliness, washroom sanitation, dustbins, campus gardens',
        defaultAuthority: null, // Unassigned for testing manual delegation
        slaDays: 2,
        icon: 'cleaning_services',
        isActive: true
      }
    ];

    for (const catData of categories) {
      await Category.create(catData);
      console.log(`[Seeder] Created category: ${catData.name} (SLA: ${catData.slaDays} days)`);
    }

    console.log('\n=============================================');
    console.log('[Seeder] Database seeding completed successfully!');
    console.log(`[Seeder] Seeded: 8 Users, 5 Categories.`);
    console.log('=============================================\n');

    process.exit(0);
  } catch (error) {
    console.error(`[Seeder Error] ${error.message}`);
    process.exit(1);
  }
};

seedData();
