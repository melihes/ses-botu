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

// Uptime için sunucu
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

client.on('ready', async () => {
    console.log(`>>> BOT AKTİF: ${client.user.tag}`);
    
    const channelId = process.env.KANAL_ID;
    
    try {
        const channel = await client.channels.fetch(channelId);
        if (!channel) return console.log("HATA: Kanal bulunamadı!");

        console.log(`>>> KANALA BAĞLANILIYOR: ${channel.name}`);

        const connection = joinVoiceChannel({
            channelId: channel.id,
            guildId: channel.guild.id,
            adapterCreator: channel.guild.voiceAdapterCreator,
            selfDeaf: false,
            selfMute: false
        });

        // Bağlantının kurulmasını zorla bekle
        try {
            await entersState(connection, VoiceConnectionStatus.Ready, 20_000);
            console.log(">>> SES BAĞLANTISI HAZIR!");
        } catch (e) {
            console.log(">>> Bağlantı zaman aşımına uğradı ama oynatma zorlanıyor...");
        }

        const player = createAudioPlayer();

        function play() {
            const filePath = path.join(__dirname, 'ses.wav');
            const resource = createAudioResource(filePath, {
                inputType: StreamType.Arbitrary,
                ffmpegPath: ffmpegPath
            });

            player.play(resource);
        }

        connection.subscribe(player);
        play();

        player.on(AudioPlayerStatus.Playing, () => {
            console.log(">>> [BAŞARILI] SES ŞU AN KANALDA ÇALIYOR!");
        });

        player.on(AudioPlayerStatus.Idle, () => {
            play();
        });

        player.on('error', err => {
            console.error("Oynatma hatası:", err);
            setTimeout(play, 1000);
        });

    } catch (err) {
        console.error("HATA OLUŞTU:", err);
    }
});

client.login(process.env.TOKEN);
