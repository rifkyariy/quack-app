/* global React, Eyebrow, Sparkles, CTA, BackBtn, Icon, Mascot, ProgressBar, Confetti, StickerTile, ObjectArt, Pill, Card, VOCAB, TONE_BG, TONE_FG */
const { useState: useStateM, useEffect: useEffectM, useRef: useRefM, useMemo: useMemoM } = React;

// ─────────────────────────────────────────────────────────────
// Top header used in mission screens (shared chrome)
// ─────────────────────────────────────────────────────────────
function MissionHeader({ onBack, label, progress = 0, total = 1, color = 'var(--quack-orange)' }) {
  return (
    <div style={{ padding: '8px 24px 0', display: 'flex', alignItems: 'center', gap: 12 }}>
      <BackBtn onClick={onBack} />
      <div style={{ flex: 1 }}>
        <ProgressBar value={progress} max={total} color={color} track="var(--ink-20)" height={10} />
      </div>
      <div style={{
        background: 'var(--paper)', padding: '8px 12px', borderRadius: 999,
        display: 'flex', alignItems: 'center', gap: 6, boxShadow: 'var(--shadow-card)',
      }}>
        <Icon name="heart" size={14} color="var(--rose)" />
        <span style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 14, color: 'var(--ink)' }}>3</span>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 1. CAMERA SCAN MISSION
