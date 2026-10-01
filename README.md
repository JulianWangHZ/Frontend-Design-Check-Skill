# frontend-design-check

English | [繁體中文](README.zh-TW.md)

**Hand Claude a Figma link. Get back a page or app screen that has been checked against the design, pixel for pixel.**

`frontend-design-check` is a Claude Code skill that rebuilds Figma screens inside an existing frontend project and verifies the result with screenshots of the **actually running** UI. Use it to build new pages, align existing pages with the design, or split a page into modules on request.

> The skill instructions are written in Traditional Chinese. Claude follows them regardless of the language you prompt in.

## Supported platforms

| Platform | Screenshot | Measurement |
|---|---|---|
| Web (React, Vue, Next.js…, including mobile web and Expo web) | Browser at a fixed viewport + DPR | DOM: `getBoundingClientRect()`, computed style |
| iOS / Android apps (Swift, Kotlin, React Native, Expo, Flutter) | Simulator or device at a fixed device + scale | Real element tree: iOS `idb`, Android `uiautomator dump`, RN `measureInWindow`, or Appium, compared against Figma values on every run |

iOS checks need macOS (the iOS Simulator only runs on a Mac). On Windows and Linux you can check web and Android.

The rule is the same on both: two original images at the same pixel size, and only differences backed by evidence get fixed.

## Why

The usual failure with "build it from Figma" isn't building it. It's **verifying it**:

- Someone reads the source or a pasted screenshot and calls it done. In the running app, positions, fonts, and overflow content are all off.
- Exporting a nested frame drops overflowing layers, so the reference image itself is incomplete.
- A similarity score or pixel-diff ratio gets treated as the verdict, and fallback fonts and anti-aliasing throw it off.
- Several reviewers look at the same downscaled composite, agree, and someone changes the code. The change is wrong.

This skill turns comparison into an evidence-based process: two original images at the same size, viewport, and DPR. Disputed spots are checked by cropping both images at the same coordinates and measuring the DOM, and code only changes after that.

## How it works

1. **Lock the comparison target**: find the Figma node that contains the full page (including overflowing sibling layers) and produce a reference image with exactly the same pixel size as the running viewport.
2. **Read the project first**: repo instructions, app shell, design tokens, existing components and icon libraries. Reuse whatever fits. What Figma draws follows Figma; states and tokens it doesn't draw follow the codebase. If neither covers something, ask once instead of guessing.
3. **Build the layout**: outer geometry first (viewport, fixed / flow regions, overflow, z-index), then content, controls, states, and interactions.
4. **Verify the running UI**:
   - Web: build, open the browser, and screenshot only after confirming the final URL and `document.fonts.ready`. Settle disputes with same-coordinate crops plus `getBoundingClientRect()`.
   - App: pin the status bar, font scale, appearance, and animations, screenshot the simulator, and settle disputes with element-tree measurements.
5. **Deliver**: Figma reference, fresh screenshot, labeled side-by-side comparison, and a check log (node, URL or device, viewport or scale, capture time).

## Before you start

