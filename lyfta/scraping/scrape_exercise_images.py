"""
Two-level web scraper for https://my.lyfta.app/exercises

Outer loop  : horizontal category menu (muscle groups)
Inner loop  : vertical scroll extraction (lazy images per category)

Dependencies: playwright, playwright-stealth
Usage:
    python scrape_exercise_images.py
    python scrape_exercise_images.py --max-categories 3
    python scrape_exercise_images.py --category-selector "div.myClass button"
    python scrape_exercise_images.py --reset-auth
"""

import argparse
import asyncio
import csv
import json
import re
import shutil
import sys
from pathlib import Path
from urllib.parse import urljoin, urlparse

# ═══════════════════════════════════════════════════════════════
#  CONFIG – adjust selectors to match the page's actual DOM
# ═══════════════════════════════════════════════════════════════
TARGET_URL = "https://my.lyfta.app/exercises"
BASE_URL = "https://my.lyfta.app"
USER_DATA_DIR = Path(__file__).parent / ".playwright_session"
OUTPUT_JSON = Path(__file__).parent / "exercise_images.json"
OUTPUT_CSV = Path(__file__).parent / "exercise_images.csv"
TIMEOUT = 30_000
SCROLL_PAUSE = 1.5
MAX_SCROLLS = 80

# Category-button selector — only elements matching this that ALSO pass the
# spatial bounding-box filter (top portion of page, inside horizontal scroll
# container) will be treated as valid muscle-group categories.
CATEGORY_SELECTOR = (
    "div[class*='Exercises-module'] button, "
    "[role='tab']:not([aria-selected='true']), "
    "[role='tablist'] [role='tab'], "
    "div[class*='scroll'] button, "
    "div[class*='horizontal'] button"
)

IGNORE_PATTERNS = [
    r"google\.com", r"google-logo", r"apple-logo", r"apple\.com",
    r"recaptcha", r"favicon", r"/_next/static.*\.woff2$",
    r"data:image/svg\+xml",
]


# ═══════════════════════════════════════════════════════════════
#  HELPERS
# ═══════════════════════════════════════════════════════════════

def load_existing_urls(path: Path) -> set:
    if path.exists():
        try:
            return {img["url"] for img in json.loads(path.read_text("utf-8")) if "url" in img}
        except (json.JSONDecodeError, KeyError):
            pass
    return set()


def save_results(results: list[dict], json_path: Path, csv_path: Path | None):
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(results, ensure_ascii=False, indent=2), "utf-8")
    print(f"  → Saved {len(results)} images to {json_path}")
    if csv_path:
        with open(csv_path, "w", encoding="utf-8", newline="") as f:
            w = csv.DictWriter(f, fieldnames=["url", "alt", "width", "height", "tag", "category"])
            w.writeheader()
            w.writerows(results)
        print(f"  → Saved {len(results)} images to {csv_path}")


def should_ignore(url: str) -> bool:
    return any(re.search(p, url, re.IGNORECASE) for p in IGNORE_PATTERNS)


def normalize_url(url: str, base: str = BASE_URL) -> str:
    """Resolve relative URLs and normalize. Preserves query string
    for image proxy URLs (Next.js _next/image, Cloudinary, etc.)."""
    resolved = urljoin(base, url)
    parsed = urlparse(resolved)
    qs = ("?" + parsed.query) if parsed.query else ""
    return f"{parsed.scheme}://{parsed.netloc}{parsed.path}{qs}"


def is_signin_page(url: str) -> bool:
    return any(seg in url.lower() for seg in ("/auth/login", "/auth/signin", "/sign-in", "/signin"))


def find_chrome_path() -> str | None:
    for p in [
        r"C:\Program Files\Google\Chrome\Application\chrome.exe",
        r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
        r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
        r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    ]:
        if Path(p).exists():
            return p
    return None


