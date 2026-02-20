# CLAUDE.md — ACN Registration App

This file provides guidance for AI assistants working on this codebase.

---

## Project Overview

A client registration SPA for **AnuNathan Financial Group**. Prospective clients fill out a form indicating their interest (entrepreneurship, wealth solutions, or both), personal details, and meeting preferences. On submission, the data is stored in Supabase PostgreSQL and automated emails are sent via Mailjet to the client and (optionally) an admin.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend framework | React 18 (functional components + hooks) |
| Build tool | Vite 5 |
| Backend / DB | Supabase (PostgreSQL + Edge Functions) |
| Edge function runtime | Deno (TypeScript) |
| Email | Mailjet REST API |
| Animation | Framer Motion |
| Icons | Lucide React |
| Styling | Plain CSS (no framework) |
| Deployment | Vercel (frontend), Supabase (backend) |

---

## Repository Structure

```
acn-registration-app/
├── src/
│   ├── components/
│   │   └── RegistrationForm.jsx   # Main form component (all logic lives here)
│   ├── lib/
│   │   ├── supabaseClient.js      # Active Supabase client (browser)
│   │   └── supabaseClient.ts      # Legacy file from old Next.js version — do not edit
│   ├── assets/
│   │   ├── acn-logo.png
│   │   └── anunathan-logo.png
│   ├── App.jsx                    # Root component, renders RegistrationForm
│   ├── main.jsx                   # Vite entry point
│   └── styles.css                 # Global styles
├── supabase/
│   ├── migrations/
│   │   └── 001_create_client_registrations.sql  # Table schema
│   ├── functions/
│   │   └── register/
│   │       └── index.ts           # Deno edge function (validation + DB insert + email)
│   └── config.toml                # Supabase project config
├── .env.example                   # Required env var template
├── index.html                     # Vite HTML entry
├── vite.config.js                 # Minimal Vite config (React plugin only)
├── vercel.json                    # Vercel deployment config (SPA rewrites)
└── package.json
```

---

## Development Setup

### Prerequisites

- Node.js 18+
- A Supabase project (free tier is fine)
- A Mailjet account for email sending

### Environment Variables

Copy `.env.example` to `.env` and fill in the values:

```bash
cp .env.example .env
```

**Client-side (Vite, prefixed with `VITE_`):**

```
VITE_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
VITE_SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

**Server-side (Supabase Edge Function secrets — set via `supabase secrets set`):**

```
SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY
MAILJET_API_KEY
MAILJET_SECRET_KEY
FROM_EMAIL
FROM_NAME           # Defaults to "AnuNathan Financial Group"
ADMIN_NOTIFY_EMAIL  # Optional — triggers admin notification email
BCC_EMAIL           # Optional — defaults to chidam.alagar@gmail.com
LOGO_URL            # Optional — embedded in email HTML
```

### Running Locally

```bash
npm install
npm run dev       # Vite dev server at http://localhost:5173
```

### Building

```bash
npm run build     # Outputs to dist/
npm run preview   # Serve the production build locally
```

---

## Key Commands

```bash
npm run dev       # Start development server
npm run build     # Production build
npm run preview   # Preview production build
```

There is **no test runner** configured. There are no lint or format scripts defined in `package.json`.

---

## Architecture & Data Flow

```
User fills form
    │
    ▼
RegistrationForm.jsx
  - Local state (useState) for all form fields
  - useMemo for canSubmit validation
  - Calls supabase.functions.invoke("register", { body: payload })
    │
    ▼
Supabase Edge Function  (supabase/functions/register/index.ts)
  - Validates required fields + email format
  - Inserts row into client_registrations table
  - Sends confirmation email to client via Mailjet
  - Optionally sends admin notification email
  - Returns { ok: true } or { ok: false, error: string }
    │
    ▼
PostgreSQL (Supabase)
  - Table: public.client_registrations
