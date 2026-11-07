const fs = require('fs');
const path = require('path');

const piecesDir = 'C:/Herramientas/Ajedrez Lyanna Godot/ajedrez-de-pollito/assets/pieces';
const avatarsDir = 'C:/Herramientas/Ajedrez Lyanna Godot/ajedrez-de-pollito/assets/avatars';
const soundsDir = 'C:/Herramientas/Ajedrez Lyanna Godot/ajedrez-de-pollito/assets/sounds';

// -------------------------------------------------------------
// 1. GENERATE PIECE SVGS
// -------------------------------------------------------------
function getPieceSvg(type, color) {
  const isWhite = color === 'w';
  const fillMain = isWhite ? '#FFFBEB' : '#1E293B';
  const fillAccent = isWhite ? '#FDE68A' : '#475569';
  const strokeColor = isWhite ? '#0F172A' : '#F8FAFC';
  const gemColor = isWhite ? '#10B981' : '#38BDF8';
  const highlightColor = isWhite ? '#FFFFFF' : '#94A3B8';

  let inner = '';
  switch (type) {
    case 'p':
      inner = `
  <ellipse cx="32" cy="56" rx="18" ry="4" fill="rgba(0,0,0,0.28)" />
  <path d="M16 52 L48 52 L44 43 L20 43 Z" fill="${fillAccent}" stroke="${strokeColor}" stroke-width="3.2" stroke-linejoin="round" />
  <path d="M22 43 C22 32, 42 32, 42 43 Z" fill="${fillMain}" stroke="${strokeColor}" stroke-width="3.2" />
  <circle cx="32" cy="22" r="10" fill="${fillMain}" stroke="${strokeColor}" stroke-width="3.2" />
  <circle cx="29" cy="19" r="2.5" fill="${highlightColor}" />`;
      break;

    case 'r':
      inner = `
  <ellipse cx="32" cy="56" rx="20" ry="4" fill="rgba(0,0,0,0.28)" />
  <rect x="14" y="46" width="36" height="7" rx="2" fill="${fillAccent}" stroke="${strokeColor}" stroke-width="3.2" />
  <rect x="19" y="24" width="26" height="22" fill="${fillMain}" stroke="${strokeColor}" stroke-width="3.2" />
  <path d="M15 24 L15 13 L23 13 L23 18 L28 18 L28 13 L36 13 L36 18 L41 18 L41 13 L49 13 L49 24 Z" fill="${fillAccent}" stroke="${strokeColor}" stroke-width="3.2" stroke-linejoin="round" />
  <rect x="29" y="31" width="6" height="9" rx="2" fill="${gemColor}" />`;
      break;

    case 'n':
      inner = `
  <ellipse cx="32" cy="56" rx="20" ry="4" fill="rgba(0,0,0,0.28)" />
  <rect x="15" y="47" width="34" height="6" rx="2" fill="${fillAccent}" stroke="${strokeColor}" stroke-width="3.2" />
  <path d="M20 47 C19 34, 24 27, 27 24 L17 26 C15 21, 20 14, 29 13 L33 8 L37 13 C45 16, 47 27, 44 47 Z" fill="${fillMain}" stroke="${strokeColor}" stroke-width="3.2" stroke-linejoin="round" />
  <circle cx="28" cy="19" r="2.6" fill="${gemColor}" />`;
      break;

    case 'b':
      inner = `
  <ellipse cx="32" cy="56" rx="20" ry="4" fill="rgba(0,0,0,0.28)" />
  <rect x="15" y="47" width="34" height="6" rx="2" fill="${fillAccent}" stroke="${strokeColor}" stroke-width="3.2" />
  <path d="M20 47 C18 30, 22 18, 32 14 C42 18, 46 30, 44 47 Z" fill="${fillMain}" stroke="${strokeColor}" stroke-width="3.2" />
  <circle cx="32" cy="10" r="4" fill="${gemColor}" stroke="${strokeColor}" stroke-width="2.5" />
  <path d="M27 27 L37 27 M32 22 L32 32" stroke="${gemColor}" stroke-width="3" stroke-linecap="round" />`;
      break;

    case 'q':
      inner = `
  <ellipse cx="32" cy="56" rx="21" ry="4" fill="rgba(0,0,0,0.28)" />
  <rect x="14" y="47" width="36" height="6" rx="2" fill="${fillAccent}" stroke="${strokeColor}" stroke-width="3.2" />
  <path d="M16 47 L11 20 L23 31 L32 16 L41 31 L53 20 L48 47 Z" fill="${fillMain}" stroke="${strokeColor}" stroke-width="3.2" stroke-linejoin="round" />
  <circle cx="11" cy="17" r="3" fill="${gemColor}" />
  <circle cx="32" cy="13" r="3.5" fill="#F59E0B" />
  <circle cx="53" cy="17" r="3" fill="${gemColor}" />`;
      break;

    case 'k':
      inner = `
  <ellipse cx="32" cy="56" rx="21" ry="4" fill="rgba(0,0,0,0.28)" />
  <rect x="14" y="47" width="36" height="6" rx="2" fill="${fillAccent}" stroke="${strokeColor}" stroke-width="3.2" />
  <path d="M17 47 C15 29, 22 21, 32 21 C42 21, 49 29, 47 47 Z" fill="${fillMain}" stroke="${strokeColor}" stroke-width="3.2" />
  <path d="M32 6 L32 19 M26 12 L38 12" stroke="#F59E0B" stroke-width="4.5" stroke-linecap="round" />
  <rect x="27" y="31" width="10" height="8" rx="2" fill="#F59E0B" />`;
      break;
  }

  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
${inner}
</svg>`;
}

const pieces = ['p', 'r', 'n', 'b', 'q', 'k'];
const colors = ['w', 'b'];

for (const c of colors) {
  for (const p of pieces) {
    const filename = `${c}_${p}.svg`;
    fs.writeFileSync(path.join(piecesDir, filename), getPieceSvg(p, c), 'utf8');
  }
}
console.log('Successfully created 12 piece SVG files in assets/pieces');

// -------------------------------------------------------------
// 2. GENERATE POLLITO AVATAR SVG
// -------------------------------------------------------------
const pollitoAvatarSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 130 130" width="130" height="130">
  <!-- Sombra en el suelo -->
  <ellipse cx="65" cy="118" rx="36" ry="6" fill="rgba(0,0,0,0.4)" />

  <!-- Cola multicolor -->
  <g id="tail">
    <path d="M 32 82 Q 8 64 12 46 Q 24 52 34 70 Z" fill="#10B981" stroke="#0F172A" stroke-width="3" />
    <path d="M 30 88 Q 4 76 6 58 Q 20 64 32 78 Z" fill="#F59E0B" stroke="#0F172A" stroke-width="3" />
    <path d="M 32 92 Q 10 88 10 72 Q 22 76 34 86 Z" fill="#EF4444" stroke="#0F172A" stroke-width="3" />
  </g>

  <!-- Patitas -->
  <g id="legs">
    <rect x="47" y="98" width="8" height="15" rx="2" fill="#F97316" stroke="#0F172A" stroke-width="3" />
    <rect x="42" y="110" width="16" height="6" rx="2" fill="#EA580C" stroke="#0F172A" stroke-width="2.5" />
    <rect x="75" y="98" width="8" height="15" rx="2" fill="#F97316" stroke="#0F172A" stroke-width="3" />
    <rect x="72" y="110" width="16" height="6" rx="2" fill="#EA580C" stroke="#0F172A" stroke-width="2.5" />
  </g>

  <!-- Cuerpo y cabeza cúbica 3D -->
  <g id="body">
    <rect x="30" y="26" width="70" height="74" rx="11" fill="#FEF08A" stroke="#0F172A" stroke-width="4" />
    <path d="M 90 30 L 96 30 L 96 94 L 36 94 L 36 98 L 98 98 L 98 30 Z" fill="#EAB308" opacity="0.65" />
    <rect x="35" y="31" width="48" height="5" rx="2.5" fill="#FFFFFF" opacity="0.45" />

    <rect x="38" y="68" width="54" height="26" rx="7" fill="#FEF9C3" stroke="#0F172A" stroke-width="2.5" />
    <path d="M 48 75 L 53 79 L 58 75 M 72 75 L 77 79 L 82 75" fill="none" stroke="#FDE047" stroke-width="2.5" stroke-linecap="round" />
  </g>

  <!-- Cresta roja -->
  <g id="comb">
    <rect x="41" y="11" width="15" height="18" rx="4" fill="#EF4444" stroke="#0F172A" stroke-width="3.2" />
    <rect x="56" y="5" width="18" height="24" rx="4" fill="#DC2626" stroke="#0F172A" stroke-width="3.2" />
    <rect x="74" y="12" width="15" height="17" rx="4" fill="#EF4444" stroke="#0F172A" stroke-width="3.2" />
    <rect x="60" y="9" width="5" height="12" rx="2" fill="#FCA5A5" opacity="0.7" />
  </g>

  <!-- Ojos grandes y amigables -->
  <g id="eyes">
    <rect x="36" y="36" width="24" height="18" rx="4" fill="#FFFFFF" stroke="#0F172A" stroke-width="3.2" />
    <rect x="70" y="36" width="24" height="18" rx="4" fill="#FFFFFF" stroke="#0F172A" stroke-width="3.2" />
    <line x1="60" y1="45" x2="70" y2="45" stroke="#0F172A" stroke-width="3.2" />
    
    <!-- Pupilas -->
    <rect x="45" y="40" width="8" height="10" rx="2.5" fill="#0F172A" />
    <rect x="79" y="40" width="8" height="10" rx="2.5" fill="#0F172A" />
    <circle cx="47.5" cy="42.5" r="2" fill="#FFFFFF" />
    <circle cx="51" cy="47.5" r="1" fill="#FFFFFF" />
    <circle cx="81.5" cy="42.5" r="2" fill="#FFFFFF" />
    <circle cx="85" cy="47.5" r="1" fill="#FFFFFF" />

    <!-- Mejillas sonrosadas -->
    <ellipse cx="35" cy="56" rx="4.5" ry="2.5" fill="#FB7185" opacity="0.65" />
    <ellipse cx="95" cy="56" rx="4.5" ry="2.5" fill="#FB7185" opacity="0.65" />
  </g>

  <!-- Pico y barbilla roja -->
  <g id="beak">
    <path d="M 57 66 C 55 82, 75 82, 73 66 Z" fill="#EF4444" stroke="#0F172A" stroke-width="2.8" />
    <polygon points="51,59 79,59 65,71" fill="#EA580C" stroke="#0F172A" stroke-width="2.8" />
    <polygon points="48,53 82,53 65,65" fill="#F97316" stroke="#0F172A" stroke-width="3" />
    <polygon points="54,55 72,55 65,60" fill="#FDBA74" opacity="0.7" />
  </g>

  <!-- Corbatín de profesor con esmeralda -->
  <g id="bowtie">
    <polygon points="51,85 65,91 51,97" fill="#10B981" stroke="#0F172A" stroke-width="2.5" />
    <polygon points="79,85 65,91 79,97" fill="#10B981" stroke="#0F172A" stroke-width="2.5" />
    <polygon points="65,85 70,91 65,97 60,91" fill="#34D399" stroke="#0F172A" stroke-width="2.2" />
  </g>

  <!-- Alitas -->
  <g id="wings">
    <rect x="16" y="54" width="16" height="32" rx="6" fill="#FACC15" stroke="#0F172A" stroke-width="3.5" />
    <line x1="20" y1="76" x2="28" y2="76" stroke="#0F172A" stroke-width="2.5" />

    <rect x="98" y="54" width="16" height="32" rx="6" fill="#FACC15" stroke="#0F172A" stroke-width="3.5" />
    <!-- Varita de profesor -->
    <line x1="106" y1="66" x2="122" y2="40" stroke="#92400E" stroke-width="4" stroke-linecap="round" />
    <polygon points="122,32 128,38 122,44 116,38" fill="#10B981" stroke="#0F172A" stroke-width="2.2" />
  </g>
</svg>`;

fs.writeFileSync(path.join(avatarsDir, 'pollito_avatar.svg'), pollitoAvatarSvg, 'utf8');
console.log('Successfully created pollito_avatar.svg in assets/avatars');

// -------------------------------------------------------------
// 3. GENERATE AUDIO WAV FILES
// -------------------------------------------------------------
function writeWavFile(filepath, sampleRate, samples) {
  const byteRate = sampleRate * 2; // 16-bit mono
  const blockAlign = 2;
  const dataSize = samples.length * 2;
  const buffer = Buffer.alloc(44 + dataSize);

  // RIFF header
  buffer.write('RIFF', 0);
  buffer.writeUInt32LE(36 + dataSize, 4);
  buffer.write('WAVE', 8);

  // fmt chunk
  buffer.write('fmt ', 12);
  buffer.writeUInt32LE(16, 16); // Subchunk1Size (16 for PCM)
  buffer.writeUInt16LE(1, 20);  // AudioFormat (1 for PCM)
  buffer.writeUInt16LE(1, 22);  // NumChannels (1 mono)
  buffer.writeUInt32LE(sampleRate, 24); // SampleRate
  buffer.writeUInt32LE(byteRate, 28);   // ByteRate
  buffer.writeUInt16LE(blockAlign, 32); // BlockAlign
  buffer.writeUInt16LE(16, 34);         // BitsPerSample

  // data chunk
  buffer.write('data', 36);
  buffer.writeUInt32LE(dataSize, 40);

  for (let i = 0; i < samples.length; i++) {
    let s = Math.max(-1, Math.min(1, samples[i]));
    const intSample = s < 0 ? Math.floor(s * 0x8000) : Math.floor(s * 0x7FFF);
    buffer.writeInt16LE(intSample, 44 + i * 2);
  }

  fs.writeFileSync(filepath, buffer);
}

const SAMPLE_RATE = 44100;

// Move sound: warm wood thud
function generateMoveSound() {
  const duration = 0.12;
  const total = Math.floor(SAMPLE_RATE * duration);
  const samples = new Float32Array(total);
  for (let i = 0; i < total; i++) {
    const t = i / SAMPLE_RATE;
    const freq = 180 * Math.exp(-t * 30) + 60;
    const env = Math.exp(-t * 25);
    samples[i] = Math.sin(2 * Math.PI * freq * t) * env * 0.75;
  }
  return samples;
}

// Capture sound: sharp crisp click + wood impact
function generateCaptureSound() {
  const duration = 0.18;
  const total = Math.floor(SAMPLE_RATE * duration);
  const samples = new Float32Array(total);
  for (let i = 0; i < total; i++) {
    const t = i / SAMPLE_RATE;
    const freq = 260 * Math.exp(-t * 22) + 80;
    const noise = (Math.random() * 2 - 1) * Math.exp(-t * 60) * 0.4;
    const tone = Math.sin(2 * Math.PI * freq * t) * Math.exp(-t * 18) * 0.7;
    samples[i] = (noise + tone) * 0.85;
  }
  return samples;
}

// Check alert sound: two pleasant ascending chimes
function generateCheckSound() {
  const duration = 0.35;
  const total = Math.floor(SAMPLE_RATE * duration);
  const samples = new Float32Array(total);
  for (let i = 0; i < total; i++) {
    const t = i / SAMPLE_RATE;
    let s = 0;
    // Note 1: 587 Hz (D5)
    if (t < 0.25) {
      s += Math.sin(2 * Math.PI * 587.33 * t) * Math.exp(-t * 15) * 0.5;
    }
    // Note 2: 880 Hz (A5)
    if (t > 0.08) {
      const t2 = t - 0.08;
      s += Math.sin(2 * Math.PI * 880.0 * t2) * Math.exp(-t2 * 12) * 0.6;
    }
    samples[i] = s;
  }
  return samples;
}

// Button Click sound (Minecraft style crisp tap)
function generateClickSound() {
  const duration = 0.06;
  const total = Math.floor(SAMPLE_RATE * duration);
  const samples = new Float32Array(total);
  for (let i = 0; i < total; i++) {
    const t = i / SAMPLE_RATE;
    const freq = 340 * Math.exp(-t * 25) + 160;
    const env = Math.exp(-t * 65);
    samples[i] = (Math.sin(2 * Math.PI * freq * t) * 0.7 + (Math.random() * 2 - 1) * 0.3) * env * 0.6;
  }
  return samples;
}

// Victory fanfare arpeggio (C - E - G - C6)
function generateVictorySound() {
  const duration = 0.8;
  const total = Math.floor(SAMPLE_RATE * duration);
  const samples = new Float32Array(total);
  const notes = [
    { freq: 523.25, start: 0.00, dur: 0.18 }, // C5
    { freq: 659.25, start: 0.12, dur: 0.18 }, // E5
    { freq: 783.99, start: 0.24, dur: 0.22 }, // G5
    { freq: 1046.5, start: 0.38, dur: 0.40 }, // C6
  ];
  for (let i = 0; i < total; i++) {
    const t = i / SAMPLE_RATE;
    let s = 0;
    for (const n of notes) {
      if (t >= n.start && t < n.start + n.dur) {
        const dt = t - n.start;
        const env = Math.exp(-dt * 7);
        s += Math.sin(2 * Math.PI * n.freq * dt) * env * 0.35;
        // add 2nd harmonic for shimmer
        s += Math.sin(4 * Math.PI * n.freq * dt) * env * 0.12;
      }
    }
    samples[i] = s;
  }
  return samples;
}

// Kikiriki sound: Profe Pollito joyful chirp
function generateKikirikiSound() {
  const duration = 0.65;
  const total = Math.floor(SAMPLE_RATE * duration);
  const samples = new Float32Array(total);
  const notes = [
    { freq: 523.25, start: 0.00, dur: 0.08 },
    { freq: 659.25, start: 0.09, dur: 0.08 },
    { freq: 783.99, start: 0.18, dur: 0.09 },
    { freq: 1046.5, start: 0.28, dur: 0.22 },
    { freq: 880.0,  start: 0.52, dur: 0.13 },
  ];
  for (let i = 0; i < total; i++) {
    const t = i / SAMPLE_RATE;
    let s = 0;
    for (const n of notes) {
      if (t >= n.start && t < n.start + n.dur) {
        const dt = t - n.start;
        const env = Math.exp(-dt * 12);
        // square wave component for chicken cluck
        const sq = Math.sign(Math.sin(2 * Math.PI * n.freq * dt));
        s += (sq * 0.2 + Math.sin(2 * Math.PI * n.freq * dt) * 0.3) * env * 0.5;
      }
    }
    samples[i] = s;
  }
  return samples;
}

writeWavFile(path.join(soundsDir, 'move.wav'), SAMPLE_RATE, generateMoveSound());
writeWavFile(path.join(soundsDir, 'capture.wav'), SAMPLE_RATE, generateCaptureSound());
writeWavFile(path.join(soundsDir, 'check.wav'), SAMPLE_RATE, generateCheckSound());
writeWavFile(path.join(soundsDir, 'click.wav'), SAMPLE_RATE, generateClickSound());
writeWavFile(path.join(soundsDir, 'victory.wav'), SAMPLE_RATE, generateVictorySound());
writeWavFile(path.join(soundsDir, 'kikiriki.wav'), SAMPLE_RATE, generateKikirikiSound());

console.log('Successfully generated clean WAV sounds in assets/sounds');
