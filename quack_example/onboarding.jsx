/* global React, Eyebrow, Sparkles, CTA, BackBtn, Icon, Mascot, ProgressBar */
const { useState: useStateOB, useEffect: useEffectOB } = React;

// ─────────────────────────────────────────────────────────────
// Splash — Q says hi
// ─────────────────────────────────────────────────────────────
function SplashScreen({ onNext, mascotState }) {
  return (
    <div style={{
      width: '100%', height: '100%', background: 'var(--quack-orange)',
      display: 'flex', flexDirection: 'column', position: 'relative', overflow: 'hidden',
      paddingTop: 64, animation: 'screen-in 320ms var(--ease-out)',
    }}>
      <Sparkles count={8} animate />
      <div style={{
        flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center',
        justifyContent: 'center', padding: '0 24px', textAlign: 'center', position: 'relative', zIndex: 2, minHeight: 0,
      }}>
        <Mascot state={mascotState || 'speaking'} size={170} />
        <div style={{ marginTop: 16 }}><Eyebrow color="var(--quack-yellow)">Mission begins</Eyebrow></div>
        <h1 style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 38, lineHeight: '42px', color: '#fff', margin: '8px 0 4px' }}>Hi, I'm Q</h1>
        <p style={{ fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 14, lineHeight: '20px', color: 'rgba(255,255,255,.92)', maxWidth: 280, margin: 0 }}>
          Your secret-agent buddy for learning Mandarin. Ready to start today's mission?
        </p>
      </div>
      <div style={{ padding: '0 24px 28px', position: 'relative', zIndex: 2 }}>
        <CTA variant="ink" onClick={onNext}>Let's go</CTA>
        <div style={{ textAlign: 'center', marginTop: 14, fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 13, color: 'rgba(255,255,255,.85)' }}>
          Already have an agent? <span style={{ textDecoration: 'underline' }}>Sign in</span>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Tell us more (name)
// ─────────────────────────────────────────────────────────────
function NameScreen({ onBack, onNext, value = '', mascotState }) {
  const [name, setName] = useStateOB(value);
  return (
    <div style={{ width: '100%', height: '100%', background: 'var(--cream)', display: 'flex', flexDirection: 'column', paddingTop: 70, animation: 'screen-in 320ms var(--ease-out)' }}>
      <div style={{ padding: '8px 24px 0' }}>
        <BackBtn onClick={onBack} />
        <div style={{ marginTop: 16 }}>
          <Eyebrow>Step 1 of 3</Eyebrow>
          <h1 style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 30, lineHeight: '36px', color: 'var(--ink)', margin: '6px 0 4px' }}>Tell us your name</h1>
          <p style={{ fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 14, color: 'var(--ink-60)', margin: 0 }}>So Q knows what to call you</p>
        </div>
      </div>
      <div style={{ flex: 1, padding: '20px 24px 0', display: 'flex', flexDirection: 'column' }}>
        <div className="grain" style={{
          background: 'var(--quack-orange)', borderRadius: 28, padding: '24px 22px',
          boxShadow: 'var(--shadow-card)', position: 'relative', overflow: 'hidden',
          flex: 1, display: 'flex', flexDirection: 'column',
        }}>
          <Sparkles count={4} opacity={.55} />
          <div style={{ position: 'relative', zIndex: 2 }}>
            <div style={{ textAlign: 'center', fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 13, color: 'rgba(255,255,255,.9)', marginBottom: 8 }}>First name</div>
            <input
              autoFocus
              value={name}
              onChange={e => setName(e.target.value)}
              placeholder="e.g. Nia"
              style={{
                width: '100%', boxSizing: 'border-box',
                padding: '18px 20px',
                background: 'var(--quack-orange-soft)', border: 'none', borderRadius: 16,
                textAlign: 'center', fontFamily: 'var(--font-body)', fontWeight: 800,
                fontSize: 18, color: '#fff',
                outline: 'none',
              }}
            />
          </div>
          <div style={{ flex: 1, display: 'flex', alignItems: 'flex-end', justifyContent: 'center', position: 'relative', zIndex: 2 }}>
            <Mascot state={mascotState || 'idle'} size={170} />
          </div>
        </div>
      </div>
      <div style={{ padding: '20px 24px 28px' }}>
        <CTA variant="ink" onClick={() => onNext(name.trim() || 'Agent')} disabled={!name.trim()}>Continue</CTA>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Age (number picker)