async def import_cookies(page, cookies_file: str):
    data = Path(cookies_file).read_text("utf-8").strip()
    if data.startswith("["):
        cookies = json.loads(data)
    else:
        cookies = []
        for line in data.splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split("\t")
            if len(parts) >= 7:
                cookies.append({
                    "name": parts[5], "value": parts[6],
                    "domain": parts[0].lstrip(".") if parts[0].startswith(".") else parts[0],
                    "path": parts[2], "secure": parts[3] == "TRUE",
                    "httpOnly": False,
                })
    if cookies:
        await page.context.add_cookies(cookies)
        print(f"  → Imported {len(cookies)} cookies")


# ═══════════════════════════════════════════════════════════════
#  DOM EXTRACTION HELPERS (injected once into the page)
# ═══════════════════════════════════════════════════════════════

EXTRACT_IMAGES_JS = """() => {
    const urls = [];
    const seen = new Set();
    const add = (url) => {
        if (url && !seen.has(url) && !url.startsWith('data:')) { seen.add(url); urls.push(url); }
    };
    // Collect from all img attributes that could hold real image URLs
    document.querySelectorAll('img').forEach(img => {
        const srcAttrs = ['src', 'data-src', 'data-lazy-src', 'data-original', 'data-image', 'data-lazy', 'data-img', 'data-src-original'];
        for (const attr of srcAttrs) {
            const val = img.getAttribute(attr);
            if (val) add(val);
        }
        if (img.srcset) img.srcset.split(',').forEach(e => add(e.trim().split(' ')[0]));
        const ds = img.getAttribute('data-srcset');
        if (ds) ds.split(',').forEach(e => add(e.trim().split(' ')[0]));
    });
    // picture > source elements
    document.querySelectorAll('picture source').forEach(s => {
        if (s.srcset) s.srcset.split(',').forEach(e => add(e.trim().split(' ')[0]));
        const ds = s.getAttribute('data-srcset');
        if (ds) ds.split(',').forEach(e => add(e.trim().split(' ')[0]));
    });
    // CSS background-images
    document.querySelectorAll('*').forEach(el => {
        const bg = getComputedStyle(el).backgroundImage;
        if (bg && bg !== 'none') {
            const m = bg.match(/url\\(["']?([^"')]+)["']?\\)/g);
            if (m) m.forEach(x => add(x.replace(/url\\(["']?/, '').replace(/["']?\\)/, '')));
        }
    });
    return urls;
}"""

FIND_VERTICAL_CONTAINER_JS = """() => {
    const candidates = [];
    const de = document.documentElement;
    if (de.scrollHeight > de.clientHeight + 50) candidates.push({ tag: 'documentElement', scrollH: de.scrollHeight, clientH: de.clientHeight });
    const b = document.body;
    if (b.scrollHeight > b.clientHeight + 50) candidates.push({ tag: 'body', scrollH: b.scrollHeight, clientH: b.clientHeight });
    document.querySelectorAll('*').forEach(el => {
        const cs = getComputedStyle(el);
        if ((cs.overflowY === 'auto' || cs.overflowY === 'scroll') && el.scrollHeight > el.clientHeight + 50) {
            candidates.push({ tag: el.tagName + (el.id ? '#' + el.id : '') + (el.className ? '.' + el.className.slice(0,40).replace(/\\s+/g,'.') : ''), scrollH: el.scrollHeight, clientH: el.clientHeight, ratio: (el.scrollHeight / el.clientHeight).toFixed(1) });
        }
    });
    candidates.sort((a, b) => b.scrollH - a.scrollH);
    return candidates;
}"""

