-- Drop existing overly permissive policies
DROP POLICY IF EXISTS "Anyone can view items" ON public.items;
DROP POLICY IF EXISTS "Anyone can create items" ON public.items;
DROP POLICY IF EXISTS "Anyone can update items" ON public.items;
DROP POLICY IF EXISTS "Anyone can delete items" ON public.items;

-- Create secure RLS policies requiring authentication
CREATE POLICY "Authenticated users can view items" 
ON public.items 
FOR SELECT 
TO authenticated
USING (true);

CREATE POLICY "Authenticated users can create items" 
ON public.items 
FOR INSERT 
TO authenticated
WITH CHECK (true);

CREATE POLICY "Authenticated users can update items" 
ON public.items 
FOR UPDATE 
TO authenticated
USING (true);

CREATE POLICY "Authenticated users can delete items" 
ON public.items 
FOR DELETE 
TO authenticated
USING (true);

-- Ensure RLS is enabled (it should already be, but just in case)
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;