# Visual Layout Guide - Responsive Design

**Date**: February 5, 2026

---

## Screen Size Categories

```
┌─────────────────────────────────────────────────────────────────┐
│                    RESPONSIVE BREAKPOINTS                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  📱 MOBILE                600dp ─────────────────→ TABLET 900dp │
│  < 600 dp                                          600-900 dp   │
│                                                                 │
│  🖥️  TABLET LANDSCAPE      900dp ──────────────→ DESKTOP 1200dp │
│  900-1200 dp                                      900-1200 dp   │
│                                                                 │
│  💻 DESKTOP                1200dp ───────────→ LARGE DESKTOP    │
│  ≥ 1200 dp                                       ≥ 1200 dp     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Home Screen: Navigation Evolution

### 📱 Mobile Layout (< 600 dp)

```
┌───────────────────────────────┐
│  🏠 Menu    My Shopping App    │  ← Top Bar
├───────────────────────────────┤
│  📍 Nearest: Whole Foods      │  ← Supermarket Info
├───────────────────────────────┤
│                               │
│                               │
│    LISTS TAB CONTENT          │  ← Full width
│                               │
│                               │
│                               │
├───────────────────────────────┤
│ 📋  📅  🏪  📊  (Bottom Nav)   │  ← Navigation
│ Lists History Supermarkets... │
└───────────────────────────────┘

Navigation: Bottom Bar (4 items)
Menu: Hamburger (drawer overlay)
```

### 🖥️ Tablet Layout (600-900 dp)

```
┌────────────────────────────────────┐
│  My Shopping App              👤   │  ← Top Bar
├─────────┬───────────────────────────┤
│  SIDE   │                           │
│  RAIL   │  LISTS TAB CONTENT        │
│  NAV    │  (Wider content area)     │
│         │                           │
│ 📋 List │                           │
│ 📅 Hist │                           │
│ 🏪 Mark │                           │
│ 📊 Stat │                           │
│         │                           │
└─────────┴───────────────────────────┘

Navigation: Persistent Side Rail
Labels: Visible below icons
Menu: Integrated (no drawer)
```

### 💻 Desktop Layout (≥ 900 dp)

```
┌────────────────────────────────────────────┐
│  My Shopping App                      👤   │  ← Top Bar
├──────────────┬─────────────────────────────┤
│   SIDE RAIL  │                             │
│   (Wider)    │  LISTS TAB CONTENT          │
│              │  (Maximum width)            │
│ 📋 Lists     │                             │
│ 📅 History   │                             │
│ 🏪 Supermark │                             │
│ 📊 Stats     │                             │
│              │                             │
└──────────────┴─────────────────────────────┘

Navigation: Permanent Side Rail
Labels: Visible below icons  
Space: Optimized for content width
```

---

## Lists Screen: Master-Detail Evolution

### 📱 Mobile Layout (< 600 dp)

```
┌──────────────────────────────┐
│      MY SHOPPING LISTS       │  ← Header
├──────────────────────────────┤
│ 🔍 Search lists...           │
├──────────────────────────────┤
│ □ Weekly Groceries      📅    │
│   5 items - Modified: today   │  ← List Item
├──────────────────────────────┤
│ □ Party Planning         🎉   │
│   12 items - Modified: 2d ago │  ← List Item
├──────────────────────────────┤
│ □ Budget Basics          💰   │
│   8 items - Modified: 1w ago  │  ← List Item
│                               │
│                        ➕    │  ← FAB (Add)
└──────────────────────────────┘

Interaction: Tap item → Full-screen editor
Navigation: Stack-based
```

### 🖥️ Tablet Layout (600-900 dp)

```
┌──────────────────┬──────────────────┐
│    MASTER        │      DETAIL      │
├──────────────────┼──────────────────┤
│ 🔍 Search        │                  │
├──────────────────┤                  │
│ □ Weekly ...     │  📝 Weekly       │
│   5 items   ✓    │  Groceries       │
│                  │                  │
│ □ Party ...      │  ✓ Bread         │
│   12 items       │  ✓ Milk          │
│                  │  □ Cheese        │
│ □ Budget ...     │  □ Eggs          │
│   8 items        │  □ Butter        │
│                  │                  │
│            ➕    │  🏪 Whole Foods  │
└──────────────────┴──────────────────┘

