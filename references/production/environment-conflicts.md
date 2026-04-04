# Environment & Requirement Conflict Detection

Pre-flight checks to catch incompatibilities BEFORE a developer starts building.
Run these checks after the user describes what they want to build, cross-referencing
against their detected environment.

---

## 1. Platform Conflicts

What they want to build vs what OS they're on.

### Windows-Only Frameworks on Linux/Mac

| Technology | Constraint | Detection |
|---|---|---|
| WPF / WinForms | Windows only — no cross-platform support | `uname -s` != "MINGW*"/"MSYS*"/"CYGWIN*" and not Windows |
| .NET MAUI (Windows target) | Windows workload needs Windows | `uname -s` != Windows |
| DirectX / Direct3D | Windows-only graphics API | `uname -s` check |
| Windows Services | Windows-only service architecture | `uname -s` check |
| PowerShell modules (Windows-specific) | WMI, COM objects, Registry | `uname -s` check |

**Suggest:** Avalonia UI, Uno Platform, or .NET MAUI (cross-platform targets) as alternatives to WPF/WinForms.

### macOS-Only Requirements

| Technology | Constraint | Detection |
|---|---|---|
| iOS app (any framework) | Xcode required, macOS only | `uname -s` != "Darwin" |
| macOS native app (SwiftUI/AppKit) | macOS only | `uname -s` != "Darwin" |
| Xcode Command Line Tools | Required for most dev tools on Mac | `xcode-select -p 2>/dev/null` |
| Universal Binary (arm64 + x86_64) | Needs macOS with Xcode | `uname -s` != "Darwin" |

**Suggest:** For iOS without Mac — use Expo EAS Build (cloud builds), or cloud Mac services (MacStadium, GitHub Actions macOS runners).

### Architecture Mismatches

| Scenario | Constraint | Detection |
|---|---|---|
| x86-only binary/library on ARM | Rosetta (Mac) or no support (Linux ARM) | `uname -m` = "aarch64"/"arm64" |
| Native ARM build on x86 | Cross-compilation needed | `uname -m` = "x86_64" but targeting ARM |
| 32-bit libraries on 64-bit system | Multilib not installed | `dpkg --print-architecture` or `file /lib*/libc.so*` |

**Detection script:**
```bash
OS=$(uname -s)
ARCH=$(uname -m)
echo "platform: ${OS}-${ARCH}"
# Flag: iOS/macOS project on non-Darwin
# Flag: WPF/WinForms project on non-Windows
# Flag: ARM-only deps on x86 or vice versa
```

---

## 2. Runtime & Toolchain Version Conflicts

The framework needs a newer version than what's installed.

### Node.js Version Requirements

| Framework | Minimum Node | Detection |
|---|---|---|
| Next.js 15+ | Node 18.18+ | `node -v` < 18.18 |
| Next.js 16+ | Node 18.18+ | `node -v` < 18.18 |
| Angular 17+ | Node 18.13+ | `node -v` < 18.13 |
| Angular 19+ | Node 20.x+ | `node -v` < 20 |
| Vue 3 / Nuxt 3 | Node 18+ | `node -v` < 18 |
| SvelteKit 2+ | Node 18.13+ | `node -v` < 18.13 |
| Astro 4+ | Node 18.17.1+ | `node -v` < 18.17 |
| Remix 2+ | Node 18+ | `node -v` < 18 |
| Vite 6+ | Node 18+ | `node -v` < 18 |

**Detection script:**
```bash
NODE_V=$(node -v 2>/dev/null | sed 's/v//')
if [ -z "$NODE_V" ]; then echo "node: not installed"; fi
# Compare against framework minimum
```

**Suggest:** Use nvm/fnm to manage Node versions: `nvm install 20 && nvm use 20`

### Python Version Requirements

| Framework | Minimum Python | Detection |
|---|---|---|
| Django 5.0+ | Python 3.10+ | `python3 -V` < 3.10 |
| Django 5.1+ | Python 3.10+ | `python3 -V` < 3.10 |
| FastAPI (current) | Python 3.8+ (3.10+ recommended) | `python3 -V` < 3.8 |
| Flask 3.0+ | Python 3.8+ | `python3 -V` < 3.8 |
| Pydantic 2+ | Python 3.8+ | `python3 -V` < 3.8 |

**Detection script:**
```bash
PY_V=$(python3 --version 2>/dev/null | awk '{print $2}')
if [ -z "$PY_V" ]; then echo "python3: not installed"; fi
```

**Suggest:** Use pyenv to manage Python versions: `pyenv install 3.12 && pyenv local 3.12`

### Other Runtime Requirements

| Framework | Requirement | Detection |
|---|---|---|
| Rust / Tauri / Actix / Axum | Rust toolchain (rustc + cargo) | `rustc --version 2>/dev/null` |
| Go / Gin / Chi | Go 1.21+ | `go version 2>/dev/null` |
| Spring Boot 3+ | Java 17+ | `java -version 2>&1 | head -1` |
| .NET 8+ | .NET SDK 8+ | `dotnet --version 2>/dev/null` |
| Ruby on Rails 7.1+ | Ruby 3.1+ | `ruby -v 2>/dev/null` |
| PHP Laravel 11+ | PHP 8.2+ | `php -v 2>/dev/null` |
| Elixir / Phoenix | Erlang/OTP + Elixir | `elixir --version 2>/dev/null` |

