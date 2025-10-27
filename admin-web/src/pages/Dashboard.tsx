import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  Users,
  DollarSign,
  TrendingUp,
  AlertTriangle,
  Clock,
  Plus,
  Eye,
  Bell,
  Settings,
  FileText,
  CreditCard,
  BarChart3,
  Calendar,
} from 'lucide-react';
import { subscribeToDocuments } from '@/lib/firebase';
import { useToast } from '@/hooks/use-toast';
import { SeedDataButton } from '@/components/SeedDataButton';

const quickActions = [
  { label: 'View Reports', icon: BarChart3 },
  { label: 'Process Transaction', icon: CreditCard },
];

export const Dashboard = () => {
  const [users, setUsers] = useState<any[]>([]);
  const [staff, setStaff] = useState<any[]>([]);
  const [transactions, setTransactions] = useState<any[]>([]);
  const [systemLogs, setSystemLogs] = useState<any[]>([]);
  const { toast } = useToast();

  // Subscribe to all collections for real-time data
  useEffect(() => {
    const unsubscribeUsers = subscribeToDocuments('users', setUsers);
    const unsubscribeStaff = subscribeToDocuments('staff', setStaff);
    const unsubscribeTransactions = subscribeToDocuments('transactions', setTransactions);
    const unsubscribeLogs = subscribeToDocuments('systemLogs', setSystemLogs);

    return () => {
      unsubscribeUsers();
      unsubscribeStaff();
      unsubscribeTransactions();
      unsubscribeLogs();
    };
  }, []);

  // Calculate real-time stats
  const stats = [
    {
      title: 'Total Users',
      value: users.length.toString(),
      change: '+12%',
      icon: Users,
      color: 'text-blue-600',
      bgColor: 'bg-blue-50',
    },
    {
      title: 'Total Revenue',
      value: `₹${transactions.reduce((sum, t) => sum + (t.amount || 0), 0).toFixed(2)}`,
      change: '+8.2%',
      icon: DollarSign,
      color: 'text-green-600',
      bgColor: 'bg-green-50',
    },
    {
      title: 'Active Staff',
      value: staff.filter(s => s.status === 'active').length.toString(),
      change: '+5.1%',
      icon: TrendingUp,
      color: 'text-purple-600',
      bgColor: 'bg-purple-50',
    },
    {
      title: 'Total Orders',
      value: transactions.length.toString(),
      change: '+15.3%',
      icon: CreditCard,
      color: 'text-blue-600',
      bgColor: 'bg-blue-50',
    },
  ];

  const recentActivities = [
    ...users.slice(0, 2).map((user, index) => ({
      id: `user-${index}`,
      type: 'User Registration',
      message: `${user.name || 'New user'} joined the canteen system`,
      time: '5 minutes ago',
      status: 'success'
    })),
    ...transactions.slice(0, 2).map((transaction, index) => ({
      id: `transaction-${index}`,
      type: 'Transaction',
      message: `Payment of ₹${transaction.amount} processed`,
      time: '10 minutes ago',
      status: 'success'
    })),
    ...systemLogs.slice(0, 1).map((log, index) => ({
      id: `log-${index}`,
      type: 'System Alert',
      message: log.message || 'System activity logged',
      time: '15 minutes ago',
      status: log.level === 'error' ? 'error' : 'info'
    }))
  ];

  const handleQuickAction = async (action: string) => {
    switch (action) {
      case 'View Reports':
        window.location.href = '/reports';
        break;
      case 'Process Transaction':
        window.location.href = '/transactions';
        break;
      case 'System Settings':
        toast({
          title: "Settings",
          description: "System settings panel will be available soon.",
        });
        break;
      default:
        toast({
          title: action,
          description: `${action} feature is being developed.`,
        });
    }
  };

  return (
    <div className="space-y-8">
      {/* Welcome Header */}
      <div className="animate-slide-up">
        <h1 className="text-3xl font-bold text-foreground mb-2">
          Welcome to Zesty Dashboard
        </h1>
        <p className="text-muted-foreground">
          Here's what's happening with your canteen today.
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4 animate-fade-in">
        {stats.map((stat, index) => (
          <Card key={stat.title} className="shadow-soft hover:shadow-elegant transition-all duration-300">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                {stat.title}
              </CardTitle>
              <div className={`p-2 rounded-lg ${stat.bgColor}`}>
                <stat.icon className={`h-4 w-4 ${stat.color}`} />
              </div>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-foreground">
                {stat.value}
              </div>
              <p className="text-xs text-muted-foreground">
                <span className="text-secondary font-medium">
                  {stat.change}
                </span>{' '}
                from last month
              </p>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        {/* Recent Activities */}
        <div className="lg:col-span-2 animate-slide-up">
          <Card className="shadow-soft">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Clock className="h-5 w-5 text-primary" />
                Recent Activities
              </CardTitle>
              <CardDescription>
                Latest updates from your canteen operations
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {recentActivities.length > 0 ? recentActivities.map((activity) => (
                  <div key={activity.id} className="flex items-center gap-3 p-3 rounded-lg hover:bg-muted/50 transition-colors">
                    <div className="flex-1">
                      <p className="text-sm font-medium text-foreground">
                        {activity.message}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        {activity.time}
                      </p>
                    </div>
                    <Badge
                      variant={
                        activity.status === 'success'
                          ? 'default'
                          : activity.status === 'warning'
                          ? 'destructive'
                          : 'secondary'
                      }
                    >
                      {activity.status}
                    </Badge>
                  </div>
                )) : (
                  <p className="text-muted-foreground text-center py-4">
                    No recent activities. Start by adding users or processing transactions.
                  </p>
                )}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Quick Actions */}
        <div className="animate-bounce-in">
          <Card className="shadow-soft">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Settings className="h-5 w-5 text-primary" />
                Quick Actions
              </CardTitle>
              <CardDescription>
                Frequently used actions for efficient management
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {quickActions.map((action, index) => (
                  <Button
                    key={index}
                    variant="outline"
                    className="w-full justify-start gap-2 hover:shadow-soft transition-all duration-200"
                    onClick={() => handleQuickAction(action.label)}
                  >
                    <action.icon className="h-4 w-4" />
                    {action.label}
                  </Button>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
};