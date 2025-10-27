import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  LineChart,
  Line,
  PieChart,
  Pie,
  Cell,
  AreaChart,
  Area
} from 'recharts';
import {
  BarChart3,
  TrendingUp,
  DollarSign,
  Users,
  Download,
  Calendar,
  Clock,
  Target,
} from 'lucide-react';
import { useToast } from '@/hooks/use-toast';

// Mock data for charts
const revenueData = [
  { month: 'Jan', revenue: 12400, orders: 245 },
  { month: 'Feb', revenue: 13200, orders: 267 },
  { month: 'Mar', revenue: 15800, orders: 298 },
  { month: 'Apr', revenue: 14200, orders: 276 },
  { month: 'May', revenue: 16500, orders: 324 },
  { month: 'Jun', revenue: 18200, orders: 356 },
];

const popularItemsData = [
  { name: 'Chicken Sandwich', orders: 156, revenue: 2340 },
  { name: 'Caesar Salad', orders: 134, revenue: 1876 },
  { name: 'Margherita Pizza', orders: 128, revenue: 2304 },
  { name: 'Beef Burger', orders: 98, revenue: 1862 },
  { name: 'Fish & Chips', orders: 87, revenue: 1653 },
];

const userActivityData = [
  { name: 'Active Users', value: 847, color: '#FF6B35' },
  { name: 'New Users', value: 123, color: '#2D8F3F' },
  { name: 'Inactive Users', value: 67, color: '#FFA500' },
];

const dailyOrdersData = [
  { day: 'Mon', breakfast: 45, lunch: 87, dinner: 23 },
  { day: 'Tue', breakfast: 52, lunch: 92, dinner: 31 },
  { day: 'Wed', breakfast: 48, lunch: 95, dinner: 28 },
  { day: 'Thu', breakfast: 61, lunch: 104, dinner: 35 },
  { day: 'Fri', breakfast: 58, lunch: 98, dinner: 42 },
  { day: 'Sat', breakfast: 35, lunch: 67, dinner: 48 },
  { day: 'Sun', breakfast: 29, lunch: 54, dinner: 39 },
];

const COLORS = ['#FF6B35', '#2D8F3F', '#FFA500', '#3B82F6'];