**Detection script:**
```bash
# Check all common runtimes
for cmd in node python3 rustc go java dotnet ruby php elixir; do
  which $cmd > /dev/null 2>&1 && echo "$cmd: $(${cmd} --version 2>&1 | head -1)" || echo "$cmd: not installed"
done
```

---

## 3. Hardware Constraints

When the machine physically can't do what they want.

### GPU Requirements (ML/AI)

| Technology | Requirement | Detection |
|---|---|---|
| TensorFlow (GPU) | NVIDIA GPU + CUDA + cuDNN | `nvidia-smi 2>/dev/null` |
| PyTorch (GPU) | NVIDIA GPU + CUDA (compute capability 6.0+) | `nvidia-smi 2>/dev/null` |
| CUDA toolkit | NVIDIA GPU driver 515+ | `nvcc --version 2>/dev/null` |
| ROCm (AMD GPU) | AMD GPU with ROCm support | `rocm-smi 2>/dev/null` |
| Stable Diffusion / LLM local | 8GB+ VRAM recommended | `nvidia-smi --query-gpu=memory.total --format=csv,noheader` |
| Apple MLX | Apple Silicon (M1+) | `uname -m` = "arm64" on Darwin |

**Suggest:** If no GPU — use CPU-only mode (slower), cloud GPU (Google Colab, Lambda Labs), or API-based inference (OpenAI, Replicate).

### Memory Requirements

| Tool | Minimum RAM | Detection |
|---|---|---|
| Android Studio + emulator | 8GB (16GB recommended) | `free -g` or `sysctl hw.memsize` (Mac) |
| Docker Desktop | 4GB allocated minimum | `docker info 2>/dev/null | grep "Total Memory"` |
| Webpack large project | 4GB+ for Node | `node -e "console.log(Math.round(os.totalmem()/1024/1024/1024)+'GB')"` |
| Xcode + simulator | 8GB minimum | `sysctl hw.memsize` on Mac |
| IntelliJ / JVM-based IDE | 4GB minimum | Check total RAM |
| Kubernetes local (minikube/kind) | 8GB+ recommended | Check total RAM |

**Detection script:**
```bash
if [ "$(uname -s)" = "Darwin" ]; then
  RAM_GB=$(($(sysctl -n hw.memsize) / 1073741824))
else
  RAM_GB=$(free -g | awk '/Mem:/{print $2}')
fi
echo "ram_gb: $RAM_GB"
```

### Disk Space Requirements

| Tool | Space Needed | Detection |
|---|---|---|
| Xcode | 35GB+ | `xcode-select -p` exists → check with `du -sh /Applications/Xcode.app` |
| Android Studio + SDK | 10-15GB | Check ANDROID_HOME size |
| Docker images (typical project) | 5-20GB | `docker system df 2>/dev/null` |
| node_modules (large project) | 500MB-2GB per project | Check available disk |
| Rust target/ directory | 1-10GB per project | Check available disk |
| .gradle cache | 2-5GB | Check `~/.gradle` size |

**Detection script:**
```bash
if [ "$(uname -s)" = "Darwin" ]; then
  AVAIL_GB=$(df -g / | awk 'NR==2{print $4}')
else
  AVAIL_GB=$(df -BG / | awk 'NR==2{print $4}' | tr -d 'G')
fi
echo "disk_available_gb: $AVAIL_GB"
# Flag if < 10GB for any project, < 40GB for Xcode/Android Studio projects
```

---

## 4. Native Module & Build Tool Prerequisites

The "I didn't know I needed X" category. These cause hours of debugging.

### node-gyp (affects: sharp, bcrypt, canvas, sqlite3, etc.)

| OS | Requirement | Detection |
|---|---|---|
| Windows | Visual Studio Build Tools 2022 + "Desktop development with C++" workload | `where cl.exe 2>NUL` or check VS installer |
| Windows | Python 3.12+ | `py --list-paths 2>NUL` |
| macOS | Xcode Command Line Tools | `xcode-select -p 2>/dev/null` |
| Linux | build-essential (gcc, g++, make) | `gcc --version 2>/dev/null && make --version 2>/dev/null` |
| Linux | Python 3.12+ | `python3 --version 2>/dev/null` |

**Suggest (Windows):** `npm install --global windows-build-tools` or install Visual Studio Build Tools via Chocolatey: `choco install visualstudio2022-workload-vctools python3 -y`

**Suggest (macOS):** `xcode-select --install`

**Suggest (Linux):** `sudo apt install build-essential python3` (Debian/Ubuntu) or `sudo dnf groupinstall "Development Tools"` (Fedora)

### sharp (image processing — used by Next.js, Payload CMS, etc.)

| OS | Requirement | Detection |
|---|---|---|
| Linux | libvips-dev (or prebuilt binary) | `pkg-config --exists vips 2>/dev/null` |
| macOS (Rosetta) | Native ARM build preferred | `uname -m` on Mac M1+ |
| All | node-gyp prerequisites (see above) | Combined check |

**Suggest:** Usually installs prebuilt binaries. If build fails: `SHARP_IGNORE_GLOBAL_LIBVIPS=1 npm install sharp`

### Puppeteer / Playwright (headless browsers)

