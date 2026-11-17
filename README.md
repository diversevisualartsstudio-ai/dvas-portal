# DVASLLC Owner Command Center

Private, mobile-first operations dashboard for DiverseVisualArtsStudioLLC. Includes customer records, quote review/approval, event tracking, communication logs, payment ledger, revenue metrics, and owner-only sign-in.

## Security model

- Supabase Auth protects owner sign-in.
- Supabase Row Level Security (RLS) protects every business table.
- Owner access is granted only by setting `profiles.is_owner = true` for the owner's Auth UID.
- No public registration flow and no service-role key in browser code.
- The dashboard fails closed until Supabase is configured.

**Important:** GitHub Pages serves public static files. Never store customer data in this repository, browser localStorage, or a public JSON file. The Supabase anon/public key is browser-safe only with correctly configured RLS. Keep all privileged provider keys server-side.

## Deploy

The GitHub Actions workflow in `.github/workflows/pages.yml` deploys the repository root on pushes to `main`. In repository Settings → Pages, choose **GitHub Actions** as the build and deployment source. GitHub Pages availability for a private repository depends on the account/organization plan and visibility settings.

## Configure Supabase

1. Create a Supabase project.
2. Run `supabase/schema.sql` in its SQL Editor.
3. Create the owner account in Authentication → Users and copy its Auth UID.
4. Replace the placeholder UUID in the commented owner-profile INSERT at the bottom of `supabase/schema.sql`, then run that INSERT in SQL Editor.
5. Copy `config.example.js` to `config.js`; set the Supabase project URL and anon/public key.
6. Add `config.js` to the repository only if you accept that these browser settings are public. Never add a `service_role` key.
7. Set Supabase Auth Site URL and redirect URL to the deployed GitHub Pages URL.
8. Disable public sign-ups after creating the owner account.

## Current limitations

This dashboard records communication activity but does not send email, SMS, WhatsApp, or place calls. Those require separately configured providers, server-side functions, consent/opt-out handling, and server-side secrets. Payment records are manually entered; no card data is collected or stored.

## Local preview

Open `index.html` in a browser. Authentication and data operations remain unavailable until Supabase is configured.
