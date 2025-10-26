import { useState, useEffect } from "react"
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { collection, query, orderBy, limit, onSnapshot, where } from "firebase/firestore"
import { db } from "@/lib/firebase"
import { Skeleton } from "@/components/ui/skeleton"
import { Avatar, AvatarFallback } from "@/components/ui/avatar"

interface Order {
  id: string;
  customer: string;
  total: number;
  status: "preparing" | "ready" | "delivered" | "cancelled";
  createdAt: Date;
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

const getInitials = (name: string) => {
  const names = name.split(' ')
  if (names.length > 1) {
    return `${names[0][0]}${names[names.length - 1][0]}`.toUpperCase()
  }
  return name.substring(0, 2).toUpperCase()
}

export function RecentOrders() {
  const [recentOrders, setRecentOrders] = useState<Order[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const today = new Date()
    today.setHours(0, 0, 0, 0)

    const q = query(
      collection(db, "orders"),
      where("timestamp", ">=", today),
      orderBy("timestamp", "desc"),
      limit(5)
    )
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const fetchedOrders = snapshot.docs.map((doc) => {
        const data = doc.data()
        // Validate that timestamp exists and is a valid Firestore Timestamp
        if (data.timestamp && typeof data.timestamp.toDate === 'function') {
          return {
            id: doc.id,
            customer: data.fullName || "Anonymous",
            total: data.totalAmount || 0,
            status: data.status === "Pending" ? "preparing" : (data.status || "preparing"),
            createdAt: data.timestamp.toDate(),
          } as Order
        }
        return null // Return null for invalid documents
      }).filter(Boolean) as Order[] // Filter out any null entries

      setRecentOrders(fetchedOrders)
      setLoading(false)
    }, (error) => {
      console.error("Error fetching recent orders:", error)
      setLoading(false)
    })

    return () => unsubscribe()
  }, [])

  return (
    <Card>
      <CardHeader>
        <CardTitle>Recent Orders</CardTitle>
        <CardDescription>Today's most recent orders.</CardDescription>
      </CardHeader>
      <CardContent>
        {loading ? (
          <div className="space-y-4">
            <Skeleton className="h-12 w-full" />
            <Skeleton className="h-12 w-full" />
            <Skeleton className="h-12 w-full" />
          </div>
        ) : recentOrders.length === 0 ? (
          <p className="text-sm text-muted-foreground text-center">No recent orders found.</p>
        ) : (
          <div className="space-y-4">
            {recentOrders.map((order, index) => (
              <div key={order.id} className={`flex items-center gap-4 ${index < recentOrders.length - 1 ? 'pb-4 border-b border-slate-100' : ''}`}>
                <Avatar className="h-9 w-9">
                  <AvatarFallback>{getInitials(order.customer)}</AvatarFallback>
                </Avatar>
                <div className="flex-grow">
                  <p className="text-sm font-medium leading-none truncate">{order.customer}</p>
                  <p className="text-sm text-muted-foreground">
                    {order.createdAt.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </p>
                </div>
                <div className="flex items-center gap-4">
                  <div className="font-semibold text-right w-20">
                    ₹{order.total.toLocaleString()}
                  </div>
                  <Badge className={`${getStatusVariant(order.status)} w-24 justify-center`}>{order.status}</Badge>
                </div>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  )
}