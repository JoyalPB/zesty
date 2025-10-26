// React and UI components
import { useEffect, useState } from "react"
import {
  Search,
  Plus,
  MoreHorizontal,
  Edit,
  Trash2,
  AlertTriangle,
  Package as PackageIcon,
  Loader2
} from "lucide-react"
import { Layout } from "@/components/Layout"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { useToast } from "@/components/ui/use-toast"
import { Switch } from "@/components/ui/switch"

// Firebase (for data operations)
import { db } from "@/lib/firebase"
import { collection, addDoc, updateDoc, deleteDoc, doc, onSnapshot } from "firebase/firestore"

// Supabase (for image uploads)
import { supabase } from "@/integrations/supabase/client"

// Types
interface InventoryItem {
  id: string
  name: string
  category: string
  dietary: "veg" | "non-veg"
  price: number
  stock: number
  minStock: number
  status: "in-stock" | "low-stock" | "out-stock" // This is now a derived client-side property
  description: string
  image: string
  createdAt: Date
  available?: boolean
}

interface NewItem {
  name: string
  category: string
  dietary: "veg" | "non-veg"
  price: string
  stock: string
  minStock: string
  description: string
}

const categories = ["All", "Main Course", "Snacks", "Breakfast Items", "Beverages", "Desserts & Sweets", "Bakery Items", "Dishes"]

// ✅ NEW: Helper function to compute status dynamically
const calculateStatus = (stock: number, minStock: number): InventoryItem["status"] => {
  if (stock <= 0) return "out-stock"
  if (stock < minStock) return "low-stock"
  return "in-stock"
}

const getStatusVariant = (status: string) => {
  switch (status) {
    case "in-stock": return "bg-status-ready text-white"
    case "low-stock": return "bg-status-low-stock text-white"
    case "out-stock": return "bg-status-out-stock text-white"
    default: return "bg-muted text-muted-foreground"
  }
}

const getStatusIcon = (status: string) => {
  switch (status) {
    case "in-stock": return <PackageIcon className="h-3 w-3" />
    case "low-stock":
    case "out-stock": return <AlertTriangle className="h-3 w-3" />
    default: return null
  }
}

