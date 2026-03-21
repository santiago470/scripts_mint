#!/usr/bin/env bash
# ╔══════════════════════════════════════════╗
# ║        SPEEDTEST VISUAL - by snats       ║
# ╚══════════════════════════════════════════╝

# Força ponto como separador decimal (evita erros com locale pt_PT)
export LC_NUMERIC=C
export LC_ALL=C

# ── Colors & Styles ──────────────────────────────────────────────────────────
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

BLACK='\033[30m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[37m'

BG_BLACK='\033[40m'
BG_BLUE='\033[44m'
BG_CYAN='\033[46m'

BRIGHT_GREEN='\033[92m'
BRIGHT_YELLOW='\033[93m'
BRIGHT_BLUE='\033[94m'
BRIGHT_MAGENTA='\033[95m'
BRIGHT_CYAN='\033[96m'
BRIGHT_WHITE='\033[97m'

# ── Check dependencies ────────────────────────────────────────────────────────
check_deps() {
    if ! command -v speedtest-cli &>/dev/null; then
        echo -e "${RED}✗ speedtest-cli não encontrado.${RESET}"
        echo -e "  Instala com: ${YELLOW}pip install speedtest-cli${RESET} ou ${YELLOW}sudo apt install speedtest-cli${RESET}"
        exit 1
    fi
    if ! command -v bc &>/dev/null; then
        echo -e "${RED}✗ bc não encontrado.${RESET} Instala com: ${YELLOW}sudo apt install bc${RESET}"
        exit 1
    fi
}

# ── Terminal width ─────────────────────────────────────────────────────────────
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
BAR_MAX=50

# ── Header ────────────────────────────────────────────────────────────────────
print_header() {
    clear
    echo ""
    echo -e "${BOLD}${BRIGHT_CYAN}"
    echo "  ███████╗██████╗ ███████╗███████╗██████╗ ████████╗███████╗███████╗████████╗"
    echo "  ██╔════╝██╔══██╗██╔════╝██╔════╝██╔══██╗╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝"
    echo "  ███████╗██████╔╝█████╗  █████╗  ██║  ██║   ██║   █████╗  ███████╗   ██║   "
    echo "  ╚════██║██╔═══╝ ██╔══╝  ██╔══╝  ██║  ██║   ██║   ██╔══╝  ╚════██║   ██║   "
    echo "  ███████║██║     ███████╗███████╗██████╔╝   ██║   ███████╗███████║   ██║   "
    echo "  ╚══════╝╚═╝     ╚══════╝╚══════╝╚═════╝    ╚═╝   ╚══════╝╚══════╝   ╚═╝   "
    echo -e "${RESET}"
    echo -e "  ${DIM}${BRIGHT_BLUE}Visual Network Speed Test  •  $(date '+%d/%m/%Y %H:%M:%S')${RESET}"
    echo ""
    printf "  ${DIM}%.0s─${RESET}" $(seq 1 $((TERM_WIDTH - 4)))
    echo ""
}

# ── Spinner ───────────────────────────────────────────────────────────────────
SPINNER_CHARS=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
spin_pid=""

start_spinner() {
    local msg="$1"
    local color="${2:-$BRIGHT_CYAN}"
    (
        local i=0
        while true; do
            printf "\r  ${color}${SPINNER_CHARS[$i]}${RESET}  %s   " "$msg"
            i=$(( (i + 1) % 10 ))
            sleep 0.08
        done
    ) &
    spin_pid=$!
}

stop_spinner() {
    if [[ -n "$spin_pid" ]]; then
        kill "$spin_pid" 2>/dev/null
        wait "$spin_pid" 2>/dev/null
        spin_pid=""
        printf "\r\033[2K"
    fi
}