| OS | Requirement | Detection |
|---|---|---|
| Linux (headless) | ~30 system libraries (libx11, libnss3, libatk, libgtk-3, etc.) | `npx puppeteer browsers install chrome --install-deps` or `npx playwright install-deps` |
| Docker | Additional deps not in slim/alpine images | Check Dockerfile |
| All | 400MB+ disk for Chromium download | Check available disk |

**Detection (Linux):**
```bash
# Check for common missing libraries
for lib in libnss3 libatk-1.0 libgtk-3-0 libgbm1 libasound2; do
  ldconfig -p 2>/dev/null | grep -q "$lib" && echo "$lib: found" || echo "$lib: MISSING"
done
```

**Suggest:** `npx playwright install --with-deps` or `npx puppeteer browsers install chrome --install-deps`

### Python C Extension Dependencies

| Package | System Dependency | Detection |
|---|---|---|
| psycopg2 | libpq-dev (PostgreSQL client) | `pg_config --version 2>/dev/null` |
| mysqlclient | libmysqlclient-dev | `mysql_config --version 2>/dev/null` |
| Pillow | libjpeg-dev, zlib1g-dev, libpng-dev | `pkg-config --exists libjpeg 2>/dev/null` |
| lxml | libxml2-dev, libxslt-dev | `pkg-config --exists libxml-2.0 2>/dev/null` |
| cryptography | libssl-dev, libffi-dev | `pkg-config --exists openssl 2>/dev/null` |
| scipy / numpy | libopenblas-dev or liblapack-dev | `pkg-config --exists openblas 2>/dev/null` |

**Suggest:** Use binary wheels when available (`pip install psycopg2-binary`), or install system deps first.

---

## 5. Service & Account Requirements

External services that cost money or need accounts.

### Payment Processing

| Service | Requirement | Detection |
|---|---|---|
| Stripe | Stripe account + business entity for payouts, restricted countries | Ask user: "Do you have a Stripe account?" |
| PayPal | Business account for receiving payments | Ask user |
| Apple Pay | Apple Developer account + Merchant ID | Check project type |
| Google Pay | Google Pay Business Console access | Check project type |

**Suggest:** For prototyping, Stripe test mode works without full verification. Flag: "You'll need a verified Stripe account before going live."

### App Store Publishing

| Platform | Requirement | Cost | Detection |
|---|---|---|---|
| Apple App Store | Apple Developer Program | $99/year | `security find-identity -p codesigning 2>/dev/null` (checks for signing cert) |
| Google Play Store | Google Play Developer account | $25 one-time | Ask user |
| Mac App Store | Apple Developer Program | $99/year (same) | See above |
| Microsoft Store | Microsoft Partner Center | Free (with limits) | Ask user |

**Suggest:** Flag cost early. For testing: iOS uses TestFlight (still needs $99 account), Android uses internal testing track.

### Domain & Infrastructure

