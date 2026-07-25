const { Client, GatewayIntentBits } = require('discord.js');
const { 
    joinVoiceChannel, 
    createAudioPlayer, 
    createAudioResource, 
    AudioPlayerStatus,
    StreamType,
    VoiceConnectionStatus,
    entersState
} = require('@discordjs/voice');
const http = require('http');
const path = require('path');
const ffmpegPath = require('ffmpeg-static');
const fs = require('fs');

http.createServer((req, res) => {
    res.write("Bot 7/24 Aktif!");
    res.end();
}).listen(process.env.PORT || 3000);

const client = new Client({
    intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildVoiceStates
    ]
});

client.on('clientReady', async () => {
    console.log(`>>> BOT AKTİF: ${client.user.tag}`);

    const channelId = process.env.KANAL_ID;
    
    try {
        const channel = await client.channels.fetch(channelId);
        if (!channel) return console.log("HATA: Kanal bulunamadı!");

        let filePath = path.join(__dirname, 'ses.mp3');
        if (!fs.existsSync(filePath)) {
            filePath = path.join(__dirname, 'ses.wav');
        }

        const stats = fs.statSync(filePath);
        console.log(`>>> Yüklenen Dosya Boyutu: ${(stats.size / 1024 / 1024).toFixed(2)} MB`);

        const connection = joinVoiceChannel({
            channelId: channel.id,
            guildId: channel.guild.id,
            adapterCreator: channel.guild.voiceAdapterCreator,
            selfDeaf: false,
            selfMute: false
        });

        const player = createAudioPlayer();

        function play() {
            const resource = createAudioResource(filePath, {
                inputType: StreamType.Arbitrary,
                ffmpegPath: ffmpegPath,
                inlineVolume: false
            });

            player.play(resource);
        }

        connection.subscribe(player);

        // Discord UDP Soketine Zorlama Pingi İletiyoruz
        connection.on(VoiceConnectionStatus.Ready, () => {
            console.log(">>> UDP SOKETİ TAM KİLİTLENDİ!");
        });

        // 1.5 saniye arayla kanala paket basmayı dene (Soket açma hamlesi)
        setTimeout(play, 1000);
        setTimeout(play, 2500);

        player.on(AudioPlayerStatus.Playing, () => {
            console.log(">>> [SON DÜZELTME] SES YAYINDA!");
        });

        player.on(AudioPlayerStatus.Idle, () => {
            play();
        });

        player.on('error', err => {
            console.error("Oynatma hatası:", err.message);
            play();
        });

    } catch (err) {
        console.error("HATA OLUŞTU:", err);
    }
});

client.login(process.env.TOKEN);
