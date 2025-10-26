import { useEffect, useState } from "react"
import { auth, db } from "@/lib/firebase"
import { doc, getDoc, setDoc } from "firebase/firestore"
import { onAuthStateChanged } from "firebase/auth"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardHeader, CardDescription } from "@/components/ui/card"
import { Save, User, Pencil, ArrowLeft } from "lucide-react"
import { Layout } from "@/components/Layout"
import { useToast } from "@/components/ui/use-toast"
import { useNavigate } from "react-router-dom"

const ProfilePage = () => {
  const [profile, setProfile] = useState<any>(null)
  const [localProfile, setLocalProfile] = useState<any>(null)
  const [isEditing, setIsEditing] = useState(false)
  const { toast } = useToast()
  const [errors, setErrors] = useState<{ [key: string]: string }>({})
  const navigate = useNavigate()

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (user) {
        const ref = doc(db, "staff", user.uid)
        const snap = await getDoc(ref)
        if (snap.exists()) {
          const profileData = { ...snap.data(), email: user.email }
          setProfile(profileData)
          setLocalProfile(profileData)
        } else {
          setProfile({ email: user.email })
          setLocalProfile({ email: user.email })
        }
      } else {
        setProfile(null)
        setLocalProfile(null)
      }
    })
    return () => unsubscribe()
  }, [])

  const handleInputChange = (field: string, value: string) => {
    setLocalProfile((prev: any) => ({ ...prev, [field]: value }))
    if (errors[field]) {
      setErrors(prev => {
        const newErrors = { ...prev }
        delete newErrors[field]
        return newErrors
      })
    }
  }

  const validateProfile = () => {
    const newErrors: { [key: string]: string } = {}

    if (!localProfile.firstName?.trim()) {
      newErrors.firstName = "First name is required."
    } else if (!/^[a-zA-Z]+$/.test(localProfile.firstName)) {
      newErrors.firstName = "First name can only contain letters."
    }

    if (!localProfile.lastName?.trim()) {
      newErrors.lastName = "Last name is required."
    } else if (!/^[a-zA-Z]+$/.test(localProfile.lastName)) {
      newErrors.lastName = "Last name can only contain letters."
    }

    if (localProfile.phone && !/^\d{10}$/.test(localProfile.phone)) {
      newErrors.phone = "Please enter a valid 10-digit phone number."
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSave = async () => {
    if (!validateProfile()) {
      toast({
        title: "Invalid Information",
        description: "Please correct the errors and try again.",
        variant: "destructive",
      })
      return
    }

    try {
      await updateProfile(localProfile)
      toast({
        title: "Profile updated",
        description: "Your profile information has been saved successfully.",
      })
      setProfile(localProfile)
      setIsEditing(false)
      setErrors({})
    } catch (err) {
      toast({
        title: "Error",
        description: "Failed to update profile.",
        variant: "destructive",
      })
    }
  }

  const handleCancel = () => {
    setLocalProfile(profile)
    setIsEditing(false)
    setErrors({})
  }

  const safeProfile = localProfile || {}

  return (
    <Layout>
      <div className="max-w-4xl mx-auto space-y-6">
        {/* Back Button */}
        <div className="flex items-center mb-4">
          <Button variant="ghost" onClick={() => navigate(-1)}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back
          </Button>
        </div>

        <div className="flex items-center gap-4">
          <User className="h-8 w-8 text-primary" />
          <div>
            <div className="font-semibold text-lg">
              {safeProfile.firstName || ""} {safeProfile.lastName || ""}
            </div>
            <div className="text-muted-foreground text-sm">{safeProfile.email || ""}</div>
          </div>

          {isEditing ? (
            <div className="ml-auto flex items-center gap-2">
              <Button variant="outline" onClick={handleCancel}>
                Cancel
              </Button>
              <Button onClick={handleSave}>
                <Save className="h-4 w-4 mr-2" />
                Save Changes
              </Button>
            </div>
          ) : (
            <Button
              variant="outline"
              className="ml-auto"
              onClick={() => setIsEditing(true)}
            >
              <Pencil className="h-4 w-4 mr-2" />
              Edit
            </Button>
          )}
        </div>

        <Card>
          <CardHeader>
            <div className="font-semibold text-base">Personal Information</div>
            <CardDescription>Update your personal details</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="firstName">First Name</Label>
                <Input
                  id="firstName"
                  value={safeProfile.firstName || ""}
                  onChange={(e) => handleInputChange("firstName", e.target.value)}
                  disabled={!isEditing}
                />
                {errors.firstName && <p className="text-sm text-destructive mt-1">{errors.firstName}</p>}
              </div>
              <div className="space-y-2">
                <Label htmlFor="lastName">Last Name</Label>
                <Input
                  id="lastName"
                  value={safeProfile.lastName || ""}
                  onChange={(e) => handleInputChange("lastName", e.target.value)}
                  disabled={!isEditing}
                />
                {errors.lastName && <p className="text-sm text-destructive mt-1">{errors.lastName}</p>}
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="email">Email Address</Label>
              <Input
                id="email"
                type="email"
                value={safeProfile.email || ""}
                readOnly
                disabled
                className="cursor-not-allowed"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="phone">Phone Number</Label>
              <Input
                id="phone"
                value={safeProfile.phone || ""}
                onChange={(e) => handleInputChange("phone", e.target.value)}
                disabled={!isEditing}
                placeholder="e.g. 9876543210"
              />
              {errors.phone && <p className="text-sm text-destructive mt-1">{errors.phone}</p>}
            </div>
          </CardContent>
        </Card>
      </div>
    </Layout>
  )
}

async function updateProfile(localProfile: any) {
  if (!auth.currentUser) {
    throw new Error("No authenticated user.")
  }
  const userRef = doc(db, "staff", auth.currentUser.uid)
  const dataToSave = { ...localProfile }
  delete dataToSave.email

  await setDoc(userRef, dataToSave, { merge: true })
}

export default ProfilePage
