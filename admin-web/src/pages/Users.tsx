import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  Users as UsersIcon,
  Search,
  Edit,
  Trash2,
  Mail,
  Phone,
  Calendar,
  Check,
  X,
} from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { addDocument, subscribeToDocuments, deleteDocument, updateDocument } from '@/lib/firebase';


export const Users = () => {
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);
  const [newUser, setNewUser] = useState({ fullName: '', email: '', phoneNumber: '', collegeId: '', username: '' });
  const [editingUserId, setEditingUserId] = useState<string | null>(null);
  const [editValues, setEditValues] = useState<{
    fullName: string;
    phoneNumber: string;
    username: string;
  }>({ fullName: '', phoneNumber: '', username: '' });
  const { toast } = useToast();

  // Subscribe to users collection
  useEffect(() => {
    const unsubscribe = subscribeToDocuments('users', (docs) => {
      console.log('Fetched users data:', docs);
      if (docs.length > 0) {
        console.log('Sample user object:', docs[0]);
        console.log('createdAt value:', docs[0].createdAt);
        console.log('createdAt type:', typeof docs[0].createdAt);
      }
      setUsers(docs);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  // Filter users based on search
  const filteredUsers = users.filter((user) => {
    const matchesSearch = 
      (user.fullName && user.fullName.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (user.email && user.email.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (user.username && user.username.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (user.collegeId && user.collegeId.toLowerCase().includes(searchTerm.toLowerCase()));
    
    return matchesSearch;
  });

  const handleDeleteUser = async (id: string) => {
    const { error } = await deleteDocument('users', id);
    if (error) {
      toast({
        title: "Error",
        description: error,
        variant: "destructive"
      });
    } else {
      toast({
        title: "User deleted",
        description: "User has been successfully removed from the system.",
      });
    }
  };

  const handleAddUser = async () => {
    if (!newUser.fullName || !newUser.email || !newUser.username) {
      toast({
        title: "Error",
        description: "Please fill in all required fields.",
        variant: "destructive"
      });
      return;
    }

    const userData = {
      ...newUser,
      createdAt: new Date().toISOString(),
    };

    const { error } = await addDocument('users', userData);
    if (error) {
      toast({
        title: "Error",
        description: error,
        variant: "destructive"
      });
    } else {
      toast({
        title: "User added",
        description: "New user has been successfully created.",
      });
      setIsAddDialogOpen(false);
      setNewUser({ fullName: '', email: '', phoneNumber: '', collegeId: '', username: '' });
    }
  };

  const handleEditUser = (user: any) => {
    setEditingUserId(user.id);
    setEditValues({
      fullName: user.fullName || '',
      phoneNumber: user.phoneNumber || '',
      username: user.username || ''
    });
  };

  const handleSaveUser = async (userId: string) => {
    if (!editValues.fullName || !editValues.username) {
      toast({
        title: "Error",
        description: "Full name and username are required.",
        variant: "destructive"
      });
      return;
    }

    const { error } = await updateDocument('users', userId, editValues);
    if (error) {
      toast({
        title: "Error",
        description: error,
        variant: "destructive"
      });
    } else {
      toast({
        title: "User updated",
        description: "User information has been successfully updated.",
      });
      setEditingUserId(null);
      setEditValues({ fullName: '', phoneNumber: '', username: '' });
    }
  };

  const handleCancelEdit = () => {
    setEditingUserId(null);
    setEditValues({ fullName: '', phoneNumber: '', username: '' });
  };

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-foreground flex items-center gap-2">
            <UsersIcon className="h-8 w-8 text-primary" />
            Users Management
          </h1>
          <p className="text-muted-foreground mt-1">
            Manage user accounts and view their information
          </p>
        </div>
        
      </div>

      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Card className="shadow-soft">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Users</CardTitle>
            <UsersIcon className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{users.length}</div>
            <p className="text-xs text-muted-foreground">
              Registered users in the system
            </p>
          </CardContent>
        </Card>
        
        <Card className="shadow-soft">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Users with Mobile</CardTitle>
            <Phone className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {users.filter(user => user.phoneNumber && user.phoneNumber.trim()).length}
            </div>
            <p className="text-xs text-muted-foreground">
              Users with phone numbers
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Filters and Search */}
      <Card className="shadow-soft">
        <CardHeader>
          <CardTitle className="text-lg">Search & Filter</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col md:flex-row gap-4">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search by full name, email, username, or college ID..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10"
              />
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Users Table */}
      <Card className="shadow-soft">
        <CardHeader>
          <CardTitle>Users List</CardTitle>
          <CardDescription>
            {loading ? 'Loading...' : `${filteredUsers.length} users found`}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Full Name</TableHead>
                <TableHead>Email</TableHead>
                <TableHead>Phone Number</TableHead>
                <TableHead>College ID</TableHead>
                <TableHead>Username</TableHead>
                <TableHead>Created At</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredUsers.map((user) => (
                <TableRow key={user.id} className="hover:bg-muted/50 transition-colors">
                  <TableCell>
                    {editingUserId === user.id ? (
                      <Input
                        value={editValues.fullName}
                        onChange={(e) => setEditValues(prev => ({ ...prev, fullName: e.target.value }))}
                        className="font-medium"
                        placeholder="Full Name"
                      />
                    ) : (
                      <div className="font-medium">{user.fullName}</div>
                    )}
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-1 text-sm">
                      <Mail className="h-3 w-3" />
                      <span className="text-muted-foreground">{user.email}</span>
                    </div>
                  </TableCell>
                  <TableCell>
                    {editingUserId === user.id ? (
                      <Input
                        value={editValues.phoneNumber}
                        onChange={(e) => setEditValues(prev => ({ ...prev, phoneNumber: e.target.value }))}
                        placeholder="Phone Number"
                      />
                    ) : (
                      <div className="flex items-center gap-1 text-sm">
                        <Phone className="h-3 w-3" />
                        <span className="text-muted-foreground">{user.phoneNumber}</span>
                      </div>
                    )}
                  </TableCell>
                  <TableCell>{user.collegeId}</TableCell>
                  <TableCell>
                    {editingUserId === user.id ? (
                      <Input
                        value={editValues.username}
                        onChange={(e) => setEditValues(prev => ({ ...prev, username: e.target.value }))}
                        placeholder="Username"
                      />
                    ) : (
                      <div>{user.username}</div>
                    )}
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-1 text-sm">
                      <Calendar className="h-3 w-3" />
                      {(() => {
                        const createdDate = user.createdAt || user.created_at || user.createdat || user.timestamp;
                        if (!createdDate) return 'N/A';
                        
                        try {
                          // Handle different date formats
                          let date;
                          if (typeof createdDate === 'string') {
                            date = new Date(createdDate);
                          } else if (createdDate.toDate && typeof createdDate.toDate === 'function') {
                            // Firestore Timestamp
                            date = createdDate.toDate();
                          } else if (createdDate.seconds) {
                            // Firestore Timestamp object
                            date = new Date(createdDate.seconds * 1000);
                          } else {
                            date = new Date(createdDate);
                          }
                          
                          if (isNaN(date.getTime())) return 'Invalid Date';
                          
                          // Format as date-month-year
                          const day = date.getDate().toString().padStart(2, '0');
                          const month = (date.getMonth() + 1).toString().padStart(2, '0');
                          const year = date.getFullYear();
                          return `${day}-${month}-${year}`;
                        } catch (error) {
                          console.error('Date parsing error:', error, 'for value:', createdDate);
                          return 'Invalid Date';
                        }
                      })()}
                    </div>
                  </TableCell>
                  <TableCell className="text-right">
                    <div className="flex gap-2 justify-end">
                      {editingUserId === user.id ? (
                        <>
                          <Button 
                            variant="outline" 
                            size="sm"
                            onClick={() => handleSaveUser(user.id)}
                            className="text-green-600 hover:text-green-700"
                          >
                            <Check className="h-4 w-4" />
                          </Button>
                          <Button 
                            variant="outline" 
                            size="sm"
                            onClick={handleCancelEdit}
                            className="text-red-600 hover:text-red-700"
                          >
                            <X className="h-4 w-4" />
                          </Button>
                        </>
                      ) : (
                        <>
                          <Button 
                            variant="outline" 
                            size="sm"
                            onClick={() => handleEditUser(user)}
                          >
                            <Edit className="h-4 w-4" />
                          </Button>
                          <Button 
                            variant="outline" 
                            size="sm"
                            onClick={() => handleDeleteUser(user.id)}
                            className="text-destructive hover:text-destructive-foreground hover:bg-destructive"
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </>
                      )}
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