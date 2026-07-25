const { Client, GatewayIntentBits } = require('discord.js');
const { 
    joinVoiceChannel, 
    createAudioPlayer, 
    createAudioResource, 
    AudioPlayerStatus,
    StreamType,
    NoSubscriberBehavior
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
        console.log(`>>> Dosya Yolu: ${filePath} | Boyut: ${stats.size} bayt`);

        if (stats.size === 0) {
            return console.error("CRITICAL HATA: Yüklediğin ses dosyası 0 bayt (BOŞ)! Lütfen sağlam bir mp3 yükle.");
        }

        const connection = joinVoiceChannel({
            channelId: channel.id,
            guildId: channel.guild.id,
            adapterCreator: channel.guild.voiceAdapterCreator,
            selfDeaf: false,
            selfMute: false
        });

        const player = createAudioPlayer({
            behaviors: {
                noSubscriber: NoSubscriberBehavior.Play
            }
        });

        function play() {
            const resource = createAudioResource(filePath, {
                inputType: StreamType.Arbitrary,
                ffmpegPath: ffmpegPath,
                inlineVolume: false
            });

            player.play(resource);
        }

        connection.subscribe(player);
        play();

        player.on(AudioPlayerStatus.Playing, () => {
            console.log(">>> SES ÇALINIYOR...");
        });

        player.on(AudioPlayerStatus.Idle, () => {
            console.log(">>> Ses bitti, 3 saniye sonra tekrar çalacak...");
            setTimeout(play, 3000);
        });

        player.on('error', err => {
            console.error(">>> FFmpeg/Oynatma Hatası:", err.message);
            setTimeout(play, 3000);
        });

    } catch (err) {
        console.error("HATA OLUŞTU:", err);
    }
});

client.login(process.env.TOKEN);
