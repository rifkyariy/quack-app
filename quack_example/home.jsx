/* global React, Eyebrow, Sparkles, CTA, BackBtn, Icon, Mascot, ProgressBar, StickerTile, ObjectArt, Pill, TabBar, Card, VOCAB, CATEGORIES, TONE_BG, TONE_FG */
const { useState: useStateH, useEffect: useEffectH, useMemo: useMemoH } = React;

// ─────────────────────────────────────────────────────────────
// HOME — daily mission card + stats + recent words
// ─────────────────────────────────────────────────────────────
function HomeScreen({ state, onMission, onTab, mascotState, onSkipTutorial, onResetTutorial }) {
  const { name, streak, learned, todayMission, dailyGoal, dailyProgress } = state;
  const recentLearned = learned.slice(-4).reverse();
  const todayWord = VOCAB.find(v => v.id === todayMission.target);

  return (
    <div className="no-scrollbar" style={{
      width: '100%', height: '100%', background: 'var(--cream)',
      display: 'flex', flexDirection: 'column', paddingTop: 64, paddingBottom: 0,
      overflowY: 'auto', position: 'relative', animation: 'screen-in 320ms var(--ease-out)',
    }}>
      {/* Greeting header */}
      <div style={{ padding: '16px 24px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{
            width: 44, height: 44, borderRadius: 14,
            background: 'var(--quack-orange)', color: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 22,
            boxShadow: 'var(--shadow-card)',
          }}>{(name || 'A')[0].toUpperCase()}</div>
          <div>
            <div style={{ fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 11, letterSpacing: '0.12em', textTransform: 'uppercase', color: 'var(--ink-60)' }}>Welcome back</div>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 22, color: 'var(--ink)', lineHeight: '24px' }}>Hey, {name}</div>
          </div>
        </div>
        <div className="tap" style={{
          background: 'var(--paper)', padding: '8px 12px', borderRadius: 999,
          display: 'flex', alignItems: 'center', gap: 6, boxShadow: 'var(--shadow-card)',
        }}>
          <Icon name="fire" size={16} color="var(--quack-orange-deep)" />
          <span style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 16, color: 'var(--ink)' }}>{streak}</span>
        </div>
      </div>

      {/* Daily goal ring */}
      <div style={{ padding: '14px 24px 0' }}>
        <div style={{ background: 'var(--paper)', borderRadius: 22, padding: 14, boxShadow: 'var(--shadow-card)', display: 'flex', alignItems: 'center', gap: 14 }}>
          <DailyRing value={dailyProgress} max={dailyGoal} />
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 18, color: 'var(--ink)' }}>{dailyProgress} / {dailyGoal} stars today</div>
            <div style={{ fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 12, color: 'var(--ink-60)', marginTop: 2 }}>
              {dailyProgress >= dailyGoal ? 'Goal smashed! Keep going for bonus stickers.' : 'Finish your mission to hit today\'s goal.'}
            </div>
          </div>
        </div>
      </div>

      {/* Today's mission hero */}
      <div style={{ padding: '14px 24px 0' }}>
        <button onClick={onMission} className="tap grain" style={{
          width: '100%', background: 'var(--quack-orange)', border: 'none', borderRadius: 28,
          padding: 22, boxShadow: 'var(--shadow-pop)', cursor: 'pointer',
          color: '#fff', textAlign: 'left', position: 'relative', overflow: 'hidden', minHeight: 220,
        }}>
          <Sparkles count={6} opacity={.6} animate />
          <div style={{ position: 'relative', zIndex: 2, display: 'flex', flexDirection: 'column', height: '100%' }}>
            <Eyebrow color="var(--quack-yellow)">Today's mission</Eyebrow>
            <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 10, marginTop: 8 }}>
              <h2 style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 26, lineHeight: '30px', margin: 0, color: '#fff' }}>{todayMission.title}</h2>
              <div style={{ flexShrink: 0, marginTop: -4 }}><Mascot state="idle" size={70} /></div>
            </div>
            <p style={{ fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 14, color: 'rgba(255,255,255,.9)', margin: '4px 0 0', lineHeight: '20px' }}>
              Q is listening. Say <b style={{ fontFamily: 'var(--font-display)', fontSize: 18 }}>{todayWord?.hanzi}</b> ({todayWord?.pinyin}) — earn 3 stars.
            </p>
            <div style={{ marginTop: 'auto', paddingTop: 14, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div style={{ display: 'flex', gap: 6 }}>
                {[1,2,3].map(i => (
                  <div key={i} style={{
                    width: 22, height: 22, borderRadius: 999, background: 'rgba(255,255,255,.18)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}><Icon name="star" size={14} color="rgba(255,255,255,.45)" /></div>
                ))}
              </div>
              <div style={{
                background: '#fff', color: 'var(--quack-orange)', padding: '10px 16px',
                borderRadius: 999, fontWeight: 800, fontSize: 14, display: 'inline-flex', alignItems: 'center', gap: 6,
              }}>Start mission <Icon name="chevron" size={16} /></div>
            </div>
          </div>
        </button>
      </div>

      {/* Stat cards row */}
      <div style={{ padding: '14px 24px 0', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
        <Card tone="mint" padding={16} style={{ height: 120 }}>
          <Eyebrow flank={false} color="var(--ink)" size={11}>Streak</Eyebrow>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 38, lineHeight: 1, marginTop: 6 }}>{streak}</div>
          <div style={{ fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 12, marginTop: 2 }}>days in a row</div>
        </Card>
        <Card tone="cobalt" padding={16} style={{ height: 120 }}>
          <Eyebrow flank={false} color="rgba(255,255,255,.85)" size={11}>Stickers</Eyebrow>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 38, lineHeight: 1, marginTop: 6 }}>{learned.length}</div>
          <div style={{ fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 12, marginTop: 2 }}>of {VOCAB.length} collected</div>
        </Card>
      </div>

      {/* Recent stickers */}
      {recentLearned.length > 0 && (
        <div style={{ padding: '20px 24px 0' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 10 }}>
            <h3 style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 18, color: 'var(--ink)', margin: 0 }}>Recent stickers</h3>
            <button onClick={() => onTab('library')} className="tap" style={{
              background: 'none', border: 'none', cursor: 'pointer',
              fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 13, color: 'var(--quack-orange)',
            }}>See all</button>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 8 }}>
            {recentLearned.map(id => {
              const item = VOCAB.find(v => v.id === id);
              return item ? <StickerTile key={id} item={item} size="sm" /> : null;
            })}
          </div>
        </div>
      )}

      {/* Quick mission types */}
      <div style={{ padding: '20px 24px 0' }}>
        <h3 style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 18, color: 'var(--ink)', margin: '0 0 10px' }}>Pick your training</h3>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          {[
            { id: 'camera', label: 'Camera scan', sub: 'Point at it', tone: 'orange', icon: 'camera' },
            { id: 'speak',  label: 'Say it back', sub: 'Mic check', tone: 'cobalt', icon: 'mic' },
            { id: 'match',  label: 'Match cards', sub: 'Word ↔ pic', tone: 'rose',   icon: 'star' },
            { id: 'story',  label: "Q's story",   sub: 'Listen & learn', tone: 'mint', icon: 'book' },
          ].map(t => (
            <button key={t.id} onClick={() => onMission(t.id)} className="tap" style={{
              background: TONE_BG[t.tone], color: TONE_FG[t.tone],
              border: 'none', borderRadius: 22, padding: 14,
              boxShadow: 'var(--shadow-card)', textAlign: 'left',
              display: 'flex', flexDirection: 'column', gap: 8, minHeight: 110,
            }}>
              <Icon name={t.icon} size={22} stroke={2} />
              <div style={{ marginTop: 'auto' }}>
                <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 16, lineHeight: '18px' }}>{t.label}</div>
                <div style={{ fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 11, opacity: .8, marginTop: 2 }}>{t.sub}</div>
              </div>
            </button>
          ))}
        </div>
      </div>

      <div style={{ height: 24 }} />
      <TabBar active="home" onChange={onTab} />
    </div>
  );
}

