const fs = require('fs');
const path = require('path');
const http = require('http');
const { spawn } = require('child_process');

// ffmpeg-static'in binary'si indirilememis olabilir (install script engelli).
// Once onu dene, yoksa sistemdeki ffmpeg'e dus.
function ffmpegBul() {
    try {
        const p = require('ffmpeg-static');
        if (p && fs.existsSync(p)) {
            console.log('>>> ffmpeg: ffmpeg-static ->', p);
            return p;
        }
        console.log('>>> ffmpeg-static binary YOK, sistem ffmpeg denenecek');
    } catch (e) {
        console.log('>>> ffmpeg-static yuklu degil, sistem ffmpeg denenecek');
    }
    return 'ffmpeg';
}
const ffmpegPath = ffmpegBul();

const { Client, GatewayIntentBits, Events } = require('discord.js');
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

// ---- Panel port kapatmasin diye basit web sunucu ----
http.createServer((req, res) => {
    res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('Bot 7/24 Aktif!');
}).listen(process.env.SERVER_PORT || process.env.PORT || 3000);

console.log('>>> @discordjs/voice surumu:', require('@discordjs/voice/package.json').version);
console.log('>>> discord.js surumu:', require('discord.js/package.json').version);

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

    if (dosyalar.length === 0) {
        throw new Error('Klasorde hic ses dosyasi yok!');
    }
    return path.join(__dirname, dosyalar[0]);
}

client.once(Events.ClientReady, async () => {
    console.log(`>>> BOT AKTIF: ${client.user.tag}`);

    try {
        const filePath = sesDosyasiniBul();
        const stats = fs.statSync(filePath);
        console.log(`>>> Calinacak dosya: ${path.basename(filePath)} (${(stats.size / 1024).toFixed(1)} KB)`);

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

            // ffmpeg dogrudan Opus uretiyor -> Node tarafinda encoder gerekmiyor
            ffmpegProc = spawn(ffmpegPath, [
                '-loglevel', 'error',
                '-stream_loop', '-1',   // sonsuz dongu
                '-re',                  // gercek zamanli oku
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
            ffmpegProc.on('error', e => console.error('ffmpeg baslatilamadi:', e.message));

            const resource = createAudioResource(ffmpegProc.stdout, {
                inputType: StreamType.OggOpus,
                inlineVolume: false
            });

            player.play(resource);
        }

        player.on(AudioPlayerStatus.Playing, () => console.log('>>> SES YAYINDA (sonsuz dongu)'));
        player.on(AudioPlayerStatus.Idle, () => {
            console.log('>>> Akis durdu, yeniden baslatiliyor...');
            setTimeout(play, 1000);
        });
        player.on('error', err => {
            console.error('Oynatma hatasi:', err.message);
            setTimeout(play, 2000);
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
                } catch {
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
