# volunteerHub — Setup Guide

A volunteer platform where NGOs post opportunities and volunteers sign up.
Built with plain HTML/JS + Supabase as the backend.

---

## Step 1 — Create a free Supabase project

1. Go to https://supabase.com and sign up (free)
2. Click **New project**, give it a name (e.g. `volunteerhub`), set a database password, choose a region close to your users
3. Wait ~1 minute for it to spin up

---

## Step 2 — Run the database schema

1. In your Supabase dashboard, go to **SQL Editor** → **New query**
2. Open the file `supabase_schema.sql` from this folder
3. Paste the entire contents into the editor and click **Run**

This creates:
- `profiles` table (volunteers & NGOs)
- `opportunities` table (posts by NGOs)
- `signups` table (volunteer applications)
- Row Level Security policies (so users only access their own data)
- A view `opportunities_with_count` (opportunities + filled seat count)

---

## Step 3 — Get your Supabase credentials

1. In your Supabase dashboard, go to **Project Settings** → **API**
2. Copy:
   - **Project URL** (looks like `https://xxxx.supabase.co`)
   - **anon / public key** (long JWT string)

---

## Step 4 — Add your credentials to index.html

Open `index.html` and find these lines near the top of the `<script>` block:

```js
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

Replace the placeholder strings with your actual values. Example:

```js
const SUPABASE_URL = 'https://abcdefgh.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

---

## Step 5 — (Optional) Enable AI description enhancement

The "✨ Enhance with AI" button calls the Anthropic API.

- If you open the file **directly in claude.ai**, it works automatically — no key needed.
- If you host it externally, add your Anthropic API key:

```js
const ANTHROPIC_KEY = 'sk-ant-...your-key-here...';
```

Get a key at https://console.anthropic.com

---

## Step 6 — Deploy

**Option A — Netlify Drop (easiest, free)**
1. Go to https://netlify.com/drop
2. Drag and drop the `index.html` file onto the page
3. Done — you get a live URL instantly

**Option B — GitHub Pages (free)**
1. Create a GitHub repo, upload `index.html` as the only file
2. Go to Settings → Pages → set source to `main` branch, `/ (root)`
3. Your site is live at `https://yourusername.github.io/yourrepo`

**Option C — Vercel (free)**
1. Go to https://vercel.com/new
2. Import your GitHub repo or drag-drop the file
3. Deploy

**Option D — Any static host**
Upload `index.html` to your web server's public directory.

---

## How it works

### User roles
- **Volunteer** — can browse opportunities, sign up, cancel sign-ups, view dashboard
- **NGO** — can post opportunities, view applicants per post, track stats

Role is set at registration and cannot be changed (by design — contact admin to change).

### Data flow
```
Supabase Auth  →  profiles table  →  role-based UI
                       ↓
NGO posts → opportunities table ← volunteers sign up via signups table
                       ↓
       opportunities_with_count view (filled seats calculated live)
```

### Security
- All tables have Row Level Security (RLS) enabled
- NGOs can only edit/delete their own posts
- Volunteers can only manage their own sign-ups
- Applicant details are only visible to the NGO who owns the post
- The anon key is safe to expose in the frontend (RLS enforces access control)

---

## File structure

```
volunteerhub/
├── index.html          ← The entire app (single file)
├── supabase_schema.sql ← Run once in Supabase SQL editor
└── README.md           ← This file
```

---

## Common issues

**"Failed to load opportunities"**
→ Check that your SUPABASE_URL and SUPABASE_ANON_KEY are correct in index.html

**Blank page after login**
→ Make sure you ran the full schema SQL — especially the `profiles` table and its insert policy

**AI enhance not working**
→ If hosting outside claude.ai, set ANTHROPIC_KEY in the config section of index.html

**Sign-up says "already signed up"**
→ The database enforces one sign-up per volunteer per opportunity (by design)
