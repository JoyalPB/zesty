import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Textarea } from '@/components/ui/textarea';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from 'recharts';
import {
  MessageSquare,
  Search,
  Filter,
  Star,
  ThumbsUp,
  ThumbsDown,
  TrendingUp,
  Users,
  Reply,
  Eye,
} from 'lucide-react';
import { useToast } from '@/hooks/use-toast';

// Mock data
const feedbackData = [
  {
    id: '1',
    customer: 'john.doe@company.com',
    rating: 5,
    category: 'Food Quality',
    subject: 'Amazing chicken sandwich!',
    message: 'The chicken sandwich was absolutely delicious. Perfect seasoning and fresh ingredients. Will definitely order again!',
    timestamp: '2024-01-15 14:32:15',
    status: 'new',
    orderRef: 'ORD1234',
    responded: false,
  },
  {
    id: '2',
    customer: 'sarah.connor@company.com',
    rating: 2,
    category: 'Service',
    subject: 'Long wait time',
    message: 'Had to wait 25 minutes for my order during lunch rush. Staff seemed overwhelmed. Please improve service speed.',
    timestamp: '2024-01-15 13:45:22',
    status: 'in-progress',
    orderRef: 'ORD1230',
    responded: true,
  },
  {
    id: '3',
    customer: 'mike.johnson@company.com',
    rating: 4,
    category: 'Cleanliness',
    subject: 'Clean and hygienic',
    message: 'The dining area was very clean and well-maintained. Staff followed proper hygiene protocols. Good experience overall.',
    timestamp: '2024-01-15 12:20:33',
    status: 'resolved',
    orderRef: 'ORD1225',
    responded: true,
  },
  {
    id: '4',
    customer: 'emily.davis@company.com',
    rating: 1,
    category: 'Food Quality',
    subject: 'Cold food delivered',
    message: 'My pizza arrived cold and the cheese was congealed. Very disappointing experience. Please ensure food is served hot.',
    timestamp: '2024-01-15 11:15:44',
    status: 'new',
    orderRef: 'ORD1220',
    responded: false,
  },
  {
    id: '5',
    customer: 'alex.smith@company.com',
    rating: 5,
    category: 'Variety',
    subject: 'Great menu options',
    message: 'Love the variety of healthy options available. The new salad combinations are fantastic. Keep up the good work!',
    timestamp: '2024-01-15 10:30:12',
    status: 'resolved',
    orderRef: 'ORD1215',
    responded: true,
  },
];

const ratingDistribution = [
  { rating: '5 Stars', count: 45, color: '#2D8F3F' },
  { rating: '4 Stars', count: 32, color: '#9ACD32' },
  { rating: '3 Stars', count: 18, color: '#FFA500' },
  { rating: '2 Stars', count: 12, color: '#FF6347' },
  { rating: '1 Star', count: 8, color: '#FF4444' },
];

const categoryData = [
  { category: 'Food Quality', positive: 67, negative: 12 },
  { category: 'Service', positive: 45, negative: 23 },
  { category: 'Cleanliness', positive: 78, negative: 5 },
  { category: 'Variety', positive: 56, negative: 8 },
  { category: 'Value', positive: 42, negative: 15 },
];