# ── Progress bar ──────────────────────────────────────────────────────────────
# draw_bar VALUE MAX COLOR LABEL UNIT
draw_bar() {
    local value="$1"
    local max="$2"
    local color="$3"
    local label="$4"
    local unit="$5"

    # Clamp
    local pct
    pct=$(echo "scale=2; $value / $max * 100" | bc 2>/dev/null || echo "0")
    local filled
    filled=$(echo "scale=0; $value * $BAR_MAX / $max" | bc 2>/dev/null || echo "0")
    [[ $filled -gt $BAR_MAX ]] && filled=$BAR_MAX
    local empty=$(( BAR_MAX - filled ))

    local bar_filled=""
    local bar_empty=""
    for ((i=0; i<filled; i++)); do bar_filled+="█"; done
    for ((i=0; i<empty; i++)); do bar_empty+="░"; done

    # Color grade
    local grade_color
    if (( $(echo "$pct >= 80" | bc -l) )); then
        grade_color="${BRIGHT_GREEN}"
    elif (( $(echo "$pct >= 50" | bc -l) )); then
        grade_color="${BRIGHT_YELLOW}"
    elif (( $(echo "$pct >= 25" | bc -l) )); then
        grade_color="${YELLOW}"
    else
        grade_color="${RED}"
    fi

    printf "  ${BOLD}${BRIGHT_WHITE}%-12s${RESET} " "$label"
    printf "${color}${bar_filled}${DIM}${bar_empty}${RESET}"
    printf "  ${BOLD}${grade_color}%7.2f ${unit}${RESET}"
    printf "  ${DIM}(%.0f%%)${RESET}\n" "$pct"
}

# ── Animated bar (fills up gradually) ────────────────────────────────────────
animated_bar() {
    local value="$1"
    local max="$2"
    local color="$3"
    local label="$4"
    local unit="$5"

    local target_fill
    target_fill=$(echo "scale=0; $value * $BAR_MAX / $max" | bc 2>/dev/null || echo "0")
    [[ $target_fill -gt $BAR_MAX ]] && target_fill=$BAR_MAX

    for ((f=0; f<=target_fill; f++)); do
        local empty=$(( BAR_MAX - f ))
        local bar_filled=""
        local bar_empty=""
        for ((i=0; i<f; i++)); do bar_filled+="█"; done
        for ((i=0; i<empty; i++)); do bar_empty+="░"; done

        local cur_val
        cur_val=$(echo "scale=2; $f * $max / $BAR_MAX" | bc 2>/dev/null || echo "0")

        printf "\r  ${BOLD}${BRIGHT_WHITE}%-12s${RESET} ${color}${bar_filled}${DIM}${bar_empty}${RESET}  ${BOLD}${color}%7.2f ${unit}${RESET}   " "$label" "$cur_val"
        sleep 0.02
    done

    # Final with grade color
    local pct
    pct=$(echo "scale=2; $value / $max * 100" | bc 2>/dev/null || echo "0")
    local grade_color
    if (( $(echo "$pct >= 80" | bc -l) )); then
        grade_color="${BRIGHT_GREEN}"
    elif (( $(echo "$pct >= 50" | bc -l) )); then
        grade_color="${BRIGHT_YELLOW}"
    elif (( $(echo "$pct >= 25" | bc -l) )); then
        grade_color="${YELLOW}"
    else
        grade_color="${RED}"
    fi

    local bar_filled=""
    for ((i=0; i<target_fill; i++)); do bar_filled+="█"; done
    local empty=$(( BAR_MAX - target_fill ))
    local bar_empty=""
    for ((i=0; i<empty; i++)); do bar_empty+="░"; done

    printf "\r  ${BOLD}${BRIGHT_WHITE}%-12s${RESET} ${color}${bar_filled}${DIM}${bar_empty}${RESET}  ${BOLD}${grade_color}%7.2f ${unit}${RESET}  ${DIM}(%.0f%%)${RESET}\n" \
        "$label" "$value" "$pct"
}

# ── Mini sparkline from history ───────────────────────────────────────────────
# Not used in single-run mode, but available for future
sparkline() {
    local -a vals=("$@")
    local chars=(' ' '▁' '▂' '▃' '▄' '▅' '▆' '▇' '█')
    local max=0
    for v in "${vals[@]}"; do
        (( $(echo "$v > $max" | bc -l) )) && max=$v
    done
    [[ $max == 0 ]] && max=1
    local line=""
    for v in "${vals[@]}"; do
        local idx
        idx=$(echo "scale=0; $v / $max * 8" | bc 2>/dev/null || echo 0)
        [[ $idx -gt 8 ]] && idx=8
        line+="${chars[$idx]}"
    done
    echo "$line"
}

