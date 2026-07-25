const { Client, GatewayIntentBits } = require('discord.js');
const { 
    joinVoiceChannel, 
    createAudioPlayer, 
    createAudioResource, 
    AudioPlayerStatus,
    StreamType
} = require('@discordjs/voice');
const http = require('http');
const path = require('path');
const ffmpegPath = require('ffmpeg-static');
const { spawn } = require('child_process');

// Uptime Sunucusu
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

        const connection = joinVoiceChannel({
            channelId: channel.id,
            guildId: channel.guild.id,
            adapterCreator: channel.guild.voiceAdapterCreator,
            selfDeaf: false,
            selfMute: false
        });

        const player = createAudioPlayer();
        connection.subscribe(player);

        function play() {
            const filePath = path.join(__dirname, 'ses.wav');
            
            // FFmpeg ile ses dosyasını Discord'un istediği PCM / 48kHz formatına zorlayarak çeviriyoruz
            const ffmpegProcess = spawn(ffmpegPath, [
                '-re',
                '-i', filePath,
                '-f', 's16le',
                '-ar', '48000',
                '-ac', '2',
                'pipe:1'
            ], { stdio: ['ignore', 'pipe', 'ignore'] });

            const resource = createAudioResource(ffmpegProcess.stdout, {
                inputType: StreamType.Raw,
                inlineVolume: true
            });

            if (resource.volume) {
                resource.volume.setVolume(1.0);
            }

            player.play(resource);
            console.log(">>> SES ZORLANARAK KANALA BASILDI!");
        }

        play();

        player.on(AudioPlayerStatus.Playing, () => {
            console.log(">>> [BAŞARILI] BOT ŞU AN KANALDA SES ÇALIYOR!");
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
