# Cloudflare & GitHub Pages Setup Guide

This guide outlines how to migrate your custom domain from your old website to this new project while enabling Cloudflare's proxy-based analytics.

## Phase 1: Preparation (Pre-Migration)

### 1. Check current CNAME
Ensure your current website's repository has the custom domain removed from its settings before you attempt to bind it to this new repository. GitHub only allows a domain to be associated with one repository at a time.

### 2. Cloudflare DNS Configuration
In your Cloudflare dashboard, update your DNS records to point to GitHub's servers:

*   **A Records (Root Domain):** Point your root domain (e.g., `dhammacharts.org`) to these four IP addresses:
    *   `185.199.108.153`
    *   `185.199.109.153`
    *   `185.199.110.153`
    *   `185.199.111.153`
*   **CNAME Record (Subdomain):** Point `www` to `cittadhammo.github.io`.

**IMPORTANT:** Ensure the **Proxy status** is set to **Proxied** (Orange Cloud icon). This is required for Cloudflare Analytics to work.

## Phase 2: GitHub Pages Activation

Once the DNS is updated in Cloudflare:

1.  Go to this repository on GitHub.
2.  Navigate to **Settings** > **Pages**.
3.  Under **Custom domain**, enter your domain name.
4.  Click **Save**.
5.  **Wait for DNS check:** GitHub will verify the DNS. Once verified, check the box **Enforce HTTPS**.

## Phase 3: Cloudflare SSL/TLS Security

To prevent "Too many redirects" errors (common when both Cloudflare and GitHub try to handle HTTPS):

1.  In Cloudflare, go to **SSL/TLS** > **Overview**.
2.  Set the encryption mode to **Full (Strict)**. 
    *   *Why?* GitHub Pages provides its own valid certificate. "Full (Strict)" ensures the entire path from user to Cloudflare to GitHub is encrypted and verified.

## Phase 4: Accessing Analytics

### 1. Traffic Analytics (Proxy-based)
Available immediately after traffic starts flowing through the proxy.
-   Go to Cloudflare Dashboard > **Analytics & Logs** > **Traffic**.
-   This shows requests, bandwidth, and visitor countries without needing any code changes.

### 2. Web Analytics (Privacy-focused JS)
For more detailed data (Core Web Vitals, Page Views):
1.  Go to Cloudflare Dashboard > **Web Analytics**.
2.  Add your site and copy the JavaScript snippet provided.
3.  Add this snippet to your project's `_includes/head.html` or `_includes/footer.html`.

## Troubleshooting Tip
If you see a `404` or `Privacy Error` immediately after switching:
-   **Purge Cache:** Go to Cloudflare > Caching > Configuration > **Purge Everything**.
-   **DNS Propagation:** It can take up to 24 hours for DNS changes to fully propagate globally, though Cloudflare usually updates within minutes.
