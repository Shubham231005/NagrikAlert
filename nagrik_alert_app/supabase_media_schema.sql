-- ============================================
-- NagrikAlert - Media Storage SQL Schema
-- For Photos and Videos in Incident Reports
-- Run this in Supabase SQL Editor
-- ============================================

-- STEP 1: Update incidents table with media columns
ALTER TABLE incidents 
ADD COLUMN IF NOT EXISTS media_urls TEXT[] DEFAULT '{}';

ALTER TABLE incidents 
ADD COLUMN IF NOT EXISTS media_types TEXT[] DEFAULT '{}';

-- STEP 2: Create incident_media table (incident_id as TEXT to match incidents.id)
CREATE TABLE IF NOT EXISTS incident_media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id TEXT NOT NULL,
    media_url TEXT NOT NULL,
    media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video')),
    file_name TEXT,
    file_size INTEGER,
    uploaded_by UUID,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_incident_media_incident_id ON incident_media(incident_id);

-- STEP 3: Enable RLS on incident_media
ALTER TABLE incident_media ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can view incident media" ON incident_media;
DROP POLICY IF EXISTS "Anyone can insert incident media" ON incident_media;

-- Policy: Anyone can view media
CREATE POLICY "Anyone can view incident media"
ON incident_media FOR SELECT
USING (true);

-- Policy: Anyone can insert media
CREATE POLICY "Anyone can insert incident media"
ON incident_media FOR INSERT
WITH CHECK (true);

-- ============================================
-- DONE! 
-- ============================================
-- After running this SQL:
-- 1. Go to Storage -> New Bucket
-- 2. Name: incident-media
-- 3. Make it PUBLIC (check the box)
-- 4. Click Create
-- ============================================