# Ultra-broad scanner: finds ANY element in the upper page zone that
# contains meaningful text. React components don't expose onclick attributes,
# so we cannot rely on tag/attribute selectors for category detection.
SCAN_UPPER_ELEMENTS_JS = """() => {
    const vph = window.innerHeight;

    // ── 1) First pass: tag + selector scan (fast) ──
    const seen = new Set();
    let cats = [];

    const candidates = document.querySelectorAll(
        'button, a, [role="tab"], [role="button"], [tabindex], span, div, li, label'
    );
    candidates.forEach(el => {
        const text = (el.textContent || '').trim();
        if (!text || text.length < 2 || seen.has(text)) return;
        const r = el.getBoundingClientRect();
        if (r.width < 20 || r.height < 16) return;
        // Spatial: upper portion (top < 350px), past sidebar zone (left > 160)
        if (!(r.top > 10 && r.top < 350 && r.left > 160)) return;
        // Exclude elements nested inside sidebar containers
        let p = el.parentElement, inSidebar = false;
        while (p && p !== document.body) {
            const cs = getComputedStyle(p);
            if ((cs.overflowY === 'auto' || cs.overflowY === 'scroll') && p.scrollHeight > p.clientHeight + 100 && p.getBoundingClientRect().left < 160) {
                inSidebar = true; break;
            }
            p = p.parentElement;
        }
        if (inSidebar) return;
        seen.add(text);
        cats.push({
            text, tag: el.tagName,
            left: Math.round(r.left), top: Math.round(r.top),
            right: Math.round(r.right), bottom: Math.round(r.bottom),
            w: Math.round(r.width), h: Math.round(r.height),
            cls: (el.className || '').slice(0, 80)
        });
    });

    // ── 2) Second pass: brute force ALL elements in upper zone ──
    //      (catches anything the tag scan missed, e.g. <i>, <em>, custom elements)
    if (cats.length < 3) {
        document.querySelectorAll('*').forEach(el => {
            if (el.children.length > 0) return;   // skip containers with children
            const text = (el.textContent || '').trim();
            if (!text || text.length < 2 || seen.has(text)) return;
            const r = el.getBoundingClientRect();
            if (r.width < 20 || r.height < 16) return;
            if (!(r.top > 10 && r.top < 350 && r.left > 160)) return;
            seen.add(text);
            cats.push({
                text, tag: el.tagName,
                left: Math.round(r.left), top: Math.round(r.top),
                right: Math.round(r.right), bottom: Math.round(r.bottom),
                w: Math.round(r.width), h: Math.round(r.height),
                cls: (el.className || '').slice(0, 80)
            });
        });
    }

    // ── 3) Deduplicate by text and sort left-to-right ──
    const unique = [];
    const dedup = new Set();
    cats.forEach(c => {
        if (!dedup.has(c.text)) { dedup.add(c.text); unique.push(c); }
    });
    unique.sort((a, b) => a.left - b.left);
    unique.forEach((c, i) => c.index = i);
    return unique;
}"""


# ═══════════════════════════════════════════════════════════════
#  CORE LOGIC
# ═══════════════════════════════════════════════════════════════

