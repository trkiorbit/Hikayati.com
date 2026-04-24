-- Schema required to build the backend of Hakawati App

-- 1. Profiles Table
CREATE TABLE public.profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT,
  credits INTEGER DEFAULT 20,
  language VARCHAR(10) DEFAULT 'ar',
  avatar_data JSONB,
  voice_clone_enabled BOOLEAN DEFAULT false,
  cloned_voice_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can insert their own profile." ON public.profiles FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own profile." ON public.profiles FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can view own profile." ON public.profiles FOR SELECT USING (auth.uid() = user_id);

-- 2. Stories Table
CREATE TABLE public.stories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  language VARCHAR(10) DEFAULT 'ar',
  scenes_json JSONB,
  cover_image TEXT,
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.stories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can create stories." ON public.stories FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own stories." ON public.stories FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can view own stories." ON public.stories FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Public stories are viewable by everyone." ON public.stories FOR SELECT USING (is_public = true);

-- 3. Public Stories Table (Pre-made stories library)
CREATE TABLE public.public_stories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  summary TEXT,
  cover TEXT,
  price_credits INTEGER DEFAULT 10,
  category VARCHAR(50),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.public_stories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public stories are viewable by everyone." ON public.public_stories FOR SELECT USING (true);
-- Insert/Update managed by Admin Dashboard, omit generic policies here.

-- 4. Purchases Table
CREATE TABLE public.purchases (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  story_id UUID,
  unlock_type VARCHAR(20), -- 'creation', 'access', 'premium'
  credits_paid INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.purchases ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own purchases." ON public.purchases FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create purchases." ON public.purchases FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Storage Buckets Configuration (Needs manual setup in dashboard or via API extensions)
-- 1. 'covers' -> for story covers.
-- 2. 'scenes' -> for generated scene images.
-- 3. 'audio' -> for narrative audios.

-- RPC Function: Securely Deduct Credits
CREATE OR REPLACE FUNCTION public.deduct_credits(
    p_user_id UUID,
    p_amount INTEGER,
    p_reason VARCHAR
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_credits INT;
    new_credits INT;
BEGIN
    -- Get current credits with row-level lock
    SELECT credits INTO current_credits
    FROM public.profiles
    WHERE user_id = p_user_id
    FOR UPDATE;

    IF current_credits IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;

    IF current_credits < p_amount THEN
        RAISE EXCEPTION 'Insufficient credits';
    END IF;

    new_credits := current_credits - p_amount;

    -- Update the profile credits
    UPDATE public.profiles
    SET credits = new_credits
    WHERE user_id = p_user_id;

    -- Return JSON result
    RETURN json_build_object(
        'success', true,
        'remaining_credits', new_credits,
        'deducted', p_amount,
        'reason', p_reason
    );
END;
$$;