- A Figma link you can open, ideally pointing at the node that holds the full page. If the file needs access, make sure Claude Code is connected to the Figma MCP and can read it.
- A frontend project that runs, plus the route to build or check (for apps, the screen name or deep link).
- Web: a browser automation tool (e.g. Playwright MCP or Claude in Chrome) to open the page and take screenshots.
- App: a booted iOS Simulator (Xcode, macOS only) or Android emulator / device (`adb`). Screenshots use built-in commands. For numeric measurement, Android uses the built-in `uiautomator dump`; iOS needs either [`idb`](https://fbidb.io) (`brew install facebook/fb/idb-companion` + `pip install fb-idb`) or Appium. React Native projects can use `measureInWindow` instead, with nothing to install.
- A clear target viewport or device model. Put any responsive, interaction, or module-split requirements in the task.

## Install

Pick one:

**Claude Code plugin** (recommended)

```text
/plugin marketplace add JulianWangHZ/Frontend-Design-Check-Skill
/plugin install frontend-design-check@frontend-design-check
```

**npx**: installs into any agent that reads `SKILL.md`

```bash
npx -y skills add JulianWangHZ/Frontend-Design-Check-Skill --skill frontend-design-check -g
```

**Manual copy**: global or per project

macOS / Linux:

```bash
git clone https://github.com/JulianWangHZ/Frontend-Design-Check-Skill.git
# Global (all projects)
mkdir -p ~/.claude/skills
cp -R Frontend-Design-Check-Skill/skills/frontend-design-check ~/.claude/skills/
# Or a single project
mkdir -p <project-root>/.claude/skills
cp -R Frontend-Design-Check-Skill/skills/frontend-design-check <project-root>/.claude/skills/
```

Windows (PowerShell):

```powershell
git clone https://github.com/JulianWangHZ/Frontend-Design-Check-Skill.git
# Global (all projects)
New-Item -ItemType Directory -Force "$HOME\.claude\skills" | Out-Null
Copy-Item -Recurse Frontend-Design-Check-Skill\skills\frontend-design-check "$HOME\.claude\skills\"
# Or a single project
New-Item -ItemType Directory -Force "<project-root>\.claude\skills" | Out-Null
Copy-Item -Recurse Frontend-Design-Check-Skill\skills\frontend-design-check "<project-root>\.claude\skills\"
```

Keep `SKILL.md` and `references/` in the same relative layout. Restart Claude Code and `frontend-design-check` should appear in the `/` menu.

## Quick start

Open Claude Code in the **target frontend project** and send a task with the Figma link and acceptance criteria.

Build a new page:

```text
Use /frontend-design-check to rebuild this Figma page: <Figma page or node link>.
Implement it in this project at route /dashboard and check it at a 1440×900 viewport.
Keep all content, controls, and states from the design, and give me a side-by-side of the running page and the design.
```

Fix an existing page:

```text
Use /frontend-design-check to check /dashboard in this project against <Figma node link>.
Fix layout and detail differences that have evidence behind them, verified at a 1440×900 viewport.
```

Build an app screen:

```text
Use /frontend-design-check to rebuild this Figma screen: <Figma node link>.
Implement the Settings screen in this React Native project and check it on an iPhone 17 Pro simulator (402×874 pt @3x).
Give me a side-by-side of the simulator screenshot and the design.
```

When a task is clearly about rebuilding or aligning to a Figma design, Claude picks the skill up automatically. Type `/frontend-design-check` to force it (`/frontend-design-check:frontend-design-check` when installed as a plugin).

| If you want… | Add this to the task |
|---|---|
| Separate modules | Name the regions to split. Each gets a [module spec](skills/frontend-design-check/references/module-contract.md) |
| Independent review | Ask for "separate reviews of layout, details, and completeness" |
| Responsive / fluid layout | Describe the expected behavior so it isn't pinned to one static export size |
| A specific comparison screenshot | Say explicitly that your screenshot is the final comparison target |

## What you get

- Code changes, plus the relevant checks and build results
- Figma reference, fresh screenshot, and labeled side-by-side comparison (both at the same pixel size)
- A short check log: Figma node, final URL, viewport, DPR, capture time (for apps: bundle ID / package name, screen, device, OS version, scale)
- Confirmed remaining limitations (e.g. a required font is missing)
- Module specs, when a module split was requested

## Notes

**A font difference isn't always a bug.** Even with identical component coordinates, a platform fallback font changes glyph width, weight, and spacing. If the required font can't be used for licensing or technical reasons, it's logged as a rendering limitation instead of forcing spacing to match.

**No similarity scores.** Pixel-diff ratios are skewed by browser rendering, fallback fonts, annotations, and anti-aliasing, so they're only a hint. Verdicts come from full-resolution crops or DOM / element-tree measurements. See the [visual review guide](skills/frontend-design-check/references/visual-review.md).

**Apps are measured as real apps.** Numeric checks read the element tree on the simulator. React Native is not converted to web and measured in a browser, because browser layout and fonts differ from native and wouldn't match what users see. Position, size, and spacing are measured; background colors are sampled from the screenshot; font size and weight are derived from code. The report lists each confidence level separately.

**The app status bar isn't a difference.** Time, battery, and signal won't match the design, and that's expected. The status bar is pinned to 9:41 and full battery before capture. If the design's status bar is only a placeholder, that area is excluded. See the [app review guide](skills/frontend-design-check/references/native-review.md).

## Files

```text
.claude-plugin/
  plugin.json                      Claude Code plugin manifest
  marketplace.json                 Plugin marketplace manifest
skills/frontend-design-check/
  SKILL.md                         Trigger, workflow, and deliverables
  references/module-contract.md    Template for module specs
  references/visual-review.md      Screenshot review and dispute verification
  references/native-review.md      App (iOS / Android) capture and measurement
```

## License

MIT. See [LICENSE](LICENSE).
