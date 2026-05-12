/* global React */
// Quack — shared UI primitives.
// Loaded after React, before the screen files.

const { useState, useEffect, useRef } = React;

// ─────────────────────────────────────────────────────────────
// VOCABULARY DATABASE — the world the kid is learning in.
// Used by missions, sticker book, parent dashboard.
// ─────────────────────────────────────────────────────────────
const VOCAB = [
  // Fruits
  { id: 'apple',    hanzi: '苹果', pinyin: 'píngguǒ',  en: 'Apple',    cat: 'fruits',    tone: 'orange', emoji: '🍎' },
  { id: 'orange',   hanzi: '橘子', pinyin: 'júzi',     en: 'Orange',   cat: 'fruits',    tone: 'orange', emoji: '🍊' },
  { id: 'banana',   hanzi: '香蕉', pinyin: 'xiāngjiāo', en: 'Banana',  cat: 'fruits',    tone: 'yellow', emoji: '🍌' },
  { id: 'grape',    hanzi: '葡萄', pinyin: 'pútáo',    en: 'Grapes',   cat: 'fruits',    tone: 'lilac',  emoji: '🍇' },
  // Animals
  { id: 'cat',      hanzi: '猫',  pinyin: 'māo',      en: 'Cat',      cat: 'animals',   tone: 'yellow', emoji: '🐱' },
  { id: 'dog',      hanzi: '狗',  pinyin: 'gǒu',      en: 'Dog',      cat: 'animals',   tone: 'orange', emoji: '🐶' },
  { id: 'bird',     hanzi: '鸟',  pinyin: 'niǎo',     en: 'Bird',     cat: 'animals',   tone: 'cobalt', emoji: '🐦' },
  { id: 'fish',     hanzi: '鱼',  pinyin: 'yú',       en: 'Fish',     cat: 'animals',   tone: 'mint',   emoji: '🐟' },
  // Household
  { id: 'chair',    hanzi: '椅子', pinyin: 'yǐzi',     en: 'Chair',    cat: 'household', tone: 'cobalt', emoji: '🪑' },
  { id: 'book',     hanzi: '书',  pinyin: 'shū',      en: 'Book',     cat: 'household', tone: 'rose',   emoji: '📖' },
  { id: 'cup',      hanzi: '杯子', pinyin: 'bēizi',    en: 'Cup',      cat: 'household', tone: 'lilac',  emoji: '🥤' },
  { id: 'lamp',     hanzi: '灯',  pinyin: 'dēng',     en: 'Lamp',     cat: 'household', tone: 'yellow', emoji: '💡' },
  // Food
  { id: 'rice',     hanzi: '米饭', pinyin: 'mǐfàn',    en: 'Rice',     cat: 'food',      tone: 'cream',  emoji: '🍚' },
  { id: 'noodle',   hanzi: '面',  pinyin: 'miàn',     en: 'Noodles',  cat: 'food',      tone: 'yellow', emoji: '🍜' },
  { id: 'egg',      hanzi: '蛋',  pinyin: 'dàn',      en: 'Egg',      cat: 'food',      tone: 'cream',  emoji: '🥚' },
  { id: 'tea',      hanzi: '茶',  pinyin: 'chá',      en: 'Tea',      cat: 'food',      tone: 'mint',   emoji: '🍵' },
  // Family
  { id: 'mom',      hanzi: '妈妈', pinyin: 'māma',     en: 'Mom',      cat: 'family',    tone: 'rose',   emoji: '👩' },
  { id: 'dad',      hanzi: '爸爸', pinyin: 'bàba',     en: 'Dad',      cat: 'family',    tone: 'cobalt', emoji: '👨' },
  { id: 'brother',  hanzi: '哥哥', pinyin: 'gēge',     en: 'Brother',  cat: 'family',    tone: 'orange', emoji: '🧒' },
  { id: 'sister',   hanzi: '姐姐', pinyin: 'jiějie',   en: 'Sister',   cat: 'family',    tone: 'lilac',  emoji: '👧' },
];

const CATEGORIES = [
  { id: 'fruits',    label: 'Fruits',    tone: 'orange' },
  { id: 'animals',   label: 'Animals',   tone: 'yellow' },
  { id: 'household', label: 'Household', tone: 'cobalt' },
  { id: 'food',      label: 'Food',      tone: 'mint' },
  { id: 'family',    label: 'Family',    tone: 'rose' },
];

