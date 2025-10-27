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
  FileText,
  Search,
  Filter,
  Download,
  AlertCircle,
  CheckCircle,
  XCircle,
  Info,
  Clock,
  RefreshCw,
} from 'lucide-react';
import { subscribeToDocuments, addDocument } from '@/lib/firebase';
import { useToast } from '@/hooks/use-toast';

// Mock data
const systemLogs = [
  {
    id: '1',
    timestamp: '2024-01-15 14:32:15',
    level: 'INFO',
    category: 'Authentication',
    message: 'User alice@zesty.com logged in successfully',
    details: 'Login from IP: 192.168.1.105',
    source: 'auth-service',
  },
  {
    id: '2',
    timestamp: '2024-01-15 14:28:43',
    level: 'WARNING',
    category: 'Inventory',
    message: 'Low stock alert: Chicken Sandwich ingredients below threshold',
    details: 'Current stock: 5 units, Threshold: 10 units',
    source: 'inventory-service',
  },
  {
    id: '3',
    timestamp: '2024-01-15 14:25:12',
    level: 'ERROR',
    category: 'Payment',
    message: 'Payment processing failed for order #1234',
    details: 'Gateway timeout error - Transaction ID: txn_abc123',
    source: 'payment-service',
  },
  {
    id: '4',
    timestamp: '2024-01-15 14:20:08',
    level: 'INFO',
    category: 'Orders',
    message: 'New order created successfully',
    details: 'Order #1234 - Total: $24.50 - Customer: john.doe@company.com',
    source: 'order-service',
  },
  {
    id: '5',
    timestamp: '2024-01-15 14:15:33',
    level: 'WARNING',
    category: 'System',
    message: 'High CPU usage detected on server node-02',
    details: 'CPU usage: 87% - Memory usage: 72%',
    source: 'monitoring-service',
  },
  {
    id: '6',
    timestamp: '2024-01-15 14:10:22',
    level: 'INFO',
    category: 'Users',
    message: 'New user registration completed',
    details: 'User: sarah.connor@company.com - Department: Marketing',
    source: 'user-service',
  },
  {
    id: '7',
    timestamp: '2024-01-15 14:05:17',
    level: 'ERROR',
    category: 'Database',
    message: 'Database connection timeout',
    details: 'Connection pool exhausted - Active connections: 50/50',
    source: 'database-service',
  },
  {
    id: '8',
    timestamp: '2024-01-15 14:00:45',
    level: 'INFO',
    category: 'Staff',
    message: 'Staff shift change recorded',
    details: 'Alice Johnson started morning shift in Kitchen department',
    source: 'staff-service',
  },
];

