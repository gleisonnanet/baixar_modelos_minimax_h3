O script `baixar_modelos_minimax_h3.sh` baixa os 7 arquivos do guia para `/storage/fast/ComfyUI/models/`. Onde havia opção, ele escolhe sempre a versão menor:

| Pasta | Arquivo | Tamanho |
|---|---|---|
| diffusion_models | Singularity **Pruned** v1.3 int8 (em vez da completa de 34 GB) | 21,0 GB |
| text_encoders | qwen3vl_32b **nvfp4_awq** (em vez do int8 de 27,1 GB) | 15,7 GB |
| vae | video_vae_int8_convrot + audio_vae_fp32 | ~3,6 GB |
| loras | turbo 4step bf16 | 2,0 GB |
| vae_approx | taeh3 | 10 MB |
| latent_upscale_models | upscaler, já salvo com o nome `minimax_h3_latent_upscaler_3d_bf16` | 0,7 GB |

O total fica em cerca de 43 GB, contra 55 GB no guia original.

Para rodar:
```bash
bash baixar_modelos_minimax_h3.sh
# ou, se algum repositório pedir login:
HF_TOKEN=hf_xxx bash baixar_modelos_minimax_h3.sh
```

O script usa `aria2c` se estiver instalado, porque é bem mais rápido. Sem ele, usa `wget` ou `curl`. Downloads interrompidos são retomados: basta rodar o script de novo. Antes de começar, ele confere se há espaço livre em disco.

Sobre a GPU de 12 GB:

- **Não há versão que caiba inteira em 12 GB.** O menor modelo principal tem 21 GB, então o ComfyUI vai descarregar parte dele na RAM. Use pelo menos 32 GB de RAM (64 GB é bem melhor) e considere iniciar o ComfyUI com `--lowvram`.
- **O codificador nvfp4 é otimizado para RTX 50.** Em RTX 30 ou 40 ele deve funcionar, mas mais devagar, porque é convertido na hora. Se der erro ou ficar lento demais, troque a linha do `text_encoders` pelo `qwen3vl_32b_minimax_h3_int8_convrot.safetensors` (27,1 GB, mesmo caminho no repositório Comfy-Org). Nesse caso, precisa de mais RAM.
- **No workflow,** escolha o nvfp4 no CLIPLoader, porque o workflow vem com o int8 selecionado. Comece com resolução baixa (cerca de 864x480 ou 1 MP) e `segment_count = 1`. Pela regra do guia, quadros × megapixels deve ficar abaixo de ~540 por trecho, e numa placa de 12 GB vale ficar bem abaixo disso.