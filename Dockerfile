# clean base image containing only comfyui, comfy-cli and comfyui-manager
FROM runpod/worker-comfyui:5.8.4-base
#

# build-time tokens for gated downloads — never baked into final image.
# pass via: docker build --build-arg HF_TOKEN=$HF_TOKEN ...
ARG HF_TOKEN=""

# install custom nodes into comfyui
RUN git clone https://github.com/scraed/LanPaint /comfyui/custom_nodes/LanPaint
RUN git clone https://github.com/rgthree/rgthree-comfy /comfyui/custom_nodes/rgthree-comfy

# download models into comfyui
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/jiangchengchengNLP/qwen3-4b-fp8-scaled/resolve/main/qwen3_4b_fp8_scaled.safetensors' --relative-path models/text_encoders --filename 'qwen3_4b_fp8_scaled.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors' --relative-path models/vae --filename 'flux2-vae.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/YuCollection/FLUX.2-klein-4B-bf16/resolve/main/flux-2-klein-4b.safetensors' --relative-path models/diffusion_models --filename 'flux-2-klein-4b-bf16.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done

# copy all input data (like images or videos) into comfyui (uncomment and adjust if needed)
# COPY input/ /comfyui/input/

# user-provided inputs override the auto-generated placeholders above.
RUN wget --progress=dot:giga -O '/comfyui/input/pexels-mimfathi-10919291.jpg' "https://cool-anteater-319.convex.cloud/api/storage/eb3ad0d4-bece-4b77-bbaf-61089e389539"
RUN wget --progress=dot:giga -O '/comfyui/input/pexels-peterfazekas-1137340.jpg' "https://cool-anteater-319.convex.cloud/api/storage/e8a9c59a-9a19-4be3-8cde-de57c3a3a717"
RUN wget --progress=dot:giga -O '/comfyui/input/00001-louis-vuitton-spring-2026-menswear-credit-gorunway.jpg.webp' "https://cool-anteater-319.convex.cloud/api/storage/dfbd47eb-d4fd-41cd-8d2a-a8d920078a1d"
RUN wget --progress=dot:giga -O '/comfyui/input/pexels-alina-zahorulko-48514961-31445409.jpg' "https://cool-anteater-319.convex.cloud/api/storage/fe538806-0489-4f6f-a289-b4fb47a6c08d"
RUN wget --progress=dot:giga -O '/comfyui/input/6dfa395c67d056ae2e94969e0bf4144b.jpg' "https://cool-anteater-319.convex.cloud/api/storage/2a2d9a66-b592-40a3-8682-2b039de6f156"

# Force Python to dump console output instantly instead of caching/buffering it
ENV PYTHONUNBUFFERED=1

# Start ComfyUI and dynamically locate and execute your handler file
CMD ["bash", "-c", "python3 /comfyui/main.py --listen 127.0.0.1 --port 8188 & python3 $(find / -maxdepth 2 -name '*handler.py' | head -n 1)"]