// Daily-goal ring
function DailyRing({ value = 0, max = 3 }) {
  const pct = Math.max(0, Math.min(1, value / max));
  const r = 24; const c = 2 * Math.PI * r;
  return (
    <div style={{ width: 64, height: 64, position: 'relative', flexShrink: 0 }}>
      <svg width="64" height="64" viewBox="0 0 64 64" style={{ transform: 'rotate(-90deg)' }}>
        <circle cx="32" cy="32" r={r} fill="none" stroke="var(--ink-20)" strokeWidth="6" />
        <circle cx="32" cy="32" r={r} fill="none" stroke="var(--quack-orange)" strokeWidth="6"
          strokeLinecap="round" strokeDasharray={c} strokeDashoffset={c * (1 - pct)}
          style={{ transition: 'stroke-dashoffset 420ms var(--ease-out)' }} />
      </svg>
      <div style={{
        position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 20, color: 'var(--ink)',
      }}>{value}</div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// MISSIONS HUB — choose a mission type, see the path
// ─────────────────────────────────────────────────────────────
function MissionsHubScreen({ state, onPick, onTab }) {
  return (
    <div className="no-scrollbar" style={{
      width: '100%', height: '100%', background: 'var(--cream)',
      display: 'flex', flexDirection: 'column', paddingTop: 64, paddingBottom: 0,
      overflowY: 'auto', position: 'relative', animation: 'screen-in 320ms var(--ease-out)',
    }}>
      <div style={{ padding: '16px 24px 0', textAlign: 'center' }}>
        <Eyebrow>Daily Briefing</Eyebrow>
        <h1 style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 30, color: 'var(--ink)', margin: '6px 0 4px' }}>Choose your mission</h1>
        <p style={{ fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 14, color: 'var(--ink-60)', margin: 0 }}>4 ways to train. Each one earns stickers.</p>
      </div>

      <div style={{ padding: '20px 24px 0', display: 'flex', flexDirection: 'column', gap: 12 }}>
        {[
          { id: 'camera', label: 'Spot it in the wild', sub: 'Point Q\'s camera at something. Q tells you the word.', tone: 'orange', icon: 'camera', stars: 3 },
          { id: 'speak',  label: 'Say it out loud',     sub: 'Q listens to your voice and rates how clear you sound.', tone: 'cobalt', icon: 'mic', stars: 3 },
          { id: 'match',  label: 'Match the picture',   sub: 'Tap the picture that matches the word.', tone: 'rose', icon: 'star', stars: 2 },
          { id: 'story',  label: "Q's bedtime story",   sub: 'Tap through a chapter and answer at the end.', tone: 'mint', icon: 'book', stars: 5 },
        ].map((t, i) => (
          <button key={t.id} onClick={() => onPick(t.id)} className="tap grain" style={{
            background: TONE_BG[t.tone], color: TONE_FG[t.tone],
            border: 'none', borderRadius: 26, padding: 18,
            boxShadow: 'var(--shadow-pop)', textAlign: 'left',
            display: 'flex', alignItems: 'center', gap: 14, position: 'relative', overflow: 'hidden',
            animation: `screen-in 400ms var(--ease-out) ${i * 0.08}s both`,
          }}>
            <div style={{
              width: 60, height: 60, borderRadius: 18, flexShrink: 0,
              background: 'rgba(255,255,255,.22)', display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <Icon name={t.icon} size={32} stroke={2.2} />
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 20, lineHeight: '22px' }}>{t.label}</div>
              <div style={{ fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 13, opacity: .9, marginTop: 4, lineHeight: '18px' }}>{t.sub}</div>
              <div style={{ display: 'flex', gap: 4, marginTop: 8 }}>
                {Array.from({ length: t.stars }).map((_, s) => (
                  <Icon key={s} name="star" size={14} color={t.tone === 'mint' || t.tone === 'rose' ? 'var(--quack-orange)' : 'var(--quack-yellow)'} />
                ))}
              </div>
            </div>
            <Icon name="chevron" size={22} />
          </button>
        ))}
      </div>

      <div style={{ height: 24 }} />
      <TabBar active="missions" onChange={onTab} />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// LIBRARY — sticker book grouped by category
// ─────────────────────────────────────────────────────────────
function LibraryScreen({ state, onTab, onPickItem }) {
  const [activeCat, setActiveCat] = useStateH('all');
  const learnedSet = new Set(state.learned);
  const filteredVocab = useMemoH(() => {
    if (activeCat === 'all') return VOCAB;
    return VOCAB.filter(v => v.cat === activeCat);
  }, [activeCat]);

  const collectedCount = state.learned.length;
  const totalCount = VOCAB.length;

  return (
    <div className="no-scrollbar" style={{
      width: '100%', height: '100%', background: 'var(--cream)',
      display: 'flex', flexDirection: 'column', paddingTop: 64, paddingBottom: 0,
      overflowY: 'auto', position: 'relative', animation: 'screen-in 320ms var(--ease-out)',
    }}>
      {/* Header — sticker book "cover" */}
      <div className="grain" style={{
        margin: '14px 24px 0', background: 'var(--quack-yellow)', color: 'var(--ink)',
        borderRadius: 26, padding: 20, boxShadow: 'var(--shadow-pop)',
        position: 'relative', overflow: 'hidden',
      }}>
        <Sparkles count={5} color="var(--ink)" opacity={.4} />
        <div style={{ position: 'relative', zIndex: 2 }}>
          <Eyebrow color="var(--ink)">Your sticker book</Eyebrow>
          <h1 style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 30, margin: '6px 0 12px' }}>Words I know</h1>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <ProgressBar value={collectedCount} max={totalCount} color="var(--quack-orange)" track="rgba(20,33,61,.12)" height={14} />
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 18, whiteSpace: 'nowrap' }}>{collectedCount}/{totalCount}</div>
          </div>
        </div>
      </div>

      {/* Category chips */}
      <div className="no-scrollbar" style={{
        padding: '14px 24px 0', display: 'flex', gap: 8, overflowX: 'auto', flexShrink: 0,
      }}>
        {[{ id: 'all', label: 'All' }, ...CATEGORIES].map(c => {
          const on = activeCat === c.id;
          return (
            <button key={c.id} onClick={() => setActiveCat(c.id)} className="tap" style={{
              background: on ? 'var(--ink)' : 'var(--paper)',
              color: on ? '#fff' : 'var(--ink)',
              border: 'none', borderRadius: 999, padding: '10px 16px',
              fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 13,
              cursor: 'pointer', flexShrink: 0,
              boxShadow: 'var(--shadow-card)',
            }}>{c.label}</button>
          );
        })}
      </div>

      {/* Sticker grid */}
      <div style={{ padding: '14px 24px 0' }}>
        {(activeCat === 'all' ? CATEGORIES : [CATEGORIES.find(c => c.id === activeCat)]).map(cat => {
          const items = VOCAB.filter(v => v.cat === cat.id);
          const learnedInCat = items.filter(v => learnedSet.has(v.id)).length;
          return (
            <div key={cat.id} style={{ marginBottom: 22 }}>
              <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 10 }}>
                <h3 style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 18, color: 'var(--ink)', margin: 0 }}>{cat.label}</h3>
                <span style={{ fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 12, color: 'var(--ink-60)' }}>{learnedInCat}/{items.length}</span>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10 }}>
                {items.map(item => (
                  <StickerTile key={item.id} item={item} locked={!learnedSet.has(item.id)}
                    onClick={() => learnedSet.has(item.id) && onPickItem && onPickItem(item)} />
                ))}
              </div>
            </div>
          );
        })}
      </div>

      <TabBar active="library" onChange={onTab} />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// PARENT DASHBOARD — different vibe: ink-on-cream, denser
