import { User, LogOut, Menu, X } from "lucide-react"
import { Avatar, AvatarFallback } from "@/components/ui/avatar"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { signOut, onAuthStateChanged } from "firebase/auth"
import { auth, db } from "@/lib/firebase"
import { doc, onSnapshot, updateDoc } from "firebase/firestore"
import { NavLink, useNavigate } from "react-router-dom"
import { useToast } from "@/hooks/use-toast"
import { useEffect, useState } from "react"
import zestyLogo from "@/assets/new.png" // Make sure this path is correct

const navigationItems = [
  { title: "Dashboard", url: "/" },
  { title: "Orders", url: "/orders" },
  { title: "Inventory", url: "/inventory" },
]

export function Header() {
  const [userName, setUserName] = useState("")
  const [userInitials, setUserInitials] = useState("")
  const [userEmail, setUserEmail] = useState("")
  const [isMenuOpen, setIsMenuOpen] = useState(false) // State for mobile menu
  const navigate = useNavigate()
  const { toast } = useToast()

  // Close mobile menu on resize
  useEffect(() => {
    const handleResize = () => {    
      if (window.innerWidth >= 768) { // md breakpoint
        setIsMenuOpen(false)
      }
    }
    window.addEventListener('resize', handleResize)
    return () => window.removeEventListener('resize', handleResize)
  }, [])

  useEffect(() => {
    let unsubscribeFirestore: (() => void) | null = null

    const unsubscribeAuth = onAuthStateChanged(auth, async (user) => {
      if (user) {
        const ref = doc(db, "staff", user.uid)
        try {
          await updateDoc(ref, { online: true, lastSeen: new Date() })
        } catch (err) {
          console.error("Error updating online status:", err)
        }

        unsubscribeFirestore = onSnapshot(ref, (snap) => {
          if (snap.exists()) {
            const data = snap.data()
            const firstName = data.firstName || ""
            const lastName = data.lastName || ""
            setUserName(firstName + (lastName ? " " + lastName : ""))
            setUserEmail(data.email || user.email || "")
            const initials = (firstName.charAt(0) + (lastName.charAt(0) || "")).toUpperCase()
            setUserInitials(initials || user.email?.charAt(0).toUpperCase() || "U")
          } else {
            setUserName("")
            setUserEmail(user.email || "")
            setUserInitials(user.email?.charAt(0).toUpperCase() || "U")
          }
        })
      } else {
        setUserName("")
        setUserInitials("")
        setUserEmail("")
        if (unsubscribeFirestore) unsubscribeFirestore()
      }
    })

    const handleBeforeUnload = async () => {
      const user = auth.currentUser
      if (user) {
        try {
          await updateDoc(doc(db, "staff", user.uid), {
            online: false,
            lastSeen: new Date(),
          })
        } catch (err) {
          console.error("Failed to update status on unload:", err)
        }
      }
    }

    window.addEventListener("beforeunload", handleBeforeUnload)

    return () => {
      unsubscribeAuth()
      if (unsubscribeFirestore) unsubscribeFirestore()
      window.removeEventListener("beforeunload", handleBeforeUnload)
    }
  }, [])

  const handleSignOut = async () => {
    try {
      // Any database operations that need to happen on sign-out should go here,
      // for example, updating a user's 'online' status.
      // await updateDoc(doc(db, "users", auth.currentUser.uid), { online: false });

      // Sign out from Firebase Auth AFTER all database operations are complete.
      await signOut(auth)

      toast({
        title: "Signed Out",
        description: "You have been successfully signed out.",
      })

      // Navigate to the sign-in page.
      navigate("/signin")
    } catch (error) {
      console.error("Sign-out error:", error)
      toast({
        title: "Sign-Out Failed",
        description: "An error occurred while signing out. Please try again.",
        variant: "destructive",
      })
    }
  }

  return (
    <header className="h-16 border-b border-border/40 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 sticky top-0 z-50">
      <div className="container relative mx-auto flex items-center justify-between h-full px-4">
        {/* Left Section: Logo */}
        <div>
          <img src={zestyLogo} alt="Zesty Logo" className="h-10" />
        </div>

        {/* Center Section: Desktop Navigation */}
        <div className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 hidden md:flex">
          <nav className="flex items-center gap-2 bg-muted p-1 rounded-full">
            {navigationItems.map((item) => (
              <NavLink
                key={item.title}
                to={item.url}
                end={item.url === "/"}
                className={({ isActive }) =>
                  `px-4 py-1.5 rounded-full text-sm font-medium transition-colors duration-200 ease-in-out ${
                    isActive
                      ? "bg-primary text-primary-foreground shadow-sm"
                      : "text-muted-foreground hover:bg-background/60 hover:text-foreground"
                  }`
                }
              >
                {item.title}
              </NavLink>
            ))}
          </nav>
        </div>

        {/* Right Section: User Profile & Mobile Menu Trigger */}
        <div className="flex items-center gap-2">
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <div className="flex items-center gap-3 cursor-pointer hover:bg-accent hover:text-accent-foreground rounded-md p-2 transition-colors">
                <div className="text-right hidden sm:block">
                  <p className="text-sm font-medium">{userName}</p>
                  <p className="text-xs text-muted-foreground">{userEmail}</p>
                </div>
                <Avatar className="h-8 w-8">
                  <AvatarFallback className="bg-primary text-primary-foreground">
                    {userInitials}
                  </AvatarFallback>
                </Avatar>
              </div>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-48">
              <DropdownMenuItem onClick={() => navigate("/profile")}>
                <User className="h-4 w-4 mr-2" />
                Profile
              </DropdownMenuItem>
              <DropdownMenuItem
                onClick={handleSignOut}
                className="text-destructive"
              >
                <LogOut className="h-4 w-4 mr-2" />
                Sign out
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>

          <button
            onClick={() => setIsMenuOpen(!isMenuOpen)}
            className="md:hidden p-2 rounded-md hover:bg-accent"
            aria-label="Toggle menu"
          >
            {isMenuOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
          </button>
        </div>
      </div>

      {/* Mobile Menu Panel */}
      {isMenuOpen && (
        <div className="absolute top-16 left-0 w-full bg-background shadow-lg md:hidden animate-in fade-in-20 slide-in-from-top-4">
          <nav className="flex flex-col p-4">
            {navigationItems.map((item) => (
              <NavLink
                key={item.title}
                to={item.url}
                onClick={() => setIsMenuOpen(false)}
                end={item.url === "/"}
                className={({ isActive }) =>
                  `w-full text-left py-3 px-4 text-base font-medium transition-colors rounded-md ${
                    isActive
                      ? 'bg-primary/10 text-primary'
                      : 'text-muted-foreground hover:bg-accent'
                  }`
                }
              >
                {item.title}
              </NavLink>
            ))}
          </nav>
        </div>
      )}
    </header>
  )
}