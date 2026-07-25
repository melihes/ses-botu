const { Client, GatewayIntentBits } = require('discord.js');
const { 
    joinVoiceChannel, 
    createAudioPlayer, 
    createAudioResource, 
    AudioPlayerStatus,
    VoiceConnectionStatus,
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

        console.log(`>>> Oynatılacak Dosya Bulundu: ${filePath}`);

        const connection = joinVoiceChannel({
            channelId: channel.id,
            guildId: channel.guild.id,
            adapterCreator: channel.guild.voiceAdapterCreator,
            selfDeaf: false,
            selfMute: false,
            group: client.user.id
        });

        const player = createAudioPlayer({
            behaviors: {
                noSubscriber: NoSubscriberBehavior.Play
            }
        });

        function play() {
            // Volume modunu false yaparak işlemci karmakarışık ses işleme katmanını atlayıp doğrudan FFmpeg akışı basıyoruz
            const resource = createAudioResource(filePath, {
                inputType: StreamType.Arbitrary,
                ffmpegPath: ffmpegPath,
                inlineVolume: false 
            });

            player.play(resource);
        }

        connection.subscribe(player);

        // Bağlantı koparsa veya kurulursa dinle
        connection.on(VoiceConnectionStatus.Ready, () => {
            console.log(">>> [BAĞLANTI BAŞARILI] Discord UDP Bağlantısı Kuruldu!");
        });

        // Oynatmayı doğrudan başlat
        play();

        player.on(AudioPlayerStatus.Playing, () => {
            console.log(">>> [BAŞARILI] Sinyal gönderiliyor, ses çalıyor!");
        });

        player.on(AudioPlayerStatus.Idle, () => {
            console.log(">>> Ses bitti, başa sarılıyor...");
            play();
        });

        player.on('error', err => {
            console.error(">>> Oynatma hatası:", err.message);
            setTimeout(play, 1000);
        });

    } catch (err) {
        console.error("HATA OLUŞTU:", err);
    }
});

client.login(process.env.TOKEN);
