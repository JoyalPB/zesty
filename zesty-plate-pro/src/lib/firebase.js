import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';

// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyBngsyyjuwZZqibgBlbB_0pGY99e2g6amU",
  authDomain: "zesty-b595d.firebaseapp.com",
  projectId: "zesty-b595d",
  storageBucket: "zesty-b595d.firebasestorage.app",
  messagingSenderId: "707573112845",
  appId: "1:707573112845:web:20a396ef851684705b7544",
  measurementId: "G-6B1WSXPKYV"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Export Firebase services
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
export default app;