import { Area, AreaChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { useState, useEffect } from "react"
import { collection, query, where, getDocs } from "firebase/firestore"
import { db } from "@/lib/firebase"
import { Skeleton } from "@/components/ui/skeleton"

export function RevenueChart() {
  const [data, setData] = useState<Array<{ name: string; revenue: number }>>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchRevenueData = async () => {
      setLoading(true)
      try {
        const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
        const sevenDaysAgo = new Date()
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 6)
        sevenDaysAgo.setHours(0, 0, 0, 0)

        // Initialize daily revenue map for the last 7 days
        const dailyRevenueMap = new Map<string, number>()
        for (let i = 0; i < 7; i++) {
          const date = new Date(sevenDaysAgo)
          date.setDate(date.getDate() + i)
          
          // Use local date parts for the key to ensure consistency
          const year = date.getFullYear()
          const month = String(date.getMonth() + 1).padStart(2, '0')
          const day = String(date.getDate()).padStart(2, '0')
          const dayName = days[date.getDay()]
          const mapKey = `${year}-${month}-${day}-${dayName}`

          dailyRevenueMap.set(mapKey, 0)
        }

        // Fetch all orders from the last 7 days in one query
        const ordersQuery = query(
          collection(db, "orders"),
          where("timestamp", ">=", sevenDaysAgo)
        )
        
        const snapshot = await getDocs(ordersQuery)
        snapshot.docs.forEach(doc => {
          const orderData = doc.data()
          const orderDate = orderData.timestamp.toDate() // This is a local Date object
          
          // Use local date parts to create the key, avoiding UTC conversion issues
          const year = orderDate.getFullYear()
          const month = String(orderDate.getMonth() + 1).padStart(2, '0')
          const day = String(orderDate.getDate()).padStart(2, '0')
          const dayName = days[orderDate.getDay()]
          const mapKey = `${year}-${month}-${day}-${dayName}`

          if (dailyRevenueMap.has(mapKey)) {
            const currentRevenue = dailyRevenueMap.get(mapKey) || 0
            dailyRevenueMap.set(mapKey, currentRevenue + (orderData.totalAmount || 0))
          }
        })
        
        // Format data for the chart
        const revenueData = Array.from(dailyRevenueMap.entries()).map(([key, revenue]) => {
          const parts = key.split('-')
          return {
            name: parts[parts.length - 1], // Correctly extract day name (e.g., 'Mon')
            revenue: revenue
          }
        })

        setData(revenueData)
      } catch (error) {
        console.error("Error fetching revenue data:", error)
      } finally {
        setLoading(false)
      }
    }

    fetchRevenueData()
  }, [])

  if (loading) {
    return (
      <Card className="shadow-elegant">
        <CardHeader>
          <CardTitle>Weekly Revenue</CardTitle>
          <CardDescription>Revenue trends for the past 7 days</CardDescription>
        </CardHeader>
        <CardContent>
          <Skeleton className="h-[300px]" />
        </CardContent>
      </Card>
    )
  }

  return (
    <Card className="shadow-elegant">
      <CardHeader>
        <CardTitle>Weekly Revenue</CardTitle>
        <CardDescription>
          Revenue trends for the past 7 days
        </CardDescription>
      </CardHeader>
      <CardContent>
        <ResponsiveContainer width="100%" height={300}>
          <AreaChart data={data}>
            <defs>
              <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="hsl(var(--primary))" stopOpacity={0.3}/>
                <stop offset="95%" stopColor="hsl(var(--primary))" stopOpacity={0}/>
              </linearGradient>
            </defs>
            <XAxis 
              dataKey="name" 
              axisLine={false}
              tickLine={false}
              className="text-xs"
            />
            <YAxis 
              axisLine={false}
              tickLine={false}
              className="text-xs"
              tickFormatter={(value) => `₹${value}`}
            />
            <Tooltip 
              contentStyle={{
                backgroundColor: "hsl(var(--card))",
                border: "1px solid hsl(var(--border))",
                borderRadius: "8px",
                fontSize: "12px"
              }}
              formatter={(value) => [`₹${value}`, "Revenue"]}
            />
            <Area
              type="monotone"
              dataKey="revenue"
              stroke="hsl(var(--primary))"
              strokeWidth={2}
              fillOpacity={1}
              fill="url(#colorRevenue)"
            />
          </AreaChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  )
}