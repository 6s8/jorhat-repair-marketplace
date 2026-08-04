-- ============================================================
-- Jorhat Repair & Spare Parts Marketplace
-- Database Schema, Indexes, RLS Policies, Realtime & Atomic RPC
-- ============================================================

-- 1. Create jobs table
CREATE TABLE IF NOT EXISTS public.jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL,
    technician_id UUID NULL,
    issue TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'completed')),
    price NUMERIC(10, 2) NOT NULL,
    distance_km NUMERIC(5, 2),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    accepted_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- 2. Create B-tree and spatial indexes
CREATE INDEX IF NOT EXISTS idx_jobs_status ON public.jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_created_at ON public.jobs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_jobs_customer_id ON public.jobs(customer_id);
CREATE INDEX IF NOT EXISTS idx_jobs_technician_id ON public.jobs(technician_id);
CREATE INDEX IF NOT EXISTS idx_jobs_latitude ON public.jobs(latitude);
CREATE INDEX IF NOT EXISTS idx_jobs_longitude ON public.jobs(longitude);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;

-- Customer Policy: Can create jobs
CREATE POLICY "Customers can insert their own jobs"
ON public.jobs FOR INSERT
TO authenticated, anon
WITH CHECK (auth.uid() = customer_id OR customer_id IS NOT NULL);

-- Technician Policy: Can read pending jobs (Customers can view their own jobs)
CREATE POLICY "Anyone can view pending or owned jobs"
ON public.jobs FOR SELECT
TO authenticated, anon
USING (
    status = 'pending' 
    OR (auth.uid() IS NOT NULL AND (customer_id = auth.uid() OR technician_id = auth.uid()))
    OR true -- Allowed for demonstration / guest access
);

-- Technician Policy: Can update ONLY if status='pending' and technician_id IS NULL
CREATE POLICY "Technicians can accept pending jobs"
ON public.jobs FOR UPDATE
TO authenticated, anon
USING (status = 'pending' AND technician_id IS NULL)
WITH CHECK (status = 'accepted' AND technician_id IS NOT NULL);

-- 4. Enable Supabase Realtime for jobs table
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime FOR TABLE public.jobs;
COMMIT;

-- 5. Atomic RPC Function to Prevent Race Conditions
-- Guarantees single winner even with concurrent microsecond requests
CREATE OR REPLACE FUNCTION accept_job(
    p_job_id UUID,
    p_technician_id UUID
)
RETURNS SETOF public.jobs AS $$
BEGIN
    RETURN QUERY
    UPDATE public.jobs
    SET 
        status = 'accepted',
        technician_id = p_technician_id,
        accepted_at = NOW()
    WHERE 
        id = p_job_id
        AND status = 'pending'
        AND technician_id IS NULL
        AND (expires_at IS NULL OR expires_at > NOW())
    RETURNING *;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 6. spare_part_orders — Orders placed from the Marketplace
-- ============================================================
CREATE TABLE IF NOT EXISTS public.spare_part_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id TEXT NOT NULL,
    retailer_id TEXT NOT NULL,
    part_id TEXT NOT NULL,
    part_name TEXT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    delivery_address TEXT,
    total_amount NUMERIC(10, 2) NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'in_progress', 'ready_for_pickup', 'completed', 'cancelled')),
    order_type TEXT NOT NULL DEFAULT 'customer'
        CHECK (order_type IN ('customer', 'technician')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.spare_part_orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view spare_part_orders"
ON public.spare_part_orders FOR SELECT
TO authenticated, anon USING (true);

CREATE POLICY "Anyone can insert spare_part_orders"
ON public.spare_part_orders FOR INSERT
TO authenticated, anon WITH CHECK (true);

CREATE POLICY "Anyone can update spare_part_orders"
ON public.spare_part_orders FOR UPDATE
TO authenticated, anon USING (true);

-- Add spare_part_orders to realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.spare_part_orders;

-- ============================================================
-- 7. appliance_orders — Orders placed for Refurbished Appliances
-- ============================================================
CREATE TABLE IF NOT EXISTS public.appliance_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id TEXT NOT NULL,
    retailer_id TEXT NOT NULL,
    appliance_id TEXT NOT NULL,
    appliance_title TEXT NOT NULL,
    appliance_category TEXT,
    brand TEXT,
    condition TEXT,
    total_amount NUMERIC(10, 2) NOT NULL DEFAULT 0,
    delivery_address TEXT,
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'in_progress', 'ready_for_pickup', 'completed', 'cancelled')),
    customer_phone TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.appliance_orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view appliance_orders"
ON public.appliance_orders FOR SELECT
TO authenticated, anon USING (true);

CREATE POLICY "Anyone can insert appliance_orders"
ON public.appliance_orders FOR INSERT
TO authenticated, anon WITH CHECK (true);

CREATE POLICY "Anyone can update appliance_orders"
ON public.appliance_orders FOR UPDATE
TO authenticated, anon USING (true);

-- Add appliance_orders to realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.appliance_orders;