//    Phases: aiming → detected → say-it → got-it
// ─────────────────────────────────────────────────────────────
function CameraMission({ target, onBack, onComplete, mascotState, setMascotState }) {
  const item = VOCAB.find(v => v.id === target) || VOCAB[0];
  const [phase, setPhase] = useStateM('aiming'); // aiming → detected → say → got
  const [scanProgress, setScanProgress] = useStateM(0);
  const [tick, setTick] = useStateM(0);

  // Simulated detection sweep
  useEffectM(() => {
    if (phase !== 'aiming') return;
    const id = setInterval(() => {
      setScanProgress(p => {
        if (p >= 1) {
          clearInterval(id);
          setTimeout(() => setPhase('detected'), 200);
          return 1;
        }
        return p + 0.04;
      });
    }, 80);
    return () => clearInterval(id);
  }, [phase]);

  // After detect, mascot speaks the word
  useEffectM(() => {
    if (phase === 'detected') {
      setMascotState && setMascotState('speaking');
      const t = setTimeout(() => setPhase('say'), 1600);
      return () => clearTimeout(t);
    } else if (phase === 'say') {
      setMascotState && setMascotState('listening');
    }
  }, [phase]);

  // Animate waveform during listen
  useEffectM(() => {
    if (phase !== 'say') return;
    const id = setInterval(() => setTick(t => t + 1), 110);
    return () => clearInterval(id);
  }, [phase]);

  const phaseLabel = {
    aiming: 'Aim at it', detected: 'Got it!',
    say: 'Say it back', got: 'Nice!',
  }[phase];

  return (
    <div style={{
      width: '100%', height: '100%', background: 'var(--cream)',
      display: 'flex', flexDirection: 'column', paddingTop: 56,
      animation: 'screen-in 320ms var(--ease-out)',
    }}>
      <MissionHeader onBack={onBack} progress={['aiming','detected','say','got'].indexOf(phase)} total={4} />
      <div style={{ padding: '16px 24px 0', textAlign: 'center' }}>
        <Eyebrow>Camera scan</Eyebrow>
        <h1 style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 26, color: 'var(--ink)', margin: '4px 0 4px' }}>{phaseLabel}</h1>
      </div>

      {/* Camera viewport */}
      <div style={{ padding: '14px 24px 0', flex: 1, display: 'flex', flexDirection: 'column' }}>
        <div className="grain" style={{
          flex: 1, background: 'var(--ink)', borderRadius: 28,
          position: 'relative', overflow: 'hidden', minHeight: 280,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          {/* Corner brackets */}
          {phase === 'aiming' && [
            { top: 14, left: 14 }, { top: 14, right: 14 },
            { bottom: 14, left: 14 }, { bottom: 14, right: 14 },
          ].map((c, i) => (
            <div key={i} style={{
              position: 'absolute', ...c, width: 32, height: 32,
              borderTop: c.top != null ? '3px solid var(--quack-orange)' : 'none',
              borderBottom: c.bottom != null ? '3px solid var(--quack-orange)' : 'none',
              borderLeft: c.left != null ? '3px solid var(--quack-orange)' : 'none',
              borderRight: c.right != null ? '3px solid var(--quack-orange)' : 'none',
              transition: 'all 220ms var(--ease-out)',
            }} />
          ))}

          {/* Scan line */}
          {phase === 'aiming' && (
            <div style={{
              position: 'absolute', left: 14, right: 14,
              top: `${14 + scanProgress * 232}px`,
              height: 2, background: 'var(--quack-orange)',
              boxShadow: '0 0 12px var(--quack-orange)',
            }} />
          )}

          {/* Object render */}
          <div style={{
            opacity: phase === 'aiming' ? 0.7 + scanProgress * 0.3 : 1,
            transform: phase === 'detected' ? 'scale(1.1)' : 'scale(1)',
            transition: 'transform 420ms var(--ease-bounce), opacity 220ms',
          }}>
            <ObjectArt id={item.id} size={180} />
          </div>

          {/* Detection bubble */}
          {(phase === 'detected' || phase === 'say' || phase === 'got') && (
            <div style={{
              position: 'absolute', top: 28, left: 28,
              background: 'rgba(0,0,0,.5)', backdropFilter: 'blur(8px)',
              padding: '8px 14px', borderRadius: 999,
              fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 11,
              letterSpacing: '0.08em', textTransform: 'uppercase',
              color: '#fff', display: 'flex', alignItems: 'center', gap: 6,
              animation: 'screen-in 420ms var(--ease-bounce)',
            }}>
              <span style={{ width: 8, height: 8, borderRadius: 999, background: 'var(--mint)' }} />
              Detected: {item.en}
            </div>
          )}

          {/* Aim instructions */}
          {phase === 'aiming' && (
            <div style={{
              position: 'absolute', bottom: 18, left: 18, right: 18,
              textAlign: 'center', color: '#fff',
              fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 12,
              opacity: .8,
            }}>Hold steady — Q is looking…</div>
          )}
        </div>
      </div>

      {/* Q's word card */}
      {phase === 'detected' && (
        <div style={{ padding: '16px 24px 0', animation: 'screen-in 320ms var(--ease-bounce)' }}>
          <Card padding={16} style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <Mascot state="speaking" size={64} />
            <div style={{ flex: 1 }}>
              <Eyebrow flank={false} size={11}>Q says</Eyebrow>
              <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 28, color: 'var(--ink)', marginTop: 2, lineHeight: 1 }}>
                {item.hanzi} <span style={{ fontFamily: 'var(--font-body)', fontSize: 14, color: 'var(--ink-60)', fontWeight: 700 }}>{item.pinyin}</span>
              </div>
            </div>
            <button className="tap" style={{
              width: 44, height: 44, borderRadius: 999, border: 'none',
              background: 'var(--quack-orange)', color: '#fff',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: 'var(--shadow-card)',
            }}><Icon name="speaker" size={20} /></button>
          </Card>
        </div>
      )}

      {/* Listen + waveform */}
      {phase === 'say' && (
        <div style={{ padding: '16px 24px 0' }}>
          <Card padding={16}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
              <Pill icon color="var(--quack-orange)">Q is listening</Pill>
              <span style={{ fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 12, color: 'var(--ink-60)' }}>Now you say it</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
              <div style={{ flex: 1, display: 'flex', gap: 4, alignItems: 'center', height: 56 }}>
                {Array.from({ length: 26 }).map((_, i) => {
                  const phase = (i + tick) * 0.6;
                  const h = 10 + Math.abs(Math.sin(phase) * 28) + (i % 4) * 3;
                  return <div key={i} style={{
                    width: 4, height: h, borderRadius: 999,
                    background: 'var(--quack-orange)',
                    opacity: 0.5 + (i % 4) * 0.13,
                    transition: 'height 220ms var(--ease-out)',
                  }} />;
                })}
              </div>
              <button onClick={() => { setMascotState && setMascotState('celebrating'); setPhase('got'); setTimeout(onComplete, 900); }} className="tap" style={{
                width: 64, height: 64, borderRadius: 999, border: 'none',
                background: 'var(--quack-orange)', color: '#fff',
                boxShadow: 'var(--shadow-pop)', display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}><Icon name="mic" size={28} stroke={2} /></button>
            </div>
            <div style={{ marginTop: 14, fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 13, color: 'var(--ink-60)', textAlign: 'center' }}>
              Tap mic, say <b style={{ color: 'var(--quack-orange)', fontFamily: 'var(--font-display)', fontSize: 16 }}>{item.hanzi}</b>
            </div>
          </Card>
        </div>
      )}

      <div style={{ padding: '20px 24px 28px' }}>
        {phase === 'aiming' && <CTA variant="ghost" disabled>Scanning…</CTA>}
        {phase === 'detected' && <CTA variant="ink" onClick={() => setPhase('say')}>Got it — I'll try saying it</CTA>}
        {phase === 'say' && <CTA variant="ghost" disabled>Tap the mic to speak</CTA>}
        {phase === 'got' && <CTA variant="orange" disabled>Nice!</CTA>}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 2. SPEAK-IT-BACK MISSION
//    A series of words. Tap mic, fake mic level, get scored.
// ─────────────────────────────────────────────────────────────
function SpeakMission({ targetCategory = 'fruits', onBack, onComplete, setMascotState, addLearned }) {
  const items = useMemoM(() => VOCAB.filter(v => v.cat === targetCategory).slice(0, 3), [targetCategory]);
  const [idx, setIdx] = useStateM(0);
  const [recState, setRecState] = useStateM('idle'); // idle | recording | scoring | result
  const [level, setLevel] = useStateM(0);
  const [score, setScore] = useStateM(0);
  const item = items[idx];

  // Recording mic level wobble
  useEffectM(() => {
    if (recState !== 'recording') { setLevel(0); return; }
    let t = 0; const id = setInterval(() => { t += 1; setLevel(0.3 + Math.abs(Math.sin(t * 0.4)) * 0.7); }, 80);
    return () => clearInterval(id);
  }, [recState]);

  const startRec = () => { setMascotState && setMascotState('listening'); setRecState('recording'); };
  const stopRec = () => {
    setRecState('scoring');
    setTimeout(() => {
      // Random-ish score 70–98
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
      display: 'flex', flexDirection: 'column', paddingTop: 56,
      animation: 'screen-in 320ms var(--ease-out)',
    }}>
      <MissionHeader onBack={onBack} progress={idx + (recState === 'result' ? 1 : 0)} total={items.length} color="var(--cobalt)" />
      <div style={{ padding: '16px 24px 0', textAlign: 'center' }}>
        <Eyebrow color="var(--cobalt)">Say it back</Eyebrow>
        <h1 style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 26, color: 'var(--ink)', margin: '4px 0 0' }}>Word {idx + 1} of {items.length}</h1>
      </div>

      {/* Hero word card */}
      <div style={{ padding: '20px 24px 0', flex: 1, display: 'flex', flexDirection: 'column' }}>
        <div className="grain" style={{
          flex: 1, background: TONE_BG[item.tone], color: TONE_FG[item.tone],
          borderRadius: 28, padding: 22, position: 'relative', overflow: 'hidden',
          display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
          textAlign: 'center', minHeight: 240,
        }}>
          <Sparkles count={5} opacity={.55} animate />
          <div style={{ position: 'relative', zIndex: 2 }}>
            <ObjectArt id={item.id} size={120} />
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 56, lineHeight: 1, marginTop: 4 }}>{item.hanzi}</div>
            <div style={{ fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 18, marginTop: 4, opacity: .9 }}>{item.pinyin}</div>
            <div style={{ fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 14, marginTop: 4, opacity: .8 }}>{item.en}</div>
          </div>
        </div>
      </div>

      {/* Mic / level meter / result */}
      <div style={{ padding: '20px 24px 0' }}>
        {recState === 'idle' && (
          <Card padding={16} style={{ textAlign: 'center' }}>
            <div style={{ fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 13, color: 'var(--ink-60)' }}>Tap and hold the mic, then say it</div>
            <button onMouseDown={startRec} onMouseUp={stopRec} onTouchStart={startRec} onTouchEnd={stopRec}
              className="tap" style={{
                marginTop: 12, width: 92, height: 92, borderRadius: 999, border: 'none',
                background: 'var(--quack-orange)', color: '#fff',
                boxShadow: 'var(--shadow-pop)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
              }}><Icon name="mic" size={40} stroke={2} /></button>
          </Card>
        )}
        {recState === 'recording' && (
          <Card padding={16}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
              <Pill icon color="var(--quack-orange)">Listening</Pill>
            </div>
            <div style={{ display: 'flex', gap: 5, alignItems: 'center', height: 56, justifyContent: 'center' }}>
              {Array.from({ length: 24 }).map((_, i) => {
                const seed = (Math.sin(i * 1.3) + 1) / 2;
                const h = 8 + level * (28 + seed * 28);
                return <div key={i} style={{ width: 4, height: h, borderRadius: 999, background: 'var(--quack-orange)', transition: 'height 80ms linear' }} />;
              })}
            </div>
            <div style={{ marginTop: 12, fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 13, color: 'var(--ink-60)', textAlign: 'center' }}>Release when you're done</div>
          </Card>
        )}
        {recState === 'scoring' && (
          <Card padding={16} style={{ textAlign: 'center' }}>
            <div style={{ display: 'inline-flex', gap: 8 }}>
              {[0,1,2].map(i => <div key={i} style={{ width: 14, height: 14, borderRadius: 999, background: 'var(--cobalt)', animation: `dot-bounce 1.2s var(--ease-out) ${i*0.16}s infinite` }} />)}
            </div>
            <div style={{ marginTop: 10, fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 13, color: 'var(--ink-60)' }}>Q is checking your pronunciation…</div>
          </Card>
        )}
        {recState === 'result' && (
          <Card padding={16}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
              <div style={{
                width: 64, height: 64, borderRadius: 999,
                background: score >= 80 ? 'var(--mint-deep)' : 'var(--quack-yellow)',
                color: score >= 80 ? '#fff' : 'var(--ink)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 22,
                boxShadow: 'var(--shadow-card)',
                animation: 'pop-in 500ms var(--ease-bounce)',
              }}>{score}%</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 18, color: 'var(--ink)' }}>
                  {score >= 90 ? 'Perfect!' : score >= 80 ? 'Nice tone!' : 'Almost!'}
                </div>
                <div style={{ fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 12, color: 'var(--ink-60)', marginTop: 2 }}>
                  {score >= 90 ? 'You sound just like Q.' : score >= 80 ? 'Tone is close. Try one more time?' : 'Listen again — round the vowel a bit more.'}
                </div>
              </div>
              <button onClick={() => { setRecState('idle'); setScore(0); }} className="tap" style={{
                background: 'transparent', border: 'none', color: 'var(--quack-orange)', cursor: 'pointer',
                fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 13,
              }}>Retry</button>
            </div>
          </Card>
        )}
      </div>

      <div style={{ padding: '20px 24px 28px' }}>
        <CTA variant="ink" onClick={next} disabled={recState !== 'result'}>
          {idx + 1 < items.length ? 'Next word' : 'Finish mission'}
        </CTA>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 3. PICTURE-MATCH MISSION