// ─────────────────────────────────────────────────────────────
function AgeScreen({ onBack, onNext, value = 8, mascotState }) {
  const ages = [4, 5, 6, 7, 8, 9, 10, 11, 12];
  const initialIdx = Math.max(0, ages.indexOf(value));
  const [idx, setIdx] = useStateOB(initialIdx);
  const trackRef = React.useRef(null);
  const stateRef = React.useRef({ dragging: false, startX: 0, startIdx: 0, dragX: 0 });
  const [drag, setDrag] = useStateOB(0);
  const ITEM = 110; // spacing between items
  const onDown = (e) => {
    const x = e.touches ? e.touches[0].clientX : e.clientX;
    stateRef.current = { dragging: true, startX: x, startIdx: idx, dragX: 0 };
    e.preventDefault();
  };
  const onMove = (e) => {
    if (!stateRef.current.dragging) return;
    const x = e.touches ? e.touches[0].clientX : e.clientX;
    const dx = x - stateRef.current.startX;
    stateRef.current.dragX = dx;
    setDrag(dx);
  };
  const onUp = () => {
    if (!stateRef.current.dragging) return;
    const dx = stateRef.current.dragX;
    const stepsMoved = Math.round(-dx / ITEM);
    let next = stateRef.current.startIdx + stepsMoved;
    next = Math.max(0, Math.min(ages.length - 1, next));
    setIdx(next);
    stateRef.current.dragging = false;
    setDrag(0);
  };
  React.useEffect(() => {
    const up = () => onUp();
    const move = (e) => onMove(e);
    window.addEventListener('mousemove', move);
    window.addEventListener('mouseup', up);
    window.addEventListener('touchmove', move, { passive: false });
    window.addEventListener('touchend', up);
    return () => {
      window.removeEventListener('mousemove', move);
      window.removeEventListener('mouseup', up);
      window.removeEventListener('touchmove', move);
      window.removeEventListener('touchend', up);
    };
  }, []);
  const offset = -idx * ITEM + (stateRef.current.dragging ? drag : 0);
  const age = ages[idx];

  return (
    <div style={{ width: '100%', height: '100%', background: 'var(--cream)', display: 'flex', flexDirection: 'column', paddingTop: 64, animation: 'screen-in 320ms var(--ease-out)' }}>
      <div style={{ padding: '8px 24px 0' }}>
        <BackBtn onClick={onBack} />
        <div style={{ marginTop: 14 }}>
          <Eyebrow>Step 2 of 3</Eyebrow>
          <h1 style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 28, color: 'var(--ink)', margin: '6px 0 2px' }}>How old are you?</h1>
          <p style={{ fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 13, color: 'var(--ink-60)', margin: 0 }}>Drag to spin · Q sets the level</p>
        </div>
      </div>
      <div style={{ flex: 1, padding: '14px 24px 0', display: 'flex', flexDirection: 'column', minHeight: 0 }}>
        <div className="grain" style={{
          background: 'var(--quack-orange)', borderRadius: 28,
          boxShadow: 'var(--shadow-card)', position: 'relative', overflow: 'hidden', flex: 1,
          display: 'flex', flexDirection: 'column', minHeight: 0,
        }}>
          <Sparkles count={4} opacity={.5} />

          {/* Center indicator */}
          <div style={{
            position: 'absolute', top: 36, left: '50%', transform: 'translateX(-50%)',
            width: 110, height: 110, borderRadius: 999,
            background: 'rgba(255,255,255,0.18)',
            border: '3px dashed rgba(255,255,255,0.45)',
            zIndex: 1,
          }} />

          {/* Draggable track */}
          <div
            ref={trackRef}
            onMouseDown={onDown}
            onTouchStart={onDown}
            style={{
              position: 'relative', zIndex: 2,
              height: 180, marginTop: 14,
              userSelect: 'none', cursor: stateRef.current.dragging ? 'grabbing' : 'grab',
              touchAction: 'none', overflow: 'hidden',
            }}
          >
            <div style={{
              position: 'absolute', top: 36, left: '50%',
              display: 'flex', gap: 0, alignItems: 'center',
              transform: `translateX(calc(-50% + ${offset}px))`,
              transition: stateRef.current.dragging ? 'none' : 'transform 320ms var(--ease-bounce)',
            }}>
              {ages.map((a, i) => {
                const dist = Math.abs(i - idx + (stateRef.current.dragging ? -drag / ITEM : 0));
                const sel = i === idx;
                const scale = Math.max(0.5, 1 - dist * 0.18);
                const op = Math.max(0.35, 1 - dist * 0.25);
                return (
                  <div key={a} style={{
                    width: ITEM, display: 'flex', alignItems: 'center', justifyContent: 'center',
                    pointerEvents: 'none',
                  }}>
                    <div style={{
                      width: 100, height: 100, borderRadius: 999,
                      background: sel ? '#fff' : 'rgba(255,255,255,0.92)',
                      color: 'var(--ink)',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      fontFamily: 'var(--font-display)', fontWeight: 800,
                      fontSize: 42, lineHeight: 1,
                      transform: `scale(${scale})`, opacity: op,
                      boxShadow: sel ? 'var(--shadow-pop)' : 'var(--shadow-card)',
                      transition: stateRef.current.dragging ? 'none' : 'all 220ms var(--ease-out)',
                    }}>{a}</div>
                  </div>
                );
              })}
            </div>
            {/* Edge fade */}
            <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none',
              background: 'linear-gradient(90deg, var(--quack-orange) 0%, transparent 18%, transparent 82%, var(--quack-orange) 100%)' }} />
          </div>

          <div style={{ textAlign: 'center', position: 'relative', zIndex: 2, marginTop: 4 }}>
            <div style={{ fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 12, letterSpacing: '0.14em', color: 'rgba(255,255,255,.85)', textTransform: 'uppercase' }}>I am</div>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 22, color: '#fff', marginTop: 2 }}>{age} years old</div>
          </div>

          <div style={{ flex: 1, display: 'flex', alignItems: 'flex-end', justifyContent: 'center', position: 'relative', zIndex: 2, minHeight: 0 }}>
            <Mascot state={mascotState || 'idle'} size={120} />
          </div>
        </div>
      </div>
      <div style={{ padding: '14px 24px 24px' }}>
        <CTA variant="ink" onClick={() => onNext(age)}>Continue</CTA>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// First-mission tutorial (skippable)