const TONE_BG = {
  orange: 'var(--quack-orange)',
  yellow: 'var(--quack-yellow)',
  cobalt: 'var(--cobalt)',
  mint:   'var(--mint)',
  rose:   'var(--rose)',
  lilac:  'var(--lilac)',
  cream:  'var(--cream-deep)',
};
const TONE_FG = {
  orange: '#fff', yellow: 'var(--ink)', cobalt: '#fff',
  mint:   'var(--ink)', rose: 'var(--ink)', lilac: 'var(--ink)', cream: 'var(--ink)',
};

// ─────────────────────────────────────────────────────────────
// Eyebrow + sparkle glyphs
// ─────────────────────────────────────────────────────────────
function Eyebrow({ children, color = 'var(--quack-orange)', flank = true, size = 12 }) {
  return (
    <div style={{
      fontFamily: 'var(--font-body)', fontWeight: 800,
      fontSize: size, letterSpacing: '0.14em', textTransform: 'uppercase',
      color, display: 'inline-flex', alignItems: 'center', gap: 8,
    }}>
      {flank && <span>✦</span>}<span>{children}</span>{flank && <span>✦</span>}
    </div>
  );
}

function Sparkles({ count = 6, color = '#fff', opacity = 0.7, animate = false }) {
  const positions = [
    { top: '8%',  left: '12%', size: 14, rot: 12,  delay: 0 },
    { top: '18%', left: '78%', size: 22, rot: -18, delay: 0.4 },
    { top: '42%', left: '6%',  size: 16, rot: 30,  delay: 0.8 },
    { top: '60%', left: '84%', size: 12, rot: 0,   delay: 0.2 },
    { top: '74%', left: '20%', size: 18, rot: 22,  delay: 0.6 },
    { top: '32%', left: '50%', size: 10, rot: -8,  delay: 1.0 },
    { top: '88%', left: '70%', size: 14, rot: -14, delay: 0.3 },
    { top: '50%', left: '30%', size: 12, rot: 14,  delay: 0.9 },
  ].slice(0, count);
  return (
    <>
      {positions.map((p, i) => (
        <div key={i} style={{
          position: 'absolute', top: p.top, left: p.left,
          color, opacity, fontSize: p.size, fontWeight: 900,
          transform: `rotate(${p.rot}deg)`, pointerEvents: 'none',
          animation: animate ? `float-y 2.4s var(--ease-out) ${p.delay}s infinite` : 'none',
        }}>✦</div>
      ))}
    </>
  );
}

// ─────────────────────────────────────────────────────────────
// CTA button — chunky, with press
// ─────────────────────────────────────────────────────────────
function CTA({ children, onClick, variant = 'ink', full = true, disabled = false, style = {} }) {
  const variants = {
    ink:    { background: 'var(--ink)',          color: '#fff' },
    orange: { background: 'var(--quack-orange)', color: '#fff' },
    white:  { background: '#fff',                color: 'var(--quack-orange)' },
    ghost:  { background: 'transparent',         color: 'var(--ink)' },
  };
  return (
    <button
      onClick={disabled ? undefined : onClick}
      className="tap"
      style={{
        ...variants[variant],
        width: full ? '100%' : 'auto',
        padding: '18px 28px',
        borderRadius: 999,
        border: variant === 'ghost' ? '2px solid var(--ink-20)' : 'none',
        fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 16,
        boxShadow: variant === 'ghost' ? 'none' : 'var(--shadow-card)',
        opacity: disabled ? 0.4 : 1,
        cursor: disabled ? 'not-allowed' : 'pointer',
        ...style,
      }}
    >{children}</button>
  );
}

