# AXESS pool website

Static site for **accesspoolada.org**, hosted free on GitHub Pages.
Plain HTML and CSS - no build step, no JavaScript, no tracking.

**This repository must never contain key material, Cloudflare credentials,
API tokens or OAuth secrets.** It is deliberately separate from the node
repository, which holds node configuration.

```
index.html          the site
style.css           styles (light/dark, colourblind-safe, reduced-motion)
poolMetaData.json   pool metadata - see the hard limits below
CNAME               tells GitHub Pages the custom domain
```

---

## The metadata file is the part that must be right

`poolMetaData.json` is referenced **by URL and by content hash** inside the
pool registration certificate.

> **Once the pool is registered, editing this file breaks the hash and the
> pool's metadata stops resolving. Changing it means re-registering the pool.**
> The rest of the site can change freely, any time.

Verified limits (checked against CIP-6 and against real mainnet pools, 2026-09-22):

| Field | Limit | Ours |
|---|---|---|
| `ticker` | **5 characters max**, A-Z and 0-9 | `AXESS` (5) |
| `name` | 50 characters max | 47 |
| `description` | 255 characters max | 210 |
| `homepage` | 64 characters max, valid URL | 25 |
| whole file | **512 bytes max** | see `check-metadata.sh` |
| metadata **URL** | **64 characters max** | `https://accesspoolada.org/poolMetaData.json` = 43 |

A CIP page states 50 characters for `description`; real pools use up to at
least 133, so 255 is the operative limit. Tickers longer than 5 characters do
not exist in practice - that's why the ticker is `AXESS`, not `ACCESS`.

Run `bash check-metadata.sh` before registering.

### Hash the file as it is *served*, not the local copy

Line endings change the bytes, and therefore the hash. `.gitattributes` marks
`poolMetaData.json` as untouchable so git never rewrites it - but the safe
habit is to hash what the world actually gets:

```bash
curl -s https://accesspoolada.org/poolMetaData.json -o served.json
diff served.json poolMetaData.json && echo "identical"
cardano-cli stake-pool metadata-hash --pool-metadata-file served.json
```

That hash is what goes into the registration certificate.

---

## Deploying

1. Create a **public** GitHub repository (any name, e.g. `axess-pool-site`).
2. Push this folder to it.
3. Repo **Settings -> Pages**: source = `main` branch, folder = `/ (root)`.
4. Under **Custom domain**, enter `accesspoolada.org`. The `CNAME` file here
   sets the same thing; both should agree.
5. Tick **Enforce HTTPS** once the certificate is issued (can take an hour).

### Cloudflare DNS

Apex A records (from `api.github.com/meta`, 2026-09-22):

```
A   @   185.199.108.153
A   @   185.199.109.153
A   @   185.199.110.153
A   @   185.199.111.153
CNAME  www   <your-github-username>.github.io
```

**Set the proxy status to DNS only (grey cloud), not proxied (orange).**
GitHub needs to reach the domain directly to issue its TLS certificate;
proxying breaks that until the certificate exists.

---

## Mission and giving policy

The public policy lives on the site itself, in `index.html`: who qualifies
(registered charitable nonprofits doing direct services, never political
campaigns, PACs or lobbying groups), how recipients are chosen, and how the
fee, margin and donations work.

## Still to write

- Shortlist of candidate organisations, with the criteria each was judged
  against
- Donation receipts page, once donations exist
- Build log posts: running a testnet node on a small low-power machine

## Accessibility

The site is the pool's argument, so it should hold up: semantic landmarks, a
skip link, visible focus, text that reflows at any width, no colour-only
signals, no motion, no JavaScript. Test with a screen reader and by keyboard
alone before publishing changes.