async def setup_browser(args):
    """Launch browser, apply stealth, handle auth → return (page, context)."""
    from playwright.async_api import async_playwright

    p = await async_playwright().start()
    chrome_path = find_chrome_path()

    if args.use_chromium:
        bt = p.chromium
        launch_args = ["--disable-blink-features=AutomationControlled",
                       "--disable-features=IsolateOrigins,site-per-process",
                       "--no-sandbox", "--disable-setuid-sandbox"]
        print("Using: Chromium\n")
    elif chrome_path:
        bt = p.chromium
        launch_args = ["--disable-blink-features=AutomationControlled"]
        print(f"Using: Chrome ({chrome_path})\n")
    else:
        bt = p.chromium
        launch_args = ["--disable-blink-features=AutomationControlled",
                       "--disable-features=IsolateOrigins,site-per-process"]
        print("Using: Chromium (fallback)\n")

    context = await bt.launch_persistent_context(
        user_data_dir=str(USER_DATA_DIR),
        headless=args.headless,
        executable_path=chrome_path if not args.use_chromium and chrome_path else None,
        channel=None,
        args=launch_args,
        viewport={"width": 1440, "height": 900},
        user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
        locale="en-US",
        timezone_id="Europe/Madrid",
        permissions=["clipboard-read", "clipboard-write"],
        ignore_https_errors=True,
    )

    page = await context.new_page()
    page.set_default_timeout(TIMEOUT)

    await page.add_init_script("""
        Object.defineProperty(navigator, 'webdriver', { get: () => false });
        Object.defineProperty(navigator, 'plugins', { get: () => [1,2,3,4,5] });
        Object.defineProperty(navigator, 'languages', { get: () => ['en-US', 'en'] });
        window.chrome = { runtime: {} };
    """)

    try:
        import playwright_stealth
        stealth = playwright_stealth.Stealth()
        await stealth.apply_stealth_async(page)
    except ImportError:
        print("(playwright-stealth not installed)\n")

    if args.cookies:
        await import_cookies(page, args.cookies)

    print(f"Navigating to {TARGET_URL} ...")
    await page.goto(TARGET_URL, wait_until="networkidle", timeout=60_000)

    if is_signin_page(page.url):
        if args.headless:
            print("ERROR: Signin required. Run without --headless.")
            await context.close()
            sys.exit(1)
        print("\n" + "=" * 60)
        print("  AUTH REQUIRED — Sign in via the browser window.")
        print("=" * 60 + "\n")
        try:
            await page.wait_for_url(lambda u: not is_signin_page(u), timeout=300_000)
            print("Login detected.\n")
        except Exception:
            print("TIMEOUT: Login not detected.")
            await context.close()
            sys.exit(1)

    await page.goto(TARGET_URL, wait_until="networkidle")
    # Extra wait for async-rendered category buttons (React lazy load)
    await asyncio.sleep(3)
    return p, context, page


def setup_vertical_scroll_helpers(page, is_document: bool):
    """Return (scroll_to, get_scroll_pos) async functions."""
    if is_document:
        async def scroll_to(y: int):
            await page.evaluate(f"window.scrollTo(0, {y})")

        async def get_scroll_pos() -> int:
            return await page.evaluate("window.scrollY || window.pageYOffset")
    else:
        async def scroll_to(y: int):
            await page.evaluate(f"(window.__scrollContainer() || {{}}).scrollTop = {y}")

        async def get_scroll_pos() -> int:
            return await page.evaluate("(window.__scrollContainer() || {}).scrollTop || 0")

    return scroll_to, get_scroll_pos


async def detect_categories(page, selector_override: str | None = None, debug: bool = False):
    """Scan the upper portion of the page for clickable category elements.
    Excludes sidebar items by position (left > 160) and container type.
    Retries once after a wait if nothing found (async rendering).
    """
    cats = await page.evaluate(SCAN_UPPER_ELEMENTS_JS)

    # Retry once if nothing found (maybe DOM hasn't rendered categories yet)
    if not cats:
        print("  (no elements found, waiting 4s and retrying...)")
        await asyncio.sleep(4)
        cats = await page.evaluate(SCAN_UPPER_ELEMENTS_JS)

    # Always print raw counts without needing --debug
    if cats:
        print(f"\n  Raw scan: {len(cats)} elements in upper zone (y<350, x>160)")
        if debug:
            for c in cats:
                print(f"    [{c['index']}] '{c['text']}' tag={c['tag']} x={c['left']} y={c['top']} w={c['w']}h={c['h']} cls='{c.get('cls','')}'")
    else:
        print("  ⚠ No elements found in upper zone at all.")
        print("  → The horizontal category bar may not have rendered yet or uses a different layout.")
        return []

    # Filter: muscle-group categories are <DIV> at y≈144, w≈50-80, no class
    # Exclude: parent containers (w > 200), exercise cards (y > 250),
    #          main containers (y < 100), trash text (?, ×, etc.)
    filtered = [c for c in cats
                if c["text"] not in ("?", "", "×", "✕", "✖", "Favorites", "Cardio", "Filters")
                and c["w"] >= 40 and c["w"] <= 100
                and c["top"] >= 130 and c["top"] <= 170]

    # Show what was excluded
    if len(cats) > len(filtered):
        excluded_texts = [(c["text"][:30], c["top"], c["w"]) for c in cats if c not in filtered]
        print(f"  (excluded {len(cats)-len(filtered)} non-category elements)")
        if debug:
            for t, y, w in excluded_texts:
                print(f"    '{t}' y={y} w={w}")

    if not filtered:
        print("  ⚠ All elements filtered out. No valid category buttons remain.")
        return []

    # Reset indices after filtering
    for i, c in enumerate(filtered):
        c["index"] = i

    print(f"\n  Found {len(filtered)} muscle-group categories:")
    for c in filtered:
        print(f"    [{c['index']}] {c['text']} ({c['tag']}) | x={c['left']} y={c['top']} w={c['w']}")
    print()
    return filtered