// ─────────────────────────────────────────────────────────────
// Phosphor-ish stroke icons (drawn inline so we don't depend on CDN)
// ─────────────────────────────────────────────────────────────
function Icon({ name, size = 24, color = 'currentColor', stroke = 1.8 }) {
  const props = {
    width: size, height: size, viewBox: '0 0 24 24', fill: 'none',
    stroke: color, strokeWidth: stroke,
    strokeLinecap: 'round', strokeLinejoin: 'round',
  };
  switch (name) {
    case 'back':    return <svg {...props}><path d="M15 6l-6 6 6 6" /></svg>;
    case 'close':   return <svg {...props}><path d="M6 6l12 12M6 18L18 6" /></svg>;
    case 'home':    return <svg {...props}><path d="M3 11l9-8 9 8" /><path d="M5 10v10h14V10" /></svg>;
    case 'mission': return <svg {...props}><circle cx="12" cy="12" r="9" /><circle cx="12" cy="12" r="4" /><circle cx="12" cy="12" r="1" fill={color} /></svg>;
    case 'book':    return <svg {...props}><path d="M4 4h7a3 3 0 013 3v13a2 2 0 00-2-2H4z" /><path d="M20 4h-7a3 3 0 00-3 3v13a2 2 0 012-2h8z" /></svg>;
    case 'parent':  return <svg {...props}><circle cx="12" cy="8" r="4" /><path d="M4 21c1-4 4.5-6 8-6s7 2 8 6" /></svg>;
    case 'mic':     return <svg {...props}><rect x="9" y="3" width="6" height="12" rx="3" /><path d="M5 11a7 7 0 0014 0M12 18v3" /></svg>;
    case 'camera':  return <svg {...props}><path d="M4 7h3l2-3h6l2 3h3v12H4z" /><circle cx="12" cy="13" r="4" /></svg>;
    case 'play':    return <svg {...props}><path d="M7 5l11 7-11 7z" fill={color} /></svg>;
    case 'speaker': return <svg {...props}><path d="M4 9v6h4l5 4V5L8 9z" fill={color} /><path d="M16 8a5 5 0 010 8" /></svg>;
    case 'star':    return <svg {...props}><path d="M12 3l2.6 5.5 6.1.7-4.5 4 1.2 6L12 16.7 6.6 19.2l1.2-6L3.3 9.2l6.1-.7z" fill={color} /></svg>;
    case 'fire':    return <svg {...props}><path d="M12 3c1 4 5 5 5 10a5 5 0 11-10 0c0-2 1-3 1-5 2 0 3-2 4-5z" fill={color} /></svg>;
    case 'check':   return <svg {...props}><path d="M5 12l4 4 10-10" /></svg>;
    case 'plus':    return <svg {...props}><path d="M12 5v14M5 12h14" /></svg>;
    case 'chevron': return <svg {...props}><path d="M9 6l6 6-6 6" /></svg>;
    case 'lock':    return <svg {...props}><rect x="5" y="11" width="14" height="9" rx="2" /><path d="M8 11V8a4 4 0 018 0v3" /></svg>;
    case 'shield':  return <svg {...props}><path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z" /></svg>;
    case 'photo':   return <svg {...props}><rect x="3" y="5" width="18" height="14" rx="2" /><circle cx="9" cy="11" r="2" /><path d="M3 17l6-5 5 4 3-2 4 3" /></svg>;
    case 'clock':   return <svg {...props}><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" /></svg>;
    case 'heart':   return <svg {...props}><path d="M12 20s-7-4.5-7-10a4 4 0 017-2 4 4 0 017 2c0 5.5-7 10-7 10z" fill={color} /></svg>;
    case 'sound':   return <svg {...props}><path d="M4 9v6h4l5 4V5L8 9z" /></svg>;
    case 'gear':    return <svg {...props}><circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.7 1.7 0 00.3 1.8l.1.1a2 2 0 11-2.8 2.8l-.1-.1a1.7 1.7 0 00-1.8-.3 1.7 1.7 0 00-1 1.5V21a2 2 0 11-4 0v-.1a1.7 1.7 0 00-1.1-1.5 1.7 1.7 0 00-1.8.3l-.1.1a2 2 0 11-2.8-2.8l.1-.1a1.7 1.7 0 00.3-1.8 1.7 1.7 0 00-1.5-1H3a2 2 0 110-4h.1a1.7 1.7 0 001.5-1.1 1.7 1.7 0 00-.3-1.8l-.1-.1a2 2 0 112.8-2.8l.1.1a1.7 1.7 0 001.8.3H9a1.7 1.7 0 001-1.5V3a2 2 0 114 0v.1a1.7 1.7 0 001 1.5 1.7 1.7 0 001.8-.3l.1-.1a2 2 0 112.8 2.8l-.1.1a1.7 1.7 0 00-.3 1.8V9a1.7 1.7 0 001.5 1H21a2 2 0 110 4h-.1a1.7 1.7 0 00-1.5 1z" /></svg>;
    default: return <svg {...props}/>;
  }
}

