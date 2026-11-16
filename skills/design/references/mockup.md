# Mockup: cheap, interactive, confined to what matters

A mockup answers "how will this look and behave?" before the real thing is built. It's cheaper than building the feature and quick to change. It works for anything: a web page, an app screen, a desktop widget, a menu, a dialog, a panel.

## 1. Scope first
Decide the smallest surface the change needs and mock only that.
- Whatever the change touches **behaves like the real thing**: its clicks, right-clicks, keyboard, hover, drag, open/close, and the transitions between its states.
- Everything around it is **static context** (drawn once, inert) or **absent**.
- Example: a new edit mode for desktop widgets = the desktop with its widgets, the right-click menu, and only the "Edit widgets" entry working; the edit mode itself fully interactive. The rest of the shell isn't mocked; the other menu entries do nothing.
- Example: a new battery widget = the widget in its real place (on the bar or desktop, at real size) and its popout; not the whole bar's other widgets beyond static context.
Write the scope as the first lines of `<slug>.feedback.md`: what's interactive, what's static context.

## 2. Look like the real thing
- **Inside a project:** read its theme/token files, fonts, icon set, a sibling screen that does something similar, and the UI wording it already uses. Reuse them, so the mockup reads as the app rather than as a web page. Before inventing a control, check whether the project has one; use the existing one.
- Tokens only: colours, sizes, radii, durations come from the project's tokens (declared once as CSS custom properties). A spec value with no token becomes one named property.
- **Strict mode** (project uses M3E): every value from `M3E:`; decisions only where the spec allows.
- **Outside a project:** facts and taste as given; ask briefly if neither says what it should look like.
- Real sizes: a widget at its real size in its real context, a dialog at dialog size, a desktop app at 1440x900 and narrow.

## 3. Control section
A clearly separated area (visually distinct, outside the mocked surface, e.g. a narrow strip at the edge) holding **only** the inputs that matter for this mockup and can't be changed inside the mocked thing itself:
- environment states (a device has a battery or not, a network is offline, a second monitor is connected),
- settings from a settings page that isn't mocked but changes what's shown,
- theme, when the change has to work in several.
Nothing generic: no switchboard of every state, no design variants unless the user asked to compare options. If something can be changed inside the mocked surface, it's not in the control section.

## 4. Text
Short labels in the app's own wording. No sentences explaining a control, no notes about what stays or what happens, no header describing the mockup. Sample data looks real (plausible names, values and counts) and includes the case that stresses the layout when it matters (a long name, several devices).

## 5. Demo script (`<slug>.demo.json`)
So captures show the behaviour: a list of steps the capture tool replays, with a still taken after each.
```json
[{"click": "#desktop", "button": "right"}, {"wait": 400}, {"click": "text=Edit widgets"}, {"wait": 600},
 {"drag": ["#widget-cpu", 120, 40]}, {"press": "Escape"}, {"click": "#ctl-battery"}]
```
Steps: `click` (selector or `text=…`, optional `button`), `hover`, `press` (key), `type` ([selector, text]), `drag` ([selector, dx, dy]), `scroll` (pixels), `wait` (ms). Cover the main path through the interactive scope and each control-section input once.

## 6. Iterate in place
Each change request edits the same file. `<slug>.feedback.md` records the scope, then per round the request verbatim and what changed. Read it before every edit; never undo a recorded decision unless the new request says so. Remove what was dropped instead of hiding it.

## 7. Check before returning
- No page errors; every interactive element in scope responds; nothing outside scope pretends to work beyond static context.
- Text fits at the real size; focus visible; keyboard reaches the interactive scope.
- The control section changes what it claims to change.
