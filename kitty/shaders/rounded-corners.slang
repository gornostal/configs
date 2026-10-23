#language slang 2026
// Rounds the corners of the OS window by making the pixels outside a rounded
// rectangle transparent. Needs background_opacity < 1 (otherwise the window has
// no alpha channel and the corners come out black) and hidden window
// decorations (kitty's titlebar is drawn outside of shaders, square).

import kitty_custom_shader_types;

// Corner radius in physical pixels (so roughly double the logical size on a 2x screen).
static const float RADIUS = 20;

public float4
fragment_main(float4 color, KittyTextures t, KittyCustomShaderData d) {
    float2 size = float2(d.viewport_size_pixels);
    // Signed distance from this pixel to the rounded rectangle's edge; > 0 outside.
    float2 q = abs(t.pos * size - size * 0.5) - (size * 0.5 - RADIUS);
    float dist = length(max(q, float2(0))) - RADIUS;
    // One pixel of antialiasing. The backbuffer is premultiplied, so scale all
    // four channels. Keep alpha above zero: the final blit divides by it.
    float coverage = clamp(0.5 - dist, 1e-4, 1.0);
    return color * coverage;
}