```

---

## Database Schema

**Table: `public.client_registrations`**

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key, auto-generated |
| `created_at` | timestamptz | Default: now() |
| `status` | text | Default: `'new'` |
| `interest_type` | text | `'entrepreneurship'`, `'client'`, or `'both'` |
| `business_opportunities` | text[] | Multi-select; shown when interest includes entrepreneurship |
| `wealth_solutions` | text[] | Multi-select; shown when interest includes client |
| `first_name` | text | Required |
| `last_name` | text | Required |
| `phone` | text | Required |
| `email` | text | Required |
| `profession` | text | Optional |
| `preferred_days` | text[] | Weekdays selected for meetings |
| `preferred_time` | text | `'AM'` or `'PM'` |
| `referred_by` | text | Required |

Migration: `supabase/migrations/001_create_client_registrations.sql`

---

## Code Conventions

### Naming

- **Variables / functions:** camelCase (`formData`, `handleSubmit`, `toggleArray`)
- **Constants (arrays/option lists):** UPPER_SNAKE_CASE (`BUSINESS_OPPORTUNITIES`, `DAYS`, `TIME`)
- **React components:** PascalCase (`RegistrationForm`, `App`)
- **Component files:** PascalCase (`RegistrationForm.jsx`)
- **Utility/config files:** lowercase (`styles.css`, `vite.config.js`)

### React Patterns

- All form state is a single `useState` object; update via spread (`setForm(f => ({ ...f, field: value }))`)
- Multi-select fields use a `toggleArray` helper that adds/removes items from arrays
- `canSubmit` is computed with `useMemo` and gates the submit button
- Framer Motion `AnimatePresence` is used for the post-submission success view

### CSS Conventions

- CSS custom properties defined on `:root` for theming (`--bg`, `--brand`, `--danger`, etc.)
- Class names use a BEM-influenced camelCase style (`.cardHeader`, `.sectionTitle`, `.pill`)
- Responsive layout uses flexbox and CSS grid; mobile-first breakpoints
- No CSS preprocessor — plain `.css` only

### Edge Function (Deno / TypeScript)

- All inputs re-validated server-side even if validated client-side
- HTML in emails is escaped using a local `escapeHtml` helper to prevent injection
- CORS headers are set on every response (including errors)
- `verify_jwt = false` in `config.toml` — the function is intentionally public (no auth required)

---

## Supabase Edge Function Deployment

```bash
# Install Supabase CLI if needed
npm install -g supabase

# Login and link project
supabase login
supabase link --project-ref YOUR_PROJECT_REF

# Deploy the function
supabase functions deploy register

# Set secrets
supabase secrets set MAILJET_API_KEY=xxx MAILJET_SECRET_KEY=xxx ...
```

---

## Vercel Deployment

The `vercel.json` configures:
- Framework: `vite`
- Build: `npm run build`
- Output: `dist/`
- SPA rewrite: all routes → `index.html`

Push to `master` triggers automatic Vercel deployment (if connected).

---

## Important Notes for AI Assistants

1. **`src/lib/supabaseClient.ts` is legacy** — it's a leftover from an earlier Next.js version. The active client is `src/lib/supabaseClient.js`. Do not modify the `.ts` file.

2. **No TypeScript in the frontend** — the project uses `.jsx` files, not `.tsx`. Do not introduce TypeScript to frontend files unless explicitly requested.

3. **No test framework** — there are no tests. Do not reference or run test commands.

4. **No linter config** — ESLint and Prettier are not configured. Do not add lint/format scripts unless asked.

5. **Single edge function** — all backend logic lives in `supabase/functions/register/index.ts`. There is no Express/Node server.

6. **Form state shape** — when modifying `RegistrationForm.jsx`, maintain the single-object `formData` state pattern. Do not split into multiple `useState` calls unless refactoring is explicitly requested.

7. **Environment variable prefix** — client-side env vars must be prefixed `VITE_` to be accessible in browser code via `import.meta.env`.

8. **Email HTML security** — always use the `escapeHtml` helper when interpolating user data into email HTML inside the edge function.