# ── Quality rating ────────────────────────────────────────────────────────────
rate_connection() {
    local dl="$1"  # Mbit/s
    local ul="$2"
    local ping="$3"

    local dl_score ul_score ping_score

    # Download score (out of 10)
    if (( $(echo "$dl >= 500" | bc -l) )); then dl_score=10
    elif (( $(echo "$dl >= 200" | bc -l) )); then dl_score=9
    elif (( $(echo "$dl >= 100" | bc -l) )); then dl_score=8
    elif (( $(echo "$dl >= 50"  | bc -l) )); then dl_score=7
    elif (( $(echo "$dl >= 25"  | bc -l) )); then dl_score=6
    elif (( $(echo "$dl >= 10"  | bc -l) )); then dl_score=5
    else dl_score=3; fi

    # Upload score
    if (( $(echo "$ul >= 200" | bc -l) )); then ul_score=10
    elif (( $(echo "$ul >= 100" | bc -l) )); then ul_score=9
    elif (( $(echo "$ul >= 50"  | bc -l) )); then ul_score=8
    elif (( $(echo "$ul >= 20"  | bc -l) )); then ul_score=7
    elif (( $(echo "$ul >= 10"  | bc -l) )); then ul_score=6
    else ul_score=4; fi

    # Ping score
    if (( $(echo "$ping <= 5"   | bc -l) )); then ping_score=10
    elif (( $(echo "$ping <= 10" | bc -l) )); then ping_score=9
    elif (( $(echo "$ping <= 20" | bc -l) )); then ping_score=8
    elif (( $(echo "$ping <= 40" | bc -l) )); then ping_score=7
    elif (( $(echo "$ping <= 80" | bc -l) )); then ping_score=5
    else ping_score=3; fi

    local total
    total=$(echo "scale=1; ($dl_score * 4 + $ul_score * 3 + $ping_score * 3) / 10" | bc)

    local label color emoji
    if (( $(echo "$total >= 9" | bc -l) )); then
        label="EXCELENTE"; color="$BRIGHT_GREEN"; emoji="🚀"
    elif (( $(echo "$total >= 7" | bc -l) )); then
        label="MUITO BOA"; color="$GREEN"; emoji="⚡"
    elif (( $(echo "$total >= 5" | bc -l) )); then
        label="BOA"; color="$BRIGHT_YELLOW"; emoji="✓"
    elif (( $(echo "$total >= 3" | bc -l) )); then
        label="FRACA"; color="$YELLOW"; emoji="⚠"
    else
        label="MÁ"; color="$RED"; emoji="✗"
    fi

    echo "$total|$label|$color|$emoji"
}

# ── Ping meter (visual) ────────────────────────────────────────────────────────
draw_ping_bar() {
    local ping="$1"
    # Lower is better — invert for bar (max reference = 200ms)
    local max_ping=200
    local inverted
    inverted=$(echo "scale=2; ($max_ping - $ping) / $max_ping * 100" | bc 2>/dev/null || echo "50")
    (( $(echo "$inverted < 0" | bc -l) )) && inverted=0

    local filled
    filled=$(echo "scale=0; $inverted * $BAR_MAX / 100" | bc 2>/dev/null || echo "0")
    [[ $filled -gt $BAR_MAX ]] && filled=$BAR_MAX
    local empty=$(( BAR_MAX - filled ))

    local bar_filled="" bar_empty=""
    for ((i=0; i<filled; i++)); do bar_filled+="█"; done
    for ((i=0; i<empty; i++)); do bar_empty+="░"; done

    local ping_color
    if (( $(echo "$ping <= 10" | bc -l) )); then ping_color="${BRIGHT_GREEN}"
    elif (( $(echo "$ping <= 30" | bc -l) )); then ping_color="${GREEN}"
    elif (( $(echo "$ping <= 60" | bc -l) )); then ping_color="${BRIGHT_YELLOW}"
    elif (( $(echo "$ping <= 100" | bc -l) )); then ping_color="${YELLOW}"
    else ping_color="${RED}"; fi

    printf "  ${BOLD}${BRIGHT_WHITE}%-12s${RESET} ${ping_color}${bar_filled}${DIM}${bar_empty}${RESET}  ${BOLD}${ping_color}%7.2f ms${RESET}  ${DIM}(menor = melhor)${RESET}\n" \
        "Ping" "$ping"
}

