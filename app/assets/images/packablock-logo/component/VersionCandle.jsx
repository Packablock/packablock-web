import React from "react";

// Map a semver-ish string ("1.2.3", "^4.0.0", "<5.0.0", "~4.18.0") to a sortable number.
export function versionToNumber(v) {
  const cleaned = String(v).replace(/^[^\d]*/, ""); // strip leading ^ ~ < > = v
  const [maj = 0, min = 0, pat = 0] = cleaned.split(".").map((n) => parseInt(n, 10) || 0);
  return maj * 1e6 + min * 1e3 + pat;
}

/**
 * Horizontal "candle" indicator for a package's version range.
 *
 *   ●────[ body ]──────●
 *   min    drift      max
 *
 *   left node  = lowest version (floor)
 *   body       = recent version drift (driftFrom..driftTo), or a marker at `current`
 *   right node = highest version the semver range allows (ceiling)
 *
 * Node spacing reflects how WIDE the allowed range is, so a tight `~4.18.0`
 * draws narrower than a `^4.0.0`. Position the component inside a fixed-width
 * column so rows line up.
 */
export default function VersionCandle({
  min,                 // lowest version  -> left node
  max,                 // highest allowed -> right node
  driftFrom,           // body start (optional)
  driftTo,             // body end   (optional)
  current,             // resolved version (used if drift not given)
  width = 200,
  height = 20,
  color = "#22D3EE",   // single accent; pass currentColor to inherit
  showNodes = true,
  className,
}) {
  const lo = versionToNumber(min);
  const hi = versionToNumber(max);
  const span = hi - lo || 1;

  const pad = height / 2;                 // keep nodes fully inside the box
  const usable = width - pad * 2;
  const cy = height / 2;
  const nodeR = Math.max(3, height * 0.3);
  const bodyH = Math.max(6, height * 0.6);
  const bodyR = bodyH / 3;

  const clamp = (p) => Math.max(pad, Math.min(width - pad, p));
  const pos = (v) => clamp(pad + ((versionToNumber(v) - lo) / span) * usable);

  const x1 = pad;
  const x2 = width - pad;

  // Body span: explicit drift range, else a small block at `current`, else centered.
  let bFrom, bTo;
  if (driftFrom != null && driftTo != null) {
    bFrom = pos(driftFrom);
    bTo = pos(driftTo);
  } else if (current != null) {
    const c = pos(current);
    bFrom = c - 14;
    bTo = c + 14;
  } else {
    const mid = (x1 + x2) / 2;
    bFrom = mid - 14;
    bTo = mid + 14;
  }
  const bx = clamp(Math.min(bFrom, bTo));
  const bw = Math.max(bodyH, Math.min(x2, Math.max(bFrom, bTo)) - bx);

  const label = `Version range ${min} to ${max}${current ? `, currently ${current}` : ""}`;

  return (
    <svg
      className={className}
      width={width}
      height={height}
      viewBox={`0 0 ${width} ${height}`}
      role="img"
      aria-label={label}
    >
      <line x1={x1} y1={cy} x2={x2} y2={cy} stroke={color} strokeWidth={height * 0.2} strokeLinecap="round" />
      <rect x={bx} y={cy - bodyH / 2} width={bw} height={bodyH} rx={bodyR} fill={color} />
      {showNodes && <circle cx={x1} cy={cy} r={nodeR} fill={color} />}
      {showNodes && <circle cx={x2} cy={cy} r={nodeR} fill={color} />}
    </svg>
  );
}
