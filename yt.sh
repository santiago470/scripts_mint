#!/bin/bash

# Verificar se yt-dlp está instalado
if ! command -v yt-dlp &> /dev/null; then
    echo "yt-dlp nao esta instalado. A instalar..."
    sudo wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -O /usr/local/bin/yt-dlp
    sudo chmod +x /usr/local/bin/yt-dlp
fi

# Pedir URL
read -p "URL do video/playlist: " URL

if [ -z "$URL" ]; then
    echo "Nenhum URL introduzido. A sair."
    exit 1
fi

# Tipo de download
echo ""
echo "1) Video (mp4)"
echo "2) So audio/musica (mp3)"
echo "3) Playlist (mp4)"
echo "4) Playlist (so audio mp3)"
read -p "Escolha [1-4]: " OPCAO

# Qualidade (apenas para video)
if [[ "$OPCAO" == "1" || "$OPCAO" == "3" ]]; then
    echo ""
    echo "Qualidade:"
    echo "1) Melhor qualidade"
    echo "2) 1080p"
    echo "3) 720p"
    echo "4) 480p"
    read -p "Escolha [1-4]: " QUALIDADE

    case $QUALIDADE in
        1) FORMAT="bestvideo+bestaudio/best" ;;
        2) FORMAT="bestvideo[height<=1080]+bestaudio/best[height<=1080]" ;;
        3) FORMAT="bestvideo[height<=720]+bestaudio/best[height<=720]" ;;
        4) FORMAT="bestvideo[height<=480]+bestaudio/best[height<=480]" ;;
        *) FORMAT="bestvideo+bestaudio/best" ;;
    esac
fi

mkdir -p ~/Vídeos
mkdir -p ~/Música

case $OPCAO in
    1)
        yt-dlp -f "$FORMAT" --merge-output-format mp4 -o "$HOME/Vídeos/%(title)s.%(ext)s" "$URL"
        echo "Video guardado em ~/Vídeos"
        ;;
    2)
        yt-dlp -x --audio-format mp3 -o "$HOME/Música/%(title)s.%(ext)s" "$URL"
        echo "Musica guardada em ~/Música"
        ;;
    3)
        yt-dlp -f "$FORMAT" --merge-output-format mp4 -o "$HOME/Vídeos/%(playlist)s/%(title)s.%(ext)s" "$URL"
        echo "Playlist guardada em ~/Vídeos"
        ;;
    4)
        yt-dlp -x --audio-format mp3 -o "$HOME/Música/%(playlist)s/%(title)s.%(ext)s" "$URL"
        echo "Playlist guardada em ~/Música"
        ;;
    *)
        echo "Opcao invalida."
        exit 1
        ;;
esac
