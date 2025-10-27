import { addDocument } from '@/lib/firebase';

// Sample seed data for demonstration
const seedUsers = [
  {
    fullName: 'John Doe',
    email: 'john.doe@company.com',
    phoneNumber: '+1 (555) 123-4567',
    collegeId: 'STU001',
    username: 'johndoe',
    createdAt: new Date().toISOString()
  },
  {
    fullName: 'Sarah Connor',
    email: 'sarah.connor@company.com',
    phoneNumber: '+1 (555) 234-5678',
    collegeId: 'STU002',
    username: 'sarahconnor',
    createdAt: new Date().toISOString()
  },
  {
    fullName: 'Mike Johnson',
    email: 'mike.johnson@company.com',
    phoneNumber: '+1 (555) 345-6789',
    collegeId: 'STU003',
    username: 'mikejohnson',
    createdAt: new Date().toISOString()
  },
  {
    fullName: 'Emily Davis',
    email: 'emily.davis@company.com',
    phoneNumber: '+1 (555) 456-7890',
    collegeId: 'STU004',
    username: 'emilydavis',
    createdAt: new Date().toISOString()
  }
];

const seedStaff = [
  {
    name: 'Alice Johnson',
    email: 'alice@zesty.com',
    phone: '+1 (555) 987-6543',
    status: 'active',
    hireDate: '2022-03-15'
  },
  {
    name: 'Bob Martinez',
    email: 'bob@zesty.com',
    phone: '+1 (555) 876-5432',
    status: 'active',
    hireDate: '2023-01-08'
  },
  {
    name: 'Carol Brown',
    email: 'carol@zesty.com',
    phone: '+1 (555) 765-4321',
    status: 'active',
    hireDate: '2023-06-12'
  },
  {
    name: 'David Wilson',
    email: 'david@zesty.com',
    phone: '+1 (555) 654-3210',
    status: 'inactive',
    hireDate: '2022-11-20'
  }
];

const seedTransactions = [
  {
    orderId: 'ORD1234',
    customer: 'john.doe@company.com',
    amount: 24.50,
    method: 'Card',
    status: 'completed',
    timestamp: new Date().toISOString(),
    fee: 0.74,
    items: 'Chicken Sandwich, Caesar Salad'
  },
  {
    orderId: 'ORD1235',
    customer: 'sarah.connor@company.com',
    amount: 18.75,
    method: 'Cash',
    status: 'completed',
    timestamp: new Date().toISOString(),
    fee: 0.00,
    items: 'Margherita Pizza'
  }
];

const seedSystemLogs = [
  {
    timestamp: new Date().toISOString(),
    level: 'INFO',
    category: 'Authentication',
    message: 'User alice@zesty.com logged in successfully',
    details: 'Login from IP: 192.168.1.105',
    source: 'auth-service'
  },
  {
    timestamp: new Date().toISOString(),
    level: 'WARNING',
    category: 'Inventory',
    message: 'Low stock alert: Chicken Sandwich ingredients below threshold',
    details: 'Current stock: 5 units, Threshold: 10 units',
    source: 'inventory-service'
  }
];

export const seedFirebaseData = async () => {
  const results = {
    users: { success: 0, errors: 0 },
    staff: { success: 0, errors: 0 },
    transactions: { success: 0, errors: 0 },
    systemLogs: { success: 0, errors: 0 }
  };

  // Seed Users
  for (const user of seedUsers) {
    const { error } = await addDocument('users', user);
    if (error) {
      results.users.errors++;
    } else {
      results.users.success++;
    }
  }

  // Seed Staff
  for (const staff of seedStaff) {
    const { error } = await addDocument('staff', staff);
    if (error) {
      results.staff.errors++;
    } else {
      results.staff.success++;
    }
  }

  // Seed Transactions
  for (const transaction of seedTransactions) {
    const { error } = await addDocument('transactions', transaction);
    if (error) {
      results.transactions.errors++;
    } else {
      results.transactions.success++;
    }
  }

  // Seed System Logs
  for (const log of seedSystemLogs) {
    const { error } = await addDocument('systemLogs', log);
    if (error) {
      results.systemLogs.errors++;
    } else {
      results.systemLogs.success++;
    }
  }

  return results;
};