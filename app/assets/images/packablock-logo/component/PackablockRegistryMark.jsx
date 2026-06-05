import React from "react";

/** Packablock registry mark: indexed spine with version bars. Pass color (default teal) or "currentColor". */
export default function PackablockRegistryMark({ size = 32, color = "#22D3EE", title = "Packablock registry", ...rest }) {
  return (
    <svg width={size} height={size} viewBox="0 0 120 120" role="img" aria-label={title} {...rest}>
      <line x1="40" y1="36" x2="40" y2="84" stroke={color} strokeWidth="7" strokeLinecap="round" />
      <circle cx="40" cy="42" r="6" fill={color} />
      <circle cx="40" cy="60" r="6" fill={color} />
      <circle cx="40" cy="78" r="6" fill={color} />
      <rect x="50" y="36.5" width="42" height="11" rx="4" fill={color} />
      <rect x="50" y="54.5" width="28" height="11" rx="4" fill={color} />
      <rect x="50" y="72.5" width="36" height="11" rx="4" fill={color} />
    </svg>
  );
}
