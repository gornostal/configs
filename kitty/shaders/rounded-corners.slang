#language slang 2026
// Rounds the corners of the OS window and draws a drop shadow around it.
//
// The visible window is the OS window inset by SHADOW pixels on every side; that
// band is transparent except for the shadow. kitty.conf sets a matching
// single_window_margin_width so text stays clear of the band.
//
// Needs background_opacity < 1 (otherwise the window has no alpha channel and
// the corners come out black) and hide_window_decorations yes (kitty's own
// titlebar is square, and its titlebar-only shadow leaves white corners on Gala).

import kitty_custom_shader_types;

// All sizes are in physical pixels (roughly double the logical size on a 2x screen).
static const float RADIUS = 20;        // corner radius of the visible window
static const float SHADOW = 40;        // width of the band around it that holds the shadow
static const float SHADOW_OFFSET = 4;  // shadow is shifted down by this much
static const float SHADOW_ALPHA = 0.16; // shadow opacity right at the window edge

// Signed distance from p to a rounded rectangle centred at the origin; > 0 outside.
float
rounded_rect(float2 p, float2 half_size, float radius) {
    float2 q = abs(p) - (half_size - radius);
    return length(max(q, float2(0))) + min(max(q.x, q.y), 0.0) - radius;
}

public float4
fragment_main(float4 color, KittyTextures t, KittyCustomShaderData d) {
    float2 size = float2(d.viewport_size_pixels);
    float2 p = t.pos * size - size * 0.5;
    float2 half_size = size * 0.5 - SHADOW;

    // One pixel of antialiasing on the window edge. color is not premultiplied.
    float coverage = clamp(0.5 - rounded_rect(p, half_size, RADIUS), 0.0, 1.0);
    float window_alpha = color.a * coverage;

    // Shadow fades out across the band (UV y grows upwards, so "down" is +y here).
    float shadow_dist = rounded_rect(p + float2(0, SHADOW_OFFSET), half_size, RADIUS);
    float fade = 1.0 - smoothstep(0.0, SHADOW - SHADOW_OFFSET, shadow_dist);
    float shadow_alpha = SHADOW_ALPHA * fade * fade;

    // Window over black shadow, still non-premultiplied.
    float alpha = window_alpha + shadow_alpha * (1.0 - window_alpha);
    float3 rgb = alpha > 0.0 ? color.rgb * window_alpha / alpha : float3(0);
    // Never let alpha reach 0 in the 8-bit buffer: kitty's final blit divides by
    // it, and 0/0 shows up as white. 1/255 is invisible.
    return float4(rgb, max(alpha, 1.0 / 255.0));
}