Left Pane (40%): List of shopping lists
Right Pane (60%): Editor for selected list
Interaction: Click to select, edit in pane
```

### 💻 Desktop Layout (≥ 900 dp)

```
┌───────────────────────┬───────────────────────┐
│      MASTER (35%)     │      DETAIL (65%)     │
├───────────────────────┼───────────────────────┤
│ 🔍 Search            │                       │
├───────────────────────┤                       │
│ □ Weekly Groceries ✓  │  📝 WEEKLY GROCERIES │
│   5 items - today     │                       │
│                       │  Edit | Share | Stats │
│ □ Party Planning      │  ─────────────────── │
│   12 items - 2d ago   │  ✓ Bread (2 × $3)   │
│                       │  ✓ Milk (1 × $4)    │
│ □ Budget Basics       │  □ Cheese (        │
│   8 items - 1w ago    │  □ Eggs (6 × $2)    │
│                       │  □ Butter (1 × $5)  │
│ □ Emergency Items     │                       │
│   3 items - 3w ago    │  Supermarket:        │
│                       │  🏪 Whole Foods      │
│                ➕    │                       │
└───────────────────────┴───────────────────────┘

Left Pane (35%): Compact list with timestamps
Right Pane (65%): Full editor with details
More screen space utilization
```

---

## Supermarkets Screen: Grid Evolution

### 📱 Mobile Layout (< 600 dp)

```
┌──────────────────────────────┐
│    SUPERMARKETS              │
├──────────────────────────────┤
│ 🔍 Search stores...          │
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │ ⭐ Whole Foods           │ │
│ │ 🏪  15 categories        │ │
│ │ 📍  37.77, -122.50       │ │
│ │ ┌─────────────────────┐ │ │
│ │ │      EDIT BUTTON    │ │ │
│ │ └─────────────────────┘ │ │
│ └──────────────────────────┘ │
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │    Trader Joe's          │ │
│ │ 🏪  12 categories        │ │
│ │ 📍  37.78, -122.51       │ │
│ │ ┌─────────────────────┐ │ │
│ │ │      EDIT BUTTON    │ │ │
│ │ └─────────────────────┘ │ │
│ └──────────────────────────┘ │
│              ➕              │
└──────────────────────────────┘

Layout: Single column list
One supermarket per item
Full width cards
```

### 🖥️ Tablet Layout (600-900 dp)

```
┌─────────────────────────────────────┐
│    SUPERMARKETS                     │
├─────────────────────────────────────┤
│ 🔍 Search stores...                 │
├──────────────────────┬──────────────┤
│ ┌────────────────┐ │ ┌────────────┐│
│ │ ⭐ Whole Foods │ │ │ Trader     ││
│ │ 15 categories  │ │ │ Joe's      ││
│ │ 📍  37.77,-122 │ │ │ 12 cat.    ││
│ │ ┌────────────┐ │ │ │ 📍 37.78   ││
│ │ │   EDIT     │ │ │ │ ┌────────┐││
│ │ └────────────┘ │ │ │ │  EDIT  │││
│ └────────────────┘ │ │ │ └────────┘││
│ ┌────────────────┐ │ │ └────────────┘│
│ │ Safeway        │ │ │ ┌────────────┐│
│ │ 18 categories  │ │ │ │ Costco     ││
│ │ 📍  37.79,-122 │ │ │ │ 8 cat.     ││
│ │ ┌────────────┐ │ │ │ │ 📍 37.80   ││
│ │ │   EDIT     │ │ │ │ │ ┌────────┐││
│ │ └────────────┘ │ │ │ │ │ EDIT   │││
│ │                │ │ │ │ └────────┘││
│ └────────────────┘ │ │ └────────────┘│
│                   │ │                │
│            ➕     │                 │
└──────────────────┴──────────────────┘

Layout: 2-column grid
Cards side-by-side
Better space utilization
```

### 💻 Desktop Layout (≥ 900 dp)

```
┌─────────────────────────────────────────────────┐
│    SUPERMARKETS                                 │
├─────────────────────────────────────────────────┤
│ 🔍 Search stores...                             │
├─────────────┬─────────────┬─────────────────────┤
│ ┌─────────┐ │ ┌─────────┐ │ ┌─────────────────┐│
│ │ Whole   │ │ │ Trader  │ │ │ Safeway         ││
│ │ Foods   │ │ │ Joe's   │ │ │ 18 categories   ││
│ │ ⭐ 15   │ │ │ 12 cat. │ │ │ 📍 37.79, -122  ││
│ │ 📍 37.77│ │ │ 📍 37.78│ │ │ ┌───────────────┐││
│ │ ┌─────┐ │ │ │ ┌─────┐ │ │ │ │     EDIT      │││
│ │ │EDIT │ │ │ │ │EDIT │ │ │ │ └───────────────┘││
│ │ └─────┘ │ │ │ └─────┘ │ │ │                 ││
│ └─────────┘ │ └─────────┘ │ └─────────────────┘│
│ ┌─────────┐ │ ┌─────────┐ │ ┌─────────────────┐│
│ │ Costco  │ │ │ Kroger  │ │ │ Sprouts         ││
│ │ 8 cat.  │ │ │ 14 cat. │ │ │ 16 categories   ││
│ │ 📍 37.80│ │ │ 📍 37.75│ │ │ 📍 37.81, -122  ││
│ │ ┌─────┐ │ │ │ ┌─────┐ │ │ │ ┌───────────────┐││
│ │ │EDIT │ │ │ │ │EDIT │ │ │ │ │     EDIT      │││
│ │ └─────┘ │ │ │ └─────┘ │ │ │ └───────────────┘││
│ └─────────┘ │ └─────────┘ │ └─────────────────┘│
│              │              │                   │
│              │              │            ➕    │
└──────────────┴──────────────┴───────────────────┘

Layout: 3-4 column grid
Maximum information density
Each card is larger and easier to interact with
```

---

## Statistics Screen: Data Visualization Evolution

### 📱 Mobile Layout (< 600 dp)

```
┌──────────────────────────────┐
│     SPENDING STATISTICS      │
├──────────────────────────────┤
│ 📅 All Time  ▼               │  ← Period Selector
├──────────────────────────────┤
│                              │
│      ╱─────╲                 │
│    ╱         ╲               │  ← Pie Chart
│   │  CHART   │               │    (Full width)
│    ╲         ╱               │
│      ╲─────╱                 │
│                              │
├──────────────────────────────┤
│ Category Breakdown           │
├──────────────────────────────┤
│ ┌────────────────────────┐   │
│ │ 🥕 Produce   32.5%     │   │
│ │          $52.80        │   │  ← Category Items
│ └────────────────────────┘   │
│ ┌────────────────────────┐   │
│ │ 🧈 Dairy     28.7%     │   │
│ │          $46.50        │   │
│ └────────────────────────┘   │
│ ┌────────────────────────┐   │
│ │ 🍞 Grains   18.2%     │   │
│ │          $29.65        │   │
│ └────────────────────────┘   │
└──────────────────────────────┘

Layout: Vertical stack
Chart on top (full width)
Category list below
```

### 🖥️ Tablet Layout (600-900 dp)

```
┌────────────────────────────────────────┐
│     SPENDING STATISTICS                │
├────────────────────────────────────────┤
│ 📅 All Time  ▼                         │
├──────────────────┬─────────────────────┤
│                  │ Category Breakdown  │
│      ╱─────╲     │ ─────────────────── │
│    ╱         ╲   │ ┌──────────────────┐│
│   │  CHART   │   │ │ 🥕 Produce  32% ││
│    ╲  (40%)  ╱   │ │      $52.80     ││
│      ╲─────╱     │ └──────────────────┘│
│                  │ ┌──────────────────┐│
│                  │ │ 🧈 Dairy    29% ││
│                  │ │      $46.50     ││
│                  │ └──────────────────┘│
│                  │ ┌──────────────────┐│
│                  │ │ 🍞 Grains   18% ││
│                  │ │      $29.65     ││
│                  │ └──────────────────┘│
│                  │ ┌──────────────────┐│
│                  │ │ 🥬 Vegetables 15%││
│                  │ │      $24.35     ││
│                  │ └──────────────────┘│
└──────────────────┴─────────────────────┘

Layout: Side-by-side
Chart: Left (40%)
Details: Right (60%)
More categories visible
```

---

## Settings Screen: Configuration Evolution

### 📱 Mobile Layout (< 600 dp)

```
┌──────────────────────────────┐
│        SETTINGS              │
├──────────────────────────────┤
│ Notifications      [Switch]  │
├──────────────────────────────┤
│ Dark Mode          [Switch]  │
├──────────────────────────────┤
│ Font Size                    │
│ ────────────●──────── 100%   │
│ Small                 Large  │
│                              │
│ ┌────────────────────────┐  │
│ │ Preview                │  │
│ │ This is how text       │  │
│ │ looks at this size     │  │
│ │ Smaller text example   │  │
│ └────────────────────────┘  │
├──────────────────────────────┤
│ About                         │
│ App Version        1.0.0      │
│ Privacy Policy               │
│ Terms of Service             │
└──────────────────────────────┘

Layout: Single column
All controls stacked vertically
Preview below settings
```

### 🖥️ Tablet+ Layout (600+ dp)

```
┌──────────────────────┬──────────────────────┐
│  SETTINGS (50%)      │  PREVIEW (50%)       │
├──────────────────────┼──────────────────────┤
│ Notifications [✓]    │ Text Preview         │
│                      │ ────────────────────│
│ Dark Mode    [✓]     │ Display Large        │
│                      │ Headline Medium      │
│ Font Size: 100%      │ Title Medium         │
│ ────●──────          │ Body Medium          │
│ Small    Large       │ Body Small           │
│                      │                      │
│ About                │ ────────────────────│
│ Version   1.0.0      │ Color Palette        │
│ Privacy Policy       │ ┌──┐ Primary        │
│ Terms               │ ├──┤ Secondary      │
│                      │ ├──┤ Tertiary       │
│                      │ ├──┤ Error          │
│                      │ ├──┤ Surface        │
│                      │                      │
└──────────────────────┴──────────────────────┘

Layout: Two-column
Settings: Left (50%)
Preview: Right (50%)
Live typography preview
Color palette display
```

---

## Master-Detail Pattern Summary

### How It Works

```
┌─────────────────────────────────────────────────────────┐
│                  RESPONSIVE BEHAVIOR                     │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  📱 MOBILE (< 600 dp):                                 │
│  Item Tap → Full-screen modal/navigation               │
│                                                          │
│  🖥️ TABLET (600-900 dp):                               │
│  ┌────────────────┬──────────────────┐                │
│  │ Master (40%)   │ Detail (60%)     │                │
│  │ Select Item    │ Shows in Pane    │                │
│  └────────────────┴──────────────────┘                │
│                                                          │
│  💻 DESKTOP (≥ 900 dp):                                │
│  ┌──────────────┬─────────────────────┐               │
│  │ Master (35%) │ Detail (65%)        │               │
│  │ Select Item  │ Shows in Wider Pane │               │
│  └──────────────┴─────────────────────┘               │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## Responsive Spacing Reference

```
┌────────────────────────────────────────┐
│   PADDING/SPACING SCALE                │
├────────────────────────────────────────┤
│                                        │
│  Metric              Mobile  Tablet    │
│  ────────────────────────────────────│
│  Horizontal Padding   16 dp  24 dp    │
│  (gaps, margins)      ──────────      │
│                                        │
│  Vertical Padding     12 dp  16 dp    │
│  (gaps, margins)      ──────────      │
│                                        │
│  Item Spacing         12 dp  16 dp    │
│  (between elements)   ──────────      │
│                                        │
│  Corner Radius         8 dp  12 dp    │
│  (border-radius)      ──────────      │
│                                        │
│  Desktop: Add 30% more for extra space │
│                                        │
└────────────────────────────────────────┘
```

---

## Interaction Patterns

### Master-Detail Selection
```
Mobile                    Tablet+
─────────────────────────────────────
Tap List Item ────→ Full-screen editor
                   
Tap List Item ────→ Updates detail pane
                   (no navigation)
                   
No Detail Pane     Shows empty state
                   "Select to view"
```

### Navigation
```
Mobile                    Tablet+
─────────────────────────────────────
Bottom Nav Bar       Persistent Side Rail
(4 items)            (always visible)

Hamburger Menu       No menu needed
(drawer)            (nav is permanent)

Back Button          Detail pane close btn
(stack-based)        (no navigation)
```

---

## Summary: Key Layout Differences

| Screen | Mobile | Tablet | Desktop |
|--------|--------|--------|---------|
| **Home** | Bottom Nav | Side Rail | Side Rail (wider) |
| **Lists** | Stack Nav | Master(40%)/Detail(60%) | Master(35%)/Detail(65%) |
| **History** | Stack Nav | Master(40%)/Detail(60%) | Master(35%)/Detail(65%) |
| **Supermarkets** | 1-col list | 2-col grid | 3-col grid |
| **Statistics** | V-stack | H-split (40/60) | H-split (40/60) |
| **Settings** | V-stack | Side+Preview (50/50) | Side+Preview (50/50) |

---

**All layouts maintain:** ✅ Same colors ✅ Same icons ✅ Same functionality ✅ Material 3 design system

**Result**: Professional, responsive app that works beautifully on all devices! 📱 🖥️ 💻

