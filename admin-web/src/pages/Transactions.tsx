import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  PieChart,
  Pie,
  Cell,
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
} from 'recharts';
import {
  CreditCard,
  Search,
  Filter,
  Download,
  DollarSign,
  TrendingUp,
  Calendar,
  Eye,
  RefreshCw,
} from 'lucide-react';
import { subscribeToDocuments, addDocument } from '@/lib/firebase';
import { useToast } from '@/hooks/use-toast';

// Mock data
const transactions = [
  {
    id: 'TXN001',
    orderId: 'ORD1234',
    customer: 'john.doe@company.com',
    amount: 24.50,
    method: 'Card',
    status: 'completed',
    timestamp: '2024-01-15 14:32:15',
    fee: 0.74,
    items: 'Chicken Sandwich, Caesar Salad',
  },
  {
    id: 'TXN002',
    orderId: 'ORD1235',
    customer: 'sarah.connor@company.com',
    amount: 18.75,
    method: 'Cash',
    status: 'completed',
    timestamp: '2024-01-15 14:25:43',
    fee: 0.00,
    items: 'Margherita Pizza',
  },
  {
    id: 'TXN003',
    orderId: 'ORD1236',
    customer: 'mike.johnson@company.com',
    amount: 32.20,
    method: 'Digital Wallet',
    status: 'pending',
    timestamp: '2024-01-15 14:20:12',
    fee: 0.97,
    items: 'Beef Burger, Fish & Chips, Coke',
  },
  {
    id: 'TXN004',
    orderId: 'ORD1237',
    customer: 'emily.davis@company.com',
    amount: 15.60,
    method: 'Card',
    status: 'failed',
    timestamp: '2024-01-15 14:15:08',
    fee: 0.47,
    items: 'Caesar Salad, Water',
  },
  {
    id: 'TXN005',
    orderId: 'ORD1238',
    customer: 'alex.smith@company.com',
    amount: 28.90,
    method: 'Digital Wallet',
    status: 'completed',
    timestamp: '2024-01-15 14:10:33',
    fee: 0.87,
    items: 'Chicken Sandwich, Fries, Smoothie',
  },
];

const paymentMethodData = [
  { name: 'Card', value: 45, color: '#FF6B35' },
  { name: 'Cash', value: 30, color: '#2D8F3F' },
  { name: 'Digital Wallet', value: 25, color: '#FFA500' },
];

const dailyTransactionData = [
  { day: 'Mon', amount: 1240, count: 28 },
  { day: 'Tue', amount: 1580, count: 35 },
  { day: 'Wed', amount: 1320, count: 31 },
  { day: 'Thu', amount: 1890, count: 42 },
  { day: 'Fri', amount: 2100, count: 48 },
  { day: 'Sat', amount: 890, count: 22 },
  { day: 'Sun', amount: 650, count: 16 },
];

