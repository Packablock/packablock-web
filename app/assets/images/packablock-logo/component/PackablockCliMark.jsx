import React from "react";

/** Packablock CLI mark: prompt chevron + cursor block. Pass color (default teal) or "currentColor". */
export default function PackablockCliMark({ size = 32, color = "#22D3EE", title = "Packablock CLI", ...rest }) {
  return (
    <svg width={size} height={size} viewBox="0 0 120 120" role="img" aria-label={title} {...rest}>
      <polyline points="34,40 58,60 34,80" fill="none" stroke={color} strokeWidth="10" strokeLinecap="round" strokeLinejoin="round" />
      <rect x="68" y="48" width="16" height="24" rx="4" fill={color} />
    </svg>
  );
}
