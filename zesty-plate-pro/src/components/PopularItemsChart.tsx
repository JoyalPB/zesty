import { Cell, Pie, PieChart, ResponsiveContainer, Tooltip } from "recharts"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { useState, useEffect } from "react"
import { collection, getDocs } from "firebase/firestore"
import { db } from "@/lib/firebase"
import { Skeleton } from "@/components/ui/skeleton"

const COLORS = ["hsl(var(--chart-1))", "hsl(var(--chart-2))", "hsl(var(--chart-3))", "hsl(var(--chart-4))", "hsl(var(--chart-5))"]

export function PopularItemsChart() {
  const [data, setData] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchPopularItems = async () => {
      try {
        // Fetch all orders and count item frequencies
        const ordersSnapshot = await getDocs(collection(db, "orders"))
        const itemCounts = {}
        
        ordersSnapshot.docs.forEach(doc => {
          const orderData = doc.data()
          
          // Handle orders with an 'items' array
          if (orderData.items && Array.isArray(orderData.items)) {
            orderData.items.forEach(item => {
              if (item.name) {
                itemCounts[item.name] = (itemCounts[item.name] || 0) + (item.quantity || 1)
              }
            })
          } 
          // Handle single-item orders with top-level fields
          else if (orderData.name) {
            itemCounts[orderData.name] = (itemCounts[orderData.name] || 0) + (orderData.quantity || 1)
          }
        })
        
        // Convert to chart data and sort by popularity
        const chartData = Object.entries(itemCounts)
          .map(([name, value], index) => ({
            name,
            value: Number(value),
            color: COLORS[index % COLORS.length]
          }))
          .sort((a, b) => b.value - a.value)
          .slice(0, 5) // Top 5 items
        
        setData(chartData)
      } catch (error) {
        console.error("Error fetching popular items:", error)
      } finally {
        setLoading(false)
      }
    }

    fetchPopularItems()
  }, [])
  if (loading) {
    return (
      <Card className="shadow-elegant">
        <CardHeader>
          <CardTitle>Popular Items</CardTitle>
          <CardDescription>Most ordered items of all time</CardDescription>
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
        <CardTitle>Popular Items</CardTitle>
        <CardDescription>
          Most ordered items of all time
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="flex items-center justify-center">
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={data}
                cx="50%"
                cy="50%"
                labelLine={false}
                outerRadius={80}
                fill="#8884d8"
                dataKey="value"
              >
                {data.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip 
                contentStyle={{
                  backgroundColor: "hsl(var(--card))",
                  border: "1px solid hsl(var(--border))",
                  borderRadius: "8px",
                  fontSize: "12px"
                }}
                formatter={(value) => [`${value} orders`, ""]}
              />
            </PieChart>
          </ResponsiveContainer>
        </div>
        
        {/* Legend */}
        <div className="mt-4 grid grid-cols-2 gap-2">
          {data.map((item, index) => (
            <div key={item.name} className="flex items-center gap-2">
              <div 
                className="w-3 h-3 rounded-full" 
                style={{ backgroundColor: COLORS[index] }}
              />
              <span className="text-sm text-muted-foreground">{item.name}</span>
              <span className="text-sm font-medium ml-auto">{item.value}</span>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  )
}