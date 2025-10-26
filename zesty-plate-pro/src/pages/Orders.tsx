import { useState, useEffect } from "react"
import { Search, Filter, MoreHorizontal, Eye, Edit, Trash2 } from "lucide-react"
import { Layout } from "@/components/Layout"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog"
import { collection, onSnapshot, query, orderBy, doc, updateDoc } from "firebase/firestore"
import { db } from "@/lib/firebase"
import { useToast } from "@/hooks/use-toast"

interface OrderItem {
  name: string;
  quantity: number;
  price: number;
}

interface Order {
  id: string;
  customer: string;
  items: OrderItem[];
  total: number;
  status: "preparing" | "ready" | "delivered" | "cancelled";
  createdAt: Date;
  notes?: string;
}

const getStatusVariant = (status: string) => {
  switch (status) {
    case "preparing": 
      return "bg-status-preparing text-white"
    case "ready":
      return "bg-status-ready text-white"
    case "delivered":
      return "bg-status-completed text-white"
    case "cancelled":
      return "bg-destructive text-destructive-foreground"
    default:
      return "bg-muted text-muted-foreground"
  }
}

const getNextStatus = (status: string) => {
  switch (status) {
    case "preparing":
      return "ready"
    case "ready":
      return "delivered"
    default:
      return status
  }
}

