const { Client, GatewayIntentBits } = require('discord.js');
const { 
    joinVoiceChannel, 
    createAudioPlayer, 
    createAudioResource, 
    AudioPlayerStatus,
    StreamType,
    generateDependencyReport
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
    console.log("--- BĞIMLILIK RAPORU ---");
    console.log(generateDependencyReport());

    const channelId = process.env.KANAL_ID;
    
    try {
        const channel = await client.channels.fetch(channelId);
        if (!channel) return console.log("HATA: Kanal bulunamadı!");

        let filePath = path.join(__dirname, 'ses.mp3');
        if (!fs.existsSync(filePath)) {
            filePath = path.join(__dirname, 'ses.wav');
        }

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
                inlineVolume: true
            });

            if (resource.volume) {
                resource.volume.setVolume(1.0);
            }

            player.play(resource);
        }

        connection.subscribe(player);

        setTimeout(() => {
            play();
            console.log(">>> SES BAŞLATIILDI!");
        }, 1500);

        player.on(AudioPlayerStatus.Playing, () => {
            console.log(">>> [BAŞARILI] SES ŞU AN KANALDA ÇALINIYOR!");
        });

        player.on(AudioPlayerStatus.Idle, () => {
            console.log(">>> Ses bitti, tekrar çalınıyor...");
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