export const Transactions = () => {
  const [transactionList, setTransactionList] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');
  const [filterMethod, setFilterMethod] = useState('all');
  const { toast } = useToast();

  // Subscribe to transactions collection
  useEffect(() => {
    const unsubscribe = subscribeToDocuments('transactions', (docs) => {
      setTransactionList(docs);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const handleSync = async () => {
    toast({
      title: "Syncing...",
      description: "Synchronizing transaction data.",
    });
    
    // Simulate sync by adding a sample transaction
    const sampleTransaction = {
      orderId: `ORD${Date.now()}`,
      customer: 'sync.test@company.com',
      amount: Math.floor(Math.random() * 50) + 10,
      method: ['Card', 'Cash', 'Digital Wallet'][Math.floor(Math.random() * 3)],
      status: 'completed',
      timestamp: new Date().toISOString(),
      fee: 0.5,
      items: 'Sync Test Order'
    };

    const { error } = await addDocument('transactions', sampleTransaction);
    if (!error) {
      toast({
        title: "Sync Complete",
        description: "Transaction data synchronized successfully.",
      });
    }
  };

  // Filter transactions
  const filteredTransactions = transactionList.filter((transaction) => {
    const matchesSearch = 
      transaction.customer.toLowerCase().includes(searchTerm.toLowerCase()) ||
      transaction.orderId.toLowerCase().includes(searchTerm.toLowerCase()) ||
      transaction.id.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesStatus = filterStatus === 'all' || transaction.status === filterStatus;
    const matchesMethod = filterMethod === 'all' || transaction.method === filterMethod;
    
    return matchesSearch && matchesStatus && matchesMethod;
  });

  const getStatusBadge = (status: string) => {
    const variants: Record<string, "default" | "destructive" | "secondary" | "outline"> = {
      completed: 'default',
      pending: 'secondary',
      failed: 'destructive'
    };
    
    return (
      <Badge variant={variants[status] || 'secondary'}>
        {status}
      </Badge>
    );
  };

  const getMethodBadge = (method: string) => {
    const colors = {
      'Card': 'bg-blue-100 text-blue-800',
      'Cash': 'bg-green-100 text-green-800',
      'Digital Wallet': 'bg-purple-100 text-purple-800'
    };
    
    return (
      <Badge className={colors[method as keyof typeof colors] || 'bg-gray-100 text-gray-800'}>
        {method}
      </Badge>
    );
  };

  const transactionStats = {
    total: transactionList.reduce((sum, t) => sum + t.amount, 0),
    completed: transactionList.filter(t => t.status === 'completed').length,
    pending: transactionList.filter(t => t.status === 'pending').length,
    failed: transactionList.filter(t => t.status === 'failed').length,
    totalFees: transactionList.reduce((sum, t) => sum + t.fee, 0),
  };

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-foreground flex items-center gap-2">
            <CreditCard className="h-8 w-8 text-primary" />
            Transactions
          </h1>
          <p className="text-muted-foreground mt-1">
            Monitor payment transactions and financial activities
          </p>
        </div>
        
        <div className="flex items-center gap-3">
          <Button variant="outline" className="gap-2" onClick={handleSync}>
            <RefreshCw className="h-4 w-4" />
            Sync
          </Button>
          <Button variant="outline" className="gap-2" onClick={() => toast({ title: "Export", description: "Transaction export feature will be implemented soon." })}>
            <Download className="h-4 w-4" />
            Export
          </Button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid gap-6 md:grid-cols-4 animate-slide-up">
        <Card className="shadow-soft">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Revenue</CardTitle>
            <DollarSign className="h-4 w-4 text-primary" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">₹{transactionStats.total.toFixed(2)}</div>
            <p className="text-xs text-muted-foreground">
              <span className="text-secondary">+12.5%</span> from last week
            </p>
          </CardContent>
        </Card>
        
        <Card className="shadow-soft">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Completed</CardTitle>
            <TrendingUp className="h-4 w-4 text-secondary" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-secondary">{transactionStats.completed}</div>
            <p className="text-xs text-muted-foreground">Successful transactions</p>
          </CardContent>
        </Card>
        
        <Card className="shadow-soft">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Pending</CardTitle>
            <Calendar className="h-4 w-4 text-warning" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-warning">{transactionStats.pending}</div>
            <p className="text-xs text-muted-foreground">Awaiting processing</p>
          </CardContent>
        </Card>
        
        <Card className="shadow-soft">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Processing Fees</CardTitle>
            <CreditCard className="h-4 w-4 text-destructive" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">₹{transactionStats.totalFees.toFixed(2)}</div>
            <p className="text-xs text-muted-foreground">Transaction fees</p>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* Payment Methods Chart */}
        <Card className="shadow-soft animate-bounce-in">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <CreditCard className="h-5 w-5 text-primary" />
              Payment Methods
            </CardTitle>
            <CardDescription>
              Distribution of payment methods used
            </CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={250}>
              <PieChart>
                <Pie
                  data={paymentMethodData}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(0)}%`}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="value"
                >
                  {paymentMethodData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Daily Transaction Volume */}
        <Card className="shadow-soft animate-bounce-in">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <TrendingUp className="h-5 w-5 text-primary" />
              Daily Transaction Volume
            </CardTitle>
            <CardDescription>
              Transaction amounts throughout the week
            </CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={dailyTransactionData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="day" />
                <YAxis />
                <Tooltip formatter={(value) => [`₹${value}`, 'Amount']} />
                <Bar dataKey="amount" fill="#FF6B35" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>

      {/* Filters and Search */}
      <Card className="shadow-soft">
        <CardHeader>
          <CardTitle className="text-lg">Filter Transactions</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col md:flex-row gap-4">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search by customer, order ID, or transaction ID..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10"
              />
            </div>
            <Select value={filterStatus} onValueChange={setFilterStatus}>
              <SelectTrigger className="w-full md:w-[180px]">
                <Filter className="h-4 w-4 mr-2" />
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Status</SelectItem>
                <SelectItem value="completed">Completed</SelectItem>
                <SelectItem value="pending">Pending</SelectItem>
                <SelectItem value="failed">Failed</SelectItem>
              </SelectContent>
            </Select>
            <Select value={filterMethod} onValueChange={setFilterMethod}>
              <SelectTrigger className="w-full md:w-[180px]">
                <SelectValue placeholder="Payment Method" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Methods</SelectItem>
                <SelectItem value="Card">Card</SelectItem>
                <SelectItem value="Cash">Cash</SelectItem>
                <SelectItem value="Digital Wallet">Digital Wallet</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {/* Transactions Table */}
      <Card className="shadow-soft">
        <CardHeader>
          <CardTitle>Transaction History</CardTitle>
          <CardDescription>
            {loading ? 'Loading...' : `${filteredTransactions.length} transactions found`}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Transaction ID</TableHead>
                <TableHead>Order</TableHead>
                <TableHead>Customer</TableHead>
                <TableHead>Amount</TableHead>
                <TableHead>Method</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Fee</TableHead>
                <TableHead>Timestamp</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredTransactions.map((transaction) => (
                <TableRow key={transaction.id} className="hover:bg-muted/50 transition-colors">
                  <TableCell>
                    <code className="text-xs bg-muted px-2 py-1 rounded">
                      {transaction.id}
                    </code>
                  </TableCell>
                  <TableCell>
                    <div className="font-medium">{transaction.orderId}</div>
                    <div className="text-sm text-muted-foreground truncate max-w-32">
                      {transaction.items}
                    </div>
                  </TableCell>
                  <TableCell className="font-medium">
                    {transaction.customer}
                  </TableCell>
                  <TableCell className="font-bold">
                    ₹{transaction.amount.toFixed(2)}
                  </TableCell>
                  <TableCell>
                    {getMethodBadge(transaction.method)}
                  </TableCell>
                  <TableCell>
                    {getStatusBadge(transaction.status)}
                  </TableCell>
                  <TableCell className="text-muted-foreground">
                    ₹{transaction.fee.toFixed(2)}
                  </TableCell>
                  <TableCell className="font-mono text-xs">
                    {transaction.timestamp}
                  </TableCell>
                  <TableCell className="text-right">
                    <Button variant="outline" size="sm">
                      <Eye className="h-4 w-4" />
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
};