async def scroll_horizontal_into_view(page, cat_name: str):
    """
    Find and click a category button by exact text match.
    Uses Playwright's get_by_text with exact=True for robust React re-render
    handling. Falls back to coordinate-based click if locator fails.
    """
    import re

    try:
        # Small wait for any React re-render to settle
        await asyncio.sleep(0.3)
        # Exact text locator – this works across DOM re-renders
        locator = page.get_by_text(cat_name, exact=True).first

        box = await locator.bounding_box()
        if not box:
            print(f"    ⚠ Cannot locate «{cat_name}» (no bounding box)")
            return False

        vph = await page.evaluate("window.innerHeight")
        vpw = await page.evaluate("window.innerWidth")

        # Verify it's in the upper category zone (not an exercise card at y≈295)
        if not (box["y"] > 5 and box["y"] < vph * 0.4 and box["width"] > 30):
            print(f"    ⚠ «{cat_name}» found at y={box['y']:.0f} (expected < {vph*0.4:.0f}) — skipping")
            return False

        # Scroll horizontally if off-screen
        if box["x"] < 30 or box["x"] + box["width"] > vpw - 30:
            await page.evaluate(f"""() => {{
                const targetX = {box["x"]};
                let hBar = null;
                document.querySelectorAll('*').forEach(el => {{
                    const cs = getComputedStyle(el);
                    if ((cs.overflowX === 'auto' || cs.overflowX === 'scroll') && el.scrollWidth > el.clientWidth + 20) {{
                        const r = el.getBoundingClientRect();
                        if (r.top > 5 && r.top < {vph} * 0.4 && r.left >= 0 && (!hBar || r.top < hBar.getBoundingClientRect().top)) hBar = el;
                    }}
                }});
                if (hBar) hBar.scrollLeft += targetX - 40;
            }}""")
            await asyncio.sleep(0.5)

        await locator.click(timeout=5000)
        return True

    except Exception as e:
        print(f"    ⚠ Cannot click «{cat_name}»: {e}")
        return False


