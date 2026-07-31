const fs = require('fs');
const path = require('path');
const http = require('http');
const { spawn } = require('child_process');

const {
    Client,
    GatewayIntentBits,
    Events
} = require('discord.js');
const {
    joinVoiceChannel,
    createAudioPlayer,
    createAudioResource,
    AudioPlayerStatus,
    NoSubscriberBehavior,
    StreamType,
    VoiceConnectionStatus,
    entersState
} = require('@discordjs/voice');

// ---- Panel portu kapatmasin diye basit web sunucu ----
http.createServer((req, res) => {
    res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('Bot 7/24 Aktif!');
}).listen(process.env.SERVER_PORT || process.env.PORT || 3000);

// ---- Paket surumunu guvenli sekilde oku ----
function paketSurumu(ad) {
    try {
        const p = path.join(__dirname, 'node_modules', ad, 'package.json');
        return JSON.parse(fs.readFileSync(p, 'utf8')).version;
    } catch (_) {
        return 'okunamadi';
    }
}
console.log('>>> @discordjs/voice surumu:', paketSurumu('@discordjs/voice'));
console.log('>>> discord.js surumu:', paketSurumu('discord.js'));

// ---- ffmpeg bul ----
function ffmpegYolu() {
    try {
        const p = require('ffmpeg-static');
        if (p && fs.existsSync(p)) return p;
    } catch (_) {}
    return 'ffmpeg';
}

function ffmpegCalisiyorMu(bin) {
    return new Promise(resolve => {
        let cikti = '';
        let bitti = false;
        const son = v => { if (!bitti) { bitti = true; resolve(v); } };
        try {
            const p = spawn(bin, ['-version'], { stdio: ['ignore', 'pipe', 'pipe'] });
            p.stdout.on('data', d => cikti += d.toString());
            p.on('error', () => son(null));
            p.on('close', code => son(code === 0 ? cikti.split('\n')[0].trim() : null));
            setTimeout(() => { try { p.kill(); } catch (_) {} son(null); }, 8000);
        } catch (_) {
            son(null);
        }
    });
}

const client = new Client({
    intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildVoiceStates
    ]
});

function sesDosyasiniBul() {
    const uzantilar = ['.ogg', '.opus', '.mp3', '.wav', '.m4a', '.flac'];
    const dosyalar = fs.readdirSync(__dirname)
        .filter(f => uzantilar.includes(path.extname(f).toLowerCase()));
    console.log('>>> Klasordeki ses dosyalari:', dosyalar);
    if (dosyalar.length === 0) throw new Error('Klasorde hic ses dosyasi yok!');
    return path.join(__dirname, dosyalar[0]);
}

client.once(Events.ClientReady, async () => {
    console.log('>>> BOT AKTIF:', client.user.tag);

    try {
        const filePath = sesDosyasiniBul();
        const stats = fs.statSync(filePath);
        console.log(`>>> Calinacak dosya: ${path.basename(filePath)} (${(stats.size / 1024).toFixed(1)} KB)`);

        // ffmpeg var mi?
        const ffmpegBin = ffmpegYolu();
        const ffmpegVar = await ffmpegCalisiyorMu(ffmpegBin);
        if (ffmpegVar) {
            console.log('>>> ffmpeg BULUNDU:', ffmpegVar);
        } else {
            console.log('>>> ffmpeg YOK. Dosya dogrudan aktarilacak.');
            console.log('>>> (Bu yontem sadece dosya Opus formatindaysa calisir.)');
        }

        const channel = await client.channels.fetch(process.env.KANAL_ID);
        if (!channel) return console.error('HATA: Kanal bulunamadi! KANAL_ID yanlis olabilir.');
        if (!channel.isVoiceBased()) return console.error('HATA: Verilen ID bir ses kanali degil!');

        const player = createAudioPlayer({
            behaviors: { noSubscriber: NoSubscriberBehavior.Play }
        });

        let ffmpegProc = null;

        function play() {
            if (ffmpegProc) {
                try { ffmpegProc.kill('SIGKILL'); } catch (_) {}
                ffmpegProc = null;
            }

            let resource;

            if (ffmpegVar) {
                // ffmpeg sonsuz dongu + dogrudan Opus uretimi
                ffmpegProc = spawn(ffmpegBin, [
                    '-loglevel', 'error',
                    '-stream_loop', '-1',
                    '-re',
                    '-i', filePath,
                    '-vn',
                    '-c:a', 'libopus',
                    '-b:a', '96k',
                    '-ar', '48000',
                    '-ac', '2',
                    '-f', 'ogg',
                    'pipe:1'
                ], { stdio: ['ignore', 'pipe', 'pipe'] });

                ffmpegProc.stderr.on('data', d => console.error('ffmpeg:', d.toString().trim()));
                ffmpegProc.on('error', e => console.error('ffmpeg hatasi:', e.message));

                resource = createAudioResource(ffmpegProc.stdout, {
                    inputType: StreamType.OggOpus,
                    inlineVolume: false
                });
            } else {
                // ffmpeg yok: dosyayi oldugu gibi gonder, bitince Idle tetiklenip tekrar baslar
                resource = createAudioResource(fs.createReadStream(filePath), {
                    inputType: StreamType.OggOpus,
                    inlineVolume: false
                });
            }

            player.play(resource);
        }

        player.on(AudioPlayerStatus.Playing, () => console.log('>>> SES YAYINDA'));
        player.on(AudioPlayerStatus.Idle, () => {
            setTimeout(play, ffmpegVar ? 1000 : 50);
        });
        player.on('error', err => {
            console.error('Oynatma hatasi:', err.message);
            setTimeout(play, 3000);
        });

        async function baglan() {
            const connection = joinVoiceChannel({
                channelId: channel.id,
                guildId: channel.guild.id,
                adapterCreator: channel.guild.voiceAdapterCreator,
                selfDeaf: false,
                selfMute: false
            });

            connection.on('stateChange', (o, n) => console.log(`>>> BAGLANTI: ${o.status} -> ${n.status}`));
            connection.on('error', e => console.error('>>> BAGLANTI HATASI:', e.message));

            connection.on(VoiceConnectionStatus.Disconnected, async () => {
                try {
                    await Promise.race([
                        entersState(connection, VoiceConnectionStatus.Signalling, 5000),
                        entersState(connection, VoiceConnectionStatus.Connecting, 5000)
                    ]);
                } catch (_) {
                    try { connection.destroy(); } catch (_) {}
                    setTimeout(baglan, 5000);
                }
            });

            await entersState(connection, VoiceConnectionStatus.Ready, 30000);
            console.log('>>> UDP SOKETI HAZIR!');

            connection.subscribe(player);
            play();
        }

        await baglan();

    } catch (err) {
        console.error('HATA OLUSTU:', err);
    }
});

client.login(process.env.TOKEN);
