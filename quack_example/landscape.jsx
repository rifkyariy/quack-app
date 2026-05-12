/* global React */
/* global Eyebrow, Sparkles, CTA, BackBtn, Icon, Mascot, ProgressBar, StickerTile, ObjectArt, Pill, Card, VOCAB, TONE_BG, TONE_FG */
const { useState: useStateL, useEffect: useEffectL, useMemo: useMemoL } = React;

// Inset to clear the dynamic island (left) and home indicator (right)
const PAD_L = 56;
const PAD_R = 44;

// ─────────────────────────────────────────────────────────────
// Vertical tab rail for landscape parent
// ─────────────────────────────────────────────────────────────
function TabRail({ active, onChange }) {
  const tabs = [
    { id: 'home',     label: 'Home',     icon: 'home' },
    { id: 'missions', label: 'Missions', icon: 'mission' },
    { id: 'library',  label: 'Stickers', icon: 'book' },
    { id: 'parent',   label: 'Parent',   icon: 'parent' },
  ];
  return (
    <div style={{
      width: 64, height: '100%',
      background: 'var(--paper)',
      borderTopRightRadius: 24, borderBottomRightRadius: 24,
      boxShadow: '4px 0 16px -8px rgba(20,33,61,.12)',
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      gap: 18, padding: '20px 0',
    }}>
      {tabs.map(t => {
        const on = active === t.id;
        return (
          <button key={t.id} onClick={() => onChange(t.id)} className="tap" style={{
            background: 'none', border: 'none', position: 'relative',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
            color: on ? 'var(--quack-orange)' : 'var(--ink-40)', padding: 0, cursor: 'pointer',
          }}>
            {on && <div style={{
              position: 'absolute', left: -16, top: '50%', transform: 'translateY(-50%)',
              width: 4, height: 26, borderRadius: 999, background: 'var(--quack-orange)',
            }} />}
            <Icon name={t.icon} size={22} stroke={on ? 2.2 : 1.8} />
            <span style={{ fontFamily: 'var(--font-body)', fontSize: 9, fontWeight: 800, letterSpacing: '0.04em' }}>{t.label}</span>
          </button>
        );
      })}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// CAMERA MISSION — LANDSCAPE
//   Big viewport on left, mascot + word card + CTA on right
// ─────────────────────────────────────────────────────────────
function CameraMissionLandscape({ target, onBack, onComplete, setMascotState }) {
  const item = VOCAB.find(v => v.id === target) || VOCAB[0];
  const [phase, setPhase] = useStateL('aiming');
  const [scanProgress, setScanProgress] = useStateL(0);
  const [tick, setTick] = useStateL(0);

  useEffectL(() => {
    if (phase !== 'aiming') return;
    const id = setInterval(() => {
      setScanProgress(p => {
        if (p >= 1) { clearInterval(id); setTimeout(() => setPhase('detected'), 200); return 1; }
        return p + 0.04;
      });
    }, 80);
    return () => clearInterval(id);
  }, [phase]);

  useEffectL(() => {
    if (phase === 'detected') {
      setMascotState && setMascotState('speaking');
      const t = setTimeout(() => setPhase('say'), 1600);
      return () => clearTimeout(t);
    } else if (phase === 'say') {
      setMascotState && setMascotState('listening');
    }
  }, [phase]);

  useEffectL(() => {
    if (phase !== 'say') return;
    const id = setInterval(() => setTick(t => t + 1), 110);
    return () => clearInterval(id);
  }, [phase]);

  const phaseLabel = { aiming: 'Aim at it', detected: 'Got it!', say: 'Say it back', got: 'Nice!' }[phase];

  return (
    <div style={{
      width: '100%', height: '100%', background: 'var(--cream)',
      display: 'flex', flexDirection: 'row',
      paddingLeft: PAD_L, paddingRight: PAD_R,
      animation: 'screen-in 320ms var(--ease-out)',
    }}>
      {/* LEFT — camera viewport */}
      <div style={{ flex: '1 1 0', padding: '14px 10px 14px 14px', display: 'flex', flexDirection: 'column' }}>
        <div className="grain" style={{
          flex: 1, background: 'var(--ink)', borderRadius: 22,
          position: 'relative', overflow: 'hidden',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          {phase === 'aiming' && [
            { top: 12, left: 12 }, { top: 12, right: 12 },
            { bottom: 12, left: 12 }, { bottom: 12, right: 12 },
          ].map((c, i) => (
            <div key={i} style={{
              position: 'absolute', ...c, width: 28, height: 28,
              borderTop: c.top != null ? '3px solid var(--quack-orange)' : 'none',
              borderBottom: c.bottom != null ? '3px solid var(--quack-orange)' : 'none',
              borderLeft: c.left != null ? '3px solid var(--quack-orange)' : 'none',
              borderRight: c.right != null ? '3px solid var(--quack-orange)' : 'none',
            }} />
          ))}
          {phase === 'aiming' && (
            <div style={{
              position: 'absolute', left: 12, right: 12,
              top: `${12 + scanProgress * (340 - 24)}px`,
              height: 2, background: 'var(--quack-orange)',
              boxShadow: '0 0 12px var(--quack-orange)',
            }} />
          )}
          <div style={{
            opacity: phase === 'aiming' ? 0.7 + scanProgress * 0.3 : 1,
            transform: phase === 'detected' ? 'scale(1.1)' : 'scale(1)',
            transition: 'transform 420ms var(--ease-bounce), opacity 220ms',
          }}>
            <ObjectArt id={item.id} size={160} />
          </div>
          {(phase === 'detected' || phase === 'say' || phase === 'got') && (
            <div style={{
              position: 'absolute', top: 18, left: 18,
              background: 'rgba(0,0,0,.5)', backdropFilter: 'blur(8px)',
              padding: '7px 12px', borderRadius: 999,
              fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 10,
              letterSpacing: '0.08em', textTransform: 'uppercase',
              color: '#fff', display: 'flex', alignItems: 'center', gap: 6,
              animation: 'screen-in 420ms var(--ease-bounce)',
            }}>
              <span style={{ width: 7, height: 7, borderRadius: 999, background: 'var(--mint)' }} />
              Detected: {item.en}
            </div>
          )}
          {phase === 'aiming' && (
            <div style={{
              position: 'absolute', bottom: 14, left: 14, right: 14, textAlign: 'center', color: '#fff',
              fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 11, opacity: .8,
            }}>Hold steady — Q is looking…</div>
          )}
        </div>
      </div>

      {/* RIGHT — header + dynamic content + CTA */}
      <div style={{ width: 320, padding: '14px 14px 14px 10px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <BackBtn onClick={onBack} />
          <div style={{ flex: 1 }}>
            <ProgressBar value={['aiming','detected','say','got'].indexOf(phase)} max={4} color="var(--quack-orange)" track="var(--ink-20)" height={9} />
          </div>
          <div style={{
            background: 'var(--paper)', padding: '6px 10px', borderRadius: 999,
            display: 'flex', alignItems: 'center', gap: 5, boxShadow: 'var(--shadow-card)',
          }}>
            <Icon name="heart" size={12} color="var(--rose)" />
            <span style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 12, color: 'var(--ink)' }}>3</span>
          </div>
        </div>

        <div>
          <Eyebrow size={10}>Camera scan</Eyebrow>
          <h1 style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 22, color: 'var(--ink)', margin: '2px 0 0' }}>{phaseLabel}</h1>
        </div>

        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', minHeight: 0 }}>
          {phase === 'aiming' && (
            <Card padding={14} style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <Mascot state="idle" size={56} />
              <div style={{ flex: 1, fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 12, color: 'var(--ink-60)' }}>
                Point the camera at the {item.en.toLowerCase()} — I'll spot it.
              </div>
            </Card>
          )}
          {phase === 'detected' && (
            <Card padding={14} style={{ animation: 'screen-in 320ms var(--ease-bounce)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <Mascot state="speaking" size={60} />
                <div style={{ flex: 1 }}>
                  <Eyebrow flank={false} size={9}>Q says</Eyebrow>
                  <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 24, color: 'var(--ink)', marginTop: 1, lineHeight: 1 }}>
                    {item.hanzi}
                  </div>
                  <div style={{ fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 12, color: 'var(--ink-60)', marginTop: 2 }}>{item.pinyin}</div>
                </div>
                <button className="tap" style={{
                  width: 38, height: 38, borderRadius: 999, border: 'none',
                  background: 'var(--quack-orange)', color: '#fff',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  boxShadow: 'var(--shadow-card)', cursor: 'pointer',
                }}><Icon name="speaker" size={18} /></button>
              </div>
            </Card>
          )}
          {phase === 'say' && (
            <Card padding={14}>
              <Pill icon color="var(--quack-orange)">Q is listening</Pill>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 10 }}>
                <div style={{ flex: 1, display: 'flex', gap: 3, alignItems: 'center', height: 44 }}>
                  {Array.from({ length: 18 }).map((_, i) => {
                    const ph = (i + tick) * 0.6;
                    const h = 8 + Math.abs(Math.sin(ph) * 22) + (i % 4) * 2;
                    return <div key={i} style={{ width: 3, height: h, borderRadius: 999, background: 'var(--quack-orange)', opacity: 0.5 + (i % 4) * 0.13 }} />;
                  })}
                </div>
                <button onClick={() => { setMascotState && setMascotState('celebrating'); setPhase('got'); setTimeout(onComplete, 900); }} className="tap" style={{
                  width: 52, height: 52, borderRadius: 999, border: 'none',
                  background: 'var(--quack-orange)', color: '#fff',
                  boxShadow: 'var(--shadow-pop)', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
                }}><Icon name="mic" size={22} stroke={2} /></button>
              </div>
              <div style={{ marginTop: 8, fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 11, color: 'var(--ink-60)', textAlign: 'center' }}>
                Tap mic, say <b style={{ color: 'var(--quack-orange)', fontFamily: 'var(--font-display)', fontSize: 14 }}>{item.hanzi}</b>
              </div>
            </Card>
          )}
        </div>

        <div>
          {phase === 'aiming' && <CTA variant="ghost" disabled>Scanning…</CTA>}
          {phase === 'detected' && <CTA variant="ink" onClick={() => setPhase('say')}>I'll try saying it</CTA>}
          {phase === 'say' && <CTA variant="ghost" disabled>Tap the mic to speak</CTA>}
          {phase === 'got' && <CTA variant="orange" disabled>Nice!</CTA>}
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// SPEAK MISSION — LANDSCAPE
// ─────────────────────────────────────────────────────────────
function SpeakMissionLandscape({ targetCategory = 'fruits', onBack, onComplete, setMascotState, addLearned }) {
  const items = useMemoL(() => VOCAB.filter(v => v.cat === targetCategory).slice(0, 3), [targetCategory]);
  const [idx, setIdx] = useStateL(0);
  const [recState, setRecState] = useStateL('idle');
  const [level, setLevel] = useStateL(0);
  const [score, setScore] = useStateL(0);
  const item = items[idx];

  useEffectL(() => {
    if (recState !== 'recording') { setLevel(0); return; }
    let t = 0; const id = setInterval(() => { t += 1; setLevel(0.3 + Math.abs(Math.sin(t * 0.4)) * 0.7); }, 80);
    return () => clearInterval(id);
  }, [recState]);

  const startRec = () => { setMascotState && setMascotState('listening'); setRecState('recording'); };
  const stopRec = () => {
    setRecState('scoring');
    setTimeout(() => {
      const s = 75 + Math.floor(Math.random() * 24);
      setScore(s); setRecState('result');
      setMascotState && setMascotState(s >= 80 ? 'celebrating' : 'idle');
    }, 900);
  };

  const next = () => {
    if (item) addLearned && addLearned(item.id);
    if (idx + 1 < items.length) { setIdx(idx + 1); setRecState('idle'); setScore(0); }
    else onComplete(items[items.length - 1].id);
  };

  return (
    <div style={{
      width: '100%', height: '100%', background: 'var(--cream)',
      display: 'flex', flexDirection: 'row',
      paddingLeft: PAD_L, paddingRight: PAD_R,
      animation: 'screen-in 320ms var(--ease-out)',
    }}>
      {/* LEFT — hero word */}
      <div style={{ flex: '1 1 0', padding: '14px 10px 14px 14px', display: 'flex', flexDirection: 'column' }}>
        <div className="grain" style={{
          flex: 1, background: TONE_BG[item.tone], color: TONE_FG[item.tone],
          borderRadius: 22, padding: 18, position: 'relative', overflow: 'hidden',
          display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
          textAlign: 'center',
        }}>
          <Sparkles count={5} opacity={.55} animate />
          <div style={{ position: 'relative', zIndex: 2 }}>
            <ObjectArt id={item.id} size={92} />
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 50, lineHeight: 1, marginTop: 4 }}>{item.hanzi}</div>
            <div style={{ fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 16, marginTop: 4, opacity: .9 }}>{item.pinyin}</div>
            <div style={{ fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 12, marginTop: 2, opacity: .8 }}>{item.en}</div>
          </div>
        </div>
      </div>

      {/* RIGHT — header + mic + CTA */}
      <div style={{ width: 340, padding: '14px 14px 14px 10px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <BackBtn onClick={onBack} />
          <div style={{ flex: 1 }}>
            <ProgressBar value={idx + (recState === 'result' ? 1 : 0)} max={items.length} color="var(--cobalt)" track="var(--ink-20)" height={9} />
          </div>
          <div style={{
            background: 'var(--paper)', padding: '6px 10px', borderRadius: 999,
            display: 'flex', alignItems: 'center', gap: 5, boxShadow: 'var(--shadow-card)',
          }}>
            <Icon name="heart" size={12} color="var(--rose)" />
            <span style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 12, color: 'var(--ink)' }}>3</span>
          </div>
        </div>

        <div>
          <Eyebrow color="var(--cobalt)" size={10}>Say it back</Eyebrow>
          <h1 style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 22, color: 'var(--ink)', margin: '2px 0 0' }}>Word {idx + 1} of {items.length}</h1>
        </div>

        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', minHeight: 0 }}>
          {recState === 'idle' && (
            <Card padding={14} style={{ textAlign: 'center' }}>
              <div style={{ fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 11, color: 'var(--ink-60)' }}>Tap and hold the mic, then say it</div>
              <button onMouseDown={startRec} onMouseUp={stopRec} onTouchStart={startRec} onTouchEnd={stopRec}
                className="tap" style={{
                  marginTop: 10, width: 76, height: 76, borderRadius: 999, border: 'none',
                  background: 'var(--quack-orange)', color: '#fff',
                  boxShadow: 'var(--shadow-pop)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
                }}><Icon name="mic" size={32} stroke={2} /></button>
            </Card>
          )}
          {recState === 'recording' && (
            <Card padding={14}>
              <Pill icon color="var(--quack-orange)">Listening</Pill>
              <div style={{ display: 'flex', gap: 4, alignItems: 'center', height: 48, justifyContent: 'center', marginTop: 10 }}>
                {Array.from({ length: 22 }).map((_, i) => {
                  const seed = (Math.sin(i * 1.3) + 1) / 2;
                  const h = 8 + level * (24 + seed * 24);
                  return <div key={i} style={{ width: 3, height: h, borderRadius: 999, background: 'var(--quack-orange)', transition: 'height 80ms linear' }} />;
                })}
              </div>
              <div style={{ marginTop: 8, fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 11, color: 'var(--ink-60)', textAlign: 'center' }}>Release when you're done</div>
            </Card>
          )}
          {recState === 'scoring' && (
            <Card padding={14} style={{ textAlign: 'center' }}>
              <div style={{ display: 'inline-flex', gap: 8 }}>
                {[0,1,2].map(i => <div key={i} style={{ width: 12, height: 12, borderRadius: 999, background: 'var(--cobalt)', animation: `dot-bounce 1.2s var(--ease-out) ${i*0.16}s infinite` }} />)}
              </div>
              <div style={{ marginTop: 8, fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 11, color: 'var(--ink-60)' }}>Q is checking…</div>
            </Card>
          )}
          {recState === 'result' && (
            <Card padding={14}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{
                  width: 56, height: 56, borderRadius: 999,
                  background: score >= 80 ? 'var(--mint-deep)' : 'var(--quack-yellow)',
                  color: score >= 80 ? '#fff' : 'var(--ink)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 18,
                  boxShadow: 'var(--shadow-card)', animation: 'pop-in 500ms var(--ease-bounce)',
                }}>{score}%</div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 16, color: 'var(--ink)' }}>
                    {score >= 90 ? 'Perfect!' : score >= 80 ? 'Nice tone!' : 'Almost!'}
                  </div>
                  <div style={{ fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 11, color: 'var(--ink-60)', marginTop: 2 }}>
                    {score >= 90 ? 'You sound just like Q.' : score >= 80 ? 'Tone is close.' : 'Round the vowel a bit more.'}
                  </div>
                </div>
                <button onClick={() => { setRecState('idle'); setScore(0); }} className="tap" style={{
                  background: 'transparent', border: 'none', color: 'var(--quack-orange)', cursor: 'pointer',
                  fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 12,
                }}>Retry</button>
              </div>
            </Card>
          )}
        </div>

        <CTA variant="ink" onClick={next} disabled={recState !== 'result'}>
          {idx + 1 < items.length ? 'Next word' : 'Finish mission'}
        </CTA>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// PARENT DASHBOARD — LANDSCAPE
