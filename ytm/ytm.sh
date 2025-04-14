#!/usr/bin/env bash

# Franklin Souza
# @frannksz
# Script to download music and videos from YouTube

# ===============================
# VERIFICAÇÃO DE DEPENDÊNCIAS
# ===============================
dependencias=(yt-dlp fzf mpv lolcat canberra-gtk-play notify-send)

verificar_dependencias() {
    faltando=()

    for cmd in "${dependencias[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            faltando+=("$cmd")
        fi
    done

    if [ ${#faltando[@]} -gt 0 ]; then
        echo "❗ Dependências faltando: ${faltando[*]}"
        echo "Deseja que o script tente instalar para você?"
        select resp in "Sim" "Não"; do
            case "$resp" in
                Sim)
                    echo "Qual é a sua distro?"
                    select distro in "Arch-based (pacman)" "Debian/Ubuntu (apt)" "Fedora (dnf)"; do
                        case "$distro" in
                            "Arch-based (pacman)")
                                sudo pacman -Sy --needed "${faltando[@]}"
                                break
                                ;;
                            "Debian/Ubuntu (apt)")
                                sudo apt update && sudo apt install -y "${faltando[@]}"
                                break
                                ;;
                            "Fedora (dnf)")
                                sudo dnf install -y "${faltando[@]}"
                                break
                                ;;
                            *) echo "Escolha inválida." ;;
                        esac
                    done
                    break
                    ;;
                Não)
                    echo "⚠️ Instale manualmente e rode o script novamente."
                    exit 1
                    ;;
                *) echo "Escolha inválida." ;;
            esac
        done
    fi
}

verificar_dependencias

# ===============================
# CONFIG
# ===============================
MUSICA_DIR="$HOME/Music"
VIDEO_DIR="$HOME/Videos"

# 🔔 Notificação com som (dunst + canberra)
notificar() {
    notify-send "$1" "$2"
    canberra-gtk-play --id="message-new-instant" --description="$1" &
}

# Pasta destino
escolher_pasta_destino() {
    local base_dir="$1"
    local prompt="$2"

    tipo=$(printf "[Nova] Criar nova pasta\n[Existente] Usar pasta existente" | \
        fzf --prompt="📁 Pasta destino: " --height=10 --no-header) || return 1

    case "$tipo" in
        "[Nova]"*)
            read -rp "🆕 Nome da nova pasta: " nova
            [[ -z "$nova" ]] && return 1

            destino="$base_dir/$nova"
            mkdir -p "$destino"
            ;;
        "[Existente]"*)
            opcoes=$(find "$base_dir" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
            pasta=$(printf "%s\n" $opcoes | fzf --prompt="$prompt" --height=15) || return 1
            destino="$base_dir/$pasta"
            ;;
        *) return 1 ;;
    esac

    echo "$destino"
}

# Baixar música
baixar_musica() {
    read -rp "🔍 Buscar por: " termo
    [[ -z "$termo" ]] && return

    selecionado=$(yt-dlp "ytsearch10:$termo" --print "%(title).80s | %(duration)s | %(uploader)s | %(webpage_url)s" 2>/dev/null | \
                  fzf --prompt="🎵 Escolha uma música: " --height=15) || return
    [[ -z "$selecionado" ]] && return

    url=$(echo "$selecionado" | awk -F ' | ' '{print $NF}')
    destino=$(escolher_pasta_destino "$MUSICA_DIR" "🎼 Pasta de músicas: ") || return

    echo "📥 Baixando para: $destino"

    yt-dlp "$url" \
        --extract-audio \
        --audio-format mp3 \
        --embed-thumbnail \
        --add-metadata \
        --output "$destino/%(title)s.%(ext)s" \
        --no-playlist

    echo "✅ Música baixada!"
    notificar "Download concluído 🎵" "Música salva em: $destino"
    read -n 1 -s -r -p "▶ Pressione qualquer tecla para voltar ao menu..."
}

# Baixar playlist
baixar_playlist() {
    read -rp "📂 URL da playlist do YouTube: " url
    [[ -z "$url" ]] && return

    destino=$(escolher_pasta_destino "$MUSICA_DIR" "🎼 Pasta de músicas: ") || return

    echo "📥 Baixando playlist para: $destino"

    yt-dlp "$url" \
        --yes-playlist \
        --extract-audio \
        --audio-format mp3 \
        --embed-thumbnail \
        --add-metadata \
        --output "$destino/%(playlist_index)s - %(title)s.%(ext)s"

    echo "✅ Playlist baixada!"
    notificar "Playlist concluída 🎶" "Arquivos salvos em: $destino"
    read -n 1 -s -r -p "▶ Pressione qualquer tecla para voltar ao menu..."
}