const Inventory = () => {
  const [filter, setFilter] = useState("All")
  const [searchTerm, setSearchTerm] = useState("")
  const [debouncedSearch, setDebouncedSearch] = useState("")
  const [inventoryList, setInventoryList] = useState<InventoryItem[]>([])
  const [editingItem, setEditingItem] = useState<InventoryItem | null>(null)
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [imagePreview, setImagePreview] = useState<string | null>(null)
  const [editImagePreview, setEditImagePreview] = useState<string | null>(null)
  const [addFile, setAddFile] = useState<File | null>(null)
  const [editFile, setEditFile] = useState<File | null>(null)
  const { toast } = useToast()

  const [newItem, setNewItem] = useState<NewItem>({
    name: "",
    category: "Main Course",
    dietary: "veg",
    price: "",
    stock: "",
    minStock: "",
    description: ""
  })

  // 🔹 Real-time Firestore subscription
  useEffect(() => {
    setIsLoading(true)
    const unsubscribe = onSnapshot(collection(db, "items"), snapshot => {
      // ✅ MODIFIED: Compute status on the client after fetching data
      const items = snapshot.docs.map(doc => {
        const data = doc.data()
        return {
          id: doc.id,
          ...data,
          // Dynamically add the status property to the client-side object
          status: calculateStatus(data.stock, data.minStock),
          createdAt: data.createdAt?.toDate() || new Date()
        }
      }) as InventoryItem[]
      setInventoryList(items)
      setIsLoading(false)
    }, error => {
      console.error("Error fetching items:", error)
      toast({ title: "Error", description: "Failed to load inventory items", variant: "destructive" })
      setIsLoading(false)
    })
    return () => unsubscribe()
  }, [toast])

  // 🔹 Debounce search
  useEffect(() => {
    const timer = setTimeout(() => setDebouncedSearch(searchTerm), 300)
    return () => clearTimeout(timer)
  }, [searchTerm])

  // 🔹 Handle image upload and preview
  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>, isEdit: boolean = false) => {
    const file = e.target.files?.[0]
    if (!file) return
    if (!file.type.startsWith("image/")) {
      toast({ title: "Invalid file", description: "Please upload an image", variant: "destructive" })
      return
    }
    if (file.size > 5 * 1024 * 1024) {
      toast({ title: "File too large", description: "Max 5MB", variant: "destructive" })
      return
    }

    const reader = new FileReader()
    reader.onloadend = () => {
      if (isEdit) {
        setEditImagePreview(reader.result as string)
        setEditFile(file)
      } else {
        setImagePreview(reader.result as string)
        setAddFile(file)
      }
    }
    reader.readAsDataURL(file)
  }

  // 🔹 Add Item
  const addItem = async () => {
    setIsLoading(true)
    try {
      if (!newItem.name.trim() || !newItem.category || !newItem.dietary || !newItem.price || isNaN(Number(newItem.price)) || !newItem.stock || isNaN(Number(newItem.stock)) || !newItem.minStock || isNaN(Number(newItem.minStock))) {
        toast({ title: "Missing Fields", description: "Please fill all required fields correctly", variant: "destructive" })
        setIsLoading(false)
        return
      }

      const stockNum = parseInt(newItem.stock)
      const minStockNum = parseInt(newItem.minStock)
      const priceNum = parseFloat(newItem.price)
      
      if (stockNum < 0 || minStockNum < 0 || priceNum < 0) {
        toast({ title: "Invalid values", description: "Values cannot be negative", variant: "destructive" })
        setIsLoading(false)
        return
      }

  
      let imageUrl = "/placeholder.svg"
      if (addFile) {
        const fileName = `${Date.now()}_${addFile.name}`
        const { error: uploadError } = await supabase.storage
          .from('item-images')
          .upload(fileName, addFile)
        
        if (uploadError) throw uploadError
        
        const { data } = supabase.storage
          .from('item-images')
          .getPublicUrl(fileName)
        
        imageUrl = data.publicUrl
      }

      // ✅ MODIFIED: The 'status' field is no longer saved to Firestore
      await addDoc(collection(db, "items"), {
        name: newItem.name,
        category: newItem.category,
        dietary: newItem.dietary,
        price: priceNum,
        stock: stockNum,
        minStock: minStockNum,
        description: newItem.description,
        image: imageUrl,
        createdAt: new Date(),
        available: true
      })

      setNewItem({ name: "", category: "Main Course", dietary: "veg", price: "", stock: "", minStock: "", description: "" })
      setImagePreview(null)
      setAddFile(null)
      setIsAddDialogOpen(false)
      toast({ title: "Success", description: "Item added successfully" })
    } catch (err) {
      console.error(err)
      toast({ title: "Error", description: "Failed to add item", variant: "destructive" })
    } finally { setIsLoading(false) }
  }

  // 🔹 Update Stock
  const updateStock = async (itemId: string, newStock: number) => {
    const item = inventoryList.find(i => i.id === itemId)
    if (!item || newStock < 0) return toast({ title: "Invalid stock", description: "Cannot be negative", variant: "destructive" })

    // ❌ REMOVED: Status is computed on read, not written on update
    // const status = newStock === 0 ? "out-stock" : newStock < item.minStock ? "low-stock" : "in-stock"
    
    // ✅ MODIFIED: Only update the stock field in Firestore
    try { await updateDoc(doc(db, "items", itemId), { stock: newStock }) }
    catch (err) { console.error(err); toast({ title: "Error", description: "Failed to update stock", variant: "destructive" }) }
  }

  // 🔹 Delete Item
  const deleteItem = async (id: string) => {
    if (!confirm("Are you sure you want to delete this item?")) return
    try { await deleteDoc(doc(db, "items", id)); toast({ title: "Item deleted" }) }
    catch (err) { console.error(err); toast({ title: "Error", description: "Failed to delete item", variant: "destructive" }) }
  }

  // 🔹 Save Edit
  const saveEdit = async () => {
    if (!editingItem) return
    setIsLoading(true)
    try {
      const { stock, minStock, price } = editingItem
      if (stock < 0 || minStock < 0 || price < 0) return toast({ title: "Invalid values", description: "Cannot be negative", variant: "destructive" })

      let imageUrl = editingItem.image
      if (editFile) {
        const fileName = `${Date.now()}_${editFile.name}`
        const { error: uploadError } = await supabase.storage
          .from('item-images')
          .upload(fileName, editFile)
        
        if (uploadError) throw uploadError
        
        const { data } = supabase.storage
          .from('item-images')
          .getPublicUrl(fileName)
        
        imageUrl = data.publicUrl
      }
      
      // ❌ REMOVED: Status is not calculated or stored
      // const status = stockNum === 0 ? "out-stock" : stockNum < minStockNum ? "low-stock" : "in-stock"

      // ✅ MODIFIED: Prepare update object without 'status' or 'id'
      const { id, status, ...dataToUpdate } = editingItem;
      await updateDoc(doc(db, "items", editingItem.id), { 
        ...dataToUpdate, 
        image: imageUrl, 
        available: editingItem.available !== false 
      });

      setEditingItem(null); setEditImagePreview(null); setEditFile(null); setIsDialogOpen(false)
      toast({ title: "Changes saved" })
    } catch (err) { console.error(err); toast({ title: "Error", description: "Failed to update item", variant: "destructive" }) }
    finally { setIsLoading(false) }
  }

  // 🔹 Toggle Available
  const toggleAvailable = async (item: InventoryItem) => {
    try {
      await updateDoc(doc(db, "items", item.id), { available: !item.available })
      toast({
        title: `Item ${!item.available ? "marked as available" : "marked as unavailable"}`,
        description: item.name,
      })
    } catch (err) {
      console.error(err)
      toast({ title: "Error", description: "Failed to update availability", variant: "destructive" })
    }
  }

  // 🔹 Filtered Inventory - No changes needed, it uses the client-side state
  const filteredInventory = inventoryList.filter(item => {
    const matchesSearch = item.name.toLowerCase().includes(debouncedSearch.toLowerCase()) || item.category.toLowerCase().includes(debouncedSearch.toLowerCase())
    const matchesFilter = filter === "All" || item.category === filter
    return matchesSearch && matchesFilter
  })

  // 🔹 Summary Calculation - No changes needed, it uses the client-side `item.status`
  const summary = {
    total: filteredInventory.length,
    inStock: filteredInventory.filter(item => item.status === "in-stock").length,
    lowStock: filteredInventory.filter(item => item.status === "low-stock").length,
    outStock: filteredInventory.filter(item => item.status === "out-stock").length
  }

  // The entire JSX render remains the same as it correctly uses the derived status
  // from the `inventoryList` state.
  return (
    <Layout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex justify-between items-start">
          <div>
            <h1 className="text-3xl font-bold">Inventory Management</h1>
            <p className="text-muted-foreground">
              Manage your menu items and track stock levels.
            </p>
          </div>
          <Button 
            className="bg-gradient-primary hover:opacity-90"
            onClick={() => setIsAddDialogOpen(true)}
            disabled={isLoading}
          >
            {isLoading ? (
              <Loader2 className="h-4 w-4 mr-2 animate-spin" />
            ) : (
              <Plus className="h-4 w-4 mr-2" />
            )}
            Add Item
          </Button>
        </div>

        {/* Summary */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <Card><CardContent className="p-4"><div className="text-2xl font-bold">{summary.total}</div><p className="text-sm text-muted-foreground">Total Items</p></CardContent></Card>
          <Card><CardContent className="p-4"><div className="text-2xl font-bold text-status-ready">{summary.inStock}</div><p className="text-sm text-muted-foreground">In Stock</p></CardContent></Card>
          <Card><CardContent className="p-4"><div className="text-2xl font-bold text-status-low-stock">{summary.lowStock}</div><p className="text-sm text-muted-foreground">Low Stock</p></CardContent></Card>
          <Card><CardContent className="p-4"><div className="text-2xl font-bold text-status-out-stock">{summary.outStock}</div><p className="text-sm text-muted-foreground">Out of Stock</p></CardContent></Card>
        </div>

        {/* Inventory Table */}
        <Card>
          <CardHeader>
            <CardTitle>Inventory Items</CardTitle>
            <CardDescription>Track and manage your menu items and stock levels</CardDescription>
            <div className="flex flex-col sm:flex-row gap-4">
              <div className="relative flex-1">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input 
                  placeholder="Search items..." 
                  value={searchTerm} 
                  onChange={(e) => setSearchTerm(e.target.value)} 
                  className="pl-10" 
                />
              </div>
              <Select value={filter} onValueChange={setFilter}>
                <SelectTrigger className="w-full sm:w-40"><SelectValue placeholder="Category" /></SelectTrigger>
                <SelectContent>
                  {categories.map(c => (
                    <SelectItem key={c} value={c}>{c}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className="flex justify-center items-center py-8">
                <Loader2 className="h-8 w-8 animate-spin text-primary" />
              </div>
            ) : filteredInventory.length === 0 ? (
              <div className="text-center py-8 text-muted-foreground">
                {searchTerm || filter !== "All" ? "No items match your search criteria" : "No items found. Add your first item to get started."}
              </div>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Item</TableHead>
                    <TableHead>Category</TableHead>
                    <TableHead>Price</TableHead>
                    <TableHead>Stock</TableHead>
                    <TableHead className="text-center">Status</TableHead>
                    <TableHead className="text-center">Available</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredInventory.map(item => (
                    <TableRow key={item.id}>
                      <TableCell>
                        <div className="flex items-center gap-3">
                          {item.image ? (
                            <img src={item.image} alt={item.name} className="w-10 h-10 rounded-lg object-cover" />
                          ) : (
                            <div className="w-10 h-10 bg-muted rounded-lg flex items-center justify-center">
                              <PackageIcon className="h-5 w-5 text-muted-foreground" />
                            </div>
                          )}
                          <div>
                            <div className="flex items-center gap-1.5">
                              {item.dietary && (
                                <div className={`p-0.5 border ${item.dietary === 'veg' ? 'border-green-500' : 'border-red-500'}`}>
                                  <div className={`w-1.5 h-1.5 rounded-full ${item.dietary === 'veg' ? 'bg-green-500' : 'bg-red-500'}`} />
                                </div>
                              )}
                              <div className="font-medium">{item.name}</div>
                            </div>
                            <div className="text-sm text-muted-foreground line-clamp-1">{item.description}</div>
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>{item.category}</TableCell>
                      <TableCell className="font-medium">₹{item.price}</TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <span className="font-medium">{item.stock}</span>
                          <span className="text-muted-foreground">units</span>
                          {item.stock < item.minStock && item.stock > 0 && (
                            <AlertTriangle className="h-4 w-4 text-status-low-stock" />
                          )}
                        </div>
                        <div className="text-xs text-muted-foreground">Min: {item.minStock}</div>
                      </TableCell>
                      <TableCell className="text-center">
                        <Badge className={getStatusVariant(item.status)}>
                          <div className="flex items-center gap-1">
                            {getStatusIcon(item.status)}
                            {item.status.replace("-", " ")}
                          </div>
                        </Badge>
                      </TableCell>
                      <TableCell className="text-center">
                        <Switch
                          checked={item.available !== false}
                          onCheckedChange={() => toggleAvailable(item)}
                          aria-label={`Toggle available for ${item.name}`}
                        />
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex items-center justify-end gap-2">
                          <Button 
                            variant="outline" 
                            size="sm" 
                            onClick={() => updateStock(item.id, item.stock + 10)}
                            disabled={isLoading}
                          >
                            +10
                          </Button>
                          <Button 
                            variant="outline" 
                            size="sm" 
                            onClick={() => updateStock(item.id, Math.max(0, item.stock - 5))}
                            disabled={isLoading || item.stock === 0}
                          >
                            -5
                          </Button>
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button variant="ghost" size="sm" disabled={isLoading}>
                                <MoreHorizontal className="h-4 w-4" />
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end">
                              <DropdownMenuItem 
                                onClick={() => { 
                                  setEditingItem(item); 
                                  setEditImagePreview(null);
                                  setIsDialogOpen(true) 
                                }}
                                disabled={isLoading}
                              >
                                <Edit className="h-4 w-4 mr-2" /> Edit Item
                              </DropdownMenuItem>
                              <DropdownMenuItem 
                                className="text-destructive" 
                                onClick={() => deleteItem(item.id)}
                                disabled={isLoading}
                              >
                                <Trash2 className="h-4 w-4 mr-2" /> Delete Item
                              </DropdownMenuItem>
                            </DropdownMenuContent>
                          </DropdownMenu>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>

        {/* Edit Item Dialog */}
        <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
          <DialogContent className="sm:max-w-[500px]">
            <DialogHeader>
              <DialogTitle>Edit Item</DialogTitle>
              <DialogDescription>Update item details and stock information.</DialogDescription>
            </DialogHeader>
            {editingItem && (
              <div className="grid gap-4 py-4">
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="edit-image" className="text-right">Image</Label>
                  <div className="col-span-3">
                    <Input 
                      id="edit-image" 
                      type="file" 
                      accept="image/*" 
                      onChange={(e) => handleImageUpload(e, true)} 
                    />
                    {(editImagePreview || editingItem.image) && (
                      <div className="mt-2">
                        <img 
                          src={editImagePreview || editingItem.image} 
                          alt="Preview" 
                          className="w-20 h-20 object-cover rounded-lg"
                        />
                      </div>
                    )}
                  </div>
                </div>
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="edit-name" className="text-right">Name</Label>
                  <Input 
                    id="edit-name" 
                    value={editingItem.name} 
                    onChange={(e) => setEditingItem({ ...editingItem, name: e.target.value })} 
                    className="col-span-3" 
                  />
                </div>
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="edit-category" className="text-right">Category</Label>
                  <Select 
                    value={editingItem.category} 
                    onValueChange={(v) => setEditingItem({ ...editingItem, category: v })}
                  >
                    <SelectTrigger className="col-span-3">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {categories.filter(c => c !== "All").map(c => (
                        <SelectItem key={c} value={c}>{c}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="edit-dietary" className="text-right">Type</Label>
                  <Select
                    value={editingItem.dietary}
                    onValueChange={(v: "veg" | "non-veg") => setEditingItem({ ...editingItem, dietary: v })}
                  >
                    <SelectTrigger className="col-span-3">
                      <SelectValue placeholder="Select Type" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="veg">Veg</SelectItem>
                      <SelectItem value="non-veg">Non-Veg</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="edit-price" className="text-right">Price (₹)</Label>
                  <Input 
                    id="edit-price" 
                    type="number" 
                    min="0"
                    value={editingItem.price} 
                    onChange={(e) => setEditingItem({ ...editingItem, price: Number(e.target.value) })} 
                    className="col-span-3" 
                  />
                </div>
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="edit-stock" className="text-right">Stock</Label>
                  <Input 
                    id="edit-stock" 
                    type="number" 
                    min="0"
                    value={editingItem.stock} 
                    onChange={(e) => setEditingItem({ ...editingItem, stock: Number(e.target.value) })} 
                    className="col-span-3" 
                  />
                </div>
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="edit-minStock" className="text-right">Min Stock</Label>
                  <Input 
                    id="edit-minStock" 
                    type="number" 
                    min="0"
                    value={editingItem.minStock} 
                    onChange={(e) => setEditingItem({ ...editingItem, minStock: Number(e.target.value) })} 
                    className="col-span-3" 
                  />
                </div>
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="edit-description" className="text-right">Description</Label>
                  <Textarea 
                    id="edit-description" 
                    value={editingItem.description} 
                    onChange={(e) => setEditingItem({ ...editingItem, description: e.target.value })} 
                    className="col-span-3" 
                  />
                </div>
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="edit-available" className="text-right">Available</Label>
                  <div className="col-span-3 flex items-center">
                    <Switch
                      id="edit-available"
                      checked={editingItem.available !== false}
                      onCheckedChange={() =>
                        setEditingItem({ ...editingItem, available: !(editingItem.available !== false) })
                      }
                    />
                    <span className="ml-2 text-sm">
                      {editingItem.available !== false ? "Available" : "Unavailable"}
                    </span>
                  </div>
                </div>
              </div>
            )}
            <DialogFooter>
              <Button variant="outline" onClick={() => setIsDialogOpen(false)} disabled={isLoading}>
                Cancel
              </Button>
              <Button onClick={saveEdit} disabled={isLoading}>
                {isLoading && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
                Save Changes
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>

        {/* Add Item Dialog */}
        <Dialog open={isAddDialogOpen} onOpenChange={setIsAddDialogOpen}>
          <DialogContent className="sm:max-w-[500px]">
            <DialogHeader>
              <DialogTitle>Add New Item</DialogTitle>
              <DialogDescription>Fill in all details to add a new item.</DialogDescription>
            </DialogHeader>
            <div className="grid gap-4 py-4">
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="add-image" className="text-right">Image</Label>
                <div className="col-span-3">
                  <Input 
                    id="add-image" 
                    type="file" 
                    accept="image/*" 
                    onChange={(e) => handleImageUpload(e)} 
                  />
                  {imagePreview && (
                    <div className="mt-2">
                      <img src={imagePreview} alt="Preview" className="w-20 h-20 object-cover rounded-lg" />
                    </div>
                  )}
                </div>
              </div>
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="add-name" className="text-right">Name</Label>
                <Input
                  id="add-name"
                  value={newItem.name}
                  onChange={(e) => setNewItem({ ...newItem, name: e.target.value })}
                  className="col-span-3"
                />
              </div>
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="add-category" className="text-right">Category</Label>
                <Select
                  value={newItem.category}
                  onValueChange={(v) => setNewItem({ ...newItem, category: v })}
                >
                  <SelectTrigger className="col-span-3">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {categories.filter(c => c !== "All").map(c => (
                      <SelectItem key={c} value={c}>{c}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="add-dietary" className="text-right">Type</Label>
                <Select
                  value={newItem.dietary}
                  onValueChange={(v: "veg" | "non-veg") => setNewItem({ ...newItem, dietary: v })}
                >
                  <SelectTrigger className="col-span-3">
                    <SelectValue placeholder="Select Type" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="veg">Veg</SelectItem>
                    <SelectItem value="non-veg">Non-Veg</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="add-price" className="text-right">Price (₹)</Label>
                <Input
                  id="add-price"
                  type="number"
                  min="0"
                  value={newItem.price}
                  onChange={(e) => setNewItem({ ...newItem, price: e.target.value })}
                  className="col-span-3"
                />
              </div>
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="add-stock" className="text-right">Stock</Label>
                <Input
                  id="add-stock"
                  type="number"
                  min="0"
                  value={newItem.stock}
                  onChange={(e) => setNewItem({ ...newItem, stock: e.target.value })}
                  className="col-span-3"
                />
              </div>
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="add-minStock" className="text-right">Min Stock</Label>
                <Input
                  id="add-minStock"
                  type="number"
                  min="0"
                  value={newItem.minStock}
                  onChange={(e) => setNewItem({ ...newItem, minStock: e.target.value })}
                  className="col-span-3"
                />
              </div>
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="add-description" className="text-right">Description</Label>
                <Textarea
                  id="add-description"
                  value={newItem.description}
                  onChange={(e) => setNewItem({ ...newItem, description: e.target.value })}
                  className="col-span-3"
                />
              </div>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={() => setIsAddDialogOpen(false)} disabled={isLoading}>
                Cancel
              </Button>
              <Button onClick={addItem} disabled={isLoading}>
                {isLoading && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
                Add Item
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>
    </Layout>
  )
}

export default Inventory