# Medical Scanner Viewport Debug Info

## Problem Analysis
The scanner screen shows:
- **White before playing** - Viewport texture not initialized
- **Magenta when playing** - ViewportTexture rendering issue (common in Godot)
- **Correct scene in editor** - Editor vs runtime rendering difference

## Solutions Applied

### 1. Viewport Render Mode ✅
- Changed to `UPDATE_ALWAYS` (mode 0) for consistent rendering
- Forces continuous updates instead of on-demand

### 2. Multi-Frame Initialization ✅
- Added 3-5 frame waits in `_ready()` to ensure proper setup
- Force viewport updates when scanner is activated

### 3. Material Setup ✅
- Added `flags_unshaded = true` to prevent lighting issues
- Increased emission energy for better visibility

### 4. Force Updates on Camera Switch ✅
- Call `force_viewport_update()` when entering scanner mode
- Ensures viewport re-renders when player switches view

## Alternative Solutions to Try

If the issue persists, try these in order:

### Option 1: Direct Texture Assignment
```gdscript
# In medical_scanner.gd _ready():
var screen_mesh = $Scanner/Screen
var viewport_texture = scanner_viewport.get_texture()
screen_mesh.material_override.albedo_texture = viewport_texture
```

### Option 2: Viewport Texture Recreation
```gdscript
# Force texture regeneration
scanner_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
await get_tree().process_frame
scanner_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
```

### Option 3: Scene Structure Change
Move SubViewport outside Scanner node hierarchy to avoid transform issues.

## Current Test State
The scanner should now:
1. Show proper blue UI with scan lines
2. Maintain visibility when switching to scanner camera
3. Force viewport updates to prevent magenta rendering

If magenta persists, the issue is likely Godot version-specific ViewportTexture bugs. Next step would be to implement a fallback 3D UI system instead of viewport rendering.
