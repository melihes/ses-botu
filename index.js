const { Client, GatewayIntentBits } = require('discord.js');
const { 
    joinVoiceChannel, 
    createAudioPlayer, 
    createAudioResource, 
    AudioPlayerStatus,
    NoSubscriberBehavior
} = require('@discordjs/voice');
const http = require('http');
const path = require('path');
const ffmpeg = require('ffmpeg-static');

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

client.once('clientReady', () => {
    console.log(`${client.user.tag} sese bağlandı!`);
    
    const channel = client.channels.cache.get(process.env.KANAL_ID);
    if (channel) {
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

        function playAudio() {
            // Yüklediğin ses dosyasının adı
            const filePath = path.join(__dirname, 'ses.mp3');
            
            const resource = createAudioResource(filePath, {
                inputType: require('@discordjs/voice').StreamType.Arbitrary,
                ffmpegPath: ffmpeg
            });

            player.play(resource);
        }

        player.on(AudioPlayerStatus.Idle, () => {
            console.log('Ses bitti, tekrar başlatılıyor...');
            playAudio();
        });

        player.on('error', error => {
            console.error('Ses hatası:', error.message);
            setTimeout(playAudio, 2000);
        });

        connection.subscribe(player);
        playAudio();
    }
});

client.login(process.env.TOKEN);
