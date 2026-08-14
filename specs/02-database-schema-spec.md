# 🗄️ 02-Database Schema & Security Specification

## 1. Supabase PostgreSQL Schema

### Table: `savings_entries`

```sql
CREATE TABLE public.savings_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    entry_date DATE NOT NULL,
    amount NUMERIC(15, 2) NOT NULL CHECK (amount >= 0),
    category VARCHAR(50) DEFAULT 'Grab / Chạy xe' NOT NULL,
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Indexes for ultra-fast query performance
CREATE INDEX idx_savings_entries_user_date ON public.savings_entries (user_id, entry_date DESC);
```

### Table: `wishlist_goals`

```sql
CREATE TABLE public.wishlist_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title VARCHAR(100) NOT NULL,
    target_amount NUMERIC(15, 2) NOT NULL CHECK (target_amount > 0),
    allocated_amount NUMERIC(15, 2) DEFAULT 0 CHECK (allocated_amount >= 0),
    emoji VARCHAR(10) DEFAULT '🏠' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_wishlist_goals_user ON public.wishlist_goals (user_id);
```

---

## 2. Row Level Security (RLS) Policies

> [!CAUTION]
> Row Level Security MUST be enabled on all tables to strictly isolate user data.

```sql
-- Enable RLS
ALTER TABLE public.savings_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wishlist_goals ENABLE ROW LEVEL SECURITY;

-- RLS Policies for savings_entries
CREATE POLICY "Users can view their own entries" 
ON public.savings_entries FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own entries" 
ON public.savings_entries FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own entries" 
ON public.savings_entries FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own entries" 
ON public.savings_entries FOR DELETE 
USING (auth.uid() = user_id);
```

---

## 3. Hive Local Storage Schema (Flutter)

### Hive Box: `savingsBox`
- **Key:** `String entryId` (UUID)
- **Value:** `SavingsEntryModel`
  - `String id`
  - `String date` (ISO `YYYY-MM-DD`)
  - `double amount`
  - `String category`
  - `String note`

### Hive Box: `wishlistBox`
- **Key:** `String goalId`
- **Value:** `WishlistGoalModel`
  - `String id`
  - `String title`
  - `double targetAmount`
  - `double allocatedAmount`
  - `String emoji`
