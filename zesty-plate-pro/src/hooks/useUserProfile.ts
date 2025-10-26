// Import Firebase
import { useEffect, useState } from "react"
import { auth, db } from "@/lib/firebase" // adjust path as needed
import { doc, setDoc, updateDoc, onSnapshot } from "firebase/firestore"
import { onAuthStateChanged } from "firebase/auth"

const useUserProfile = () => {
  const [profile, setProfile] = useState<any>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let unsubscribeFirestore: (() => void) | null = null

    const unsubscribeAuth = onAuthStateChanged(auth, (user) => {
      if (user) {
        const ref = doc(db, "staff", user.uid)

        // ✅ Listen to Firestore doc in real-time
        unsubscribeFirestore = onSnapshot(ref, async (snap) => {
          if (snap.exists()) {
            setProfile(snap.data())
          } else {
            // ✅ Create new profile with empty names
            const newProfile = {
              uid: user.uid,
              email: user.email,
              firstName: "",
              lastName: "",
              photoURL: user.photoURL || "",
              createdAt: new Date(),
            }
            await setDoc(ref, newProfile)
            setProfile(newProfile)
          }
          setLoading(false)
        })
      } else {
        setProfile(null)
        setLoading(false)
        if (unsubscribeFirestore) unsubscribeFirestore()
      }
    })

    return () => {
      unsubscribeAuth()
      if (unsubscribeFirestore) unsubscribeFirestore()
    }
  }, [])

  // Update profile helper
  const updateProfile = async (updates: any) => {
    if (!profile) return
    const ref = doc(db, "staff", profile.uid)
    await updateDoc(ref, updates)
    setProfile({ ...profile, ...updates }) // keep local state in sync
  }

  return { profile, loading, updateProfile }
}

export default useUserProfile