// ─────────────────────────────────────────────────────────────
function ParentScreenLandscape({ state, onTab, onSnapPhoto, onResetProgress }) {
  const week = [3, 5, 8, 4, 7, 9, state.dailyProgress];
  const max = Math.max(...week, state.dailyGoal);
  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  const learnedItems = state.learned.map(id => VOCAB.find(v => v.id === id)).filter(Boolean);

  return (
    <div style={{
      width: '100%', height: '100%', background: 'var(--cream)',
      display: 'flex', flexDirection: 'row',
      paddingLeft: PAD_L - 8, paddingRight: PAD_R,
      animation: 'screen-in 320ms var(--ease-out)',
    }}>
      <div style={{ paddingTop: 14, paddingBottom: 14 }}>
        <TabRail active="parent" onChange={onTab} />
      </div>

      {/* Center column — header + chart + photo */}
      <div className="no-scrollbar" style={{
        flex: '1 1 0', padding: '14px 10px 14px 14px', display: 'flex', flexDirection: 'column', gap: 10,
        overflowY: 'auto', minWidth: 0,
      }}>
        <div>
          <Eyebrow size={10}>Parent dashboard</Eyebrow>
          <h1 style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 22, color: 'var(--ink)', margin: '2px 0 0' }}>{state.name}'s progress</h1>
        </div>

        {/* 3 stat cards */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
          <Card padding={10} style={{ textAlign: 'center' }}>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 22, color: 'var(--quack-orange)' }}>{state.dailyProgress}</div>
            <div style={{ fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 9, letterSpacing: '0.06em', textTransform: 'uppercase', color: 'var(--ink-60)', marginTop: 2 }}>Today</div>
          </Card>
          <Card padding={10} style={{ textAlign: 'center' }}>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 22, color: 'var(--cobalt)' }}>{state.streak}</div>
            <div style={{ fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 9, letterSpacing: '0.06em', textTransform: 'uppercase', color: 'var(--ink-60)', marginTop: 2 }}>Streak</div>
          </Card>
          <Card padding={10} style={{ textAlign: 'center' }}>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 22, color: 'var(--mint-deep)' }}>{state.learned.length}</div>
            <div style={{ fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 9, letterSpacing: '0.06em', textTransform: 'uppercase', color: 'var(--ink-60)', marginTop: 2 }}>Words</div>
          </Card>
        </div>

        {/* Week chart */}
        <Card padding={14}>
          <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 10 }}>
            <h3 style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 14, color: 'var(--ink)', margin: 0 }}>This week</h3>
            <span style={{ fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 10, color: 'var(--ink-60)' }}>Stars per day</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', height: 76, gap: 6 }}>
            {week.map((v, i) => {
              const isToday = i === 6;
              const h = (v / max) * 100;
              return (
                <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, height: '100%', justifyContent: 'flex-end' }}>
                  <div style={{
                    width: '100%', height: `${h}%`,
                    background: isToday ? 'var(--quack-orange)' : 'var(--ink-20)',
                    borderRadius: 6, minHeight: 4,
                    display: 'flex', alignItems: 'flex-start', justifyContent: 'center',
                    paddingTop: 2,
                    fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 9,
                    color: isToday ? '#fff' : 'var(--ink-60)',
                  }}>{v}</div>
                  <div style={{ fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 9, color: isToday ? 'var(--quack-orange)' : 'var(--ink-60)' }}>{days[i]}</div>
                </div>
              );
            })}
          </div>
        </Card>

        {/* Photo CTA */}
        <button onClick={onSnapPhoto} className="tap" style={{
          width: '100%', background: 'var(--ink)', color: '#fff',
          border: 'none', borderRadius: 18, padding: 12,
          boxShadow: 'var(--shadow-card)', textAlign: 'left',
          display: 'flex', alignItems: 'center', gap: 12, cursor: 'pointer',
        }}>
          <div style={{
            width: 42, height: 42, borderRadius: 12, background: 'var(--quack-orange)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
          }}><Icon name="photo" size={22} color="#fff" stroke={2} /></div>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 13 }}>Snap a room photo</div>
            <div style={{ fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 10, color: 'rgba(255,255,255,.7)', marginTop: 1 }}>Q makes a custom mission</div>
          </div>
          <Icon name="chevron" size={18} />
        </button>
      </div>

      {/* RIGHT column — vocab + edge + screentime + reset */}
      <div className="no-scrollbar" style={{
        width: 280, padding: '14px 14px 14px 10px', display: 'flex', flexDirection: 'column', gap: 10,
        overflowY: 'auto',
      }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
          <h3 style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 14, color: 'var(--ink)', margin: 0 }}>Vocabulary</h3>
          <span style={{ fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 10, color: 'var(--ink-60)' }}>{learnedItems.length} words</span>
        </div>

        <Card padding={4} style={{ maxHeight: 156, overflowY: 'auto' }}>
          {learnedItems.length === 0 ? (
            <div style={{ padding: 14, textAlign: 'center', fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 11, color: 'var(--ink-60)' }}>No words yet</div>
          ) : learnedItems.slice().reverse().map((item, i, arr) => (
            <div key={item.id} style={{
              display: 'flex', alignItems: 'center', gap: 10, padding: '6px 8px',
              borderBottom: i < arr.length - 1 ? '1px solid var(--ink-20)' : 'none',
            }}>
              <div style={{
                width: 30, height: 30, borderRadius: 9,
                background: TONE_BG[item.tone], color: TONE_FG[item.tone],
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 14,
              }}>{item.hanzi}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 12, color: 'var(--ink)' }}>{item.en}</div>
                <div style={{ fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 10, color: 'var(--ink-60)' }}>{item.pinyin}</div>
              </div>
              <Icon name="check" size={16} color="var(--mint-deep)" stroke={2.4} />
            </div>
          ))}
        </Card>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          <Card padding={10} style={{ background: '#0F1A30', color: '#fff' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 6 }}>
              <Icon name="shield" size={14} color="var(--mint)" stroke={2.2} />
              <Eyebrow flank={false} color="var(--mint)" size={8}>Edge</Eyebrow>
            </div>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 12 }}>Q‑Pod online</div>
            <div style={{ marginTop: 6, display: 'flex', alignItems: 'center', gap: 5 }}>
              <span style={{ width: 5, height: 5, borderRadius: 999, background: 'var(--mint)', animation: 'pulse 1.4s infinite' }} />
              <span style={{ fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 9, color: 'var(--mint)' }}>Connected</span>
            </div>
          </Card>
          <Card padding={10}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 6 }}>
              <Icon name="clock" size={14} color="var(--cobalt)" stroke={2.2} />
              <Eyebrow flank={false} color="var(--cobalt)" size={8}>Screen</Eyebrow>
            </div>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 12 }}>14 / 30</div>
            <div style={{ marginTop: 6 }}>
              <ProgressBar value={14} max={30} color="var(--cobalt)" track="var(--ink-20)" height={6} />
            </div>
          </Card>
        </div>

        <button onClick={onResetProgress} className="tap" style={{
          width: '100%', background: 'transparent',
          border: '2px solid var(--ink-20)', color: 'var(--ink-60)',
          borderRadius: 999, padding: '10px 14px',
          fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 11, cursor: 'pointer',
        }}>Reset progress</button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// SNAP PHOTO — LANDSCAPE
