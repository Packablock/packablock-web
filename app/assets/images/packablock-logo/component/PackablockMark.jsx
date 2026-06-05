import React from "react";

/** The upright Packablock candle mark. Pass color (default teal) or "currentColor". */
export default function PackablockMark({ size = 32, color = "#22D3EE", title = "Packablock", ...rest }) {
  return (
    <svg width={size} height={size} viewBox="0 0 120 120" role="img" aria-label={title} {...rest}>
      <line x1="60" y1="24" x2="60" y2="96" stroke={color} strokeWidth="7" strokeLinecap="round" />
      <rect x="37" y="42" width="46" height="36" rx="9" fill={color} />
      <circle cx="60" cy="24" r="9" fill={color} />
      <circle cx="60" cy="96" r="9" fill={color} />
    </svg>
  );
}