// ─────────────────────────────────────────────────────────────
function ParentScreen({ state, onTab, onSnapPhoto, onResetProgress }) {
  const week = [3, 5, 8, 4, 7, 9, state.dailyProgress];
  const max = Math.max(...week, state.dailyGoal);
  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  const learnedItems = state.learned.map(id => VOCAB.find(v => v.id === id)).filter(Boolean);

  return (
    <div className="no-scrollbar" style={{
      width: '100%', height: '100%', background: 'var(--cream)',
      display: 'flex', flexDirection: 'column', paddingTop: 64, paddingBottom: 0,
      overflowY: 'auto', position: 'relative', animation: 'screen-in 320ms var(--ease-out)',
    }}>
      {/* Tabby header */}
      <div style={{ padding: '16px 24px 0' }}>
        <Eyebrow>Parent dashboard</Eyebrow>
        <h1 style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 30, color: 'var(--ink)', margin: '6px 0 4px' }}>{state.name}'s progress</h1>
        <p style={{ fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 14, color: 'var(--ink-60)', margin: 0 }}>This week, in plain numbers</p>
      </div>

      {/* Today snapshot */}
      <div style={{ padding: '16px 24px 0', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
        <Card padding={14} style={{ textAlign: 'center' }}>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 26, color: 'var(--quack-orange)' }}>{state.dailyProgress}</div>
          <div style={{ fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 10, letterSpacing: '0.06em', textTransform: 'uppercase', color: 'var(--ink-60)', marginTop: 2 }}>Stars today</div>
        </Card>
        <Card padding={14} style={{ textAlign: 'center' }}>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 26, color: 'var(--cobalt)' }}>{state.streak}</div>
          <div style={{ fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 10, letterSpacing: '0.06em', textTransform: 'uppercase', color: 'var(--ink-60)', marginTop: 2 }}>Day streak</div>
        </Card>
        <Card padding={14} style={{ textAlign: 'center' }}>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 26, color: 'var(--mint-deep)' }}>{state.learned.length}</div>
          <div style={{ fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 10, letterSpacing: '0.06em', textTransform: 'uppercase', color: 'var(--ink-60)', marginTop: 2 }}>Words known</div>
        </Card>
      </div>

      {/* Week chart */}
      <div style={{ padding: '14px 24px 0' }}>
        <Card padding={18}>
          <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 14 }}>
            <h3 style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 18, color: 'var(--ink)', margin: 0 }}>This week</h3>
            <span style={{ fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 12, color: 'var(--ink-60)' }}>Stars per day</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', height: 110, gap: 6 }}>
            {week.map((v, i) => {
              const isToday = i === 6;
              const h = (v / max) * 100;
              return (
                <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, height: '100%', justifyContent: 'flex-end' }}>
                  <div style={{
                    width: '100%', height: `${h}%`,
                    background: isToday ? 'var(--quack-orange)' : 'var(--ink-20)',
                    borderRadius: 8,
                    minHeight: 6,
                    display: 'flex', alignItems: 'flex-start', justifyContent: 'center',
                    paddingTop: 4,
                    fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 11,
                    color: isToday ? '#fff' : 'var(--ink-60)',
                  }}>{v}</div>
                  <div style={{
                    fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 11,
                    color: isToday ? 'var(--quack-orange)' : 'var(--ink-60)',
                  }}>{days[i]}</div>
                </div>
              );
            })}
          </div>
        </Card>
      </div>

      {/* Photo → Quiz */}
      <div style={{ padding: '14px 24px 0' }}>
        <button onClick={onSnapPhoto} className="tap" style={{
          width: '100%', background: 'var(--ink)', color: '#fff',
          border: 'none', borderRadius: 22, padding: 16,
          boxShadow: 'var(--shadow-card)', textAlign: 'left',
          display: 'flex', alignItems: 'center', gap: 14, cursor: 'pointer',
        }}>
          <div style={{
            width: 56, height: 56, borderRadius: 16, background: 'var(--quack-orange)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
          }}><Icon name="photo" size={26} color="#fff" stroke={2} /></div>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 16 }}>Snap a room photo</div>
            <div style={{ fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 12, color: 'rgba(255,255,255,.7)', marginTop: 2 }}>Q makes a custom mission from what's in it</div>
          </div>
          <Icon name="chevron" size={20} />
        </button>
      </div>

      {/* Word list */}
      <div style={{ padding: '20px 24px 0' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 10 }}>
          <h3 style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 18, color: 'var(--ink)', margin: 0 }}>Vocabulary learned</h3>
          <span style={{ fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 12, color: 'var(--ink-60)' }}>{learnedItems.length} words</span>
        </div>
        <Card padding={6}>
          {learnedItems.length === 0 ? (
            <div style={{ padding: 20, textAlign: 'center', fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 13, color: 'var(--ink-60)' }}>No words yet — finish today's mission!</div>
          ) : learnedItems.slice().reverse().slice(0, 6).map((item, i, arr) => (
            <div key={item.id} style={{
              display: 'flex', alignItems: 'center', gap: 12, padding: '10px 12px',
              borderBottom: i < arr.length - 1 ? '1px solid var(--ink-20)' : 'none',
            }}>
              <div style={{
                width: 40, height: 40, borderRadius: 12,
                background: TONE_BG[item.tone], color: TONE_FG[item.tone],
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 18,
              }}>{item.hanzi}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 14, color: 'var(--ink)' }}>{item.en}</div>
                <div style={{ fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 12, color: 'var(--ink-60)' }}>{item.pinyin}</div>
              </div>
              <Icon name="check" size={20} color="var(--mint-deep)" stroke={2.4} />
            </div>
          ))}
        </Card>
      </div>

      {/* Edge device + screentime */}
      <div style={{ padding: '20px 24px 0', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        <Card padding={14} style={{ background: '#0F1A30', color: '#fff' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
            <Icon name="shield" size={18} color="var(--mint)" stroke={2.2} />
            <Eyebrow flank={false} color="var(--mint)" size={10}>Edge device</Eyebrow>
          </div>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 14, lineHeight: '18px' }}>Q‑Pod online</div>
          <div style={{ fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 11, color: 'rgba(255,255,255,.6)', marginTop: 4, lineHeight: '15px' }}>All voice + photos stay in your home</div>
          <div style={{ marginTop: 8, display: 'flex', alignItems: 'center', gap: 6 }}>
            <span style={{ width: 6, height: 6, borderRadius: 999, background: 'var(--mint)', animation: 'pulse 1.4s infinite' }} />
            <span style={{ fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 11, color: 'var(--mint)' }}>Connected</span>
          </div>
        </Card>
        <Card padding={14}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
            <Icon name="clock" size={18} color="var(--cobalt)" stroke={2.2} />
            <Eyebrow flank={false} color="var(--cobalt)" size={10}>Screentime</Eyebrow>
          </div>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 14, lineHeight: '18px' }}>14 / 30 min</div>
          <div style={{ marginTop: 8 }}>
            <ProgressBar value={14} max={30} color="var(--cobalt)" track="var(--ink-20)" height={8} />
          </div>
          <button className="tap" style={{
            marginTop: 8, background: 'none', border: 'none',
            fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 11, color: 'var(--cobalt)',
            cursor: 'pointer', padding: 0,
          }}>Adjust limit ›</button>
        </Card>
      </div>

      {/* Reset row */}
      <div style={{ padding: '20px 24px 28px' }}>
        <button onClick={onResetProgress} className="tap" style={{
          width: '100%', background: 'transparent',
          border: '2px solid var(--ink-20)', color: 'var(--ink-60)',
          borderRadius: 999, padding: '14px 18px',
          fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 13,
          cursor: 'pointer',
        }}>Reset {state.name}'s progress</button>
      </div>

      <TabBar active="parent" onChange={onTab} />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// SNAP PHOTO modal flow (parent)
