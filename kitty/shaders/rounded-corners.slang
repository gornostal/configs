#language slang 2026
// Rounds the corners of the OS window and draws a Dock-style edge and a drop shadow.
//
// The edge copies elementary's Dock: a translucent dark outline just outside the
// window, and a faint white highlight just inside it that is strongest along the
// top (a light reflection), like CSS `inset 0 1px 0 alpha(white, …)`.
//
// A light window needs different values: a faint white line is invisible on it, and
// a dark outline reads as a drawn stroke. So the edge is lit from above instead: a
// bright rim and a soft sheen along the top, almost no outline there, and the outline
// darkening towards the bottom into a tight contact shadow. The theme is told apart by
// the brightness of kitty's background, so the paired constants below hold
// (dark, light) values and are blended by it.
//
// The visible window is the OS window inset by SHADOW pixels on every side; that
// band is transparent except for the outline and the shadow. kitty.conf sets a
// matching single_window_margin_width so text stays clear of the band.
//
// Needs background_opacity < 1 (otherwise the window has no alpha channel and
// the corners come out black) and hide_window_decorations yes (kitty's own
// titlebar is square, and its titlebar-only shadow leaves white corners on Gala).

import kitty_custom_shader_types;

// All sizes are in physical pixels (roughly double the logical size on a 2x screen).
// SHADOW and RADIUS are mirrored, in logical pixels, by INSET and CLIP_RADIUS in
// ../gala-blur.c (the blurred area behind the window); change them together.
static const float RADIUS = 20;        // corner radius of the visible window
static const float SHADOW = 40;        // width of the band around it that holds the shadow
static const float SHADOW_OFFSET = 4;  // shadow is shifted down by this much
static const float2 SHADOW_ALPHA = float2(0.16, 0.12); // shadow opacity right at the window edge
static const float CONTACT = 6;        // width of the contact shadow, a tight dark one under the window
static const float CONTACT_OFFSET = 2; // contact shadow is shifted down by this much
static const float2 CONTACT_ALPHA = float2(0, 0.05);
static const float BORDER = 2;         // outline width, outside the window; 0 = none
static const float3 BORDER_COLOR = float3(0);
// On top of the shadow, so 0.4 ends up ~half black. Top and bottom of the window; the
// sides blend between them.
static const float2 BORDER_TOP = float2(0.4, 0.04);
static const float2 BORDER_BOTTOM = float2(0.4, 0.1);
static const float HIGHLIGHT = 2;      // highlight width, inside the window
static const float2 HIGHLIGHT_TOP = float2(0.09, 0.9);   // white opacity along the top edge
static const float2 HIGHLIGHT_SIDE = float2(0.02, 0.35); // white opacity along the sides and bottom
static const float SHEEN = 14;         // depth of the sheen that fades down from the top edge
static const float2 SHEEN_ALPHA = float2(0, 0.5);        // its white opacity at the edge

// Signed distance from p to a rounded rectangle centred at the origin; > 0 outside.
float
rounded_rect(float2 p, float2 half_size, float radius) {
    float2 q = abs(p) - (half_size - radius);
    return length(max(q, float2(0))) + min(max(q.x, q.y), 0.0) - radius;
}

// The dark (x) or light (y) value of a pair, or a blend of the two.
float
pick(float2 v, float light) {
    return lerp(v.x, v.y, light);
}

// Fraction of the pixel inside a shape, given the signed distance to it (1px of antialiasing).
float
cover(float dist) {
    return clamp(0.5 - dist, 0.0, 1.0);
}

public float4
fragment_main(float4 color, KittyTextures t, KittyCustomShaderData d) {
    float2 size = float2(d.viewport_size_pixels);
    float2 p = t.pos * size - size * 0.5;
    float2 half_size = size * 0.5 - SHADOW;
    // UV y grows upwards, so "down" is +y here.
    float2 down = float2(0, 1);
    // 0 on a dark background, 1 on a light one; picks between the (dark, light) pairs.
    float light = smoothstep(0.2, 0.5, dot(d.background.rgb, float3(0.2126, 0.7152, 0.0722)));

    // Window: content with the white highlight on top. color is not premultiplied.
    float edge = rounded_rect(p, half_size, RADIUS);
    float coverage = cover(edge);
    // A thin ring all around, and a crescent that is the window minus a copy of
    // itself shifted down: full width on the top edge, tapering to nothing
    // through the corners.
    float ring = coverage - cover(edge + HIGHLIGHT);
    float crescent = max(coverage - cover(rounded_rect(p + down * HIGHLIGHT, half_size, RADIUS)), 0.0);
    float highlight = max(ring * pick(HIGHLIGHT_SIDE, light), crescent * pick(HIGHLIGHT_TOP, light));
    // Sheen: the same crescent, SHEEN deep, fading out downwards.
    float sheen_crescent = max(coverage - cover(rounded_rect(p + down * SHEEN, half_size, RADIUS)), 0.0);
    float sheen_fade = 1.0 - clamp((half_size.y - p.y) / SHEEN, 0.0, 1.0);
    highlight = max(highlight, sheen_crescent * sheen_fade * sheen_fade * pick(SHEEN_ALPHA, light));
    float content_alpha = highlight + color.a * (1.0 - highlight);
    float3 window_rgb = content_alpha > 0.0
        ? (float3(1) * highlight + color.rgb * color.a * (1.0 - highlight)) / content_alpha
        : float3(0);
    float window_alpha = content_alpha * coverage;

    // Outline: the window grown by BORDER (its corners grow with it, like a CSS
    // spread). The window covers all of it except the ring outside the edge.
    float bottomness = smoothstep(-1.0, 1.0, -p.y / half_size.y);
    float border_opacity = lerp(pick(BORDER_TOP, light), pick(BORDER_BOTTOM, light), bottomness);
    float border_alpha = BORDER > 0.0 ? border_opacity * cover(edge - BORDER) : 0.0;

    // Shadow fades out across the band.
    float shadow_dist = rounded_rect(p + down * SHADOW_OFFSET, half_size, RADIUS);
    float fade = 1.0 - smoothstep(0.0, SHADOW - SHADOW_OFFSET, shadow_dist);
    float shadow_alpha = pick(SHADOW_ALPHA, light) * fade * fade;
    float contact_dist = rounded_rect(p + down * CONTACT_OFFSET, half_size, RADIUS);
    float contact_fade = 1.0 - smoothstep(0.0, CONTACT, contact_dist);
    float contact_alpha = pick(CONTACT_ALPHA, light) * contact_fade * contact_fade;
    shadow_alpha = contact_alpha + shadow_alpha * (1.0 - contact_alpha);

    // Window over outline over black shadow, still non-premultiplied.
    float under_alpha = border_alpha + shadow_alpha * (1.0 - border_alpha);
    float3 under_rgb = under_alpha > 0.0 ? BORDER_COLOR * border_alpha / under_alpha : float3(0);
    float alpha = window_alpha + under_alpha * (1.0 - window_alpha);
    float3 rgb = alpha > 0.0
        ? (window_rgb * window_alpha + under_rgb * under_alpha * (1.0 - window_alpha)) / alpha
        : float3(0);
    // Never let alpha reach 0 in the 8-bit buffer: kitty's final blit divides by
    // it, and 0/0 shows up as white. 1/255 is invisible.
    return float4(rgb, max(alpha, 1.0 / 255.0));
}
