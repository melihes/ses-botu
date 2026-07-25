const { Client, GatewayIntentBits } = require('discord.js');
const { 
    joinVoiceChannel, 
    createAudioPlayer, 
    createAudioResource, 
    AudioPlayerStatus,
    StreamType,
    VoiceConnectionStatus
} = require('@discordjs/voice');
const http = require('http');
const path = require('path');
const ffmpegPath = require('ffmpeg-static');

// Web sunucusu (UptimeRobot aktif tutsun diye)
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

client.once('clientReady', () => {
    console.log(`${client.user.tag} başarıyla giriş yaptı!`);
    
    const channel = client.channels.cache.get(process.env.KANAL_ID);
    if (!channel) {
        return console.error("HATA: KANAL_ID yanlış veya bot o kanalı göremiyor!");
    }

    const connection = joinVoiceChannel({
        channelId: channel.id,
        guildId: channel.guild.id,
        adapterCreator: channel.guild.voiceAdapterCreator,
        selfDeaf: false,
        selfMute: false
    });

    const player = createAudioPlayer();

    function playAudio() {
        const filePath = path.join(__dirname, 'ses.wav');
        
        const resource = createAudioResource(filePath, {
            inputType: StreamType.Arbitrary,
            ffmpegPath: ffmpegPath
        });

        player.play(resource);
    }

    // Bağlantı durumlarını loglayalım
    connection.on(VoiceConnectionStatus.Ready, () => {
        console.log("Ses kanalına bağlantı tamamlandı, ses başlatılıyor!");
        connection.subscribe(player);
        playAudio();
    });

    connection.on(VoiceConnectionStatus.Disconnected, () => {
        console.log("Sesten koptu, tekrar bağlanmaya çalışıyor...");
    });

    player.on(AudioPlayerStatus.Idle, () => {
        console.log("Ses bitti, döngü gereği tekrar çalınıyor...");
        playAudio();
    });

    player.on('error', error => {
        console.error("Oynatma Hatası:", error.message);
        setTimeout(playAudio, 1000);
    });
});

client.login(process.env.TOKEN);