# Baixar vídeo (máx. 1080p)
baixar_video() {
    read -rp "🔍 Buscar por: " termo
    [[ -z "$termo" ]] && return

    selecionado=$(yt-dlp "ytsearch10:$termo" --print "%(title).80s | %(duration)s | %(uploader)s | %(webpage_url)s" 2>/dev/null | \
                  fzf --prompt="🎬 Escolha um vídeo: " --height=15) || return
    [[ -z "$selecionado" ]] && return

    url=$(echo "$selecionado" | awk -F ' | ' '{print $NF}')
    destino=$(escolher_pasta_destino "$VIDEO_DIR" "📁 Pasta de vídeos: ") || return

    echo "📥 Baixando vídeo (máx. 1080p) para: $destino"

    yt-dlp "$url" \
        -f "bestvideo[height<=1080]+bestaudio/best[height<=1080]" \
        --embed-metadata \
        --merge-output-format mp4 \
        --output "$destino/%(title)s.%(ext)s"

    echo "✅ Vídeo baixado!"
    notificar "Download concluído 🎬" "Vídeo salvo em: $destino"
    read -n 1 -s -r -p "▶ Pressione qualquer tecla para voltar ao menu..."
}

# Tocar música
tocar_musica() {
    pasta=$(find "$MUSICA_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | fzf --prompt="🎧 Pasta: ") || return
    [[ -z "$pasta" ]] && return

    musica=$(find "$MUSICA_DIR/$pasta" -type f -iname "*.mp3" | fzf --prompt="🎶 Música: ") || return
    [[ -z "$musica" ]] && return

    echo "🎵 Tocando: $(basename "$musica")"
    mpv --no-audio-display "$musica"
}

# Assistir vídeo
assistir_video() {
    pasta=$(find "$VIDEO_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | fzf --prompt="🎞️ Pasta de vídeos: ") || return
    [[ -z "$pasta" ]] && return

    video=$(find "$VIDEO_DIR/$pasta" -type f \( -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mkv" \) | fzf --prompt="🎬 Escolha o vídeo: ") || return
    [[ -z "$video" ]] && return

    echo "🎥 Assistindo: $(basename "$video")"
    mpv "$video"
}

# Remover arquivo
remover_arquivo() {
    tipo=$(printf "🎵 Música\n🎬 Vídeo" | fzf --prompt="🗑️ Tipo de mídia: ") || return
    [[ -z "$tipo" ]] && return

    if [[ "$tipo" == "🎵 Música" ]]; then
        base="$MUSICA_DIR"
        filtro="-iname *.mp3"
    else
        base="$VIDEO_DIR"
        filtro="-iname *.mp4 -o -iname *.webm -o -iname *.mkv"
    fi

    pasta=$(find "$base" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | fzf --prompt="🗂️ Pasta: ") || return
    [[ -z "$pasta" ]] && return

    arquivo=$(find "$base/$pasta" -type f \( $filtro \) | fzf --prompt="🗑️ Arquivo a remover: ") || return
    [[ -z "$arquivo" ]] && return

    rm -i "$arquivo"
    read -n 1 -s -r -p "▶ Pressione qualquer tecla para voltar ao menu..."
}

# Listar músicas
listar_musicas() {
    pasta=$(find "$MUSICA_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | fzf --prompt="🎵 Pasta de músicas: ") || return
    [[ -z "$pasta" ]] && return

    echo "🎶 Músicas em '$pasta':"
    find "$MUSICA_DIR/$pasta" -type f -iname "*.mp3" -exec basename {} \; | less
}

# Listar vídeos
listar_videos() {
    pasta=$(find "$VIDEO_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | fzf --prompt="🎥 Pasta de vídeos: ") || return
    [[ -z "$pasta" ]] && return

    echo "📹 Vídeos em '$pasta':"
    find "$VIDEO_DIR/$pasta" -type f \( -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mkv" \) -exec basename {} \; | less
}

# Menu principal
menu() {
    while true; do
        clear

        cores=('\e[31m' '\e[32m' '\e[33m' '\e[34m' '\e[35m' '\e[36m')
        cor_random="${cores[$((RANDOM % ${#cores[@]}))]}"

        echo -e "$cor_random╔════════════════════════════════════╗\e[0m" | lolcat
        echo -e "$cor_random║  🔴 YouTube Downloader Manager     ║\e[0m" | lolcat
        echo -e "$cor_random╚════════════════════════════════════╝\e[0m" | lolcat
        echo "🎛️ Selecione uma opção:"

        opcao=$(printf "🚪 Sair\n❌ Remover música/vídeo\n📃 Listar vídeos\n📜 Listar músicas\n🎞️ Assistir vídeo\n🎬 Baixar vídeo\n📂 Baixar playlist\n📥 Baixar música\n🎧 Ouvir música" | \
                fzf --prompt="🎛️ Menu: " --height=12 --no-header) || continue

        [[ -z "$opcao" ]] && continue

        case "$opcao" in
            "🎧 Ouvir música") tocar_musica ;;
            "📥 Baixar música") baixar_musica ;;
            "📂 Baixar playlist") baixar_playlist ;;
            "🎬 Baixar vídeo") baixar_video ;;
            "🎞️ Assistir vídeo") assistir_video ;;
            "📜 Listar músicas") listar_musicas ;;
            "📃 Listar vídeos") listar_videos ;;
            "❌ Remover música/vídeo") remover_arquivo ;;
            "🚪 Sair") break ;;
            *) echo "❌ Opção inválida." ;;
        esac
        echo ""
    done
}

# Executar
mkdir -p "$MUSICA_DIR" "$VIDEO_DIR"
menu
clear
