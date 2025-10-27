import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { useToast } from '@/hooks/use-toast';
import { seedFirebaseData } from '@/utils/seedData';
import { Database, Loader2 } from 'lucide-react';

export const SeedDataButton = () => {
  const [isSeeding, setIsSeeding] = useState(false);
  const { toast } = useToast();

  const handleSeedData = async () => {
    setIsSeeding(true);
    try {
      const results = await seedFirebaseData();
      
      toast({
        title: "Database seeded successfully!",
        description: `Added ${results.users.success} users, ${results.staff.success} staff members, ${results.transactions.success} transactions, and ${results.systemLogs.success} system logs.`,
      });
    } catch (error: any) {
      toast({
        title: "Error seeding database",
        description: error.message,
        variant: "destructive"
      });
    } finally {
      setIsSeeding(false);
    }
  };

  return (
    <Button 
      onClick={handleSeedData} 
      disabled={isSeeding}
      className="gap-2"
      variant="outline"
    >
      {isSeeding ? (
        <Loader2 className="h-4 w-4 animate-spin" />
      ) : (
        <Database className="h-4 w-4" />
      )}
      {isSeeding ? 'Seeding Database...' : 'Seed Database'}
    </Button>
  );
};