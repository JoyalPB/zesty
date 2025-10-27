import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { onAuthStateChange, subscribeToDocuments } from '@/lib/firebase';

export interface Notification {
  id: string;
  type: 'info' | 'success' | 'warning' | 'error';
  title: string;
  message: string;
  timestamp: Date;
  read: boolean;
  category: 'auth' | 'system' | 'user' | 'staff';
}

interface NotificationContextType {
  notifications: Notification[];
  unreadCount: number;
  markAsRead: (id: string) => void;
  markAllAsRead: () => void;
  clearNotification: (id: string) => void;
  clearAllNotifications: () => void;
}

const NotificationContext = createContext<NotificationContextType | undefined>(undefined);

export const useNotifications = () => {
  const context = useContext(NotificationContext);
  if (!context) {
    throw new Error('useNotifications must be used within a NotificationProvider');
  }
  return context;
};

interface NotificationProviderProps {
  children: ReactNode;
}

export const NotificationProvider: React.FC<NotificationProviderProps> = ({ children }) => {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [lastAuthState, setLastAuthState] = useState<any>(null);
  const [initialized, setInitialized] = useState(false);
  const [initialUserCount, setInitialUserCount] = useState<number | null>(null);
  const [initialStaffCount, setInitialStaffCount] = useState<number | null>(null);

  const addNotification = (notification: Omit<Notification, 'id' | 'timestamp' | 'read'>) => {
    const newNotification: Notification = {
      ...notification,
      id: `notification-${Date.now()}-${Math.random()}`,
      timestamp: new Date(),
      read: false,
    };
    
    setNotifications(prev => [newNotification, ...prev].slice(0, 50)); // Keep only last 50 notifications
  };

  // Add initial welcome notification
  useEffect(() => {
    if (!initialized) {
      addNotification({
        type: 'info',
        title: 'Welcome to Zesty!',
        message: 'Your notification system is now active. You\'ll receive updates about new users, staff, and logins.',
        category: 'system'
      });
      
      setInitialized(true);
    }
  }, [initialized]);

  // Monitor authentication state changes for login notifications
  useEffect(() => {
    const unsubscribe = onAuthStateChange((user) => {
      if (initialized && user && !lastAuthState) {
        // User just signed in
        const userEmail = user.email || 'Unknown user';
        const isStaff = userEmail.includes('@zesty.com') || userEmail.includes('staff');
        
        addNotification({
          type: 'success',
          title: isStaff ? 'Staff Login' : 'User Login',
          message: `${userEmail} has successfully signed in`,
          category: 'auth'
        });
      }
      setLastAuthState(user);
    });

    return () => unsubscribe();
  }, [initialized, lastAuthState]);

  // Monitor new users being added
  useEffect(() => {
    if (!initialized) return;

    const unsubscribe = subscribeToDocuments('users', (users) => {
      if (initialUserCount === null) {
        // First load - set initial count
        setInitialUserCount(users.length);
      } else if (users.length > initialUserCount) {
        // New user(s) added
        const newUserCount = users.length - initialUserCount;
        const latestUser = users[0]; // Users are ordered by createdAt desc
        
        addNotification({
          type: 'success',
          title: 'New User Registered',
          message: `${latestUser.fullName || latestUser.email} has joined the system`,
          category: 'user'
        });
        
        setInitialUserCount(users.length);
      }
    });

    return () => unsubscribe();
  }, [initialized, initialUserCount]);

  // Monitor new staff being added
  useEffect(() => {
    if (!initialized) return;

    const unsubscribe = subscribeToDocuments('staff', (staff) => {
      if (initialStaffCount === null) {
        // First load - set initial count
        setInitialStaffCount(staff.length);
      } else if (staff.length > initialStaffCount) {
        // New staff member(s) added
        const newStaffCount = staff.length - initialStaffCount;
        const latestStaff = staff[0]; // Staff are ordered by createdAt desc
        
        addNotification({
          type: 'success',
          title: 'New Staff Member Added',
          message: `${latestStaff.name || latestStaff.email} has been added to the staff`,
          category: 'staff'
        });
        
        setInitialStaffCount(staff.length);
      }
    });

    return () => unsubscribe();
  }, [initialized, initialStaffCount]);

  const markAsRead = (id: string) => {
    setNotifications(prev =>
      prev.map(notification =>
        notification.id === id ? { ...notification, read: true } : notification
      )
    );
  };

  const markAllAsRead = () => {
    setNotifications(prev =>
      prev.map(notification => ({ ...notification, read: true }))
    );
  };

  const clearNotification = (id: string) => {
    setNotifications(prev => prev.filter(notification => notification.id !== id));
  };

  const clearAllNotifications = () => {
    setNotifications([]);
  };

  const unreadCount = notifications.filter(n => !n.read).length;

  return (
    <NotificationContext.Provider
      value={{
        notifications,
        unreadCount,
        markAsRead,
        markAllAsRead,
        clearNotification,
        clearAllNotifications,
      }}
    >
      {children}
    </NotificationContext.Provider>
  );
};