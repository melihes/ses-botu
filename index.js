const { Client, GatewayIntentBits } = require('discord.js');
const { 
    joinVoiceChannel, 
    createAudioPlayer, 
    createAudioResource, 
    AudioPlayerStatus,
    VoiceConnectionStatus,
    StreamType
} = require('@discordjs/voice');
const http = require('http');
const path = require('path');
const ffmpegPath = require('ffmpeg-static');

// Uptime için Web Sunucusu
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
    console.log(`[LOG] ${client.user.tag} başarıyla giriş yaptı.`);

    const channelId = process.env.KANAL_ID;
    const channel = client.channels.cache.get(channelId);

    if (!channel) {
        return console.error("[HATA] KANAL_ID bulunamadı!");
    }

    const connection = joinVoiceChannel({
        channelId: channel.id,
        guildId: channel.guild.id,
        adapterCreator: channel.guild.voiceAdapterCreator,
        selfDeaf: false,
        selfMute: false
    });

    const player = createAudioPlayer();

    function startPlayback() {
        const filePath = path.join(__dirname, 'ses.wav');
        
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

    connection.on(VoiceConnectionStatus.Ready, () => {
        console.log('[LOG] Ses kanalına bağlantı kuruldu, ses başlatılıyor...');
        connection.subscribe(player);
        startPlayback();
    });

    player.on(AudioPlayerStatus.Playing, () => {
        console.log('[BAŞARILI] Bot şu an kanalda ses çalıyor!');
    });

    player.on(AudioPlayerStatus.Idle, () => {
        console.log('[LOG] Ses bitti, tekrar başlatılıyor...');
        startPlayback();
    });

    player.on('error', (err) => {
        console.error('[HATA] Oynatma hatası:', err.message);
        setTimeout(startPlayback, 1000);
    });
});

client.login(process.env.TOKEN);
