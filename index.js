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

// UptimeRobot web sunucusu
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

client.once('clientReady', async () => {
    console.log(`${client.user.tag} sese bağlandı!`);
    
    const channel = client.channels.cache.get(process.env.KANAL_ID);
    if (!channel) return console.log("Kanal bulunamadı!");

    const connection = joinVoiceChannel({
        channelId: channel.id,
        guildId: channel.guild.id,
        adapterCreator: channel.guild.voiceAdapterCreator,
        selfDeaf: false,
        selfMute: false
    });

    try {
        // Ses kanalına bağlantının tamamen kurulmasını bekle
        await entersState(connection, VoiceConnectionStatus.Ready, 20_000);
        
        const player = createAudioPlayer();

        function playAudio() {
            // Yüklediğin ses dosyasının tam adı (ses.wav / ses.mp3)
            const filePath = path.join(__dirname, 'ses.wav'); 
            
            const resource = createAudioResource(filePath, {
                inputType: StreamType.Arbitrary,
                ffmpegPath: ffmpegPath,
                inlineVolume: true
            });

            // Ses seviyesini garantiye al
            if (resource.volume) {
                resource.volume.setVolume(1.0);
            }

            player.play(resource);
        }

        player.on(AudioPlayerStatus.Idle, () => {
            console.log('Ses bitti, tekrar oynatılıyor...');
            playAudio();
        });

        player.on('error', error => {
            console.error('Ses hatası:', error.message);
            setTimeout(playAudio, 1000);
        });

        connection.subscribe(player);
        playAudio();
        console.log("Ses oynatılmaya başladı!");

    } catch (error) {
        console.error("Sese bağlanırken hata oluştu:", error);
    }
});

client.login(process.env.TOKEN);