# ── Section label ─────────────────────────────────────────────────────────────
section() {
    echo ""
    echo -e "  ${BOLD}${BRIGHT_BLUE}$1${RESET}"
    echo -e "  ${DIM}$(printf '─%.0s' $(seq 1 $((TERM_WIDTH - 4))))${RESET}"
}

# ═════════════════════════════════════════════════════════════════════════════
# MAIN
# ═════════════════════════════════════════════════════════════════════════════

check_deps
print_header

# ── Run speedtest ─────────────────────────────────────────────────────────────
section "▶  A correr o teste..."
echo ""

start_spinner "A obter configuração do servidor..." "$BRIGHT_CYAN"
RAW=$(speedtest-cli --simple 2>&1)
EXITCODE=$?
stop_spinner

if [[ $EXITCODE -ne 0 ]]; then
    echo -e "  ${RED}${BOLD}✗ Erro ao executar o speedtest:${RESET}"
    echo -e "  ${DIM}$RAW${RESET}"
    exit 1
fi

# Parse results
PING=$(echo "$RAW" | grep -i "ping"     | awk '{print $2}')
DL=$(  echo "$RAW" | grep -i "download" | awk '{print $2}')
UL=$(  echo "$RAW" | grep -i "upload"   | awk '{print $2}')

# Fallback
[[ -z "$PING" ]] && PING="0"
[[ -z "$DL"   ]] && DL="0"
[[ -z "$UL"   ]] && UL="0"

# ── Server info ───────────────────────────────────────────────────────────────
SERVER_INFO=$(speedtest-cli --simple --no-pre-allocate 2>&1 | head -1 || true)
FULL_OUTPUT=$(speedtest-cli 2>&1)
SERVER_LINE=$(echo "$FULL_OUTPUT" | grep -i "Hosted by" | head -1)
ISP_LINE=$(   echo "$FULL_OUTPUT" | grep -i "Testing from" | head -1)

section "🌐  Informações da Ligação"
echo ""
if [[ -n "$ISP_LINE" ]]; then
    echo -e "  ${BRIGHT_WHITE}ISP   ${DIM}${ISP_LINE#*from }${RESET}"
fi
if [[ -n "$SERVER_LINE" ]]; then
    echo -e "  ${BRIGHT_WHITE}Server${DIM}${SERVER_LINE#*by }${RESET}"
fi
echo ""

# ── Results ───────────────────────────────────────────────────────────────────
section "📊  Resultados"
echo ""

# Benchmark maximums for bar scale
DL_MAX=1000   # Mbit/s
UL_MAX=500
PING_MAX=200

echo -e "  ${DIM}(barras em relação a ${DL_MAX} Mbps DL / ${UL_MAX} Mbps UL / ${PING_MAX}ms ping)${RESET}"
echo ""

animated_bar "$DL"   "$DL_MAX"   "$BRIGHT_CYAN"    "Download ↓" "Mbps"
sleep 0.1
animated_bar "$UL"   "$UL_MAX"   "$BRIGHT_MAGENTA" "Upload ↑"   "Mbps"
sleep 0.1
draw_ping_bar "$PING"

# ── Quality ────────────────────────────────────────────────────────────────────
section "⭐  Avaliação da Ligação"
echo ""

IFS='|' read -r score label color emoji <<< "$(rate_connection "$DL" "$UL" "$PING")"