//    Show hanzi + pinyin, kid taps the matching picture (4 options).
// ─────────────────────────────────────────────────────────────
function MatchMission({ targetCategory = 'animals', onBack, onComplete, setMascotState, addLearned }) {
  const all = VOCAB.filter(v => v.cat === targetCategory);
  const [order] = useStateM(() => shuffle(all).slice(0, 3));
  const [idx, setIdx] = useStateM(0);
  const [picked, setPicked] = useStateM(null);
  const [revealed, setRevealed] = useStateM(false);

  const word = order[idx];
  const choices = useMemoM(() => {
    const others = shuffle(VOCAB.filter(v => v.id !== word.id)).slice(0, 3);
    return shuffle([word, ...others]);
  }, [word.id]);

  const choose = (id) => {
    if (revealed) return;
    setPicked(id); setRevealed(true);
    if (id === word.id) {
      setMascotState && setMascotState('celebrating');
      addLearned && addLearned(word.id);
    } else {
      setMascotState && setMascotState('idle');
    }
  };

  const next = () => {
    if (idx + 1 < order.length) { setIdx(idx + 1); setPicked(null); setRevealed(false); setMascotState && setMascotState('idle'); }
    else onComplete(word.id);
  };

  return (
    <div style={{
      width: '100%', height: '100%', background: 'var(--cream)',
      display: 'flex', flexDirection: 'column', paddingTop: 56,
      animation: 'screen-in 320ms var(--ease-out)',
    }}>
      <MissionHeader onBack={onBack} progress={idx + (revealed ? 1 : 0)} total={order.length} color="var(--rose)" />
      <div style={{ padding: '16px 24px 0', textAlign: 'center' }}>
        <Eyebrow color="var(--rose)">Match the picture</Eyebrow>
        <h1 style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 26, color: 'var(--ink)', margin: '4px 0 0' }}>Which one is this?</h1>
      </div>

      {/* Word prompt card */}
      <div style={{ padding: '14px 24px 0' }}>
        <Card padding={20} style={{ textAlign: 'center', background: 'var(--ink)', color: '#fff' }}>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 56, lineHeight: 1 }}>{word.hanzi}</div>
          <div style={{ fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 16, marginTop: 4, opacity: .8 }}>{word.pinyin}</div>
        </Card>
      </div>

      {/* Choice grid */}
      <div style={{ padding: '14px 24px 0', flex: 1, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        {choices.map((c) => {
          const isAnswer = c.id === word.id;
          const isPicked = picked === c.id;
          let ring = 'transparent';
          let bgOverlay = 'transparent';
          if (revealed) {
            if (isAnswer) { ring = 'var(--mint-deep)'; bgOverlay = 'rgba(95,181,148,0.15)'; }
            else if (isPicked) { ring = 'var(--quack-orange-deep)'; bgOverlay = 'rgba(229,78,27,0.15)'; }
          }
          return (
            <button key={c.id} onClick={() => choose(c.id)} className="tap grain" style={{
              background: TONE_BG[c.tone], color: TONE_FG[c.tone],
              border: 'none', borderRadius: 22, padding: 14,
              boxShadow: 'var(--shadow-card)',
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
              minHeight: 130, position: 'relative', overflow: 'hidden',
              outline: ring !== 'transparent' ? `4px solid ${ring}` : 'none',
              outlineOffset: -4,
            }}>
              <div style={{ position: 'absolute', inset: 0, background: bgOverlay, pointerEvents: 'none' }} />
              <ObjectArt id={c.id} size={80} />
              <div style={{ fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 13 }}>{c.en}</div>
              {revealed && isAnswer && (
                <div style={{
                  position: 'absolute', top: 8, right: 8,
                  width: 26, height: 26, borderRadius: 999,
                  background: 'var(--mint-deep)', color: '#fff',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  animation: 'pop-in 320ms var(--ease-bounce)',
                }}><Icon name="check" size={16} stroke={3} /></div>
              )}
              {revealed && !isAnswer && isPicked && (
                <div style={{
                  position: 'absolute', top: 8, right: 8,
                  width: 26, height: 26, borderRadius: 999,
                  background: 'var(--quack-orange-deep)', color: '#fff',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}><Icon name="close" size={16} stroke={3} /></div>
              )}
            </button>
          );
        })}
      </div>

      <div style={{ padding: '20px 24px 28px' }}>
        <CTA variant="ink" onClick={next} disabled={!revealed}>
          {idx + 1 < order.length ? 'Next' : 'Finish mission'}
        </CTA>
      </div>
    </div>
  );
}

function shuffle(arr) {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

// ─────────────────────────────────────────────────────────────
// 4. STORY MISSION
//    Q narrates a 4-page story; final page is a tap-the-word quiz.
// ─────────────────────────────────────────────────────────────
const STORY = {
  title: 'The hungry cat',
  pages: [
    {
      bg: 'var(--cobalt)', color: '#fff',
      vocab: 'cat',
      narrate: 'Once there was a hungry 猫 (māo). She wanted breakfast.',
      pieces: [{ k: 'cat', tone: 'yellow' }],
    },
    {
      bg: 'var(--mint)', color: 'var(--ink)',
      vocab: 'fish',
      narrate: 'In the kitchen she found a 鱼 (yú). "Mmm!" said the cat.',
      pieces: [{ k: 'fish', tone: 'mint' }],
    },
    {
      bg: 'var(--rose)', color: 'var(--ink)',
      vocab: 'mom',
      narrate: 'But 妈妈 (māma) said, "Wait, that fish is for dinner!"',
      pieces: [{ k: 'mom', tone: 'rose' }],
    },
    {
      bg: 'var(--quack-yellow)', color: 'var(--ink)',
      vocab: 'rice',
      narrate: 'So mom gave her warm 米饭 (mǐfàn) instead. Cat was happy.',
      pieces: [{ k: 'rice', tone: 'cream' }],
    },
  ],
};

function StoryMission({ onBack, onComplete, setMascotState, addLearned }) {
  const [page, setPage] = useStateM(0);
  const [phase, setPhase] = useStateM('reading'); // reading | quiz | done
  const [picked, setPicked] = useStateM(null);
  const [reveal, setReveal] = useStateM(false);

  useEffectM(() => {
    setMascotState && setMascotState('speaking');
  }, [page]);

  const current = STORY.pages[page];
  const totalPages = STORY.pages.length;

  const next = () => {
    if (page + 1 < totalPages) setPage(page + 1);
    else { setPhase('quiz'); setMascotState && setMascotState('idle'); }
  };

  const quizWord = STORY.pages[1]; // ask about fish
  const quizItem = VOCAB.find(v => v.id === quizWord.vocab);
  const quizChoices = useMemoM(() => {
    const others = shuffle(VOCAB.filter(v => v.id !== quizItem.id)).slice(0, 2);
    return shuffle([quizItem, ...others]);
  }, []);

  const finish = () => {
    STORY.pages.forEach(p => addLearned && addLearned(p.vocab));
    onComplete(quizItem.id);
  };

  if (phase === 'quiz') {
    return (
      <div style={{
        width: '100%', height: '100%', background: 'var(--cream)',
        display: 'flex', flexDirection: 'column', paddingTop: 56,
        animation: 'screen-in 320ms var(--ease-out)',
      }}>
        <MissionHeader onBack={onBack} progress={totalPages} total={totalPages + 1} color="var(--mint-deep)" />
        <div style={{ padding: '16px 24px 0', textAlign: 'center' }}>
          <Eyebrow color="var(--mint-deep)">Did you spot it?</Eyebrow>
          <h1 style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 26, color: 'var(--ink)', margin: '4px 0 0' }}>What was in the kitchen?</h1>
        </div>
        <div style={{ padding: '20px 24px 0', flex: 1, display: 'flex', flexDirection: 'column', gap: 10 }}>
          {quizChoices.map(c => {
            const isAns = c.id === quizItem.id;
            const isPicked = picked === c.id;
            const showCorrect = reveal && isAns;
            const showWrong = reveal && isPicked && !isAns;
            return (
              <button key={c.id} onClick={() => { if (!reveal) { setPicked(c.id); setReveal(true); if (c.id === quizItem.id) setMascotState && setMascotState('celebrating'); } }}
                className="tap" style={{
                  background: showCorrect ? 'var(--mint-deep)' : showWrong ? 'var(--quack-orange-deep)' : TONE_BG[c.tone],
                  color: showCorrect || showWrong ? '#fff' : TONE_FG[c.tone],
                  border: 'none', borderRadius: 22, padding: 16,
                  boxShadow: 'var(--shadow-card)',
                  display: 'flex', alignItems: 'center', gap: 14,
                  textAlign: 'left',
                }}>
                <ObjectArt id={c.id} size={56} />
                <div style={{ flex: 1 }}>
                  <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 22 }}>{c.hanzi}</div>
                  <div style={{ fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 13, opacity: .8 }}>{c.pinyin} · {c.en}</div>
                </div>
                {showCorrect && <Icon name="check" size={22} stroke={3} />}
                {showWrong && <Icon name="close" size={22} stroke={3} />}
              </button>
            );
          })}
        </div>
        <div style={{ padding: '20px 24px 28px' }}>
          <CTA variant="ink" onClick={finish} disabled={!reveal}>Finish story</CTA>
        </div>
      </div>
    );
  }

  // Reading
  return (
    <div style={{
      width: '100%', height: '100%', background: current.bg,
      display: 'flex', flexDirection: 'column', paddingTop: 56,
      animation: 'screen-in 320ms var(--ease-out)',
      position: 'relative', overflow: 'hidden',
    }}>
      <Sparkles count={5} color={current.color} opacity={.4} />
      <div style={{ padding: '8px 24px 0', display: 'flex', alignItems: 'center', gap: 12, position: 'relative', zIndex: 2 }}>
        <BackBtn onClick={onBack} dark />
        <div style={{ flex: 1, display: 'flex', gap: 6 }}>
          {STORY.pages.map((_, i) => (
            <div key={i} style={{
              flex: 1, height: 4, borderRadius: 999,
              background: i <= page ? current.color : 'rgba(0,0,0,.15)',
            }} />
          ))}
        </div>
      </div>

      <div style={{ padding: '20px 24px 0', position: 'relative', zIndex: 2, color: current.color, textAlign: 'center' }}>
        <Eyebrow flank={false} color={current.color} size={11}>Chapter {page + 1} of {totalPages}</Eyebrow>
        <h2 style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 22, margin: '4px 0 0' }}>{STORY.title}</h2>
      </div>

      <div style={{ padding: '20px 24px 0', flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column', position: 'relative', zIndex: 2 }}>
        <ObjectArt id={current.vocab} size={170} />
      </div>

      {/* Q narration card */}
      <div style={{ padding: '0 24px', position: 'relative', zIndex: 2 }}>
        <div style={{
          background: 'var(--paper)', borderRadius: 22, padding: 16,
          boxShadow: 'var(--shadow-pop)',
          display: 'flex', alignItems: 'flex-start', gap: 12,
          animation: 'screen-in 320ms var(--ease-bounce)',
        }} key={page}>
          <Mascot state="speaking" size={56} />
          <div style={{ flex: 1, paddingTop: 4 }}>
            <Eyebrow flank={false} size={10}>Q reads</Eyebrow>
            <div style={{
              fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 15, lineHeight: '22px',
              color: 'var(--ink)', marginTop: 4,
            }}>{current.narrate}</div>
          </div>
          <button className="tap" style={{
            width: 36, height: 36, borderRadius: 999, border: 'none',
            background: 'var(--quack-orange)', color: '#fff', flexShrink: 0,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}><Icon name="speaker" size={18} /></button>
        </div>
      </div>

      <div style={{ padding: '20px 24px 28px', position: 'relative', zIndex: 2 }}>
        <CTA variant="ink" onClick={next}>
          {page + 1 < totalPages ? 'Next page' : 'Time for a quiz'}
        </CTA>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// COMPLETION SCREEN — confetti, mascot, sticker earned
// ─────────────────────────────────────────────────────────────
function CompleteScreen({ earnedItem, name = 'Agent', onHome, mascotState }) {
  return (
    <div style={{
      width: '100%', height: '100%', background: 'var(--mint)',
      display: 'flex', flexDirection: 'column', position: 'relative', overflow: 'hidden',
      paddingTop: 70, animation: 'screen-in 320ms var(--ease-out)',
    }}>
      <Confetti count={30} />
      <Sparkles color="#fff" count={8} opacity={.85} animate />
      <div style={{
        flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
        padding: '0 24px', textAlign: 'center', position: 'relative', zIndex: 2,
      }}>
        <Mascot state={mascotState || 'celebrating'} size={170} />
        <div style={{ marginTop: 18 }}><Eyebrow color="var(--ink)">Mission complete</Eyebrow></div>
        <h1 style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 36, lineHeight: '42px', color: 'var(--ink)', margin: '6px 0 6px' }}>Nice one, {name}!</h1>
        {earnedItem && (
          <p style={{ fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 16, lineHeight: '22px', color: 'var(--ink)', maxWidth: 280, margin: 0 }}>
            You learned <b style={{ fontFamily: 'var(--font-display)', fontSize: 20 }}>{earnedItem.hanzi}</b> — sticker earned.
          </p>
        )}

        {/* Sticker reveal */}
        {earnedItem && (
          <div style={{ marginTop: 24, width: 140, animation: 'pop-in 700ms var(--ease-bounce) 200ms both' }}>
            <StickerTile item={earnedItem} size="lg" justEarned />
          </div>
        )}

        {/* Stars */}
        <div style={{ display: 'flex', gap: 10, marginTop: 22 }}>
          {[1, 2, 3].map(i => (
            <div key={i} style={{
              width: 48, height: 48, borderRadius: 999, background: 'var(--quack-yellow)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: 'var(--shadow-card)',
              animation: `pop-in 500ms var(--ease-bounce) ${0.4 + i * 0.12}s both`,
            }}><Icon name="star" size={26} color="var(--quack-orange-deep)" /></div>
          ))}
        </div>
      </div>
      <div style={{ padding: '0 24px 32px', position: 'relative', zIndex: 2, display: 'flex', gap: 10 }}>
        <CTA variant="ink" onClick={onHome}>Back home</CTA>
      </div>
    </div>
  );
}

Object.assign(window, { CameraMission, SpeakMission, MatchMission, StoryMission, CompleteScreen, MissionHeader });
