/* global React, ReactDOM */
/* global SplashScreen, NameScreen, AgeScreen, IntroScreen */
/* global HomeScreen, MissionsHubScreen, LibraryScreen, ParentScreen, SnapPhotoScreen */
/* global CameraMission, SpeakMission, MatchMission, StoryMission, CompleteScreen */
/* global TweaksPanel, useTweaks, TweakSection, TweakRadio, TweakSelect, TweakToggle, TweakButton */
/* global StickerTile, Card, Eyebrow, CTA, BackBtn, Mascot, Icon, VOCAB */
/* global IOSFrame */

const { useState, useEffect, useMemo, useCallback } = React;

// Pick today's mission target — rotate by a small seed so it changes
const todayTarget = () => {
  const d = new Date();
  const idx = (d.getDate() + d.getMonth() * 3) % VOCAB.length;
  return VOCAB[idx].id;
};

const DEFAULT_STATE = {
  name: 'Alex',
  age: 8,
  streak: 4,
  dailyGoal: 3,
  dailyProgress: 1,
  learned: ['apple', 'cat', 'mom', 'rice'],
  todayMission: { id: 'today', title: 'Find the apple', target: todayTarget() },
};

const TWEAKS_DEFAULTS = /*EDITMODE-BEGIN*/{
  "startAt": "home",
  "theme": "light",
  "mascot": "auto",
  "showFrame": true,
  "landscape": false
}/*EDITMODE-END*/;

const SCREEN_OPTIONS = [
  { value: 'splash',   label: 'Splash' },
  { value: 'name',     label: 'Onboard · Name' },
  { value: 'age',      label: 'Onboard · Age' },
  { value: 'intro',    label: 'Onboard · Intro' },
  { value: 'home',     label: 'Home' },
  { value: 'missions', label: 'Missions hub' },
  { value: 'mission-camera', label: 'Mission · Camera' },
  { value: 'mission-speak',  label: 'Mission · Speak' },
  { value: 'mission-match',  label: 'Mission · Match' },
  { value: 'mission-story',  label: 'Mission · Story' },
  { value: 'complete', label: 'Mission complete' },
  { value: 'library',  label: 'Sticker book' },
  { value: 'parent',   label: 'Parent dashboard' },
  { value: 'snap',     label: 'Parent · Snap photo' },
  { value: 'profile',  label: 'Profile' },
];