async def process_category(page, cat_info, all_urls: set, all_details: dict, output_json, output_csv, args):
    """
    Outer-loop per category: wait for load → scroll vertical → extract.
    all_urls / all_details are mutated in place (global session state).
    """
    cat_name = cat_info["text"]
    cat_idx = cat_info["index"]

    print(f"\n{'─' * 60}")
    print(f"  Processing category {cat_idx + 1}: «{cat_name}»")
    print(f"{'─' * 60}")

    # 1. Click the category (locate by exact text, handles React re-renders)
    clicked = await scroll_horizontal_into_view(page, cat_name)
    if not clicked:
        print(f"  ⚠ Could not click category «{cat_name}», skipping.")
        return

    # 1b. ═══════════════════════════════════════════════════════
    #     SAFETY CHECK: ensure we didn't navigate away from /exercises
    #     If the sidebar was clicked, page URL will have changed — go back.
    #     ═══════════════════════════════════════════════════════
    await asyncio.sleep(1)
    current_url = page.url
    if "/exercises" not in current_url:
        print(f"  ⚠ NAVIGATION DETECTED! URL changed to: {current_url}")
        print(f"  → Going back and skipping category «{cat_name}»")
        await page.go_back()
        await asyncio.sleep(2)
        # Ensure we're back on exercises
        if "/exercises" not in page.url:
            print(f"  → Navigating back to {TARGET_URL}")
            await page.goto(TARGET_URL, wait_until="networkidle")
            await asyncio.sleep(1)
        return

    # 2. Wait for the vertical container to respond
    await asyncio.sleep(1)
    try:
        await page.wait_for_load_state("networkidle", timeout=10_000)
    except Exception:
        pass
    await asyncio.sleep(1)

    # 3. Re-detect vertical scroll container (DOM changes per category)
    vert_info = await page.evaluate(FIND_VERTICAL_CONTAINER_JS)
    if not vert_info:
        print("  ⚠ No vertical scroll container found, skipping category.")
        return

    best = vert_info[0]
    is_doc = best["tag"] in ("documentElement", "body")
    total_h = best["scrollH"]
    vp_h = best["clientH"]

    if not is_doc:
        await page.evaluate("""
            window.__scrollContainer = () => {
                let best = null, maxH = 0;
                document.querySelectorAll('*').forEach(el => {
                    const cs = getComputedStyle(el);
                    if ((cs.overflowY === 'auto' || cs.overflowY === 'scroll') && el.scrollHeight > el.clientHeight + 50) {
                        if (el.scrollHeight > maxH) { maxH = el.scrollHeight; best = el; }
                    }
                });
                return best;
            };
        """)

    scroll_to, get_scroll_pos = setup_vertical_scroll_helpers(page, is_doc)
    last_total_h = total_h
    no_new = 0
    same_h = 0

    # Reset scroll to top for this category
    await scroll_to(0)
    await asyncio.sleep(0.5)

    # 4. Inner scroll loop
    for step in range(args.max_scrolls):
        new_urls = await page.evaluate(EXTRACT_IMAGES_JS)
        before = len(all_urls)
        for u in new_urls:
            raw = u.strip()
            if not raw or should_ignore(raw):
                continue
            norm = normalize_url(raw)
            if norm not in all_urls:
                all_urls.add(norm)
                # Store raw URL for metadata lookup later
                all_details[norm] = {"raw": raw}

        curr_scroll = await get_scroll_pos()

        if len(all_urls) > before:
            no_new = 0
            if step % 5 == 0 or step == 0:
                print(f"    step {step:3d} — scroll={curr_scroll} — category total: {len(all_urls)}")
        else:
            no_new += 1

        if no_new >= 8 and step > 10:
            print(f"    → {no_new} steps with no new images, stopping vertical scroll.")
            break

        # "Load More" button click
        clicked_lm = await page.evaluate("""() => {
            for (const btn of document.querySelectorAll('button')) {
                const t = btn.textContent.toLowerCase().trim();
                if ((t.includes('load more') || t.includes('show more') || t.includes('ver más')) && !btn.disabled && btn.offsetParent !== null) {
                    btn.click(); return true;
                }
            }
            return false;
        }""")
        if clicked_lm:
            print(f"    → Clicked 'Load More' at step {step}")

        next_pos = curr_scroll + vp_h
        await scroll_to(next_pos)
        try:
            await page.wait_for_load_state("networkidle", timeout=5000)
        except Exception:
            pass
        await asyncio.sleep(SCROLL_PAUSE)

        # Check container growth
        cur_h = await page.evaluate("(window.__scrollContainer() || document.documentElement).scrollHeight") if not is_doc else await page.evaluate("document.documentElement.scrollHeight")
        if cur_h > last_total_h + 50:
            total_h = cur_h
            same_h = 0
            print(f"    → Container grew to {cur_h}")
        else:
            same_h += 1

        if next_pos >= total_h and same_h >= 3:
            print(f"    → Reached bottom at step {step} (scroll={next_pos} >= total={total_h})")
            fin_urls = await page.evaluate(EXTRACT_IMAGES_JS)
            for u in fin_urls:
                raw = u.strip()
                if not raw or should_ignore(raw):
                    continue
                all_urls.add(normalize_url(raw))
            break

    print(f"  ✔ Category «{cat_name}» done. Running total: {len(all_urls)} unique URLs\n")

    # ---- Scroll back to top so categories are visible again ----
    await scroll_to(0)
    await asyncio.sleep(0.5)

    # ---- Save progress after each category ----
    seen_before = load_existing_urls(output_json)
    fresh = [{"url": u, "alt": "", "width": 0, "height": 0, "tag": "img", "category": cat_name}
             for u in sorted(all_urls) if u not in seen_before]
    # Merge with previous results
    if output_json.exists():
        try:
            prev = json.loads(output_json.read_text("utf-8"))
            fresh = prev + fresh
        except (json.JSONDecodeError, KeyError):
            pass
    save_results(fresh, output_json, output_csv)


