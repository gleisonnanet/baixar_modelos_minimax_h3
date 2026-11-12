#!/usr/bin/env bash
# Baixa os modelos MENORES do workflow MiniMax H3 Motion Context V2 (foco: GPU de 12 GB)
# Uso:  bash baixar_modelos_minimax_h3.sh
# Opcional: HF_TOKEN=hf_xxx bash baixar_modelos_minimax_h3.sh   (se algum repo pedir login)
#           MODELS_DIR=/outro/caminho bash baixar_modelos_minimax_h3.sh
set -euo pipefail

MODELS_DIR="${MODELS_DIR:-/storage/fast/ComfyUI/models}"
HF="https://huggingface.co"

# pasta | URL | nome final do arquivo
MODELOS=(
  # Modelo principal: versão PODADA (21 GB) em vez da completa (34 GB)
  "diffusion_models|$HF/WarmBloodAban/Minimax-h3_Singularity/resolve/main/Minimax-h3_Singularity_ref2va_Pruned_v1.3_int8.safetensors|Minimax-h3_Singularity_ref2va_Pruned_v1.3_int8.safetensors"
  # Codificador de texto: nvfp4_awq (15,7 GB) em vez do int8_convrot (27,1 GB)
  "text_encoders|$HF/Comfy-Org/MiniMax-H3/resolve/main/text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors|qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors"
  # VAE de vídeo (int8, ~3 GB) e VAE de áudio (0,6 GB)
  "vae|$HF/Comfy-Org/MiniMax-H3/resolve/main/vae/minimax_h3_video_vae_int8_convrot.safetensors|minimax_h3_video_vae_int8_convrot.safetensors"
  "vae|$HF/Comfy-Org/MiniMax-H3/resolve/main/vae/minimax_h3_audio_vae_fp32.safetensors|minimax_h3_audio_vae_fp32.safetensors"
  # LoRA turbo de 4 passos (2 GB)
  "loras|$HF/Comfy-Org/MiniMax-H3/resolve/main/loras/minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors|minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors"
  # Prévia rápida (10 MB)
  "vae_approx|$HF/Kijai/MiniMax-H3-TAE/resolve/main/vae_approx/taeh3.safetensors|taeh3.safetensors"
  # Upscaler de latente (0,7 GB) - já salvo com o nome que o workflow procura
  "latent_upscale_models|$HF/LBH-123-AI/Minimax_h3_latent_Upscaler/resolve/main/minimax_h3_latent_upscaler_3d_conv_v1/minimax_h3_latent_upscaler_3d_conv_v1_bf16.safetensors|minimax_h3_latent_upscaler_3d_bf16.safetensors"
)

# --- ferramenta de download (aria2c é mais rápido; cai para wget ou curl) ---
AUTH=()
if command -v aria2c >/dev/null; then
  [[ -n "${HF_TOKEN:-}" ]] && AUTH=(--header="Authorization: Bearer $HF_TOKEN")
  baixar() { aria2c -c -x 16 -s 16 -k 1M --console-log-level=warn --summary-interval=0 \
               "${AUTH[@]}" -d "$(dirname "$2")" -o "$(basename "$2").part" "$1"; }
elif command -v wget >/dev/null; then
  [[ -n "${HF_TOKEN:-}" ]] && AUTH=(--header="Authorization: Bearer $HF_TOKEN")
  baixar() { wget -c -q --show-progress "${AUTH[@]}" -O "$2.part" "$1"; }
elif command -v curl >/dev/null; then
  [[ -n "${HF_TOKEN:-}" ]] && AUTH=(-H "Authorization: Bearer $HF_TOKEN")
  baixar() { curl -fL -C - --retry 5 "${AUTH[@]}" -o "$2.part" "$1"; }
else
  echo "ERRO: instale aria2c, wget ou curl." >&2; exit 1
fi

# --- espaço em disco (~43 GB no total; pede 50 GB de folga) ---
mkdir -p "$MODELS_DIR"
LIVRE_GB=$(df -BG --output=avail "$MODELS_DIR" | tail -1 | tr -dc '0-9')
if (( LIVRE_GB < 50 )); then
  echo "AVISO: só ${LIVRE_GB} GB livres em $MODELS_DIR (o recomendado é 50 GB)."
  read -rp "Continuar mesmo assim? [s/N] " r; [[ "$r" =~ ^[sS]$ ]] || exit 1
fi

# --- downloads ---
FALHAS=()
for item in "${MODELOS[@]}"; do
  IFS='|' read -r pasta url nome <<< "$item"
  destino="$MODELS_DIR/$pasta/$nome"
  mkdir -p "$MODELS_DIR/$pasta"
  if [[ -s "$destino" ]]; then
    echo "[ok] já existe: $pasta/$nome"; continue
  fi
  echo; echo ">>> $pasta/$nome"
  if baixar "$url" "$destino"; then
    mv -f "$destino.part" "$destino"
    echo "[ok] $(du -h "$destino" | cut -f1)  $pasta/$nome"
  else
    echo "[FALHOU] $pasta/$nome (rode o script de novo para retomar)" >&2
    FALHAS+=("$pasta/$nome")
  fi
done

echo; echo "===== Resumo ====="
for item in "${MODELOS[@]}"; do
  IFS='|' read -r pasta _ nome <<< "$item"
  f="$MODELS_DIR/$pasta/$nome"
  [[ -s "$f" ]] && printf '%8s  %s\n' "$(du -h "$f" | cut -f1)" "$pasta/$nome" \
                || printf '%8s  %s\n' "FALTA" "$pasta/$nome"
done
(( ${#FALHAS[@]} )) && { echo "Alguns downloads falharam. Rode novamente para retomar."; exit 1; }
echo "Tudo pronto. No CLIPLoader, escolha qwen3vl_32b_minimax_h3_nvfp4_awq (tipo minimax)."