function App() {
  const [t, setTweak] = useTweaks(TWEAKS_DEFAULTS);
  const [appState, setAppState] = useState(DEFAULT_STATE);
  const [screen, setScreen] = useState(t.startAt);
  const [mascotOverride, setMascotOverride] = useState('auto');
  const [autoMascot, setAutoMascot] = useState('idle');
  const [completedItem, setCompletedItem] = useState(null);
  const [activeTab, setActiveTab] = useState('home');

  // Apply theme class on root
  useEffect(() => {
    document.documentElement.classList.toggle('theme-dark', t.theme === 'dark');
  }, [t.theme]);

  // When tweak changes startAt, jump
  useEffect(() => { setScreen(t.startAt); }, [t.startAt]);

  // Effective mascot state — tweak override beats internal animation
  const mascotState = mascotOverride !== 'auto' ? mascotOverride
    : (t.mascot !== 'auto' ? t.mascot : autoMascot);

  // ── Helpers ──
  const addLearned = useCallback((id) => {
    if (!id) return;
    setAppState(s => s.learned.includes(id) ? s : { ...s, learned: [...s.learned, id], dailyProgress: Math.min(s.dailyProgress + 1, 99) });
  }, []);

  const finishMission = (earnedId) => {
    addLearned(earnedId);
    setCompletedItem(VOCAB.find(v => v.id === earnedId) || null);
    setAutoMascot('celebrating');
    setScreen('complete');
  };

  const onTab = (tab) => {
    setActiveTab(tab);
    if (tab === 'home') setScreen('home');
    if (tab === 'missions') setScreen('missions');
    if (tab === 'library') setScreen('library');
    if (tab === 'parent') setScreen('parent');
    if (tab === 'profile') setScreen('profile');
  };

  // ── Routing render ──
  let body = null;
  switch (screen) {
    case 'splash':
      body = <SplashScreen mascotState={mascotState} onNext={() => setScreen('name')} />; break;
    case 'name':
      body = <NameScreen value={appState.name} mascotState={mascotState}
        onBack={() => setScreen('splash')}
        onNext={(name) => { setAppState(s => ({ ...s, name })); setScreen('age'); }} />; break;
    case 'age':
      body = <AgeScreen value={appState.age} mascotState={mascotState}
        onBack={() => setScreen('name')}
        onNext={(age) => { setAppState(s => ({ ...s, age })); setScreen('intro'); }} />; break;
    case 'intro':
      body = <IntroScreen name={appState.name} mascotState={mascotState}
        onBack={() => setScreen('age')}
        onNext={() => setScreen('home')} />; break;
    case 'home':
      body = <HomeScreen state={appState} mascotState={mascotState}
        onTab={onTab}
        onMission={(type) => {
          if (type === 'camera') setScreen('mission-camera');
          else if (type === 'speak') setScreen('mission-speak');
          else if (type === 'match') setScreen('mission-match');
          else if (type === 'story') setScreen('mission-story');
          else setScreen('mission-camera');
        }}
      />; break;
    case 'missions':
      body = <MissionsHubScreen state={appState} onTab={onTab}
        onPick={(type) => setScreen(`mission-${type}`)} />; break;
    case 'mission-camera':
      body = <CameraMission target={appState.todayMission.target}
        setMascotState={setAutoMascot}
        onBack={() => setScreen('home')}
        onComplete={() => finishMission(appState.todayMission.target)} />; break;
    case 'mission-speak':
      body = <SpeakMission targetCategory="fruits"
        setMascotState={setAutoMascot}
        addLearned={addLearned}
        onBack={() => setScreen('home')}
        onComplete={(id) => finishMission(id)} />; break;
    case 'mission-match':
      body = <MatchMission targetCategory="animals"
        setMascotState={setAutoMascot}
        addLearned={addLearned}
        onBack={() => setScreen('home')}
        onComplete={(id) => finishMission(id)} />; break;
    case 'mission-story':
      body = <StoryMission
        setMascotState={setAutoMascot}
        addLearned={addLearned}
        onBack={() => setScreen('home')}
        onComplete={(id) => finishMission(id)} />; break;
    case 'complete':
      body = <CompleteScreen earnedItem={completedItem} name={appState.name}
        mascotState={mascotState}
        onHome={() => { setAutoMascot('idle'); setScreen('home'); setActiveTab('home'); }} />; break;
    case 'library':
      body = <LibraryScreen state={appState} onTab={onTab} />; break;
    case 'parent':
      body = <ParentScreen state={appState} onTab={onTab}
        onSnapPhoto={() => setScreen('snap')}
        onResetProgress={() => {
          if (!confirm('Reset all progress?')) return;
          setAppState(s => ({ ...s, learned: [], dailyProgress: 0, streak: 0 }));
        }} />; break;
    case 'snap':
      body = <SnapPhotoScreen
        onBack={() => setScreen('parent')}
        onGenerate={(id) => {
          setAppState(s => ({ ...s, todayMission: { ...s.todayMission, title: `Find the ${VOCAB.find(v=>v.id===id).en.toLowerCase()}`, target: id } }));
          setScreen('home'); setActiveTab('home');
        }} />; break;
    case 'profile':
      body = <ProfileScreen state={appState} onTab={onTab} />; break;
    default:
      body = <HomeScreen state={appState} onTab={onTab} mascotState={mascotState} onMission={() => setScreen('mission-camera')} />;
  }

  return (
    <>
      <div className="stage">
        <IOSFrame frame={t.showFrame} dark={t.theme === 'dark'} landscape={t.landscape}>
          {body}
        </IOSFrame>
      </div>

      <TweaksPanel title="Tweaks">
        <TweakSection label="App">
          <TweakRadio label="Theme" value={t.theme}
            options={[{ value: 'light', label: 'Light' }, { value: 'dark', label: 'Dark' }]}
            onChange={(v) => setTweak('theme', v)} />
          <TweakToggle label="Phone frame" value={t.showFrame}
            onChange={(v) => setTweak('showFrame', v)} />
          <TweakToggle label="Landscape (doll-belly)" value={t.landscape}
            onChange={(v) => setTweak('landscape', v)} />
        </TweakSection>

        <TweakSection label="Mascot expression">
          <TweakRadio label="Agent Q" value={t.mascot}
            options={[
              { value: 'auto', label: 'Auto' },
              { value: 'idle', label: 'Idle' },
              { value: 'speaking', label: 'Speaking' },
              { value: 'celebrating', label: 'Celebrate' },
            ]}
            onChange={(v) => setTweak('mascot', v)} />
        </TweakSection>

        <TweakSection label="Navigate">
          <TweakSelect label="Jump to screen" value={screen}
            options={SCREEN_OPTIONS}
            onChange={(v) => { setScreen(v); setTweak('startAt', v); }} />
        </TweakSection>

        <TweakSection label="State">
          <TweakButton label="Reset progress"
            onClick={() => setAppState({ ...DEFAULT_STATE, learned: [], dailyProgress: 0, streak: 0 })} />
          <TweakButton secondary label="Restart at splash"
            onClick={() => { setScreen('splash'); setTweak('startAt', 'splash'); }} />
          <TweakButton secondary label="Fill all stickers"
            onClick={() => setAppState(s => ({ ...s, learned: VOCAB.map(v => v.id) }))} />
        </TweakSection>
      </TweaksPanel>
    </>
  );
}

