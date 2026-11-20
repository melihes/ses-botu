"""Oyunun seslerini sıfırdan sentezler (telifsiz, harici kaynak yok).

Kullanım: python3 tool/make_sounds.py  ->  assets/sounds/*.m4a
- voice_<tip>_<n>: karakterlerin anlamsız "bıdı bıdı" konuşması
- applause, laugh, cheer: seyirci sesleri
"""
import math
import os
import subprocess
import wave

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sounds')
rng = np.random.default_rng(42)

VOWELS = {  # formant frekansları (F1, F2)
    'a': (800, 1250), 'e': (500, 1850), 'ı': (400, 1500), 'i': (320, 2300),
    'o': (520, 900), 'u': (360, 800),
}


def resonator(x, f, bw):
    """İki kutuplu rezonans filtresi (formant)."""
    r = math.exp(-math.pi * bw / SR)
    a1 = -2 * r * math.cos(2 * math.pi * f / SR)
    a2 = r * r
    y = np.zeros_like(x)
    y1 = y2 = 0.0
    g = 1 - r
    for n in range(len(x)):
        v = g * x[n] - a1 * y1 - a2 * y2
        y[n] = v
        y2, y1 = y1, v
    return y


def syllable(f0, vowel, dur, rise=0.0, breath=0.02):
    n = int(SR * dur)
    t = np.arange(n) / SR
    # perde eğrisi: hafif titreşim + istenirse soru gibi yükselme
    f = f0 * (1 + 0.04 * np.sin(2 * np.pi * 6 * t) + rise * t / dur)
    phase = np.cumsum(2 * np.pi * f / SR)
    src = (phase / (2 * np.pi)) % 1.0 * 2 - 1  # testere dişi (ses telleri)
    src += breath * rng.standard_normal(n)
    f1, f2 = VOWELS[vowel]
    y = resonator(src, f1, 90) * 1.0 + resonator(src, f2, 120) * 0.6
    env = np.minimum(1, t / 0.012) * np.minimum(1, (dur - t) / 0.03)
    # ünsüz: başta kısa bir "b/d/t" patlaması
    k = int(SR * 0.012)
    burst = rng.standard_normal(k) * np.linspace(1, 0, k) * 0.25
    y[:k] += burst
    return y * env


def voice(f0, n_syll, question=False):
    parts = []
    vowels = list(VOWELS.keys())
    for i in range(n_syll):
        last = i == n_syll - 1
        dur = rng.uniform(0.07, 0.13) * (1.6 if last else 1)
        pitch = f0 * rng.uniform(0.85, 1.2) * (1.0 - 0.15 * i / n_syll)
        parts.append(syllable(pitch, rng.choice(vowels), dur,
                              rise=0.5 if (last and question) else 0.0))
        parts.append(np.zeros(int(SR * rng.uniform(0.015, 0.05))))
    return np.concatenate(parts)


def normalize(x, peak=0.85):
    m = np.max(np.abs(x)) or 1.0
    return x / m * peak


def clap():
    k = int(SR * 0.02)
    c = rng.standard_normal(k) * np.exp(-np.linspace(0, 6, k))
    return np.diff(c, prepend=0)  # tiz, el çırpma gibi


def applause(dur=2.4):
    n = int(SR * dur)
    y = np.zeros(n)
    t = np.arange(n) / SR
    density = np.minimum(1, t / 0.3) * np.minimum(1, (dur - t) / 0.8)
    for _ in range(int(70 * dur)):
        pos = int(rng.uniform(0, n - 500))
        if rng.uniform() > density[pos]:
            continue
        cl = clap() * rng.uniform(0.3, 1)
        y[pos:pos + len(cl)] += cl
    return y


def laugh(voices=5):
    total = np.zeros(int(SR * 1.8))
    for _ in range(voices):
        f0 = rng.uniform(140, 300)
        seq = []
        for i in range(rng.integers(4, 7)):
            seq.append(syllable(f0 * (1 - 0.05 * i), 'a', rng.uniform(0.08, 0.12), breath=0.15))
            seq.append(np.zeros(int(SR * rng.uniform(0.04, 0.08))))
        v = np.concatenate(seq)
        start = int(rng.uniform(0, 0.3) * SR)
        end = min(len(total), start + len(v))
        total[start:end] += v[:end - start] * rng.uniform(0.5, 1)
    return total


def cheer(dur=2.6):
    n = int(SR * dur)
    t = np.arange(n) / SR
    noise = rng.standard_normal(n)
    crowd = resonator(noise, 700, 600) * 0.6
    for _ in range(8):
        f0 = rng.uniform(150, 320)
        s = syllable(f0, rng.choice(['o', 'a', 'e']), dur, breath=0.2)
        crowd[:len(s)] += s * rng.uniform(0.3, 0.7)
    env = np.minimum(1, t / 0.6) * np.minimum(1, (dur - t) / 0.7)
    return crowd * env


def save(name, x):
    x = normalize(x)
    wav = os.path.join(OUT, name + '.wav')
    with wave.open(wav, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())
    m4a = os.path.join(OUT, name + '.m4a')
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wav, '-c:a', 'aac', '-b:a', '64k', m4a], check=True)
    os.remove(wav)


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    # Not: karakter sesleri (voice) ve kahkaha kulağa hoş gelmediği için
    # oyundan çıkarıldı; sadece alkış ve tribün sesi üretiliyor.
    save('applause', applause())
    save('cheer', cheer())
    print('\n'.join(sorted(os.listdir(OUT))))