// ─────────────────────────────────────────────────────────────
// BackBtn — small chunky pill
// ─────────────────────────────────────────────────────────────
function BackBtn({ onClick, dark = false }) {
  return (
    <button onClick={onClick} className="tap" style={{
      width: 44, height: 44, borderRadius: 14, border: 'none',
      background: dark ? '#fff' : 'var(--ink)',
      color: dark ? 'var(--ink)' : '#fff',
      cursor: 'pointer',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      boxShadow: 'var(--shadow-card)',
    }}>
      <Icon name="back" size={22} />
    </button>
  );
}

// ─────────────────────────────────────────────────────────────
// Mascot — duck with expression states
// states: idle | speaking | celebrating | listening
// ─────────────────────────────────────────────────────────────
function Mascot({ state = 'idle', size = 160, src = (window.__resources && window.__resources.duckMascot) || 'assets/duck-mascot.png' }) {
  const anim = {
    idle:        'mascot-idle 3.6s var(--ease-out) infinite',
    speaking:    'mascot-speak 0.7s var(--ease-out) infinite',
    celebrating: 'mascot-celebrate 1.4s var(--ease-bounce) infinite',
    listening:   'mascot-idle 2.2s var(--ease-out) infinite',
  }[state] || 'none';
  return (
    <div style={{ position: 'relative', width: size, height: size, display: 'inline-block' }}>
      {state === 'listening' && (
        <>
          {[0, 0.5, 1].map(d => (
            <div key={d} style={{
              position: 'absolute', inset: '8%', borderRadius: '50%',
              border: '3px solid var(--quack-orange)',
              animation: `ring-grow 1.8s var(--ease-out) ${d}s infinite`,
              opacity: 0.4,
            }} />
          ))}
        </>
      )}
      <img src={src} alt="Agent Q" draggable="false" style={{
        width: '100%', height: '100%', objectFit: 'contain',
        filter: 'drop-shadow(0 8px 16px rgba(0,0,0,.18))',
        animation: anim,
        transformOrigin: 'center bottom',
      }} />
      {state === 'celebrating' && (
        <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}>
          {['✦', '★', '✦', '+', '★'].map((g, i) => (
            <div key={i} style={{
              position: 'absolute',
              top: `${[10, 30, 60, 20, 70][i]}%`,
              left: `${[-8, 100, -4, 108, 95][i]}%`,
              fontSize: [22, 16, 18, 14, 20][i],
              color: ['var(--quack-yellow)', 'var(--quack-orange)', '#fff', 'var(--quack-yellow)', 'var(--quack-orange)'][i],
              fontWeight: 900,
              animation: `star-spin 1.6s var(--ease-out) ${i * 0.15}s infinite`,
            }}>{g}</div>
          ))}
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// ProgressBar — chunky pill with animated fill
// ─────────────────────────────────────────────────────────────
function ProgressBar({ value = 0, max = 1, color = 'var(--quack-orange)', track = 'var(--ink-20)', height = 12 }) {
  const pct = Math.max(0, Math.min(1, value / max)) * 100;
  return (
    <div style={{ width: '100%', height, background: track, borderRadius: 999, overflow: 'hidden' }}>
      <div style={{
        width: `${pct}%`, height: '100%', background: color, borderRadius: 999,
        transition: 'width 420ms var(--ease-out)',
      }} />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Confetti burst — for mission complete
// ─────────────────────────────────────────────────────────────
function Confetti({ count = 28 }) {
  const pieces = Array.from({ length: count }).map((_, i) => ({
    x: Math.random() * 100,
    delay: Math.random() * 0.8,
    dur: 1.6 + Math.random() * 1.6,
    rot: Math.random() * 360,
    color: ['var(--quack-orange)', 'var(--quack-yellow)', 'var(--mint)', 'var(--cobalt)', 'var(--rose)'][i % 5],
    shape: i % 3,
  }));
  return (
    <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none', overflow: 'hidden' }}>
      {pieces.map((p, i) => (
        <div key={i} style={{
          position: 'absolute', left: `${p.x}%`, top: -20,
          width: p.shape === 0 ? 10 : 14,
          height: p.shape === 1 ? 16 : 10,
          background: p.color,
          borderRadius: p.shape === 2 ? '50%' : 2,
          transform: `rotate(${p.rot}deg)`,
          animation: `confetti-drop ${p.dur}s var(--ease-out) ${p.delay}s infinite`,
        }} />
      ))}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Sticker tile — the collected/locked artwork for a vocab item
// Drawn as a chunky tinted card with the hanzi as hero + emoji halo
// ─────────────────────────────────────────────────────────────
function StickerTile({ item, locked = false, size = 'md', onClick, justEarned = false }) {
  const dim = { sm: 78, md: 110, lg: 140 }[size];
  const bg = TONE_BG[item.tone] || 'var(--cream-deep)';
  const fg = TONE_FG[item.tone] || 'var(--ink)';
  return (
    <button
      onClick={onClick}
      className={`tap grain`}
      style={{
        width: '100%', aspectRatio: '1/1', minHeight: dim,
        background: locked ? 'var(--ink-20)' : bg,
        color: locked ? 'var(--ink-40)' : fg,
        borderRadius: 22,
        border: 'none',
        boxShadow: locked ? 'none' : 'var(--shadow-card)',
        position: 'relative', overflow: 'hidden',
        display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
        gap: 4, padding: 8,
        animation: justEarned ? 'pop-in 600ms var(--ease-bounce)' : 'none',
      }}
    >
      {!locked && (
        <>
          <div style={{
            position: 'absolute', top: 8, right: 10, fontSize: 18,
            opacity: .35, transform: 'rotate(14deg)',
          }}>{item.emoji}</div>
          <div style={{
            position: 'absolute', bottom: 6, left: 8, fontSize: 14,
            opacity: .35, transform: 'rotate(-10deg)',
          }}>✦</div>
        </>
      )}
      {locked ? (
        <Icon name="lock" size={28} color="var(--ink-40)" />
      ) : (
        <>
          <div style={{
            fontFamily: 'var(--font-display)', fontWeight: 800,
            fontSize: dim < 90 ? 28 : 38, lineHeight: 1, letterSpacing: '-0.01em',
          }}>{item.hanzi}</div>
          <div style={{
            fontFamily: 'var(--font-body)', fontWeight: 700,
            fontSize: dim < 90 ? 10 : 11, opacity: .9,
          }}>{item.pinyin}</div>
        </>
      )}
    </button>
  );
}

// ─────────────────────────────────────────────────────────────
// Object render — a stylized SVG of a vocab item for "scan" missions
// (Replaces emoji for hi-fi mission staging)
// ─────────────────────────────────────────────────────────────
function ObjectArt({ id, size = 140 }) {
  // Hand-rolled chunky SVGs for the most-used items.
  const common = { width: size, height: size, viewBox: '0 0 200 200' };
  const stroke = 'var(--ink)';
  switch (id) {
    case 'apple':
      return (
        <svg {...common}>
          <ellipse cx="100" cy="115" rx="68" ry="66" fill="#E54E1B" />
          <path d="M40 110c0-30 25-50 60-50s60 20 60 50c0 5-1 10-2 14-8-26-30-42-58-42s-50 16-58 42c-1-4-2-9-2-14z" fill="#FF8B5A" opacity=".6"/>
          <path d="M100 60c0-12 8-22 22-22-2 12-10 22-22 22z" fill="#3A8A3A"/>
          <path d="M100 60c-2-12 4-26 4-26s2 10-4 26z" fill="#5C2B0E" stroke={stroke} strokeWidth="2"/>
          <ellipse cx="78" cy="100" rx="16" ry="22" fill="#fff" opacity=".35"/>
        </svg>
      );
    case 'orange':
      return (
        <svg {...common}>
          <circle cx="100" cy="110" r="68" fill="#F86A38" />
          <circle cx="100" cy="110" r="68" fill="url(#og)" />
          <defs><radialGradient id="og" cx=".35" cy=".3"><stop offset="0" stopColor="#FFB76A"/><stop offset=".7" stopColor="#F86A38" stopOpacity="0"/></radialGradient></defs>
          {Array.from({length:8}).map((_,i) => {
            const a = (i/8)*Math.PI*2; const x = 100 + Math.cos(a)*40; const y = 110 + Math.sin(a)*40;
            return <circle key={i} cx={x} cy={y} r="2.5" fill="#fff" opacity=".4" />;
          })}
          <path d="M96 38c-4-4-4-12 4-14 6-2 12 4 10 10-1 4-8 6-14 4z" fill="#3A8A3A"/>
          <ellipse cx="78" cy="95" rx="14" ry="20" fill="#fff" opacity=".35"/>
        </svg>
      );
    case 'banana':
      return (
        <svg {...common}>
          <path d="M30 150c10-50 50-90 110-100 4 0 8 4 6 8-30 50-70 90-110 100-4 1-8-4-6-8z" fill="#FCC83C" stroke={stroke} strokeWidth="3"/>
          <path d="M50 140c10-30 40-60 80-72-30 30-60 60-80 72z" fill="#FFE89A"/>
          <circle cx="38" cy="148" r="4" fill="#5C2B0E"/>
          <circle cx="142" cy="50" r="4" fill="#5C2B0E"/>
        </svg>
      );
    case 'cup':
      return (
        <svg {...common}>
          <path d="M50 60h100l-8 100c-1 8-8 14-16 14H74c-8 0-15-6-16-14z" fill="#4F5DDB" stroke={stroke} strokeWidth="3"/>
          <path d="M150 80c20 0 30 12 30 28s-10 28-30 28" fill="none" stroke={stroke} strokeWidth="3"/>
          <path d="M70 70h80l-4 30H74z" fill="#fff" opacity=".25"/>
          <ellipse cx="75" cy="100" rx="10" ry="20" fill="#fff" opacity=".3"/>
        </svg>
      );
    case 'book':
      return (
        <svg {...common}>
          <path d="M30 50h60c10 0 20 6 20 16v90c0-6-6-12-16-12H30z" fill="#FF8FA3" stroke={stroke} strokeWidth="3"/>
          <path d="M170 50h-60c-10 0-20 6-20 16v90c0-6 6-12 16-12h64z" fill="#FF8FA3" stroke={stroke} strokeWidth="3"/>
          <path d="M40 70h50M40 86h44M40 102h48" stroke={stroke} strokeWidth="2" strokeLinecap="round"/>
          <path d="M116 70h50M116 86h44M116 102h48" stroke={stroke} strokeWidth="2" strokeLinecap="round"/>
        </svg>
      );
    case 'cat':
      return (
        <svg {...common}>
          <path d="M50 100l-8-32 28 18M150 100l8-32-28 18" fill="#FCC83C" stroke={stroke} strokeWidth="3"/>
          <ellipse cx="100" cy="120" rx="60" ry="54" fill="#FCC83C" stroke={stroke} strokeWidth="3"/>
          <circle cx="80" cy="115" r="6" fill={stroke}/>
          <circle cx="120" cy="115" r="6" fill={stroke}/>
          <path d="M100 130l-6 8h12z" fill="#FF8FA3"/>
          <path d="M70 145c10 4 50 4 60 0" stroke={stroke} strokeWidth="3" fill="none" strokeLinecap="round"/>
          <circle cx="62" cy="138" r="8" fill="#FF8FA3" opacity=".7"/>
          <circle cx="138" cy="138" r="8" fill="#FF8FA3" opacity=".7"/>
        </svg>
      );
    case 'dog':
      return (
        <svg {...common}>
          <ellipse cx="60" cy="90" rx="22" ry="34" fill="#E54E1B" stroke={stroke} strokeWidth="3" transform="rotate(-15 60 90)"/>
          <ellipse cx="140" cy="90" rx="22" ry="34" fill="#E54E1B" stroke={stroke} strokeWidth="3" transform="rotate(15 140 90)"/>
          <ellipse cx="100" cy="120" rx="60" ry="52" fill="#F86A38" stroke={stroke} strokeWidth="3"/>
          <circle cx="80" cy="115" r="6" fill={stroke}/>
          <circle cx="120" cy="115" r="6" fill={stroke}/>
          <ellipse cx="100" cy="138" rx="10" ry="7" fill={stroke}/>
          <path d="M100 145v8M88 152c4 4 20 4 24 0" stroke={stroke} strokeWidth="3" fill="none" strokeLinecap="round"/>
        </svg>
      );
    case 'fish':
      return (
        <svg {...common}>
          <path d="M150 100l30-30v60z" fill="#5FB594" stroke={stroke} strokeWidth="3"/>
          <ellipse cx="90" cy="100" rx="60" ry="40" fill="#93D5B8" stroke={stroke} strokeWidth="3"/>
          <circle cx="120" cy="92" r="6" fill="#fff"/><circle cx="122" cy="92" r="3" fill={stroke}/>
          <path d="M70 95c4-2 8-2 12 0M70 110c4 2 8 2 12 0" stroke={stroke} strokeWidth="2" fill="none" strokeLinecap="round"/>
          <path d="M140 80c2 4 2 36 0 40" stroke={stroke} strokeWidth="2" fill="none"/>
        </svg>
      );
    case 'bird':
      return (
        <svg {...common}>
          <ellipse cx="100" cy="115" rx="55" ry="50" fill="#4F5DDB" stroke={stroke} strokeWidth="3"/>
          <circle cx="100" cy="80" r="34" fill="#4F5DDB" stroke={stroke} strokeWidth="3"/>
          <circle cx="92" cy="78" r="5" fill="#fff"/><circle cx="93" cy="78" r="2.5" fill={stroke}/>
          <path d="M118 82l16-4-12 12z" fill="#FCC83C" stroke={stroke} strokeWidth="2"/>
          <path d="M60 130c-10 6-18 16-18 28 14-2 28-10 32-22z" fill="#2F3CB8" stroke={stroke} strokeWidth="2"/>
        </svg>
      );
    default:
      // Fallback: tinted blob with emoji
      return (
        <svg {...common}>
          <circle cx="100" cy="100" r="90" fill={TONE_BG[VOCAB.find(v=>v.id===id)?.tone] || 'var(--cream-deep)'}/>
          <text x="100" y="125" fontSize="92" textAnchor="middle">{VOCAB.find(v=>v.id===id)?.emoji || '?'}</text>
        </svg>
      );
  }
}

// ─────────────────────────────────────────────────────────────
// Status pill — small UPPERCASE chip
// ─────────────────────────────────────────────────────────────
function Pill({ children, color = 'var(--quack-orange)', bg = '#fff', icon }) {
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      background: bg, color, padding: '6px 12px', borderRadius: 999,
      boxShadow: 'var(--shadow-card)',
      fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 11,
      letterSpacing: '0.08em', textTransform: 'uppercase',
    }}>
      {icon && <span style={{ width: 8, height: 8, borderRadius: 999, background: color, animation: 'pulse 1.2s infinite' }} />}
      {children}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Tab bar (5 tabs)
// ─────────────────────────────────────────────────────────────
function TabBar({ active, onChange, dark = false }) {
  const tabs = [
    { id: 'home',     label: 'Home',     icon: 'home' },
    { id: 'missions', label: 'Missions', icon: 'mission' },
    { id: 'library',  label: 'Stickers', icon: 'book' },
    { id: 'parent',   label: 'Parent',   icon: 'parent' },
  ];
  return (
    <div style={{
      position: 'sticky', bottom: 0, left: 0, right: 0,
      marginTop: 'auto', flexShrink: 0,
      padding: '12px 12px 28px',
      background: 'var(--paper)',
      borderTopLeftRadius: 24, borderTopRightRadius: 24,
      boxShadow: '0 -6px 16px -8px rgba(20,33,61,.12)',
      display: 'flex', justifyContent: 'space-around', alignItems: 'center',
      zIndex: 30,
    }}>
      {tabs.map(t => {
        const on = active === t.id;
        return (
          <button key={t.id} onClick={() => onChange(t.id)} className="tap" style={{
            background: 'none', border: 'none',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
            color: on ? 'var(--quack-orange)' : 'var(--ink-40)',
            padding: '4px 8px',
            position: 'relative',
          }}>
            {on && <div style={{
              position: 'absolute', top: -8, width: 28, height: 4, borderRadius: 999,
              background: 'var(--quack-orange)',
            }} />}
            <Icon name={t.icon} size={24} stroke={on ? 2.2 : 1.8} />
            <span style={{ fontFamily: 'var(--font-body)', fontSize: 10, fontWeight: 800, letterSpacing: '0.04em' }}>{t.label}</span>
          </button>
        );
      })}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Card — paper surface with shadow + radius
// ─────────────────────────────────────────────────────────────
function Card({ children, color = 'var(--paper)', tone, padding = 18, style = {}, onClick }) {
  const bg = tone ? TONE_BG[tone] : color;
  const fg = tone ? TONE_FG[tone] : 'var(--ink)';
  return (
    <div onClick={onClick} className={onClick ? 'tap' : ''} style={{
      background: bg, color: fg,
      borderRadius: 22, padding,
      boxShadow: 'var(--shadow-card)',
      ...style,
    }}>{children}</div>
  );
}

Object.assign(window, {
  VOCAB, CATEGORIES, TONE_BG, TONE_FG,
  Eyebrow, Sparkles, CTA, Icon, BackBtn, Mascot, ProgressBar, Confetti,
  StickerTile, ObjectArt, Pill, TabBar, Card,
});