export const SystemLogs = () => {
  const [logs, setLogs] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterLevel, setFilterLevel] = useState('all');
  const [filterCategory, setFilterCategory] = useState('all');
  const [autoRefresh, setAutoRefresh] = useState(false);
  const { toast } = useToast();

  // Subscribe to system logs
  useEffect(() => {
    const unsubscribe = subscribeToDocuments('systemLogs', (docs) => {
      setLogs(docs);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  // Filter logs based on search and filters
  const filteredLogs = logs.filter((log) => {
    const matchesSearch = 
      log.message.toLowerCase().includes(searchTerm.toLowerCase()) ||
      log.category.toLowerCase().includes(searchTerm.toLowerCase()) ||
      log.source.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesLevel = filterLevel === 'all' || log.level === filterLevel;
    const matchesCategory = filterCategory === 'all' || log.category === filterCategory;
    
    return matchesSearch && matchesLevel && matchesCategory;
  });

  const categories = [...new Set(logs.map(log => log.category))];
  const levels = [...new Set(logs.map(log => log.level))];

  const getLevelBadge = (level: string) => {
    const variants = {
      INFO: { variant: 'default' as const, icon: Info, color: 'text-blue-600' },
      WARNING: { variant: 'destructive' as const, icon: AlertCircle, color: 'text-yellow-600' },
      ERROR: { variant: 'destructive' as const, icon: XCircle, color: 'text-red-600' },
      SUCCESS: { variant: 'default' as const, icon: CheckCircle, color: 'text-green-600' },
    };
    
    const config = variants[level as keyof typeof variants] || variants.INFO;
    
    return (
      <Badge variant={config.variant} className="flex items-center gap-1">
        <config.icon className={`h-3 w-3 ${config.color}`} />
        {level}
      </Badge>
    );
  };

  const handleRefresh = async () => {
    const newLog = {
      timestamp: new Date().toISOString(),
      level: 'INFO',
      category: 'System',
      message: `System refresh performed at ${new Date().toLocaleString()}`,
      details: 'Manual refresh triggered by user',
      source: 'dashboard'
    };

    const { error } = await addDocument('systemLogs', newLog);
    if (error) {
      toast({
        title: "Error",
        description: error,
        variant: "destructive"
      });
    } else {
      toast({
        title: "Logs refreshed",
        description: "New log entry has been added.",
      });
    }
  };

  const handleExport = () => {
    toast({
      title: "Export Started",
      description: "System logs export feature will be implemented soon.",
    });
  };

  const logStats = {
    total: logs.length,
    errors: logs.filter(log => log.level === 'ERROR').length,
    warnings: logs.filter(log => log.level === 'WARNING').length,
    info: logs.filter(log => log.level === 'INFO').length,
  };

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-foreground flex items-center gap-2">
            <FileText className="h-8 w-8 text-primary" />
            System Logs
          </h1>
          <p className="text-muted-foreground mt-1">
            Monitor system activities, errors, and performance metrics
          </p>
        </div>
        
        <div className="flex items-center gap-3">
          <Button
            variant="outline"
            size="sm"
            onClick={() => {
              setAutoRefresh(!autoRefresh);
              toast({
                title: autoRefresh ? "Auto-refresh disabled" : "Auto-refresh enabled",
                description: autoRefresh ? "Manual refresh only" : "Logs will update automatically",
              });
            }}
            className={autoRefresh ? 'bg-primary/10 text-primary' : ''}
          >
            <RefreshCw className={`h-4 w-4 mr-2 ${autoRefresh ? 'animate-spin' : ''}`} />
            Auto Refresh
          </Button>
          <Button variant="outline" onClick={handleRefresh} className="gap-2">
            <RefreshCw className="h-4 w-4" />
            Refresh
          </Button>
          <Button variant="outline" className="gap-2" onClick={handleExport}>
            <Download className="h-4 w-4" />
            Export Logs
          </Button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid gap-6 md:grid-cols-4 animate-slide-up">
        <Card className="shadow-soft">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Logs</CardTitle>
            <FileText className="h-4 w-4 text-primary" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{logStats.total}</div>
            <p className="text-xs text-muted-foreground">All system events</p>
          </CardContent>
        </Card>
        
        <Card className="shadow-soft">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Errors</CardTitle>
            <XCircle className="h-4 w-4 text-red-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-red-600">{logStats.errors}</div>
            <p className="text-xs text-muted-foreground">Critical issues</p>
          </CardContent>
        </Card>
        
        <Card className="shadow-soft">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Warnings</CardTitle>
            <AlertCircle className="h-4 w-4 text-yellow-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-yellow-600">{logStats.warnings}</div>
            <p className="text-xs text-muted-foreground">Need attention</p>
          </CardContent>
        </Card>
        
        <Card className="shadow-soft">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Info</CardTitle>
            <Info className="h-4 w-4 text-blue-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-blue-600">{logStats.info}</div>
            <p className="text-xs text-muted-foreground">Normal operations</p>
          </CardContent>
        </Card>
      </div>

      {/* Filters and Search */}
      <Card className="shadow-soft">
        <CardHeader>
          <CardTitle className="text-lg">Filter Logs</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col md:flex-row gap-4">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search logs by message, category, or source..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10"
              />
            </div>
            <Select value={filterLevel} onValueChange={setFilterLevel}>
              <SelectTrigger className="w-full md:w-[180px]">
                <Filter className="h-4 w-4 mr-2" />
                <SelectValue placeholder="Log Level" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Levels</SelectItem>
                {levels.map(level => (
                  <SelectItem key={level} value={level}>{level}</SelectItem>
                ))}
              </SelectContent>
            </Select>
            <Select value={filterCategory} onValueChange={setFilterCategory}>
              <SelectTrigger className="w-full md:w-[180px]">
                <SelectValue placeholder="Category" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Categories</SelectItem>
                {categories.map(category => (
                  <SelectItem key={category} value={category}>{category}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {/* Logs Table */}
      <Card className="shadow-soft">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Clock className="h-5 w-5 text-primary" />
            System Events Log
          </CardTitle>
            <CardDescription>
              {loading ? 'Loading...' : `${filteredLogs.length} log entries found`}
            </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Timestamp</TableHead>
                <TableHead>Level</TableHead>
                <TableHead>Category</TableHead>
                <TableHead>Message</TableHead>
                <TableHead>Source</TableHead>
                <TableHead>Details</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredLogs.map((log) => (
                <TableRow key={log.id} className="hover:bg-muted/50 transition-colors">
                  <TableCell className="font-mono text-sm">
                    {log.timestamp}
                  </TableCell>
                  <TableCell>
                    {getLevelBadge(log.level)}
                  </TableCell>
                  <TableCell>
                    <Badge variant="outline">{log.category}</Badge>
                  </TableCell>
                  <TableCell className="max-w-sm">
                    <div className="truncate" title={log.message}>
                      {log.message}
                    </div>
                  </TableCell>
                  <TableCell>
                    <code className="text-xs bg-muted px-2 py-1 rounded">
                      {log.source}
                    </code>
                  </TableCell>
                  <TableCell className="max-w-xs">
                    <div className="text-sm text-muted-foreground truncate" title={log.details}>
                      {log.details}
                    </div>
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