export const Feedback = () => {
  const [feedback, setFeedback] = useState(feedbackData);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterRating, setFilterRating] = useState('all');
  const [filterCategory, setFilterCategory] = useState('all');
  const [filterStatus, setFilterStatus] = useState('all');
  const [isReplyDialogOpen, setIsReplyDialogOpen] = useState(false);
  const [selectedFeedback, setSelectedFeedback] = useState<any>(null);
  const { toast } = useToast();

  // Filter feedback
  const filteredFeedback = feedback.filter((item) => {
    const matchesSearch = 
      item.customer.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.subject.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.message.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesRating = filterRating === 'all' || item.rating.toString() === filterRating;
    const matchesCategory = filterCategory === 'all' || item.category === filterCategory;
    const matchesStatus = filterStatus === 'all' || item.status === filterStatus;
    
    return matchesSearch && matchesRating && matchesCategory && matchesStatus;
  });

  const categories = [...new Set(feedback.map(item => item.category))];

  const getStatusBadge = (status: string) => {
    const variants: Record<string, "default" | "destructive" | "secondary" | "outline"> = {
      'new': 'destructive',
      'in-progress': 'secondary',
      'resolved': 'default'
    };
    
    return (
      <Badge variant={variants[status] || 'secondary'}>
        {status.replace('-', ' ')}
      </Badge>
    );
  };

  const getRatingStars = (rating: number) => {
    return (
      <div className="flex items-center gap-1">
        {[...Array(5)].map((_, i) => (
          <Star
            key={i}
            className={`h-4 w-4 ${
              i < rating
                ? 'text-yellow-400 fill-yellow-400'
                : 'text-gray-300'
            }`}
          />
        ))}
        <span className="text-sm text-muted-foreground ml-1">({rating})</span>
      </div>
    );
  };

  const handleReply = (feedbackItem: any) => {
    setSelectedFeedback(feedbackItem);
    setIsReplyDialogOpen(true);
  };

  const handleSendReply = () => {
    if (selectedFeedback) {
      setFeedback(feedback.map(item => 
        item.id === selectedFeedback.id 
          ? { ...item, responded: true, status: 'in-progress' }
          : item
      ));
      toast({
        title: "Reply sent",
        description: "Your response has been sent to the customer.",
      });
    }
    setIsReplyDialogOpen(false);
    setSelectedFeedback(null);
  };

  const feedbackStats = {
    total: feedback.length,
    avgRating: (feedback.reduce((sum, item) => sum + item.rating, 0) / feedback.length).toFixed(1),
    newFeedback: feedback.filter(item => item.status === 'new').length,
    positiveRating: feedback.filter(item => item.rating >= 4).length,
    responseRate: ((feedback.filter(item => item.responded).length / feedback.length) * 100).toFixed(0),
  };

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-foreground flex items-center gap-2">
            <MessageSquare className="h-8 w-8 text-primary" />
            Feedback & Reviews
          </h1>
          <p className="text-muted-foreground mt-1">
            Monitor customer feedback and manage reviews
          </p>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid gap-6 md:grid-cols-5 animate-slide-up">
        <Card className="shadow-soft">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Reviews</CardTitle>
            <MessageSquare className="h-4 w-4 text-primary" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{feedbackStats.total}</div>
            <p className="text-xs text-muted-foreground">All time feedback</p>
          </CardContent>
        </Card>
        
        <Card className="shadow-soft">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Avg Rating</CardTitle>
            <Star className="h-4 w-4 text-yellow-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{feedbackStats.avgRating}</div>
            <p className="text-xs text-muted-foreground">Out of 5 stars</p>
          </CardContent>
        </Card>
        
        <Card className="shadow-soft">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">New Feedback</CardTitle>
            <ThumbsUp className="h-4 w-4 text-secondary" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-secondary">{feedbackStats.newFeedback}</div>
            <p className="text-xs text-muted-foreground">Needs attention</p>
          </CardContent>
        </Card>
        
        <Card className="shadow-soft">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Positive</CardTitle>
            <TrendingUp className="h-4 w-4 text-accent" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{feedbackStats.positiveRating}</div>
            <p className="text-xs text-muted-foreground">4+ star ratings</p>
          </CardContent>
        </Card>
        
        <Card className="shadow-soft">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Response Rate</CardTitle>
            <Reply className="h-4 w-4 text-warning" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{feedbackStats.responseRate}%</div>
            <p className="text-xs text-muted-foreground">Replied to feedback</p>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* Rating Distribution */}
        <Card className="shadow-soft animate-bounce-in">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Star className="h-5 w-5 text-primary" />
              Rating Distribution
            </CardTitle>
            <CardDescription>
              Breakdown of customer ratings
            </CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={250}>
              <PieChart>
                <Pie
                  data={ratingDistribution}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ rating, percent }) => `${rating}: ${(percent * 100).toFixed(0)}%`}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="count"
                >
                  {ratingDistribution.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Category Feedback */}
        <Card className="shadow-soft animate-bounce-in">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Users className="h-5 w-5 text-primary" />
              Feedback by Category
            </CardTitle>
            <CardDescription>
              Positive vs negative feedback per category
            </CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={categoryData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="category" />
                <YAxis />
                <Tooltip />
                <Bar dataKey="positive" fill="#2D8F3F" />
                <Bar dataKey="negative" fill="#FF4444" />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>

      {/* Filters and Search */}
      <Card className="shadow-soft">
        <CardHeader>
          <CardTitle className="text-lg">Filter Feedback</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col md:flex-row gap-4">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search by customer, subject, or message..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10"
              />
            </div>
            <Select value={filterRating} onValueChange={setFilterRating}>
              <SelectTrigger className="w-full md:w-[140px]">
                <SelectValue placeholder="Rating" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Ratings</SelectItem>
                <SelectItem value="5">5 Stars</SelectItem>
                <SelectItem value="4">4 Stars</SelectItem>
                <SelectItem value="3">3 Stars</SelectItem>
                <SelectItem value="2">2 Stars</SelectItem>
                <SelectItem value="1">1 Star</SelectItem>
              </SelectContent>
            </Select>
            <Select value={filterCategory} onValueChange={setFilterCategory}>
              <SelectTrigger className="w-full md:w-[160px]">
                <SelectValue placeholder="Category" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Categories</SelectItem>
                {categories.map(category => (
                  <SelectItem key={category} value={category}>{category}</SelectItem>
                ))}
              </SelectContent>
            </Select>
            <Select value={filterStatus} onValueChange={setFilterStatus}>
              <SelectTrigger className="w-full md:w-[140px]">
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Status</SelectItem>
                <SelectItem value="new">New</SelectItem>
                <SelectItem value="in-progress">In Progress</SelectItem>
                <SelectItem value="resolved">Resolved</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {/* Feedback List */}
      <div className="space-y-4">
        {filteredFeedback.map((item) => (
          <Card key={item.id} className="shadow-soft hover:shadow-elegant transition-all duration-300">
            <CardHeader>
              <div className="flex justify-between items-start">
                <div className="space-y-2">
                  <div className="flex items-center gap-3">
                    <h3 className="font-semibold text-lg">{item.subject}</h3>
                    {getStatusBadge(item.status)}
                    <Badge variant="outline">{item.category}</Badge>
                  </div>
                  <div className="flex items-center gap-4 text-sm text-muted-foreground">
                    <span>{item.customer}</span>
                    <span>•</span>
                    <span>{item.timestamp}</span>
                    <span>•</span>
                    <span>Order: {item.orderRef}</span>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  {getRatingStars(item.rating)}
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground mb-4">{item.message}</p>
              <div className="flex justify-between items-center">
                <div className="flex items-center gap-2 text-sm">
                  {item.responded ? (
                    <span className="flex items-center gap-1 text-secondary">
                      <Reply className="h-4 w-4" />
                      Responded
                    </span>
                  ) : (
                    <span className="flex items-center gap-1 text-warning">
                      <MessageSquare className="h-4 w-4" />
                      Needs Response
                    </span>
                  )}
                </div>
                <div className="flex gap-2">
                  <Button variant="outline" size="sm">
                    <Eye className="h-4 w-4 mr-2" />
                    View Details
                  </Button>
                  {!item.responded && (
                    <Button 
                      size="sm"
                      onClick={() => handleReply(item)}
                      className="bg-gradient-primary hover:shadow-elegant transition-all duration-300"
                    >
                      <Reply className="h-4 w-4 mr-2" />
                      Reply
                    </Button>
                  )}
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Reply Dialog */}
      <Dialog open={isReplyDialogOpen} onOpenChange={setIsReplyDialogOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Reply to Feedback</DialogTitle>
            <DialogDescription>
              Respond to {selectedFeedback?.customer}'s feedback about "{selectedFeedback?.subject}"
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="p-4 bg-muted/50 rounded-lg">
              <p className="text-sm text-muted-foreground mb-2">Original feedback:</p>
              <p className="font-medium">{selectedFeedback?.message}</p>
            </div>
            <div className="space-y-2">
              <Label htmlFor="reply">Your Response</Label>
              <Textarea
                id="reply"
                placeholder="Type your response here..."
                rows={4}
                className="resize-none"
              />
            </div>
          </div>
          <div className="flex justify-end gap-2 mt-6">
            <Button variant="outline" onClick={() => setIsReplyDialogOpen(false)}>
              Cancel
            </Button>
            <Button onClick={handleSendReply} className="bg-gradient-primary">
              Send Reply
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
};