const Orders = () => {
  const [filter, setFilter] = useState("all")
  const [searchTerm, setSearchTerm] = useState("")
  const [orderList, setOrderList] = useState<Order[]>([])
  const [loading, setLoading] = useState(true)
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false)
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null)
  const [newStatus, setNewStatus] = useState<Order['status']>('preparing')
  const { toast } = useToast()

  useEffect(() => {
    setLoading(true)
    const q = query(collection(db, "orders"), orderBy("timestamp", "desc"))
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const fetchedOrders = snapshot.docs.reduce((acc, doc) => {
        const data = doc.data()
        // Basic validation to ensure timestamp exists
        if (data.timestamp && typeof data.timestamp.toDate === 'function') {
          // Adapt single-item order structure to the expected items array
          const orderItems: OrderItem[] = (data.items && Array.isArray(data.items))
            ? data.items
            : [{
                name: data.name || 'Unknown Item',
                quantity: data.quantity || 1,
                price: data.price || 0
              }];

          // Prefer fullName field; fall back to username or N/A
          const customerName = (typeof data.fullName === 'string' && data.fullName.trim())
            ? data.fullName.trim()
            : (typeof data.username === 'string' && data.username.trim())
              ? data.username.trim()
              : "N/A"

          acc.push({
            id: doc.id,
            customer: customerName,
            items: orderItems,
            total: data.totalAmount || 0,
            status: data.status === "Pending" ? "preparing" : (data.status || "preparing"),
            createdAt: data.timestamp.toDate(),
            notes: data.notes,
          } as Order)
        } else {
          console.warn(`Skipping order with ID ${doc.id} due to invalid or missing 'timestamp' field.`)
        }
        return acc
      }, [] as Order[])
      
      setOrderList(fetchedOrders)
      setLoading(false)
    }, (error) => {
      console.error("Error fetching orders:", error)
      toast({ title: "Error", description: "Failed to fetch orders.", variant: "destructive" })
      setLoading(false)
    })

    return () => unsubscribe()
  }, [toast])

  const filteredOrders = orderList.filter(order => {
    const matchesSearch = order.customer.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         order.id.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesFilter = filter === "all" || order.status === filter
    return matchesSearch && matchesFilter
  })

  // Filter for today's data for the summary cards
  const todayStart = new Date()
  todayStart.setHours(0, 0, 0, 0)
  const todaysOrders = orderList.filter(order => order.createdAt >= todayStart)

  const getTodaysTotalAmount = () => {
    return todaysOrders.reduce((sum, order) => sum + order.total, 0)
  }

  const handleManualStatusUpdate = async () => {
    if (!selectedOrder) return

    const orderRef = doc(db, "orders", selectedOrder.id)
    try {
      await updateDoc(orderRef, { status: newStatus })
      toast({ title: "Status Updated", description: `Order ${selectedOrder.id.substring(0, 7)} is now ${newStatus}.` })
    } catch (error) {
      console.error("Error updating status:", error)
      toast({ title: "Error", description: "Failed to update order status.", variant: "destructive" })
    } finally {
      setIsEditDialogOpen(false)
      setSelectedOrder(null)
    }
  }

  const cancelOrder = async (orderId: string) => {
    const orderRef = doc(db, "orders", orderId)
    try {
      await updateDoc(orderRef, { status: "cancelled" })
      toast({ title: "Order Cancelled", description: `Order ${orderId.substring(0, 7)} has been cancelled.` })
    } catch (error) {
      console.error("Error cancelling order:", error)
      toast({ title: "Error", description: "Failed to cancel order.", variant: "destructive" })
    }
  }

  const updateOrderStatus = async (orderId: string) => {
    const order = orderList.find(o => o.id === orderId)
    if (!order) return

    const newStatus = getNextStatus(order.status)
    const orderRef = doc(db, "orders", orderId)

    try {
      await updateDoc(orderRef, { status: newStatus })
      toast({ title: "Status Updated", description: `Order ${orderId.substring(0,7)} is now ${newStatus}.` })
    } catch (error) {
      console.error("Error updating status:", error)
      toast({ title: "Error", description: "Failed to update order status.", variant: "destructive" })
    }
  }

  const getTotalAmount = () => {
    return filteredOrders.reduce((sum, order) => sum + order.total, 0)
  }

  return (
    <Layout>
      <div className="space-y-6">
        {/* Header */}
        <div>
          <h1 className="text-3xl font-bold">Orders Management</h1>
          <p className="text-muted-foreground">
            Track and manage all customer orders in real-time.
          </p>
        </div>

        {/* Summary Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <Card>
            <CardContent className="p-4">
              <div className="text-2xl font-bold">{todaysOrders.length}</div>
              <p className="text-sm text-muted-foreground">Today's Orders</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4">
              <div className="text-2xl font-bold">₹{getTodaysTotalAmount()}</div>
              <p className="text-sm text-muted-foreground">Today's Value</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4">
              <div className="text-2xl font-bold">
                {todaysOrders.filter(o => o.status === "delivered").length}
              </div>
              <p className="text-sm text-muted-foreground">Delivered Today</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4">
              <div className="text-2xl font-bold">
                {todaysOrders.filter(o => o.status === "preparing").length}
              </div>
              <p className="text-sm text-muted-foreground">Preparing Today</p>
            </CardContent>
          </Card>
        </div>

        {/* Filters and Search */}
        <Card>
          <CardHeader>
            <CardTitle>Order List</CardTitle>
            <CardDescription>
              Manage and track customer orders
            </CardDescription>
            <div className="flex flex-col sm:flex-row gap-4">
              <div className="relative flex-1">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Search orders or customers..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10"
                />
              </div>
              <Select value={filter} onValueChange={setFilter}>
                <SelectTrigger className="w-full sm:w-40">
                  <SelectValue placeholder="Filter status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Status</SelectItem>
                  <SelectItem value="preparing">Preparing</SelectItem>
                  <SelectItem value="ready">Ready</SelectItem>
                  <SelectItem value="delivered">Delivered</SelectItem>
                  <SelectItem value="cancelled">Cancelled</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </CardHeader>
          <CardContent>
            <div className="relative w-full overflow-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Order ID</TableHead>
                    <TableHead>Customer</TableHead>
                    <TableHead>Items</TableHead>
                    <TableHead className="text-right">Total</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead className="text-right">Time</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {loading ? (
                    <TableRow>
                      <TableCell colSpan={7} className="text-center h-24">Loading orders...</TableCell>
                    </TableRow>
                  ) : filteredOrders.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={7} className="text-center h-24">No orders found.</TableCell>
                    </TableRow>
                  ) : (
                    filteredOrders.map((order) => (
                      <TableRow key={order.id}>
                        <TableCell className="font-medium">{order.id.substring(0, 7)}</TableCell>
                        <TableCell>
                          <div className="font-medium">{order.customer}</div>
                        </TableCell>
                        <TableCell>
                          <div className="space-y-1">
                            {order.items.map((item, index) => (
                              <div key={index} className="text-sm">
                                {item.quantity}x {item.name}
                              </div>
                            ))}
                            {order.notes && (
                              <div className="text-xs text-muted-foreground italic">
                                Note: {order.notes}
                              </div>
                            )}
                          </div>
                        </TableCell>
                        <TableCell className="font-medium text-right">₹{order.total}</TableCell>
                        <TableCell>
                          <Badge className={getStatusVariant(order.status)}>
                            {order.status}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-muted-foreground text-right">
                          <div>{order.createdAt.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</div>
                          <div className="text-xs">{order.createdAt.toLocaleDateString()}</div>
                        </TableCell>
                        <TableCell className="text-right">
                          <div className="flex items-center justify-end gap-2">
                            {order.status !== "delivered" && order.status !== "cancelled" && (
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={() => updateOrderStatus(order.id)}
                              >
                                {order.status === "preparing" && "Mark Ready"}
                                {order.status === "ready" && "Mark Delivered"}
                              </Button>
                            )}
                            <DropdownMenu>
                              <DropdownMenuTrigger asChild>
                                <Button variant="ghost" size="sm">
                                  <MoreHorizontal className="h-4 w-4" />
                                </Button>
                              </DropdownMenuTrigger>
                              <DropdownMenuContent align="end">
                                <DropdownMenuItem onSelect={() => {
                                  setSelectedOrder(order)
                                  setNewStatus(order.status)
                                  setIsEditDialogOpen(true)
                                }}>
                                  <Edit className="h-4 w-4 mr-2" />
                                  Edit Status
                                </DropdownMenuItem>
                                <DropdownMenuItem
                                  onSelect={() => cancelOrder(order.id)}
                                  className="text-destructive"
                                >
                                  <Trash2 className="h-4 w-4 mr-2" />
                                  Cancel Order
                                </DropdownMenuItem>
                              </DropdownMenuContent>
                            </DropdownMenu>
                          </div>
                        </TableCell>
                      </TableRow>
                  )))}
                </TableBody>
              </Table>
            </div>
          </CardContent>
        </Card>
      </div>
      <Dialog open={isEditDialogOpen} onOpenChange={setIsEditDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Order Status</DialogTitle>
            <DialogDescription>
              Manually change the status for order {selectedOrder?.id.substring(0, 7)}
            </DialogDescription>
          </DialogHeader>
          <div className="py-4">
            <Select value={newStatus} onValueChange={(value) => setNewStatus(value as Order['status'])}>
              <SelectTrigger>
                <SelectValue placeholder="Select a status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="preparing">Preparing</SelectItem>
                <SelectItem value="ready">Ready</SelectItem>
                <SelectItem value="delivered">Delivered</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsEditDialogOpen(false)}>Cancel</Button>
            <Button onClick={handleManualStatusUpdate}>Save Changes</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </Layout>
  )
}

export default Orders