export const Reports = () => {
  const [timeRange, setTimeRange] = useState('6months');
  const [reportType, setReportType] = useState('revenue');
  const { toast } = useToast();

  const handleExport = () => {
    toast({
      title: "Export Started",
      description: "Report data will be exported to CSV format.",
    });
  };

  const kpiCards = [
    {
      title: 'Total Revenue',
      value: '₹89,240',
      change: '+12.5%',
      changeType: 'positive',
      icon: DollarSign,
      description: 'Compared to last period'
    },
    {
      title: 'Total Orders',
      value: '1,847',
      change: '+8.2%',
      changeType: 'positive',
      icon: BarChart3,
      description: 'Orders completed'
    },
    {
      title: 'Active Users',
      value: '847',
      change: '+15.3%',
      changeType: 'positive',
      icon: Users,
      description: 'Monthly active users'
    },
    {
      title: 'Avg Order Value',
      value: '₹48.35',
      change: '-2.1%',
      changeType: 'negative',
      icon: Target,
      description: 'Per order average'
    },
  ];

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-foreground flex items-center gap-2">
            <BarChart3 className="h-8 w-8 text-primary" />
            Reports & Analytics
          </h1>
          <p className="text-muted-foreground mt-1">
            Comprehensive insights into your canteen operations
          </p>
        </div>
        
        <div className="flex items-center gap-3">
          <Select value={timeRange} onValueChange={setTimeRange}>
            <SelectTrigger className="w-[180px]">
              <Calendar className="h-4 w-4 mr-2" />
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="7days">Last 7 days</SelectItem>
              <SelectItem value="30days">Last 30 days</SelectItem>
              <SelectItem value="3months">Last 3 months</SelectItem>
              <SelectItem value="6months">Last 6 months</SelectItem>
              <SelectItem value="1year">Last year</SelectItem>
            </SelectContent>
          </Select>
          
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2">
            <Button 
              variant="outline"
              onClick={async () => {
                const { seedFirebaseData } = await import('@/utils/seedData');
                const results = await seedFirebaseData();
                toast({
                  title: "Sample Data Added",
                  description: `Added ${results.users.success} users, ${results.staff.success} staff, ${results.transactions.success} transactions`,
                });
              }}
            >
              Add Sample Data
            </Button>
          </div>
          <Button 
            variant="outline" 
            className="gap-2"
            onClick={handleExport}
          >
            <Download className="h-4 w-4" />
            Export Report
          </Button>
        </div>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4 animate-slide-up">
        {kpiCards.map((kpi, index) => (
          <Card key={kpi.title} className="shadow-soft hover:shadow-elegant transition-all duration-300">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                {kpi.title}
              </CardTitle>
              <div className="p-2 rounded-lg bg-primary/10">
                <kpi.icon className="h-4 w-4 text-primary" />
              </div>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-foreground mb-1">
                {kpi.value}
              </div>
              <div className="flex items-center gap-2">
                <Badge 
                  variant={kpi.changeType === 'positive' ? 'default' : 'destructive'}
                  className="text-xs"
                >
                  <TrendingUp className="h-3 w-3 mr-1" />
                  {kpi.change}
                </Badge>
                <span className="text-xs text-muted-foreground">
                  {kpi.description}
                </span>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* Revenue Chart */}
        <Card className="shadow-soft animate-bounce-in">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <DollarSign className="h-5 w-5 text-primary" />
              Revenue Overview
            </CardTitle>
            <CardDescription>
              Monthly revenue and order trends
            </CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <AreaChart data={revenueData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="month" />
                <YAxis />
                <Tooltip 
                  formatter={(value, name) => [
                    name === 'revenue' ? `₹${value}` : value,
                    name === 'revenue' ? 'Revenue' : 'Orders'
                  ]}
                />
                <Area 
                  type="monotone" 
                  dataKey="revenue" 
                  stroke="#FF6B35" 
                  fill="#FF6B35" 
                  fillOpacity={0.3}
                />
                <Area 
                  type="monotone" 
                  dataKey="orders" 
                  stroke="#2D8F3F" 
                  fill="#2D8F3F" 
                  fillOpacity={0.3}
                />
              </AreaChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* User Activity Pie Chart */}
        <Card className="shadow-soft animate-bounce-in">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Users className="h-5 w-5 text-primary" />
              User Activity
            </CardTitle>
            <CardDescription>
              User engagement breakdown
            </CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={userActivityData}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(0)}%`}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="value"
                >
                  {userActivityData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* Popular Items */}
        <Card className="shadow-soft">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Target className="h-5 w-5 text-primary" />
              Popular Menu Items
            </CardTitle>
            <CardDescription>
              Top performing items by orders
            </CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={popularItemsData} layout="horizontal">
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis type="number" />
                <YAxis dataKey="name" type="category" width={80} />
                <Tooltip />
                <Bar dataKey="orders" fill="#FF6B35" radius={[0, 4, 4, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Daily Orders */}
        <Card className="shadow-soft">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Clock className="h-5 w-5 text-primary" />
              Daily Order Distribution
            </CardTitle>
            <CardDescription>
              Orders by meal time throughout the week
            </CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={dailyOrdersData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="day" />
                <YAxis />
                <Tooltip />
                <Bar dataKey="breakfast" stackId="a" fill="#FF6B35" />
                <Bar dataKey="lunch" stackId="a" fill="#2D8F3F" />
                <Bar dataKey="dinner" stackId="a" fill="#FFA500" />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>

      {/* Insights & Recommendations */}
      <Card className="shadow-soft">
        <CardHeader>
          <CardTitle>Business Insights & Recommendations</CardTitle>
          <CardDescription>
            AI-powered insights to optimize your canteen operations
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="p-4 bg-primary/5 rounded-lg border-l-4 border-primary">
            <h4 className="font-semibold text-primary mb-2">Peak Hours Optimization</h4>
            <p className="text-sm text-muted-foreground">
              Thursday lunch shows highest demand. Consider adding 2 additional staff members during 12-2 PM to reduce wait times.
            </p>
          </div>
          
          <div className="p-4 bg-secondary/5 rounded-lg border-l-4 border-secondary">
            <h4 className="font-semibold text-secondary mb-2">Menu Performance</h4>
            <p className="text-sm text-muted-foreground">
              Chicken Sandwich generates 37% more revenue than other items. Consider expanding chicken-based options.
            </p>
          </div>
          
          <div className="p-4 bg-warning/5 rounded-lg border-l-4 border-warning">
            <h4 className="font-semibold text-warning mb-2">User Retention</h4>
            <p className="text-sm text-muted-foreground">
              67 users haven't ordered in 30+ days. Launch a "Welcome Back" campaign with 15% discount to re-engage them.
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};