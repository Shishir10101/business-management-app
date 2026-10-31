# Privacy Policy — Nepal Digital Khata

Last updated: 31 October 2026

This policy describes what the Nepal Digital Khata mobile application and API
(the "Service") collect, why, where it is stored, and what you can do about it.
It is written to match the software as shipped; if the two ever disagree, the
code is the bug.

## Who is responsible

The Service is operated by the publisher of the application, who is the data
controller for the account and ledger data described below. Contact details are
in the repository's `README.md`.

If you are a **staff member** using an account created by a business owner, that
business decides what is recorded and is the controller of the ledger data;
the publisher processes it on their behalf.

## What is collected

**Account data** — your full name, email address, phone number, a password hash
(never the password), your preferred language, your time zone, an optional
profile image URL, and which business you last had open. Staff accounts also
record the role and permissions granted by the business owner.

**Business data you enter** — business name, address, phone, PAN/VAT number and
bank details; customer and supplier names, phone numbers, addresses and opening
balances; and the transactions themselves: sales, purchases, payments,
expenses, income, invoices, stock movements and any notes attached to them.

**Technical data** — authentication tokens, a record of which account performed
each action and when (an audit log), and standard server logs that include the
request path, timestamp and client IP address. Server logs are what any web
service necessarily receives; they are used for security and troubleshooting.

## What is *not* collected

This matters as much as the list above, so it is stated plainly:

- **No analytics or crash-reporting SDKs.** There is no Firebase, Google
  Analytics, Sentry or equivalent in the app.
- **No advertising identifiers**, no ad networks, no behavioural profiling, and
  no selling or renting of data to anyone.
- **No location, contacts, camera, microphone or photo-library access.** The
  Android build requests exactly two permissions: `INTERNET` and
  `POST_NOTIFICATIONS`.
- **No background tracking.** The app contacts the server when you use it, and
  when it checks for an update on launch.

## Why it is processed

- To provide the Service: authenticate you, store your ledger, compute balances
  and reports, and sync between devices.
- To keep it secure: rate limiting, detecting replayed or stolen sessions, and
  an audit trail of who changed what.
- To meet legal obligations, where accounting or tax law requires records to be
  retained.

The legal basis is performance of a contract with you (or with the business you
work for) and, for security logging, the legitimate interest of protecting the
Service and its users.

## Where it is stored

| Data | Location |
|------|----------|
| Ledger and account data | Supabase (PostgreSQL), Singapore |
| Audit log, sync journal, notifications, backup snapshots | MongoDB Atlas, Singapore |
| Offline copy on your device | Local app storage, unencrypted |

The on-device copy is a plaintext JSON snapshot used for offline work. Signing
out deletes it, along with any writes still queued. While you are signed in it
is readable by anyone with file-system access to an unlocked device — the same
exposure as any offline-first app.

## Who else sees it

**Sub-processors.** Supabase (database hosting), MongoDB Atlas (document
storage), Render (API hosting) and GitHub (release distribution and the update
check). Each processes data only as needed to run the Service. The update check
sends a request to `api.github.com`, which necessarily reveals your IP address
to GitHub.

**People you share with.** Customer statements are served from an expiring,
unguessable link. Anyone holding that link can read that customer's ledger until
it expires, and because the link is a signed token rather than a stored record,
it **cannot be revoked early** — share it deliberately, and only for as long as
the customer needs it.

**Business members.** Data entered in a business is visible to every member of
that business who has the relevant permission, and to platform administrators
for support and abuse handling.

No data is sold, and none is shared with third parties for their own marketing.

## How long it is kept

Ledger and account data is kept while the account exists, and afterwards for as
long as accounting and tax law requires. Audit logs and server logs are kept for
a shorter operational period. Statement links expire on their own: 7 days by
default, 90 days at most.

## How it is protected

Passwords are hashed with ASP.NET Core Identity's PBKDF2 implementation.
Traffic between the app and the API is HTTPS in any deployed configuration.
Access to data is scoped per business, and permissions are enforced on the
server for every request rather than trusted from the client. Refresh tokens are
revoked when a password changes or an account is suspended, and a replayed token
revokes the whole session family. Known residual risks — including that the
statement links appear in server logs, and that there is no multi-factor
authentication yet — are documented in [`SECURITY-AUDIT.md`](SECURITY-AUDIT.md)
rather than quietly omitted here.

No system is perfectly secure. If you believe an account has been compromised,
change the password immediately, which revokes existing sessions, and contact
the publisher.

## Your rights

You can ask to see the data held about you, have inaccurate data corrected,
receive a copy of your ledger in a portable format, or have your account and
data deleted. Reports export as CSV from inside the app.

There is currently **no self-service account deletion** — deletion is performed
by the operator on request. This is a known gap, not a policy choice, and it is
listed in [`roadmap.md`](roadmap.md). Where accounting law requires records to
be retained after deletion, the account is closed and the retained records are
restricted to that purpose.

## Children

The Service is intended for business use and is not directed at children. It is
not knowingly used to collect data from anyone under 16.

## Changes

Material changes to this policy will be published here and, where the change is
significant, noted in the app's release notes ([`CHANGELOG.md`](../CHANGELOG.md)).
The "last updated" date above always reflects the current version.