// ── Profile (small, lives behind the avatar tab) ──
function ProfileScreen({ state, onTab }) {
  return (
    <div className="no-scrollbar" style={{
      width: '100%', height: '100%', background: 'var(--cream)',
      display: 'flex', flexDirection: 'column', paddingTop: 64, paddingBottom: 0,
      overflowY: 'auto', animation: 'screen-in 320ms var(--ease-out)',
    }}>
      <div className="grain" style={{
        margin: '14px 24px 0', background: 'var(--quack-orange)', color: '#fff',
        borderRadius: 28, padding: 22, boxShadow: 'var(--shadow-pop)', textAlign: 'center',
      }}>
        <Mascot state="idle" size={120} />
        <Eyebrow color="var(--quack-yellow)">Agent file</Eyebrow>
        <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 30, marginTop: 4 }}>{state.name}</div>
        <div style={{ fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 13, opacity: .85, marginTop: 2 }}>Age {state.age} · Level {Math.floor(state.learned.length / 5) + 1}</div>
      </div>

      <div style={{ padding: '20px 24px 0', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
        <Card padding={14} style={{ textAlign: 'center' }}>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 28, color: 'var(--quack-orange)' }}>{state.streak}</div>
          <div style={{ fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 11, color: 'var(--ink-60)', marginTop: 2 }}>Streak</div>
        </Card>
        <Card padding={14} style={{ textAlign: 'center' }}>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 28, color: 'var(--cobalt)' }}>{state.learned.length}</div>
          <div style={{ fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 11, color: 'var(--ink-60)', marginTop: 2 }}>Words</div>
        </Card>
        <Card padding={14} style={{ textAlign: 'center' }}>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 28, color: 'var(--mint-deep)' }}>{state.dailyProgress}</div>
          <div style={{ fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 11, color: 'var(--ink-60)', marginTop: 2 }}>Today</div>
        </Card>
      </div>

      <div style={{ padding: '20px 24px 0' }}>
        <Eyebrow>Latest stickers</Eyebrow>
        <div style={{ marginTop: 10, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10 }}>
          {state.learned.slice(-6).reverse().map(id => {
            const item = VOCAB.find(v => v.id === id);
            return item ? <StickerTile key={id} item={item} size="sm" /> : null;
          })}
          {state.learned.length === 0 && (
            <div style={{ gridColumn: '1 / -1', padding: 24, textAlign: 'center', fontFamily: 'var(--font-body)', fontWeight: 600, color: 'var(--ink-60)' }}>No stickers yet — Q is waiting!</div>
          )}
        </div>
      </div>

      <div style={{ padding: '20px 24px 0' }}>
        <CTA variant="ghost" onClick={() => onTab('library')}>See full sticker book</CTA>
      </div>

      {/* Bottom tab bar */}
      <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0 }}>
        {React.createElement(window.TabBar, { active: 'profile', onChange: onTab })}
      </div>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
