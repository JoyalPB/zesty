import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
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
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  UserCheck,
  Search,
  Filter,
  Edit,
  Trash2,
  Clock,
  Phone,
  Check,
  X,
  Calendar,
} from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { subscribeToDocuments, deleteDocument, updateDocument } from '@/lib/firebase';

export const Staff = () => {
  const [staff, setStaff] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');
  const [editingStaffId, setEditingStaffId] = useState<string | null>(null);
  const [editValues, setEditValues] = useState<{
    staffName: string;
    phone: string;
  }>({ staffName: '', phone: '' });
  const { toast } = useToast();

  // Subscribe to staff collection
  useEffect(() => {
    const unsubscribe = subscribeToDocuments('staff', (docs) => {
      console.log('Fetched staff data:', docs);
      if (docs.length > 0) {
        console.log('Sample staff object:', docs[0]);
        console.log('createdAt value:', docs[0].createdAt);
        console.log('createdAt type:', typeof docs[0].createdAt);
      }
      setStaff(docs);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  // Filter staff based on search and filters
  const filteredStaff = staff.filter((member) => {
    const fullName = member.fullName || `${member.firstName || ''} ${member.lastName || ''}`.trim() || member.name || '';
    const matchesSearch = 
      fullName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (member.email?.toLowerCase() || '').includes(searchTerm.toLowerCase()) ||
      (member.phone?.toLowerCase() || '').includes(searchTerm.toLowerCase());
    
    const matchesStatus = filterStatus === 'all' || member.status === filterStatus;
    
    return matchesSearch && matchesStatus;
  });

  const handleDeleteStaff = async (id: string) => {
    const { error } = await deleteDocument('staff', id);
    if (error) {
      toast({
        title: "Error",
        description: error,
        variant: "destructive"
      });
    } else {
      toast({
        title: "Staff member removed",
        description: "Staff member has been successfully removed from the system.",
      });
    }
  };

  const handleEditStaff = (member: any) => {
    setEditingStaffId(member.id);
    const staffName = member.fullName || `${member.firstName || ''} ${member.lastName || ''}`.trim() || member.name || '';
    setEditValues({
      staffName: staffName,
      phone: member.phone || ''
    });
  };

  const handleSaveStaff = async (staffId: string) => {
    if (!editValues.staffName.trim()) {
      toast({
        title: "Error",
        description: "Staff name is required.",
        variant: "destructive"
      });
      return;
    }

    const updateData: any = {
      phone: editValues.phone
    };

    // Update the appropriate name field based on what exists
    const currentMember = staff.find(s => s.id === staffId);
    if (currentMember?.fullName !== undefined) {
      updateData.fullName = editValues.staffName;
    } else if (currentMember?.name !== undefined) {
      updateData.name = editValues.staffName;
    } else {
      updateData.fullName = editValues.staffName;
    }

    const { error } = await updateDocument('staff', staffId, updateData);
    if (error) {
      toast({
        title: "Error",
        description: error,
        variant: "destructive"
      });
    } else {
      toast({
        title: "Staff updated",
        description: "Staff information has been successfully updated.",
      });
      setEditingStaffId(null);
      setEditValues({ staffName: '', phone: '' });
    }
  };

  const handleCancelEdit = () => {
    setEditingStaffId(null);
    setEditValues({ staffName: '', phone: '' });
  };

  const getStatusBadge = (status: string) => {
    return (
      <Badge variant={status === 'active' ? 'default' : 'secondary'}>
        {status}
      </Badge>
    );
  };

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-foreground flex items-center gap-2">
            <UserCheck className="h-8 w-8 text-primary" />
            Staff Management
          </h1>
          <p className="text-muted-foreground mt-1">
            Manage canteen staff and their contact information
          </p>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid gap-6 md:grid-cols-3 animate-slide-up">
        <Card className="shadow-soft">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Staff</CardTitle>
            <UserCheck className="h-4 w-4 text-primary" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{staff.length}</div>
            <p className="text-xs text-muted-foreground">
              <span className="text-secondary">+2</span> from last month
            </p>
          </CardContent>
        </Card>
        
        <Card className="shadow-soft">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Active Staff</CardTitle>
            <Clock className="h-4 w-4 text-secondary" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {staff.filter(s => s.status === 'active').length}
            </div>
            <p className="text-xs text-muted-foreground">Currently active</p>
          </CardContent>
        </Card>
        
        <Card className="shadow-soft">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">With Mobile</CardTitle>
            <Phone className="h-4 w-4 text-accent" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {staff.filter(s => s.phone).length}
            </div>
            <p className="text-xs text-muted-foreground">Have contact info</p>
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
                placeholder="Search by name, email, or phone..."
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
                <SelectItem value="active">Active</SelectItem>
                <SelectItem value="inactive">Inactive</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {/* Staff Table */}
      <Card className="shadow-soft">
        <CardHeader>
          <CardTitle>Staff Directory</CardTitle>
          <CardDescription>
            {filteredStaff.length} staff members found
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Staff Name</TableHead>
                <TableHead>Email</TableHead>
                <TableHead>Mobile Number</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Date Created</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredStaff.map((member) => (
                <TableRow key={member.id} className="hover:bg-muted/50 transition-colors">
                  <TableCell>
                    {editingStaffId === member.id ? (
                      <Input
                        value={editValues.staffName}
                        onChange={(e) => setEditValues(prev => ({ ...prev, staffName: e.target.value }))}
                        className="font-medium"
                        placeholder="Staff Name"
                      />
                    ) : (
                      <div className="font-medium">
                        {member.fullName || `${member.firstName || ''} ${member.lastName || ''}`.trim() || member.name || 'N/A'}
                      </div>
                    )}
                  </TableCell>
                  <TableCell>
                    <div className="text-sm">{member.email || 'N/A'}</div>
                  </TableCell>
                  <TableCell>
                    {editingStaffId === member.id ? (
                      <Input
                        value={editValues.phone}
                        onChange={(e) => setEditValues(prev => ({ ...prev, phone: e.target.value }))}
                        placeholder="Mobile Number"
                      />
                    ) : (
                      <div className="font-medium">{member.phone || 'N/A'}</div>
                    )}
                  </TableCell>
                  <TableCell>{getStatusBadge(member.status || 'inactive')}</TableCell>
                  <TableCell>
                    <div className="flex items-center gap-1 text-sm">
                      <Calendar className="h-3 w-3" />
                      {(() => {
                        const createdDate = member.createdAt || member.created_at || member.createdat || member.timestamp;
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
                      {editingStaffId === member.id ? (
                        <>
                          <Button 
                            variant="outline" 
                            size="sm"
                            onClick={() => handleSaveStaff(member.id)}
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
                            onClick={() => handleEditStaff(member)}
                          >
                            <Edit className="h-4 w-4" />
                          </Button>
                          <Button 
                            variant="outline" 
                            size="sm"
                            onClick={() => handleDeleteStaff(member.id)}
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