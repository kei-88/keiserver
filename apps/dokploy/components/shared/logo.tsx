import { cn } from "@/lib/utils";

interface Props {
	className?: string;
	logoUrl?: string;
}

export const Logo = ({ className = "size-14", logoUrl }: Props) => {
	if (logoUrl) {
		return (
			<img
				src={logoUrl}
				alt="Organization Logo"
				className={cn(className, "object-contain rounded-sm")}
			/>
		);
	}

	return (
    <svg
      viewBox="0 0 200 200"
      className={className}
      xmlns="http://www.w3.org/2000/svg"
    >
      {/* Background circle with gradient */}
      <defs>
        <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" style={{ stopColor: '#6366f1', stopOpacity: 1 }} />
          <stop offset="100%" style={{ stopColor: '#8b5cf6', stopOpacity: 1 }} />
        </linearGradient>
        
        <linearGradient id="grad2" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" style={{ stopColor: '#8b5cf6', stopOpacity: 1 }} />
          <stop offset="100%" style={{ stopColor: '#ec4899', stopOpacity: 1 }} />
        </linearGradient>
      </defs>

      {/* Outer ring */}
      <circle
        cx="100"
        cy="100"
        r="90"
        fill="none"
        stroke="url(#grad1)"
        strokeWidth="3"
        opacity="0.3"
      />

      {/* Inner design - Abstract K shape */}
      <path
        d="M 60 60 L 60 140 M 60 100 L 120 60 M 60 100 L 120 140"
        stroke="url(#grad2)"
        strokeWidth="8"
        strokeLinecap="round"
        strokeLinejoin="round"
        fill="none"
      />

      {/* Number 88 stylized */}
      <g transform="translate(110, 85)">
        {/* First 8 */}
        <circle cx="10" cy="0" r="12" fill="url(#grad1)" opacity="0.8" />
        <circle cx="10" cy="30" r="12" fill="url(#grad1)" opacity="0.8" />
        
        {/* Second 8 */}
        <circle cx="35" cy="0" r="12" fill="url(#grad2)" opacity="0.8" />
        <circle cx="35" cy="30" r="12" fill="url(#grad2)" opacity="0.8" />
      </g>

      {/* Accent dots */}
      <circle cx="100" cy="100" r="3" fill="url(#grad1)" opacity="0.6" />
      <circle cx="85" cy="85" r="2" fill="url(#grad2)" opacity="0.4" />
      <circle cx="115" cy="115" r="2" fill="url(#grad2)" opacity="0.4" />
    </svg>
  );
};
