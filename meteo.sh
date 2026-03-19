#!/bin/bash

# ─── Configuração ────────────────────────────────────────────────
LOCAL_PADRAO="Santarem"
API="https://api.ipma.pt/open-data"

descricao_tempo() {
    case $1 in
        1)  echo "☀️  Céu limpo" ;;
        2)  echo "🌤  Céu pouco nublado" ;;
        3)  echo "⛅  Céu parcialmente nublado" ;;
        4)  echo "🌥  Céu muito nublado" ;;
        5)  echo "☁️  Céu nublado" ;;
        6)  echo "🌦  Aguaceiros" ;;
        7)  echo "🌧  Aguaceiros frequentes" ;;
        8)  echo "🌨  Aguaceiros com trovoada" ;;
        9)  echo "⛈️  Trovoada" ;;
        10) echo "🌫  Nevoeiro" ;;
        11) echo "🌧  Chuva fraca" ;;
        12) echo "🌧  Chuva" ;;
        13) echo "🌧  Chuva forte" ;;
        14) echo "❄️  Neve fraca" ;;
        15) echo "❄️  Neve" ;;
        16) echo "🌩  Aguaceiros com granizo" ;;
        *)  echo "🌡  Tipo $1" ;;
    esac
}

descricao_vento() {
    case $1 in
        1) echo "fraco (<15 km/h)" ;;
        2) echo "moderado (15-35 km/h)" ;;
        3) echo "forte (35-55 km/h)" ;;
        4) echo "muito forte (>55 km/h)" ;;
        *) echo "classe $1" ;;
    esac
}

# Remove acentos para comparação
sem_acentos() {
    echo "$1" | iconv -f utf-8 -t ascii//TRANSLIT 2>/dev/null || echo "$1"
}

PESQUISA="${1:-$LOCAL_PADRAO}"

for cmd in curl jq; do
    if ! command -v $cmd &>/dev/null; then
        echo "Erro: '$cmd' não está instalado. Instala com: sudo apt install $cmd"
        exit 1
    fi
done

LOCALIDADES=$(curl -s "$API/distrits-islands.json")

# Procura com e sem acentos
PESQUISA_NORM=$(sem_acentos "$PESQUISA" | tr '[:upper:]' '[:lower:]')

ID=$(echo "$LOCALIDADES" | jq -r '.data[] | "\(.globalIdLocal) \(.local)"' | while read -r id nome; do
    nome_norm=$(sem_acentos "$nome" | tr '[:upper:]' '[:lower:]')
    if [[ "$nome_norm" == *"$PESQUISA_NORM"* ]]; then
        echo "$id"
        break
    fi
done | head -1)

NOME=$(echo "$LOCALIDADES" | jq -r '.data[] | "\(.globalIdLocal) \(.local)"' | while read -r id nome; do
    nome_norm=$(sem_acentos "$nome" | tr '[:upper:]' '[:lower:]')
    if [[ "$nome_norm" == *"$PESQUISA_NORM"* ]]; then
        echo "$nome"
        break
    fi
done | head -1)

if [ -z "$ID" ]; then
    echo "Local '$PESQUISA' não encontrado. Locais disponíveis:"
    echo "$LOCALIDADES" | jq -r '.data[].local' | sort
    exit 1
fi

echo ""
echo "╔══════════════════════════════════════════════════╗"
printf "║  🌍 Previsão para: %-29s║\n" "$NOME"
echo "╚══════════════════════════════════════════════════╝"

# ─── Previsão horária (hoje) ──────────────────────────────────────
HORARIA=$(curl -s "$API/forecast/meteorology/cities/hourly/hp-$ID-hourly.json")

echo ""
echo "┌─────────────────────────────────────────────────┐"
echo "│  ⏱  HOJE — Próximas horas                       │"
echo "└─────────────────────────────────────────────────┘"

HOJE=$(date -u +"%Y-%m-%dT")

if echo "$HORARIA" | jq -e '.data' &>/dev/null; then
    RESULTADO=$(echo "$HORARIA" | jq -r \
        --arg hoje "$HOJE" \
        '.data[] | select(.forecastDate | startswith($hoje)) |
        "  \(.forecastDate | split("T")[1] | split(":")[0])h — \(.tMed)°C  💧\(.precipitaProb)%  💨\(.predWindDir)"' \
        2>/dev/null | head -12)
    [ -n "$RESULTADO" ] && echo "$RESULTADO" || echo "  (sem dados para hoje)"
else
    echo "  (dados horários indisponíveis)"
fi

# ─── Previsão diária (3 dias) ─────────────────────────────────────
DIARIA=$(curl -s "$API/forecast/meteorology/cities/daily/hp-$ID-daily.json")

echo ""
echo "┌─────────────────────────────────────────────────┐"
echo "│  📅 PRÓXIMOS 3 DIAS                             │"
echo "└─────────────────────────────────────────────────┘"

if echo "$DIARIA" | jq -e '.data' &>/dev/null; then
    echo "$DIARIA" | jq -c '.data[0:3][]' | while read -r dia; do
        DATA=$(echo "$dia" | jq -r '.forecastDate')
        TMIN=$(echo "$dia" | jq -r '.tMin')
        TMAX=$(echo "$dia" | jq -r '.tMax')
        CHUVA=$(echo "$dia" | jq -r '.precipitaProb')
        TIPO=$(echo "$dia" | jq -r '.idWeatherType')
        VENTO_DIR=$(echo "$dia" | jq -r '.predWindDir')
        VENTO_INT=$(echo "$dia" | jq -r '.classWindSpeed')
        DESC=$(descricao_tempo "$TIPO")
        VDESC=$(descricao_vento "$VENTO_INT")

        echo ""
        echo "  📆 $DATA"
        echo "     $DESC"
        echo "     🌡  $TMIN°C — $TMAX°C   💧 Chuva: $CHUVA%"
        echo "     💨  Vento $VDESC de $VENTO_DIR"
    done
else
    echo "  (dados diários indisponíveis)"
fi

echo ""
