import { useState, useEffect } from "react"
import { DollarSign, ShoppingCart, Package, AlertTriangle } from "lucide-react"
import { MetricCard } from "@/components/MetricCard"
import { RevenueChart } from "@/components/RevenueChart" 
import { PopularItemsChart } from "@/components/PopularItemsChart"
import { RecentOrders } from "@/components/RecentOrders"
import { Layout } from "@/components/Layout"
import { collection, query, where, onSnapshot } from "firebase/firestore"
import { db } from "@/lib/firebase"
import { Skeleton } from "@/components/ui/skeleton"

interface Metrics {
  totalRevenue: number
  ordersToday: number
  activeItems: number
  lowStockAlerts: number
}

const Index = () => {
  const [metrics, setMetrics] = useState<Metrics>({
    totalRevenue: 0,
    ordersToday: 0,
    activeItems: 0,
    lowStockAlerts: 0
  })
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const today = new Date()
    today.setHours(0, 0, 0, 0)

    // 🔹 Listen to today's orders in real time
    const ordersQuery = query(
      collection(db, "orders"),
      where("timestamp", ">=", today)
    )
    const unsubscribeOrders = onSnapshot(ordersQuery, (snapshot) => {
      const todayOrders = snapshot.docs
      const totalRevenue = todayOrders.reduce((sum, doc) => {
        const data = doc.data() as { totalAmount?: number }
        return sum + (data.totalAmount || 0)
      }, 0)

      setMetrics((prev) => ({
        ...prev,
        totalRevenue,
        ordersToday: todayOrders.length
      }))
      setLoading(false)
    })

    // 🔹 Listen to items in real time
    const unsubscribeItems = onSnapshot(collection(db, "items"), (snapshot) => {
      let activeItems = 0
      let lowStockCount = 0

      snapshot.docs.forEach((doc) => {
        const data = doc.data() as {
          available?: boolean
          stock?: number
          minStock?: number
          status?: string
        }

        // ✅ Count active items
        if (data.available) activeItems++

        // ✅ Prefer Firestore status
        if (data.status) {
          if (data.status === "low-stock") lowStockCount++
        } else {
          // 🔄 Fallback: calculate status locally
          if (typeof data.stock === "number" && typeof data.minStock === "number") {
            if (data.stock === 0 || data.stock < data.minStock) {
              lowStockCount++
            }
          }
        }
      })

      setMetrics((prev) => ({
        ...prev,
        activeItems,
        lowStockAlerts: lowStockCount
      }))
      setLoading(false)
    })

    // Cleanup listeners on unmount
    return () => {
      unsubscribeOrders()
      unsubscribeItems()
    }
  }, [])

  return (
    <Layout>
      <div className="space-y-6">
        {/* Page Header */}
        <div>
          <h1 className="text-3xl font-bold">Dashboard</h1>
          <p className="text-muted-foreground">
            Welcome back! Here's what's happening at your canteen today.
          </p>
        </div>

        {/* Metrics Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {loading ? (
            <>
              <Skeleton className="h-32" />
              <Skeleton className="h-32" />
              <Skeleton className="h-32" />
              <Skeleton className="h-32" />
            </>
          ) : (
            <>
              <MetricCard
                title="Total Revenue"
                value={`₹${metrics.totalRevenue.toLocaleString()}`}
                icon={DollarSign}
                description="Today's earnings"
              />
              <MetricCard
                title="Orders Today"
                value={metrics.ordersToday.toString()}
                icon={ShoppingCart}
                description="Orders processed"
              />
              <MetricCard
                title="Active Items"
                value={metrics.activeItems.toString()}
                icon={Package}
                description="Menu items available"
              />
              <MetricCard
                title="Low Stock Alerts"
                value={metrics.lowStockAlerts.toString()}
                icon={AlertTriangle}
                description="Items need restocking"
              />
            </>
          )}
        </div>

        {/* Charts */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <RevenueChart />
          <PopularItemsChart />
        </div>

        {/* Recent Orders */}
        <RecentOrders />
      </div>
    </Layout>
  )
}

export default Index