// ─────────────────────────────────────────────────────────────
function SnapPhotoLandscape({ onBack, onGenerate }) {
  const [phase, setPhase] = useStateL('compose');
  const [picked, setPicked] = useStateL(null);

  useEffectL(() => {
    if (phase === 'analyzing') {
      const t = setTimeout(() => setPhase('result'), 1800);
      return () => clearTimeout(t);
    }
  }, [phase]);

  const detected = ['cup', 'book', 'lamp', 'chair'];
  const detectedItems = detected.map(id => VOCAB.find(v => v.id === id)).filter(Boolean);

  return (
    <div style={{
      width: '100%', height: '100%', background: 'var(--cream)',
      display: 'flex', flexDirection: 'row',
      paddingLeft: PAD_L, paddingRight: PAD_R,
      animation: 'screen-in 320ms var(--ease-out)',
    }}>
      {/* LEFT — viewfinder */}
      <div style={{ flex: '1 1 0', padding: '14px 10px 14px 14px', display: 'flex', flexDirection: 'column' }}>
        <div className="grain" style={{
          flex: 1, background: 'var(--ink)', borderRadius: 22,
          position: 'relative', overflow: 'hidden',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          {phase === 'compose' && (
            <>
              {[
                { top: 14, left: 14 }, { top: 14, right: 14 },
                { bottom: 14, left: 14 }, { bottom: 14, right: 14 },
              ].map((c, i) => (
                <div key={i} style={{
                  position: 'absolute', ...c, width: 28, height: 28,
                  borderTop: c.top != null ? '3px solid #fff' : 'none',
                  borderBottom: c.bottom != null ? '3px solid #fff' : 'none',
                  borderLeft: c.left != null ? '3px solid #fff' : 'none',
                  borderRight: c.right != null ? '3px solid #fff' : 'none',
                  opacity: .8,
                }} />
              ))}
              <div style={{
                fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 12, color: 'rgba(255,255,255,.7)', textAlign: 'center',
              }}>Frame the room — point Q at it</div>
            </>
          )}
          {phase === 'analyzing' && (
            <div style={{ textAlign: 'center', color: '#fff' }}>
              <div style={{ display: 'inline-flex', gap: 8 }}>
                {[0,1,2].map(i => <div key={i} style={{ width: 14, height: 14, borderRadius: 999, background: 'var(--quack-orange)', animation: `dot-bounce 1.2s var(--ease-out) ${i*0.16}s infinite` }} />)}
              </div>
              <div style={{ marginTop: 12, fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 12 }}>Q is looking at the photo…</div>
            </div>
          )}
          {phase === 'result' && (
            <div style={{ textAlign: 'center', color: '#fff', padding: 20 }}>
              <Mascot state="celebrating" size={100} />
              <div style={{ marginTop: 8, fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 20 }}>Found {detectedItems.length} things</div>
              <div style={{ marginTop: 4, fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 12, opacity: .7 }}>Pick one to make today's mission</div>
            </div>
          )}
        </div>
      </div>

      {/* RIGHT — controls */}
      <div style={{ width: 320, padding: '14px 14px 14px 10px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <BackBtn onClick={onBack} />
          <div>
            <Eyebrow size={10}>Photo → Mission</Eyebrow>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 18, color: 'var(--ink)', lineHeight: '20px', marginTop: 2 }}>
              {phase === 'compose' && 'Snap a room'}
              {phase === 'analyzing' && 'Q is looking…'}
              {phase === 'result' && 'Pick a mission'}
            </div>
          </div>
        </div>

        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 8, minHeight: 0, overflowY: 'auto' }} className="no-scrollbar">
          {phase === 'result' && detectedItems.map(it => (
            <button key={it.id} onClick={() => setPicked(it.id)} className="tap" style={{
              display: 'flex', alignItems: 'center', gap: 10, padding: 10,
              background: picked === it.id ? 'var(--quack-orange)' : 'var(--paper)',
              color: picked === it.id ? '#fff' : 'var(--ink)',
              border: 'none', borderRadius: 14, cursor: 'pointer', textAlign: 'left',
              boxShadow: 'var(--shadow-card)',
            }}>
              <div style={{
                width: 36, height: 36, borderRadius: 10,
                background: picked === it.id ? 'rgba(255,255,255,.2)' : TONE_BG[it.tone],
                color: picked === it.id ? '#fff' : TONE_FG[it.tone],
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 16,
              }}>{it.hanzi}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 13 }}>Find the {it.en.toLowerCase()}</div>
                <div style={{ fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 10, opacity: .7 }}>{it.pinyin}</div>
              </div>
              {picked === it.id && <Icon name="check" size={18} color="#fff" stroke={2.4} />}
            </button>
          ))}
        </div>

        <div>
          {phase === 'compose' && (
            <CTA variant="orange" onClick={() => setPhase('analyzing')}>Take photo</CTA>
          )}
          {phase === 'analyzing' && <CTA variant="ghost" disabled>Analyzing…</CTA>}
          {phase === 'result' && (
            <CTA variant="ink" disabled={!picked} onClick={() => onGenerate(picked)}>
              {picked ? 'Set as today\'s mission' : 'Pick a mission'}
            </CTA>
          )}
        </div>
      </div>
    </div>
  );
}

Object.assign(window, {
  CameraMissionLandscape,
  SpeakMissionLandscape,
  ParentScreenLandscape,
  SnapPhotoLandscape,
  TabRail,
});