| Service | Requirement | Typical Cost |
|---|---|---|
| Custom domain | Purchase + DNS configuration | $10-50/year |
| SSL certificate | Required for HTTPS (free via Let's Encrypt, Cloudflare, or hosting platform) | Free-$100/year |
| Email sending (SendGrid, Resend, SES) | Account + domain verification for production | Free tier: 100-300 emails/day |
| SMS (Twilio) | Account + phone number purchase | $1/month + $0.0079/SMS |
| File storage (S3, Cloudflare R2) | Account + bucket configuration | Pay per use |
| CDN | Usually included with hosting platform | Usually free tier available |

### Cloud Provider Free Tier Limits

| Provider | Free Tier Limits | What Breaks |
|---|---|---|
| Vercel | 100GB bandwidth, 100 hrs serverless, 6000 min build | High-traffic site, long builds |
| Netlify | 100GB bandwidth, 300 min build/month | Large/frequent deployments |
| Supabase | 500MB database, 1GB file storage, 2 projects | Growing data, multiple projects |
| Firebase | 1GB Firestore, 10GB hosting, 125K auth/month | Scale, phone auth (10K/month) |
| Railway | $5 free credit/month | Any sustained workload |
| Render | 750 hours free instances, sleep after 15 min inactivity | Always-on requirement |
| Fly.io | 3 shared VMs, 3GB persistent storage | Multiple services |
| AWS Free Tier | 12 months, t2.micro, 5GB S3 | After 12 months, everything costs |

---

## 6. Legal & Licensing Conflicts

Dependencies that can force your project open-source or create legal risk.

### License Incompatibilities

| License | Risk for Commercial Software | Detection |
|---|---|---|
| GPL-3.0 | Copyleft — entire project must be GPL if distributed | `npx license-checker --production --onlyAllow "MIT;ISC;BSD-2-Clause;BSD-3-Clause;Apache-2.0"` |
| AGPL-3.0 | Network copyleft — SaaS must release source code | Same as above — AGPL is the most dangerous for SaaS |
| SSPL (MongoDB) | Server Side Public License — similar to AGPL but broader | Check database license |
| EUPL | Copyleft with compatibility provisions | License checker |
| CC-BY-NC | Non-commercial only — cannot use in commercial product | Check asset licenses |

**Detection script (npm):**
```bash
npx license-checker --production --json 2>/dev/null | grep -i "GPL\|AGPL\|SSPL\|EUPL"
```

**Detection script (pip):**
```bash
pip-licenses --format=csv 2>/dev/null | grep -i "GPL\|AGPL"
```

**Suggest:** Flag GPL/AGPL dependencies immediately. Alternatives usually exist (e.g., use PostgreSQL instead of MongoDB/SSPL, use MIT-licensed alternatives).

### Regulatory Constraints

| Regulation | Technology Impact | When to Flag |
|---|---|---|
| HIPAA | PHI storage requirements, BAA needed with cloud providers | Healthcare data project |
| GDPR | EU data storage requirements, right to deletion, consent | Any EU-facing project |
| SOC 2 | Audit logging, access controls, encryption requirements | Enterprise SaaS |
| PCI DSS | Payment card data handling, cannot store CVV | Direct card processing |
| COPPA | Children's data protection, parental consent | Apps targeting children under 13 |
| Export restrictions | Cryptography export controls (EAR/ITAR) | Strong encryption features |

**Suggest:** Flag early: "Your project handles [healthcare data / payments / children's data]. This has legal requirements that affect technology choices. Consider [Stripe Elements instead of direct card handling / HIPAA-compliant hosting / age verification]."

---

## 7. Scale Mismatches

Choosing technology that won't scale to their stated goals.

| Stated Goal | Bad Choice | Why It Breaks | Better Choice |
|---|---|---|---|
| "millions of users" | SQLite | Single-writer, no concurrent writes, single-file | PostgreSQL, MySQL |
| "millions of users" | In-memory sessions | Lost on restart, can't share across servers | Redis, database sessions, JWTs |
| "real-time updates" | REST polling | Inefficient at scale, high latency | WebSockets, SSE, Supabase Realtime |
| "file uploads" | Local filesystem | Lost on redeploy (serverless), can't scale | S3, Cloudflare R2, Supabase Storage |
| "serverless deployment" | WebSocket server | Serverless = stateless, connections drop | Ably, Pusher, Supabase Realtime, or use a persistent server |
| "global low-latency" | Single-region database | High latency for distant users | Read replicas, edge caching, CockroachDB, Turso |
| "CPU-intensive tasks" | Single-threaded Node.js main thread | Blocks event loop, all requests stall | Worker threads, background jobs (BullMQ), or different runtime |
| "high write throughput" | MongoDB free tier (Atlas) | 512MB storage, shared cluster | Self-hosted or dedicated cluster |
| "offline-first" | Cloud-only database (Supabase, Firebase) | No data without internet | SQLite + sync (PowerSync, ElectricSQL), or IndexedDB + sync |
| "multi-tenant SaaS" | Shared tables no isolation | Data leaks between tenants, noisy neighbor | Row-level security (RLS), schema-per-tenant, or separate DBs |

**Detection:** Cross-reference user's scale language ("thousands of users", "enterprise", "global") against technology choices. Flag mismatches.

---

## 8. Deployment Platform Conflicts

Choosing a hosting platform that doesn't support their stack or requirements.

### Platform vs Stack

| Platform | Supports | Does NOT Support | Detection |
|---|---|---|---|
| Vercel | Next.js, Node.js, Python, Go, Ruby (serverless) | Persistent processes, WebSocket servers, background workers | User wants WebSockets + Vercel |
| Netlify | Static sites, serverless functions (Node/Go) | Persistent processes, WebSockets, non-Node backends | User wants Django + Netlify |
| GitHub Pages | Static HTML/CSS/JS only | Any server-side code, API routes, databases | User wants dynamic site + GH Pages |
| Cloudflare Pages/Workers | Edge functions (V8 runtime), static | Full Node.js APIs (limited fs, no child_process), >1MB bundles (free) | User wants heavy backend + CF Workers |
| AWS Lambda | Any runtime (Node, Python, Go, Rust, Java) | Persistent connections, >15min tasks, >250MB packages | User wants long-running jobs |
| Heroku | Any runtime with Procfile | Free tier (gone), ephemeral filesystem | User wants free hosting + file storage |
| Railway | Any Dockerfile or Nixpack-supported stack | Free beyond $5 credit/month | User wants free production hosting |

### Platform Size/Timeout Limits

| Platform | Function Size | Timeout | Payload |
|---|---|---|---|
| Vercel (Hobby) | 250MB unzipped | 60s (Hobby), 300s (Pro) | 5MB request/response |
| Netlify | 50MB zipped | 10s (free), 26s (paid) | 6MB |
| Cloudflare Workers (Free) | 1MB | 10ms CPU time | 100MB |
| Cloudflare Workers (Paid) | 10MB | 30s CPU time | 100MB |
| AWS Lambda | 250MB unzipped | 15 min | 6MB sync, 20MB async |

**Suggest:** Match platform to stack. Python/Django → Railway, Render, Fly.io. Next.js → Vercel. Static → Cloudflare Pages.

---

## 9. Mobile Development Prerequisites

Mobile dev has the MOST hidden requirements.

### React Native

| Requirement | Platform | Detection |
|---|---|---|
| Node.js 18+ | All | `node -v` |
| Watchman | macOS (recommended) | `which watchman` |
| JDK 17+ | Android | `java -version 2>&1 | grep -i version` |
| Android Studio + SDK | Android | `echo $ANDROID_HOME` and `which adb` |
| Android SDK Platform 35 | Android | `ls $ANDROID_HOME/platforms/ 2>/dev/null` |
| Android SDK Build-Tools | Android | `ls $ANDROID_HOME/build-tools/ 2>/dev/null` |
| ANDROID_HOME env var | Android | `echo $ANDROID_HOME` |
| Xcode 15+ | iOS | `xcodebuild -version 2>/dev/null` |
| CocoaPods | iOS | `pod --version 2>/dev/null` |
| Ruby (for CocoaPods) | iOS | `ruby -v 2>/dev/null` |

**Detection script:**
```bash
# Android readiness
[ -n "$ANDROID_HOME" ] && echo "ANDROID_HOME: $ANDROID_HOME" || echo "ANDROID_HOME: NOT SET"
which adb > /dev/null 2>&1 && echo "adb: found" || echo "adb: MISSING"
java -version 2>&1 | head -1

# iOS readiness (macOS only)
if [ "$(uname -s)" = "Darwin" ]; then
  xcodebuild -version 2>/dev/null | head -1 || echo "Xcode: NOT INSTALLED"
  pod --version 2>/dev/null && echo "CocoaPods: found" || echo "CocoaPods: MISSING"
fi
```

### Flutter

| Requirement | Platform | Detection |
|---|---|---|
| Flutter SDK | All | `flutter --version 2>/dev/null` |
| Dart SDK | All (bundled with Flutter) | `dart --version 2>/dev/null` |
| Android Studio + SDK | Android | Same as React Native |
| Android SDK command-line tools | Android | `flutter doctor --android-licenses` check |
| Xcode + CocoaPods | iOS | Same as React Native |
| Chrome | Web | `which google-chrome` or `which chromium` |
| Visual Studio (Windows) | Windows desktop target | Check VS installation |
| GTK dev libraries | Linux desktop target | `pkg-config --exists gtk+-3.0` |

**Suggest:** Run `flutter doctor` — it's the gold standard for environment detection. Our checks should mirror what `flutter doctor` does.

### Expo (managed React Native)

| Requirement | Detection | Notes |
|---|---|---|
| Node.js 18+ | `node -v` | Strict requirement |
| Expo CLI | `npx expo --version` | Installed per-project now |
| EAS CLI (for builds) | `eas --version 2>/dev/null` | Needed for production builds |
| iOS: No local Xcode needed | Expo EAS builds in cloud | But $99 Apple account still needed for App Store |
| Android: No local SDK needed | Expo EAS builds in cloud | But Google Play account needed for Play Store |

**Suggest:** Expo dramatically reduces local setup. Recommend for beginners building mobile apps.

---

## 10. Desktop Development Prerequisites

### Electron

| Requirement | Detection | Notes |
|---|---|---|
| Node.js 18+ | `node -v` | Core requirement |
| node-gyp prerequisites | See Section 4 | For native modules |
| Windows: Visual Studio Build Tools | See Section 4 | For native compilation |
| macOS: Xcode CLT | `xcode-select -p` | For native compilation |
| Linux: build-essential, libgtk-3-dev, libnotify-dev, libnss3 | Package manager check | For building + running |

### Tauri

| Requirement | OS | Detection |
|---|---|---|
| Rust toolchain (rustc + cargo) | All | `rustc --version 2>/dev/null` |
| Node.js (for frontend) | All | `node -v` |
| C compiler (gcc/clang) | All | `cc --version 2>/dev/null` |
| webkit2gtk-4.1 | Linux | `pkg-config --exists webkit2gtk-4.1 2>/dev/null` |
| libssl-dev | Linux | `pkg-config --exists openssl 2>/dev/null` |
| librsvg2-dev | Linux | `pkg-config --exists librsvg-2.0 2>/dev/null` |
| libayatana-appindicator3-dev | Linux | `pkg-config --exists ayatana-appindicator3-0.1 2>/dev/null` |
| Xcode CLT | macOS | `xcode-select -p` |
| Visual Studio Build Tools | Windows | Check VS installation |
| WebView2 | Windows | Usually pre-installed on Win 10/11 |

**Detection script (Linux/Tauri):**
```bash
for pkg in webkit2gtk-4.1 openssl librsvg-2.0 ayatana-appindicator3-0.1; do
  pkg-config --exists $pkg 2>/dev/null && echo "$pkg: found" || echo "$pkg: MISSING"
done
```

**Suggest (Ubuntu/Debian):**
```bash
sudo apt install libwebkit2gtk-4.1-dev build-essential curl wget file \
  libxdo-dev libssl-dev libayatana-appindicator3-dev librsvg2-dev
```

---

## 11. Database Conflicts

Database choice vs requirements mismatch.

| Requirement | Bad Choice | Why | Better Choice |
|---|---|---|---|
| Real-time subscriptions | MySQL, standard PostgreSQL | No built-in real-time | Supabase (Realtime), Firebase, Convex |
| Multi-server deployment | SQLite | Single-file, single-writer | PostgreSQL, MySQL, PlanetScale |
| Offline-first | Any cloud-only DB | No data without internet | SQLite + sync layer (PowerSync, ElectricSQL) |
| Full-text search | Basic SQL LIKE queries | Slow, no relevance ranking | PostgreSQL FTS, Meilisearch, Typesense, Algolia |
| Graph relationships | Relational DB with many JOINs | Complex queries, poor performance | Neo4j, or PostgreSQL with recursive CTEs |
| Time-series data | Standard RDBMS | Not optimized for time-range queries | TimescaleDB (PostgreSQL extension), InfluxDB |
| Geospatial queries | MySQL basic | Limited spatial functions | PostgreSQL + PostGIS |
| Embedded/edge | PostgreSQL, MySQL | Needs server process | SQLite, DuckDB, LibSQL |

**Detection:** Cross-reference stated requirements against chosen database capabilities.

---

## 12. Auth Provider Constraints

| Provider | Free Tier Limit | What Breaks | Detection |
|---|---|---|---|
| Clerk | 10,000 MAUs | User growth past 10K | Ask about expected scale |
| Auth0 | 7,500 MAUs | User growth past 7.5K | Ask about expected scale |
| Firebase Auth | Unlimited email/password; 10K phone verifications/month | Phone auth at scale | Check if SMS auth needed |
| Supabase Auth | 50,000 MAUs | Unlikely to hit for most projects | Included with Supabase |
| Cognito | 50,000 MAUs (first 50K free) | After 50K, pay per MAU | Check if AWS stack |
| Clerk | No custom domain on free tier | Branding requirements | Ask about white-labeling |

**Suggest:** For most projects, auth provider free tiers are generous enough. Flag only when user mentions "enterprise", "100K+ users", or "white-label".

---

## 13. Network & Connectivity Conflicts

| Scenario | Problem | Detection |
|---|---|---|
| Corporate proxy | npm/pip/cargo installs fail with network errors | `echo $HTTP_PROXY $HTTPS_PROXY` |
| VPN active | localhost routing issues, DNS resolution failures | `ifconfig | grep -c tun` or check for VPN interfaces |
| Firewall blocking dev ports | Can't access localhost:3000, database ports | `ss -tlnp 2>/dev/null | grep -E "3000|5432|6379"` |
| Offline development + cloud DB | No database access without internet | `ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1` |
| DNS issues with *.localhost | Subdomains don't resolve locally | `getent hosts test.localhost 2>/dev/null` |
| npm registry blocked | `npm install` fails | `npm ping 2>/dev/null` |

**Suggest:** For proxy issues — configure npm/git proxy settings. For offline — use local databases and mock services.

---

## 14. Port Conflicts

Existing services blocking default development ports.

| Port | Used By | Conflicts With |
|---|---|---|
| 3000 | Next.js, React dev server, Rails | Each other |
| 3001 | Next.js (fallback), various dev tools | Subsequent dev servers |
| 4200 | Angular dev server | Other Angular projects |
| 5000 | Flask, macOS AirPlay Receiver (!) | Flask on modern macOS |
| 5173 | Vite dev server | Multiple Vite projects |
| 5432 | PostgreSQL | Other PostgreSQL instances |
| 6379 | Redis | Other Redis instances |
| 8080 | Many Java servers, alternative HTTP | Various |
| 8000 | Django, PHP built-in server | Each other |
| 27017 | MongoDB | Other MongoDB instances |

**Detection script:**
```bash
# Check if common dev ports are already in use
for port in 3000 3001 4200 5000 5173 5432 6379 8000 8080 27017; do
  (echo > /dev/tcp/localhost/$port) 2>/dev/null && echo "port $port: IN USE" || echo "port $port: available"
done
```

**macOS-specific:** Port 5000 is used by AirPlay Receiver in macOS Monterey+. Detect: `lsof -i :5000 2>/dev/null | grep ControlCe`

**Suggest:** "Port [X] is already in use. You can either stop the existing process (`lsof -ti :X | xargs kill`) or configure the dev server to use a different port."

---

## 15. Git & Project State Conflicts

Issues with the current repository state that should be resolved first.

| Issue | Detection | Suggest |
|---|---|---|
| Git not installed | `git --version 2>/dev/null` fails | Install git |
| Git not configured (no user) | `git config user.name` is empty | `git config --global user.name "Name"` |
| Uncommitted changes | `git status --porcelain | head -1` is non-empty | Commit or stash before starting |
| Detached HEAD | `git symbolic-ref HEAD 2>/dev/null` fails | Checkout a branch |
| Existing remote conflicts | `git remote -v` shows unexpected remote | Verify remote URL |
| .gitignore missing | `[ ! -f .gitignore ]` | Create with standard patterns |
| Large files in history | `git rev-list --objects --all | git cat-file --batch-check | awk '$3 > 10000000'` | Set up Git LFS |
| Submodules present | `[ -f .gitmodules ]` | Run `git submodule update --init` |

**Detection script:**
```bash
git --version > /dev/null 2>&1 || { echo "git: NOT INSTALLED"; exit 1; }
[ -z "$(git config user.name)" ] && echo "git user.name: NOT SET"
[ -z "$(git config user.email)" ] && echo "git user.email: NOT SET"
[ -n "$(git status --porcelain 2>/dev/null | head -1)" ] && echo "git: UNCOMMITTED CHANGES"
git symbolic-ref HEAD > /dev/null 2>&1 || echo "git: DETACHED HEAD"
```

---

## 16. Existing Project Structure Conflicts

When initializing inside a folder that already has stuff.

| Issue | Detection | Suggest |
|---|---|---|
| package.json already exists | `[ -f package.json ]` | Merge or confirm overwrite |
| Conflicting framework detected | `grep -l "react\|vue\|angular\|svelte" package.json 2>/dev/null` | Flag: "This project already uses [X]. Starting a new [Y] project here will conflict." |
| tsconfig.json with incompatible settings | `[ -f tsconfig.json ]` | Review and merge |
| Existing .env with secrets | `[ -f .env ]` | Preserve and extend, never overwrite |
| Existing database | `[ -f *.sqlite ] || [ -d data/ ]` | Ask before modifying |
| node_modules present | `[ -d node_modules ]` | May need `rm -rf node_modules && npm install` for clean state |
| Docker containers running | `docker ps --format '{{.Names}}' 2>/dev/null | head -5` | Flag running containers |
| Conflicting package manager lockfiles | Multiple of: package-lock.json, yarn.lock, pnpm-lock.yaml | Choose one, remove others |

**Detection script:**
```bash
[ -f package.json ] && echo "existing: package.json"
[ -f requirements.txt ] && echo "existing: requirements.txt"
[ -f Cargo.toml ] && echo "existing: Cargo.toml"
[ -f go.mod ] && echo "existing: go.mod"
[ -f tsconfig.json ] && echo "existing: tsconfig.json"
[ -f .env ] && echo "existing: .env (PRESERVE — may contain secrets)"

# Conflicting lockfiles
LOCKS=0
[ -f package-lock.json ] && LOCKS=$((LOCKS+1)) && echo "lockfile: npm"
[ -f yarn.lock ] && LOCKS=$((LOCKS+1)) && echo "lockfile: yarn"
[ -f pnpm-lock.yaml ] && LOCKS=$((LOCKS+1)) && echo "lockfile: pnpm"
[ -f bun.lockb ] && LOCKS=$((LOCKS+1)) && echo "lockfile: bun"
[ $LOCKS -gt 1 ] && echo "WARNING: Multiple package manager lockfiles detected — pick one"
```

---

## 17. Docker & Container Prerequisites

| Issue | Detection | Suggest |
|---|---|---|
| Docker not installed | `docker --version 2>/dev/null` fails | Install Docker Desktop or Docker Engine |
| Docker daemon not running | `docker info 2>/dev/null` fails with "Cannot connect" | Start Docker Desktop or `sudo systemctl start docker` |
| Docker Compose not available | `docker compose version 2>/dev/null` fails | Install Docker Compose plugin |
| User not in docker group (Linux) | `groups | grep -q docker` fails | `sudo usermod -aG docker $USER` then re-login |
| WSL2 not enabled (Windows Docker) | Docker Desktop error on Windows | Enable WSL2 in Windows Features |
| Insufficient Docker disk space | `docker system df` shows high usage | `docker system prune -a` |
| Docker memory limit too low | `docker info 2>/dev/null | grep "Total Memory"` < 4GB | Increase in Docker Desktop settings |

---

## 18. Python-Specific Environment Issues

| Issue | Detection | Suggest |
|---|---|---|
| System Python (no venv) | `which python3` points to /usr/bin | Use venv: `python3 -m venv .venv && source .venv/bin/activate` |
| "Externally managed environment" error | Python 3.11+ on Debian/Ubuntu blocks pip | Use venv or `pipx` for CLI tools |
| Multiple Python versions conflicting | `python3 --version` != expected | Use pyenv to manage versions |
| pip not installed | `pip3 --version` fails | `python3 -m ensurepip --upgrade` |
| No C compiler for C extensions | `gcc --version` fails | `sudo apt install build-essential` |
| Missing development headers | `pip install psycopg2` fails | Install libpq-dev, libssl-dev, etc. |
| Poetry/PDM/Pipenv not installed | Project uses these but they're missing | Install the project's chosen package manager |

**Detection script:**
```bash
python3 --version 2>/dev/null || echo "python3: NOT INSTALLED"
python3 -m venv --help > /dev/null 2>&1 || echo "venv: NOT AVAILABLE"
pip3 --version 2>/dev/null || echo "pip3: NOT INSTALLED"
gcc --version > /dev/null 2>&1 || echo "gcc: NOT INSTALLED (needed for C extensions)"
```

---

## 19. Package Manager Conflicts

| Issue | Detection | Suggest |
|---|---|---|
| npm vs yarn vs pnpm vs bun | Check which lockfile exists | Use whichever lockfile is present |
| npm EACCES permission error | Global installs fail without sudo | Use nvm (installs Node to user dir) or `npm config set prefix '~/.npm-global'` |
| Corepack not enabled (for yarn/pnpm) | `corepack --version` fails or packageManager field ignored | `corepack enable` |
| Registry authentication issues | Private registry needs auth token | Check `.npmrc` configuration |
| Conflicting global packages | Old globally installed CLI tools | `npm ls -g --depth=0` to audit |
| pnpm strict mode breaking installs | Phantom dependencies not available | `pnpm install --shamefully-hoist` or fix imports |

---

## 20. Comprehensive Pre-Flight Detection Script

Run this SILENTLY before starting any project. Only surface conflicts found.

```bash
#!/bin/bash
# STP — Ship To Production Pre-Flight Environment Check
# Run silently — only output detected conflicts

CONFLICTS=()

# --- OS & Architecture ---
OS=$(uname -s)
ARCH=$(uname -m)

# --- RAM ---
if [ "$OS" = "Darwin" ]; then
  RAM_GB=$(($(sysctl -n hw.memsize) / 1073741824))
else
  RAM_GB=$(free -g 2>/dev/null | awk '/Mem:/{print $2}')
fi

# --- Disk ---
if [ "$OS" = "Darwin" ]; then
  DISK_AVAIL=$(df -g / | awk 'NR==2{print $4}')
else
  DISK_AVAIL=$(df -BG / | awk 'NR==2{print $4}' | tr -d 'G')
fi
[ "${DISK_AVAIL:-0}" -lt 5 ] && CONFLICTS+=("LOW DISK: Only ${DISK_AVAIL}GB available")

# --- Git ---
git --version > /dev/null 2>&1 || CONFLICTS+=("GIT: Not installed")
[ -z "$(git config user.name 2>/dev/null)" ] && CONFLICTS+=("GIT: user.name not configured")
[ -z "$(git config user.email 2>/dev/null)" ] && CONFLICTS+=("GIT: user.email not configured")

# --- Node.js ---
if command -v node > /dev/null 2>&1; then
  NODE_MAJOR=$(node -v | sed 's/v//' | cut -d. -f1)
  [ "$NODE_MAJOR" -lt 18 ] && CONFLICTS+=("NODE: Version $(node -v) is below minimum (v18+) for modern frameworks")
else
  # Only flag if project needs Node
  echo "node: not installed"
fi

# --- Python ---
if command -v python3 > /dev/null 2>&1; then
  PY_MINOR=$(python3 -c 'import sys; print(sys.version_info.minor)')
  PY_MAJOR=$(python3 -c 'import sys; print(sys.version_info.major)')
fi

# --- Build tools ---
if [ "$OS" = "Linux" ]; then
  gcc --version > /dev/null 2>&1 || CONFLICTS+=("BUILD: gcc not installed (needed for native modules)")
  make --version > /dev/null 2>&1 || CONFLICTS+=("BUILD: make not installed")
elif [ "$OS" = "Darwin" ]; then
  xcode-select -p > /dev/null 2>&1 || CONFLICTS+=("BUILD: Xcode Command Line Tools not installed. Run: xcode-select --install")
fi

# --- Docker ---
if command -v docker > /dev/null 2>&1; then
  docker info > /dev/null 2>&1 || CONFLICTS+=("DOCKER: Installed but daemon not running")
fi

# --- Ports ---
for port in 3000 5432 6379 8080; do
  (echo > /dev/tcp/localhost/$port) 2>/dev/null && CONFLICTS+=("PORT: $port is already in use")
done

# --- macOS: AirPlay on port 5000 ---
if [ "$OS" = "Darwin" ]; then
  lsof -i :5000 2>/dev/null | grep -q ControlCe && CONFLICTS+=("PORT: 5000 is used by macOS AirPlay Receiver (disable in System Settings > General > AirDrop & Handoff)")
fi

# --- Proxy ---
[ -n "$HTTP_PROXY" ] && CONFLICTS+=("NETWORK: HTTP_PROXY is set ($HTTP_PROXY) — may affect package installs")

# --- Existing project files ---
LOCKS=0
[ -f package-lock.json ] && LOCKS=$((LOCKS+1))
[ -f yarn.lock ] && LOCKS=$((LOCKS+1))
[ -f pnpm-lock.yaml ] && LOCKS=$((LOCKS+1))
[ -f bun.lockb ] && LOCKS=$((LOCKS+1))
[ $LOCKS -gt 1 ] && CONFLICTS+=("LOCKFILE: Multiple package manager lockfiles detected — pick one")

# --- GPU (for ML projects) ---
# nvidia-smi > /dev/null 2>&1 || echo "gpu: no NVIDIA GPU detected"

# --- Output ---
if [ ${#CONFLICTS[@]} -gt 0 ]; then
  echo "=== ENVIRONMENT CONFLICTS DETECTED ==="
  for c in "${CONFLICTS[@]}"; do
    echo "  ⚠ $c"
  done
fi
```

---

## Quick Reference: What to Check Per Project Type

| Project Type | Must Check |
|---|---|
| **Web app (Next.js/React)** | Node version, ports, package manager |
| **Python backend** | Python version, venv, pip, C compiler for extensions |
| **Mobile (React Native)** | Node, JDK, Android SDK, ANDROID_HOME, Xcode (iOS), CocoaPods |
| **Mobile (Flutter)** | Flutter SDK, Android SDK, Xcode (iOS), CocoaPods, Chrome (web) |
| **Mobile (Expo)** | Node, Apple/Google developer accounts (for publishing) |
| **Desktop (Electron)** | Node, node-gyp prerequisites, platform-specific build tools |
| **Desktop (Tauri)** | Rust, Node, webkit2gtk (Linux), system libraries |
| **ML/AI** | Python, GPU (nvidia-smi), CUDA, RAM (16GB+), disk space |
| **Docker-based** | Docker running, Docker Compose, disk space, memory allocation |
| **SaaS** | License audit (no AGPL/GPL), auth provider limits, payment provider |
| **Serverless** | Platform limits (size, timeout), no persistent state, no WebSockets |
| **iOS app** | macOS, Xcode, Apple Developer account ($99), signing certificates |
| **Game dev** | GPU, graphics libraries, game engine prerequisites |