# ═══════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════

async def run():
    parser = argparse.ArgumentParser(description="Scrape exercise images from Lyfta (two-level navigation)")
    parser.add_argument("--output", "-o", help="Output JSON path")
    parser.add_argument("--csv", help="Also save as CSV")
    parser.add_argument("--reset-auth", action="store_true", help="Clear saved session")
    parser.add_argument("--headless", action="store_true", help="Run without window (needs saved session)")
    parser.add_argument("--max-scrolls", type=int, default=MAX_SCROLLS, help="Max vertical scroll steps per category")
    parser.add_argument("--max-categories", type=int, default=0, help="Max categories to process (0 = all)")
    parser.add_argument("--cookies", help="Import cookies from JSON or Netscape file")
    parser.add_argument("--use-chromium", action="store_true", help="Force Chromium over system Chrome")
    parser.add_argument("--category-selector", help="Override CATEGORY_SELECTOR CSS selector")
    parser.add_argument("--debug", action="store_true", help="Dump raw DOM info for debugging")
    args = parser.parse_args()

    # Global category selector override
    global CATEGORY_SELECTOR
    if args.category_selector:
        CATEGORY_SELECTOR = args.category_selector

    if args.reset_auth and USER_DATA_DIR.exists():
        shutil.rmtree(USER_DATA_DIR, ignore_errors=True)
        print("Session cleared.\n")

    output_json = Path(args.output) if args.output else OUTPUT_JSON
    output_csv = Path(args.csv) if args.csv else None

    # ---- Bootstrap ----
    play, context, page = await setup_browser(args)

    # ---- Detect categories (scan upper zone, filter spatially) ----
    categories = await detect_categories(page, CATEGORY_SELECTOR, debug=args.debug)
    if args.max_categories and categories:
        categories = categories[:args.max_categories]
        print(f"  (limited to {args.max_categories} categories)\n")

    # ---- Global session state ----
    all_urls = set()
    all_details: dict[str, dict] = {}

    if categories:
        for cat_info in categories:
            await process_category(page, cat_info, all_urls, all_details, output_json, output_csv, args)
    else:
        # No categories found; scrape whatever is visible as a single pass
        print("  No categories detected — falling back to one-pass vertical scroll.\n")

        # Reuse vertical scroll logic inline (minimal)
        vert_info = await page.evaluate(FIND_VERTICAL_CONTAINER_JS)
        if vert_info:
            best = vert_info[0]
            is_doc = best["tag"] in ("documentElement", "body")
            total_h = best["scrollH"]
            vp_h = best["clientH"]

            if not is_doc:
                await page.evaluate("""
                    window.__scrollContainer = () => {
                        let best = null, maxH = 0;
                        document.querySelectorAll('*').forEach(el => {
                            const cs = getComputedStyle(el);
                            if ((cs.overflowY === 'auto' || cs.overflowY === 'scroll') && el.scrollHeight > el.clientHeight + 50) {
                                if (el.scrollHeight > maxH) { maxH = el.scrollHeight; best = el; }
                            }
                        });
                        return best;
                    };
                """)

            scroll_to, get_scroll_pos = setup_vertical_scroll_helpers(page, is_doc)
            last_total_h = total_h
            no_new = 0
            same_h = 0
            await scroll_to(0)
            await asyncio.sleep(0.5)

            for step in range(args.max_scrolls):
                new_urls = await page.evaluate(EXTRACT_IMAGES_JS)
                before = len(all_urls)
                for u in new_urls:
                    raw = u.strip()
                    if not raw or should_ignore(raw):
                        continue
                    norm = normalize_url(raw)
                    if norm not in all_urls:
                        all_urls.add(norm)
                curr_scroll = await get_scroll_pos()
                if len(all_urls) > before:
                    no_new = 0
                    if step % 5 == 0 or step == 0:
                        print(f"    step {step:3d} — scroll={curr_scroll} — total: {len(all_urls)}")
                else:
                    no_new += 1
                if no_new >= 8 and step > 10:
                    break
                next_pos = curr_scroll + vp_h
                await scroll_to(next_pos)
                try:
                    await page.wait_for_load_state("networkidle", timeout=5000)
                except Exception:
                    pass
                await asyncio.sleep(SCROLL_PAUSE)
                cur_h = await page.evaluate("(window.__scrollContainer() || document.documentElement).scrollHeight") if not is_doc else await page.evaluate("document.documentElement.scrollHeight")
                if cur_h > last_total_h + 50:
                    total_h = cur_h
                    same_h = 0
                else:
                    same_h += 1
                if next_pos >= total_h and same_h >= 3:
                    fin_urls = await page.evaluate(EXTRACT_IMAGES_JS)
                    for u in fin_urls:
                        all_urls.add(normalize_url(u.strip()))
                    break

        # Save fallback results
        seen_before = load_existing_urls(output_json)
        fresh = [{"url": u, "alt": "", "width": 0, "height": 0, "tag": "img"}
                 for u in sorted(all_urls) if u not in seen_before]
        if output_json.exists():
            try:
                prev = json.loads(output_json.read_text("utf-8"))
                fresh = prev + fresh
            except (json.JSONDecodeError, KeyError):
                pass
        save_results(fresh, output_json, output_csv)

    # ---- Extract metadata (alt, dimensions) for final dedup & save ----
    final_details = await page.evaluate("""() => {
        const m = {};
        document.querySelectorAll('img').forEach(img => {
            const src = img.src || img.getAttribute('data-src') || '';
            if (src && !src.startsWith('data:')) {
                m[src] = { alt: img.alt || '', width: img.naturalWidth || img.width || 0, height: img.naturalHeight || img.height || 0 };
            }
        });
        return m;
    }""")

    # Merge metadata into saved results
    if output_json.exists():
        data = json.loads(output_json.read_text("utf-8"))
        for item in data:
            url = item["url"]
            if url in final_details:
                item.update(final_details[url])
        output_json.write_text(json.dumps(data, ensure_ascii=False, indent=2), "utf-8")
        print(f"\nMetadata enriched and saved to {output_json}")
        if output_csv:
            with open(output_csv, "w", encoding="utf-8", newline="") as f:
                w = csv.DictWriter(f, fieldnames=["url", "alt", "width", "height", "tag", "category"])
                w.writeheader()
                w.writerows(data)
            print(f"Updated CSV → {output_csv}")

    await context.close()
    await play.stop()
    print("\nDone.\n")


if __name__ == "__main__":
    asyncio.run(run())
