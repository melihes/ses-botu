// ---- ffmpeg-static'i kütüphaneye tanıt (bazı iç yollar bunu kullanır) ----
require('dotenv').config();
process.env.FFMPEG_PATH = require('ffmpeg-static');

const fs = require('fs');
const path = require('path');
const http = require('http');
const { spawn } = require('child_process');
const ffmpegPath = require('ffmpeg-static');

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

// ---- Railway'in portu kapatmaması için basit web sunucu ----
http.createServer((req, res) => {
    res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('Bot 7/24 Aktif!');
}).listen(process.env.PORT || 3000);

const client = new Client({
    intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildVoiceStates
    ]
});

// ---- Klasördeki ses dosyasını otomatik bul (ses.mp3, ses1.ogg, hangisiyse) ----
function sesDosyasiniBul() {
    const uzantilar = ['.ogg', '.opus', '.mp3', '.wav', '.m4a', '.flac'];
    const dosyalar = fs.readdirSync(__dirname)
        .filter(f => uzantilar.includes(path.extname(f).toLowerCase()));

    console.log('>>> Klasördeki ses dosyaları:', dosyalar);

    if (dosyalar.length === 0) {
        throw new Error('Klasörde hiç ses dosyası yok! Dosyayı index.js ile aynı yere koy.');
    }
    return path.join(__dirname, dosyalar[0]);
}

client.once(Events.ClientReady, async () => {
    console.log(`>>> BOT AKTİF: ${client.user.tag}`);

    try {
        const filePath = sesDosyasiniBul();
        const stats = fs.statSync(filePath);
        console.log(`>>> Çalınacak dosya: ${path.basename(filePath)} (${(stats.size / 1024).toFixed(1)} KB)`);

        const channel = await client.channels.fetch(process.env.KANAL_ID);
        if (!channel) return console.error('HATA: Kanal bulunamadı! KANAL_ID yanlış olabilir.');
        if (!channel.isVoiceBased()) return console.error('HATA: Verilen ID bir ses kanalı değil!');

        // ---- Player ----
        const player = createAudioPlayer({
            behaviors: { noSubscriber: NoSubscriberBehavior.Play }
        });

        let ffmpegProc = null;

        // ffmpeg'e sonsuz döngü yaptırıyoruz -> aradaki boşluk sıfır
        function play() {
            if (ffmpegProc) {
                try { ffmpegProc.kill('SIGKILL'); } catch (_) {}
                ffmpegProc = null;
            }

            ffmpegProc = spawn(ffmpegPath, [
                '-loglevel', 'error',
                '-stream_loop', '-1',   // dosyayı sonsuz tekrarla
                '-re',                  // gerçek zamanlı oku (RAM şişmesin)
                '-i', filePath,
                '-vn',
                '-f', 's16le',          // ham PCM: her ffmpeg derlemesinde çalışır
                '-ar', '48000',
                '-ac', '2',
                'pipe:1'
            ], { stdio: ['ignore', 'pipe', 'pipe'] });

            ffmpegProc.stderr.on('data', d => console.error('ffmpeg:', d.toString().trim()));
            ffmpegProc.on('error', e => console.error('ffmpeg başlatılamadı:', e.message));

            const resource = createAudioResource(ffmpegProc.stdout, {
                inputType: StreamType.Raw,
                inlineVolume: false
            });

            player.play(resource);
        }

        player.on(AudioPlayerStatus.Playing, () => console.log('>>> SES YAYINDA (sonsuz döngü)'));
        player.on(AudioPlayerStatus.Idle, () => {
            console.log('>>> Akış durdu, yeniden başlatılıyor...');
            setTimeout(play, 1000);
        });
        player.on('error', err => {
            console.error('Oynatma hatası:', err.message);
            setTimeout(play, 2000);
        });

        // ---- Bağlantı ----
        async function baglan() {
            const connection = joinVoiceChannel({
                channelId: channel.id,
                guildId: channel.guild.id,
                adapterCreator: channel.guild.voiceAdapterCreator,
                selfDeaf: false,
                selfMute: false
            });

            connection.on(VoiceConnectionStatus.Disconnected, async () => {
                console.log('>>> Bağlantı koptu, tekrar deneniyor...');
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

            // Sesi ANCAK UDP soketi hazır olduktan sonra başlat
            await entersState(connection, VoiceConnectionStatus.Ready, 30000);
            console.log('>>> UDP SOKETİ HAZIR!');

            connection.subscribe(player);
            play();
        }

        await baglan();

    } catch (err) {
        console.error('HATA OLUŞTU:', err);
    }
});

client.login(process.env.TOKEN);