// ─────────────────────────────────────────────────────────────
function SnapPhotoScreen({ onBack, onGenerate }) {
  const [phase, setPhase] = useStateH('compose'); // compose | analyzing | result
  const [picked, setPicked] = useStateH(null);

  useEffectH(() => {
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
      display: 'flex', flexDirection: 'column', paddingTop: 56,
      animation: 'screen-in 320ms var(--ease-out)',
    }}>
      <div style={{ padding: '16px 24px 0', display: 'flex', alignItems: 'center', gap: 12 }}>
        <BackBtn onClick={onBack} />
        <div>
          <Eyebrow>Photo → Mission</Eyebrow>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 22, color: 'var(--ink)', lineHeight: '24px' }}>
            {phase === 'compose' && 'Snap a room'}
            {phase === 'analyzing' && 'Q is looking…'}
            {phase === 'result' && '4 missions ready'}
          </div>
        </div>
      </div>

      {/* Fake camera viewport */}
      <div style={{ padding: '16px 24px 0', flex: 1, display: 'flex', flexDirection: 'column' }}>
        <div className="grain" style={{
          flex: 1, background: phase === 'compose' ? 'var(--ink)' : 'var(--cream-deep)',
          borderRadius: 28, position: 'relative', overflow: 'hidden',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          minHeight: 280,
        }}>
          {phase === 'compose' && (
            <>
              {[
                { top: 14, left: 14 }, { top: 14, right: 14 },
                { bottom: 14, left: 14 }, { bottom: 14, right: 14 },
              ].map((c, i) => (
                <div key={i} style={{
                  position: 'absolute', ...c, width: 28, height: 28,
                  borderTop: c.top != null ? '3px solid var(--quack-orange)' : 'none',
                  borderBottom: c.bottom != null ? '3px solid var(--quack-orange)' : 'none',
                  borderLeft: c.left != null ? '3px solid var(--quack-orange)' : 'none',
                  borderRight: c.right != null ? '3px solid var(--quack-orange)' : 'none',
                }} />
              ))}
              <div style={{ textAlign: 'center', color: '#fff', padding: 24 }}>
                <Icon name="photo" size={56} color="rgba(255,255,255,.6)" stroke={1.6} />
                <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 18, marginTop: 12 }}>Aim at a room</div>
                <div style={{ fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 12, color: 'rgba(255,255,255,.6)', marginTop: 4 }}>
                  Living room, kitchen, bedroom — anywhere
                </div>
              </div>
            </>
          )}
          {phase === 'analyzing' && (
            <div style={{ textAlign: 'center' }}>
              <div style={{ display: 'inline-flex', gap: 8 }}>
                {[0, 1, 2].map(i => (
                  <div key={i} style={{
                    width: 14, height: 14, borderRadius: 999, background: 'var(--quack-orange)',
                    animation: `dot-bounce 1.2s var(--ease-out) ${i * 0.16}s infinite`,
                  }} />
                ))}
              </div>
              <div style={{ fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 14, color: 'var(--ink-60)', marginTop: 16 }}>
                Spotting things Q can teach…
              </div>
            </div>
          )}
          {phase === 'result' && (
            <div style={{ width: '100%', padding: 20, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
              {detectedItems.map(it => (
                <button key={it.id} onClick={() => setPicked(it.id)} className="tap" style={{
                  background: picked === it.id ? 'var(--quack-orange)' : 'var(--paper)',
                  color: picked === it.id ? '#fff' : 'var(--ink)',
                  border: 'none', borderRadius: 18, padding: 12,
                  boxShadow: 'var(--shadow-card)', textAlign: 'left',
                  display: 'flex', alignItems: 'center', gap: 10,
                }}>
                  <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 22 }}>{it.hanzi}</div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 13 }}>{it.en}</div>
                    <div style={{ fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 11, opacity: .8 }}>{it.pinyin}</div>
                  </div>
                </button>
              ))}
            </div>
          )}
        </div>
      </div>

      <div style={{ padding: '20px 24px 28px' }}>
        {phase === 'compose' && (
          <CTA variant="orange" onClick={() => setPhase('analyzing')}>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 8 }}><Icon name="camera" size={18} /> Take photo</span>
          </CTA>
        )}
        {phase === 'analyzing' && (
          <CTA variant="ghost" disabled>Working…</CTA>
        )}
        {phase === 'result' && (
          <CTA variant="ink" onClick={() => onGenerate(picked || detected[0])} disabled={false}>
            Send mission to {picked ? VOCAB.find(v => v.id === picked).en : 'kid'}
          </CTA>
        )}
      </div>
    </div>
  );
}

Object.assign(window, { HomeScreen, MissionsHubScreen, LibraryScreen, ParentScreen, SnapPhotoScreen, DailyRing });