# Big score display
echo -e "  ${BOLD}${color}${emoji}  ${label}${RESET}  ${DIM}(score: ${score}/10)${RESET}"
echo ""

# Score bar
score_filled=$(echo "scale=0; $score * $BAR_MAX / 10" | bc 2>/dev/null || echo 0)
score_bar=""
score_empty_bar=""
for ((i=0; i<score_filled; i++)); do score_bar+="█"; done
for ((i=score_filled; i<BAR_MAX; i++)); do score_empty_bar+="░"; done
echo -e "  ${BOLD}${BRIGHT_WHITE}Qualidade   ${RESET}${color}${score_bar}${DIM}${score_empty_bar}${RESET}  ${BOLD}${color}${score}/10${RESET}"

# ── Usage guide ───────────────────────────────────────────────────────────────
section "💡  Para que serve esta velocidade?"
echo ""

echo -e "  ${DIM}Download: ${RESET}${BOLD}${BRIGHT_CYAN}${DL} Mbps${RESET}"
echo ""

# 4K streaming needs ~25 Mbps
streams_4k=$(echo "scale=0; $DL / 25" | bc 2>/dev/null || echo 0)
streams_hd=$(echo "scale=0; $DL / 5"  | bc 2>/dev/null || echo 0)
zoom=$(      echo "scale=0; $DL / 3"  | bc 2>/dev/null || echo 0)

[[ $streams_4k -gt 20 ]] && streams_4k="20+"
[[ $streams_hd -gt 30 ]] && streams_hd="30+"
[[ $zoom       -gt 50 ]] && zoom="50+"

printf "  ${BRIGHT_WHITE}%-28s${RESET} ${BRIGHT_GREEN}%s simultâneos${RESET}\n"      "▸ Streams 4K (Netflix/YouTube)" "$streams_4k"
printf "  ${BRIGHT_WHITE}%-28s${RESET} ${BRIGHT_GREEN}%s simultâneos${RESET}\n"      "▸ Streams HD"                   "$streams_hd"
printf "  ${BRIGHT_WHITE}%-28s${RESET} ${BRIGHT_GREEN}%s videochamadas HD${RESET}\n" "▸ Zoom/Teams"                   "$zoom"

# ── Summary table ─────────────────────────────────────────────────────────────
section "📋  Resumo"
echo ""
printf "  ${DIM}┌─────────────────┬──────────────────┐${RESET}\n"
printf "  ${DIM}│${RESET} ${BRIGHT_WHITE}%-15s${RESET} ${DIM}│${RESET} ${BOLD}${BRIGHT_CYAN}%-16s${RESET}${DIM}│${RESET}\n" "Download" "${DL} Mbit/s"
printf "  ${DIM}├─────────────────┼──────────────────┤${RESET}\n"
printf "  ${DIM}│${RESET} ${BRIGHT_WHITE}%-15s${RESET} ${DIM}│${RESET} ${BOLD}${BRIGHT_MAGENTA}%-16s${RESET}${DIM}│${RESET}\n" "Upload" "${UL} Mbit/s"
printf "  ${DIM}├─────────────────┼──────────────────┤${RESET}\n"
printf "  ${DIM}│${RESET} ${BRIGHT_WHITE}%-15s${RESET} ${DIM}│${RESET} ${BOLD}${BRIGHT_YELLOW}%-16s${RESET}${DIM}│${RESET}\n" "Ping" "${PING} ms"
printf "  ${DIM}├─────────────────┼──────────────────┤${RESET}\n"
printf "  ${DIM}│${RESET} ${BRIGHT_WHITE}%-15s${RESET} ${DIM}│${RESET} ${BOLD}${color}%-16s${RESET}${DIM}│${RESET}\n" "Avaliação" "${emoji} ${label}"
printf "  ${DIM}└─────────────────┴──────────────────┘${RESET}\n"

echo ""
printf "  ${DIM}%.0s─${RESET}" $(seq 1 $((TERM_WIDTH - 4)))
echo ""
echo -e "  ${DIM}Teste concluído às $(date '+%H:%M:%S')${RESET}"
echo ""
