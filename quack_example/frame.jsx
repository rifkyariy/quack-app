/* global React, IOSDevice */
function IOSFrame({ children, frame = true, dark = false, landscape = false }) {
  if (!landscape) {
    if (!frame) {
      return (
        <div style={{
          width: 402, height: 874, borderRadius: 36,
          background: dark ? '#1A2540' : 'var(--cream)',
          boxShadow: '0 30px 80px rgba(0,0,0,0.45), 0 4px 12px rgba(0,0,0,0.25)',
          overflow: 'hidden', position: 'relative',
        }}>{children}</div>
      );
    }
    return <IOSDevice dark={dark}>{children}</IOSDevice>;
  }

  // Landscape device — 874 × 402, dynamic island on left edge
  const bezelBg = dark ? '#000' : '#F2F2F7';
  return (
    <div style={{
      width: 874, height: 402, borderRadius: 48, overflow: 'hidden',
      position: 'relative', background: bezelBg,
      boxShadow: '0 40px 80px rgba(0,0,0,0.18), 0 0 0 1px rgba(0,0,0,0.12)',
      fontFamily: '-apple-system, system-ui, sans-serif',
    }}>
      {/* dynamic island — vertical, on the left edge */}
      {frame && (
        <div style={{
          position: 'absolute', left: 11, top: '50%', transform: 'translateY(-50%)',
          width: 37, height: 126, borderRadius: 24, background: '#000', zIndex: 50,
        }} />
      )}
      {/* content */}
      <div style={{ width: '100%', height: '100%', position: 'relative' }}>{children}</div>
      {/* home indicator — vertical, right edge */}
      {frame && (
        <div style={{
          position: 'absolute', right: 0, top: 0, bottom: 0, zIndex: 60,
          width: 34, display: 'flex', alignItems: 'center', justifyContent: 'flex-end',
          paddingRight: 8, pointerEvents: 'none',
        }}>
          <div style={{
            width: 5, height: 139, borderRadius: 100,
            background: dark ? 'rgba(255,255,255,0.7)' : 'rgba(0,0,0,0.25)',
          }} />
        </div>
      )}
    </div>
  );
}
window.IOSFrame = IOSFrame;
