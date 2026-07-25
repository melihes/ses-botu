const { Client, GatewayIntentBits } = require('discord.js');
const { 
    joinVoiceChannel, 
    createAudioPlayer, 
    createAudioResource, 
    AudioPlayerStatus,
    VoiceConnectionStatus,
    StreamType,
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
    
    async function connectAndPlay() {
        try {
            const channel = await client.channels.fetch(channelId);
            if (!channel) return console.log("HATA: Kanal bulunamadı!");

            let filePath = path.join(__dirname, 'ses.mp3');
            if (!fs.existsSync(filePath)) {
                filePath = path.join(__dirname, 'ses.wav');
            }

            console.log(">>> Kanala bağlantı isteği gönderiliyor...");

            const connection = joinVoiceChannel({
                channelId: channel.id,
                guildId: channel.guild.id,
                adapterCreator: channel.guild.voiceAdapterCreator,
                selfDeaf: false,
                selfMute: false
            });

            // UDP Soketinin açılmasını zorla bekliyoruz
            try {
                await entersState(connection, VoiceConnectionStatus.Ready, 10_000);
                console.log(">>> [EFSANE BAŞARI] UDP SOKETİ AÇILDI! PAKETLER İLETİLİYOR!");
            } catch (error) {
                console.log(">>> UDP Soketi kilitlendi! Bağlantı yenileniyor...");
                connection.destroy();
                setTimeout(connectAndPlay, 2000);
                return;
            }

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
            play();

            player.on(AudioPlayerStatus.Playing, () => {
                console.log(">>> [BAŞARILI] SES ŞU AN KANALDA YANAYOR!");
            });

            player.on(AudioPlayerStatus.Idle, () => {
                play();
            });

            player.on('error', err => {
                console.error(">>> Oynatma hatası:", err.message);
                play();
            });

        } catch (err) {
            console.error("HATA OLUŞTU:", err);
        }
    }

    connectAndPlay();
});

client.login(process.env.TOKEN);