// ─────────────────────────────────────────────────────────────
function IntroScreen({ onBack, onNext, name = 'Agent', mascotState }) {
  const tips = [
    { icon: 'camera', title: 'Point at things', body: 'Show Q an apple. Q tells you what it is in Mandarin.' },
    { icon: 'mic',    title: 'Say it back',     body: 'Repeat the word. Q listens and tells you if it sounds right.' },
    { icon: 'star',   title: 'Collect stickers', body: 'Every word you learn becomes a sticker in your book.' },
  ];
  return (
    <div style={{ width: '100%', height: '100%', background: 'var(--cream)', display: 'flex', flexDirection: 'column', paddingTop: 70, animation: 'screen-in 320ms var(--ease-out)' }}>
      <div style={{ padding: '8px 24px 0' }}>
        <BackBtn onClick={onBack} />
        <div style={{ marginTop: 16 }}>
          <Eyebrow>Step 3 of 3</Eyebrow>
          <h1 style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 30, color: 'var(--ink)', margin: '6px 0 4px' }}>How it works, {name}</h1>
          <p style={{ fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 14, color: 'var(--ink-60)', margin: 0 }}>Three things to know before your first mission</p>
        </div>
      </div>
      <div style={{ flex: 1, padding: '20px 24px 0', display: 'flex', flexDirection: 'column', gap: 12 }}>
        {tips.map((t, i) => (
          <div key={i} style={{
            background: 'var(--paper)', borderRadius: 22, padding: 16,
            boxShadow: 'var(--shadow-card)', display: 'flex', alignItems: 'center', gap: 14,
            animation: `screen-in 400ms var(--ease-out) ${i * 0.1}s both`,
          }}>
            <div style={{
              width: 56, height: 56, borderRadius: 16,
              background: ['var(--quack-orange)', 'var(--cobalt)', 'var(--mint-deep)'][i],
              color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
              boxShadow: 'var(--shadow-card)',
            }}>
              <Icon name={t.icon} size={28} stroke={2.2} />
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 18, color: 'var(--ink)' }}>{t.title}</div>
              <div style={{ fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 13, color: 'var(--ink-60)', marginTop: 2, lineHeight: '18px' }}>{t.body}</div>
            </div>
          </div>
        ))}
      </div>
      <div style={{ padding: '20px 24px 28px' }}>
        <CTA variant="orange" onClick={onNext}>Start my first mission</CTA>
      </div>
    </div>
  );
}

Object.assign(window, { SplashScreen, NameScreen, AgeScreen, IntroScreen });
