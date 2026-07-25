const { Client, GatewayIntentBits } = require('discord.js');
const { 
    joinVoiceChannel, 
    createAudioPlayer, 
    createAudioResource, 
    AudioPlayerStatus 
} = require('@discordjs/voice');
const http = require('http');
const path = require('path');

// UptimeRobot / Web sunucusu ayarı (Uykuyu engellemek için)
http.createServer((req, res) => {
    res.write("Bot 7/24 Aktif!");
    res.end();
}).listen(process.env.PORT || 3000);

const client = new Client({
    intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildVoiceStates]
});

// ready yerine güncel clientReady olayı kullanıldı
client.once('clientReady', () => {
    console.log(`${client.user.tag} sese bağlandı!`);
    
    const channel = client.channels.cache.get(process.env.KANAL_ID);
    if (channel) {
        // Ses kanalına bağlan
        const connection = joinVoiceChannel({
            channelId: channel.id,
            guildId: channel.guild.id,
            adapterCreator: channel.guild.voiceAdapterCreator,
            selfDeaf: false
        });

        // Ses çalıcıyı oluştur
        const player = createAudioPlayer();

        // Ses oynatma fonksiyonu
        function playAudio() {
            // "ses.mp3" dosyasının adını GitHub'a yükleyeceğin dosya adı ile aynı yapmalısın
            const resource = createAudioResource(path.join(__dirname, 'ses.mp3'));
            player.play(resource);
        }

        // Ses bittiğinde tekrar başlat (Sonsuz Döngü)
        player.on(AudioPlayerStatus.Idle, () => {
            playAudio();
        });

        // Olası ses hatalarında botun çökmemesi ve tekrar denemesi için
        player.on('error', error => {
            console.error('Ses oynatılırken bir hata oluştu:', error);
            playAudio();
        });

        // Çalıcıyı kanala bağla ve ilk sesi başlat
        connection.subscribe(player);
        playAudio();
    }
});

client.login(process.env.TOKEN);
