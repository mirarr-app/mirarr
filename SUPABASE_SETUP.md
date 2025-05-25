# Supabase Setup Guide for Mirarr

This guide will help you set up Supabase to sync your watch history across devices.

## Prerequisites

1. A Supabase account (free tier is sufficient)
2. A Supabase project

## Step 1: Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign up/sign in
2. Click "New Project"
3. Choose your organization and enter project details
4. Wait for the project to be created

## Step 2: Create the Watch History Table

1. In your Supabase dashboard, go to the "SQL Editor"
2. Run the following SQL command to create the watch history table:

```sql
CREATE TABLE IF NOT EXISTS watch_history (
  id BIGSERIAL PRIMARY KEY,
  tmdb_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('movie', 'tv')),
  poster_path TEXT,
  watched_at TIMESTAMPTZ NOT NULL,
  season_number INTEGER,
  episode_number INTEGER,
  episode_title TEXT,
  user_rating REAL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(tmdb_id, type, season_number, episode_number)
);
ALTER TABLE watch_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all operations on watch_history" ON watch_history
FOR ALL USING (true);
```

## Step 3: Get Your Project Credentials

1. In your Supabase dashboard, go to "Settings" > "API"
2. Copy the following values:
   - **Project URL** (looks like `https://your-project-id.supabase.co`)
   - **Anon/Public Key** (the `anon` key, not the `service_role` key)

## Step 4: Configure Mirarr

1. Open Mirarr and go to Settings
2. In the "Supabase Configuration" section:
   - Enter your **Project URL** in the "Supabase URL" field
   - Enter your **Anon Key** in the "Supabase Anon Key" field
3. Click "Save Configuration"
4. You should see a green checkmark indicating successful configuration

## Step 5: Sync Your Data

Once configured, you can:

- **Sync All**: Bidirectional sync (download from Supabase, then upload local changes)
- **Upload & Sync**: Send your local watch history to Supabase and remove items that were deleted locally
- **Download**: Get watch history from Supabase to your device

### Sync Behavior Details

- **Upload & Sync**: Compares your local database with Supabase and ensures they match exactly. Items deleted locally will be removed from Supabase, and new/updated items will be uploaded.
- **Download**: Merges remote data with local data without removing anything locally.
- **Sync All**: Combines both operations for complete synchronization.

## Security Notes

- Don't share your url and anon key. The current setup has no authentication implemented.

## Troubleshooting

### "Failed to sync" error
- Check your internet connection
- Verify your Supabase URL and anon key are correct
- Make sure the watch_history table exists in your Supabase project

### Table doesn't exist error
- Make sure you ran the SQL commands from Step 2
- Check that the table name is exactly `watch_history`


## Support

If you encounter issues, please check:
1. Supabase project status
2. Network connectivity. Try with a VPN.
3. Correct credentials in Mirarr settings 