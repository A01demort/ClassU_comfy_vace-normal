FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_CACHE_DIR=/workspace/.cache/pip

# 시스템 패키지 및 빌드 도구 + Jupyter 필수 툴 설치
RUN apt-get update && apt-get install -y \
    git wget curl ffmpeg libgl1 \
    build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev libncurses5-dev \
    libncursesw5-dev xz-utils tk-dev libffi-dev \
    liblzma-dev software-properties-common \
    locales sudo tzdata xterm nano \
    nodejs npm && \
    apt-get clean

# 정확한 Python 3.10.6 소스 설치 + pip 심볼릭 링크 추가
WORKDIR /tmp
RUN wget https://www.python.org/ftp/python/3.10.6/Python-3.10.6.tgz && \
    tar xzf Python-3.10.6.tgz && cd Python-3.10.6 && \
    ./configure --enable-optimizations && \
    make -j$(nproc) && make altinstall && \
    ln -sf /usr/local/bin/python3.10 /usr/bin/python && \
    ln -sf /usr/local/bin/python3.10 /usr/bin/python3 && \
    ln -sf /usr/local/bin/pip3.10 /usr/bin/pip && \
    ln -sf /usr/local/bin/pip3.10 /usr/local/bin/pip && \
    cd / && rm -rf /tmp/*

# ComfyUI 설치
WORKDIR /workspace
RUN mkdir -p /workspace && chmod -R 777 /workspace && \
    chown -R root:root /workspace && \
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI && \
    cd /workspace/ComfyUI && \
    git fetch --tags && \
    git checkout v0.3.56
WORKDIR /workspace/ComfyUI

# 기존(git코드 백업- 최초)
# git fetch origin ff57793659702d502506047445f0972b10b6b9fe && \
# git checkout ff57793659702d502506047445f0972b10b6b9fe
# 그 이후 v0.3.43
# 그 이후 v0.3.56 -> 안정적인데 UI가 다름 


# 의존성 설치
RUN pip install -r requirements.txt && \
    pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu126

# Node.js 18 설치 (기존 nodejs 제거 후)
RUN apt-get remove -y nodejs npm && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    node -v && npm -v

# JupyterLab 안정 버전 설치
RUN pip install --force-reinstall jupyterlab==3.6.6 jupyter-server==1.23.6

# Jupyter 설정파일 보완
RUN mkdir -p /root/.jupyter && \
    echo "c.NotebookApp.allow_origin = '*'\n\
c.NotebookApp.ip = '0.0.0.0'\n\
c.NotebookApp.open_browser = False\n\
c.NotebookApp.token = ''\n\
c.NotebookApp.password = ''\n\
c.NotebookApp.terminado_settings = {'shell_command': ['/bin/bash']}" \
> /root/.jupyter/jupyter_notebook_config.py



# 커스텀 노드 및 의존성 설치 통합
RUN echo '📁 커스텀 노드 및 의존성 설치 시작' && \
    mkdir -p /workspace/ComfyUI/custom_nodes && \
    cd /workspace/ComfyUI/custom_nodes && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git && cd ComfyUI-Manager && git checkout 116e068ac31c8b76860cd7aa369d5aacd61d27dc || echo '⚠️ Manager 실패' && cd .. && \
    git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git && cd ComfyUI-Custom-Scripts && git checkout f2838ed5e59de4d73cde5c98354b87a8d3200190 || echo '⚠️ Scripts 실패' && cd .. && \
    git clone https://github.com/rgthree/rgthree-comfy.git && cd rgthree-comfy && git checkout 110e4ef1dbf2ea20ec39ae5a737bd5e56d4e54c2 || echo '⚠️ rgthree 실패' && cd .. && \
    git clone https://github.com/WASasquatch/was-node-suite-comfyui.git && cd was-node-suite-comfyui && git checkout ea935d1044ae5a26efa54ebeb18fe9020af49a45 || echo '⚠️ WAS 실패' && cd .. && \
    git clone https://github.com/kijai/ComfyUI-KJNodes.git && cd ComfyUI-KJNodes && git checkout e2ce0843d1183aea86ce6a1617426f492dcdc802 || echo '⚠️ KJNodes 실패' && cd .. && \
    git clone https://github.com/cubiq/ComfyUI_essentials.git && cd ComfyUI_essentials && git checkout 9d9f4bedfc9f0321c19faf71855e228c93bd0dc9 || echo '⚠️ Essentials 실패' && cd .. && \
    git clone https://github.com/city96/ComfyUI-GGUF.git && cd ComfyUI-GGUF && git checkout d247022e3fa66851c5084cc251b076aab816423d || echo '⚠️ GGUF 실패' && cd .. && \
    git clone https://github.com/welltop-cn/ComfyUI-TeaCache.git && cd ComfyUI-TeaCache && git checkout 91dff8e31684ca70a5fda309611484402d8fa192 || echo '⚠️ TeaCache 실패' && cd .. && \
    git clone https://github.com/kaibioinfo/ComfyUI_AdvancedRefluxControl.git && cd ComfyUI_AdvancedRefluxControl && git checkout 2b95c2c866399ca1914b4da486fe52808f7a9c60 || echo '⚠️ ARC 실패' && cd .. && \
    git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git && cd ComfyUI_Comfyroll_CustomNodes && git checkout d78b780ae43fcf8c6b7c6505e6ffb4584281ceca || echo '⚠️ Comfyroll 실패' && cd .. && \
    git clone https://github.com/cubiq/PuLID_ComfyUI.git && cd PuLID_ComfyUI && git checkout 93e0c4c226b87b23c0009d671978bad0e77289ff || echo '⚠️ PuLID 실패' && cd .. && \
    git clone https://github.com/sipie800/ComfyUI-PuLID-Flux-Enhanced.git && cd ComfyUI-PuLID-Flux-Enhanced && git checkout 04e1b52320f1f14383afe18959349703623c5b88 || echo '⚠️ Flux 실패' && cd .. && \
    git clone https://github.com/Gourieff/ComfyUI-ReActor.git && cd ComfyUI-ReActor && git checkout d60458f212e8c7a496269bbd29ca7c6a3198239a || echo '⚠️ ReActor 실패' && cd .. && \
    git clone https://github.com/yolain/ComfyUI-Easy-Use.git && cd ComfyUI-Easy-Use && git checkout 11794f7d718dc38dded09e677817add796ce0234 || echo '⚠️ EasyUse 실패' && cd .. && \
    git clone https://github.com/PowerHouseMan/ComfyUI-AdvancedLivePortrait.git && cd ComfyUI-AdvancedLivePortrait && git checkout 3bba732915e22f18af0d221b9c5c282990181f1b || echo '⚠️ LivePortrait 실패' && cd .. && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && cd ComfyUI-VideoHelperSuite && git checkout 8e4d79471bf1952154768e8435a9300077b534fa || echo '⚠️ VideoHelper 실패' && cd .. && \
    git clone https://github.com/Jonseed/ComfyUI-Detail-Daemon.git && cd ComfyUI-Detail-Daemon && git checkout f391accbda2d309cdcbec65cb9fcc80a41197b20 || echo '⚠️ Daemon 실패' && cd .. && \
    git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git && cd ComfyUI_UltimateSDUpscale && git checkout 627c871f14532b164331f08d0eebfbf7404161ee || echo '⚠️ Upscale 실패' && cd .. && \
    git clone https://github.com/risunobushi/comfyUI_FrequencySeparation_RGB-HSV.git && cd comfyUI_FrequencySeparation_RGB-HSV && git checkout 67a08c55ee6aa8e9140616f01497bd54d3533fa6 || echo '⚠️ Frequency 실패' && cd .. && \
    git clone https://github.com/silveroxides/ComfyUI_bnb_nf4_fp4_Loaders.git && cd ComfyUI_bnb_nf4_fp4_Loaders && git checkout dd2f774a2d3930de06fddc995901c830fc936715 || echo '⚠️ NF4 노드 실패' && cd .. && \
    git clone https://github.com/kijai/ComfyUI-FramePackWrapper.git && cd ComfyUI-FramePackWrapper && git checkout a7c4b704455aee0d016143f2fc232928cc0f1d83 || echo '⚠️ FramePackWrapper 실패' && cd .. && \
    git clone https://github.com/pollockjj/ComfyUI-MultiGPU.git && cd ComfyUI-MultiGPU && git checkout 6e4181a7bb5e2ef147aa8e1d0845098a709306a4 || echo '⚠️ MultiGPU 실패' && cd .. && \
    git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git && cd comfyui_controlnet_aux && git checkout 59b027e088c1c8facf7258f6e392d16d204b4d27 || echo '⚠️ controlnet_aux 실패' && cd .. && \
    git clone https://github.com/chflame163/ComfyUI_LayerStyle.git && cd ComfyUI_LayerStyle && git checkout 3bfe8e4 || echo '⚠️ ComfyUI_LayerStyle 설치 실패' && cd .. && \
    git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git && cd ComfyUI-Frame-Interpolation && git checkout a969c01dbccd9e5510641be04eb51fe93f6bfc3d || echo '⚠️ Frame-Interpolation 실패' && cd .. && \
    git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git && cd ComfyUI-Impact-Pack && git checkout 48a814315f500a6f3e87ac4c8446305f8b2ef8f6 || echo '⚠️ Impact-Pack 실패' && cd .. && \
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git && cd ComfyUI-WanVideoWrapper && git checkout 6eddec54a69d9fac30b0125a3c06656e7c533eca || echo '⚠️ ComfyUI-WanVideoWrapper 설치 실패' && \

    \
    echo '📦 segment-anything 설치' && \
    git clone https://github.com/facebookresearch/segment-anything.git /workspace/segment-anything || echo '⚠️ segment-anything 실패' && \
    pip install -e /workspace/segment-anything || echo '⚠️ segment-anything pip 설치 실패' && \
    \
    echo '📦 ReActor ONNX 모델 설치' && \
    mkdir -p /workspace/ComfyUI/models/insightface && \
    wget -O /workspace/ComfyUI/models/insightface/inswapper_128.onnx \
    https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/inswapper_128.onnx || echo '⚠️ ONNX 다운로드 실패' && \
    \
    echo '📦 파이썬 패키지 설치' && \
    pip install --no-cache-dir \
        GitPython onnx onnxruntime opencv-python-headless tqdm requests \
        scikit-image piexif packaging transformers accelerate peft sentencepiece \
        protobuf scipy einops pandas matplotlib imageio[ffmpeg] pyzbar pillow numba \
        gguf diffusers insightface dill || echo '⚠️ 일부 pip 설치 실패' && \
    pip install facelib==0.2.2 mtcnn==0.1.1 || echo '⚠️ facelib 실패' && \
    pip install facexlib basicsr gfpgan realesrgan || echo '⚠️ facexlib 실패' && \
    pip install timm || echo '⚠️ timm 실패' && \
    pip install ultralytics || echo '⚠️ ultralytics 실패' && \
    pip install ftfy || echo '⚠️ ftfy 실패' && \
    pip install bitsandbytes xformers || echo '⚠️ bitsandbytes 또는 xformers 설치 실패' && \
    pip install sageattention || echo '⚠️ sageattention 설치 실패'


# A1 폴더 생성 후 자동 커스텀 노드 설치 스크립트 복사
RUN mkdir -p /workspace/A1
COPY init_or_check_nodes.sh /workspace/A1/init_or_check_nodes.sh
RUN chmod +x /workspace/A1/init_or_check_nodes.sh

# Wan2.1_Vace_a1.sh 스크립트 복사 및 실행 권한 설정
COPY Wan2.1_Vace_a1.sh /workspace/A1/Wan2.1_Vace_a1.sh
RUN chmod +x /workspace/A1/Wan2.1_Vace_a1.sh



# 볼륨 마운트
VOLUME ["/workspace"]

# 포트 설정
EXPOSE 8188
EXPOSE 8888



    
# 실행 명령어(신규)
CMD bash -c "\
echo '🌀 A1(AI는 에이원) : https://www.youtube.com/@A01demort' && \
jupyter lab --ip=0.0.0.0 --port=8888 --allow-root \
--ServerApp.root_dir=/workspace \
--ServerApp.token='' --ServerApp.password='' & \
python -u /workspace/ComfyUI/main.py --listen 0.0.0.0 --port=8188 --front-end-version Comfy-Org/ComfyUI_frontend@1.33.9 & \
/workspace/A1/init_or_check_nodes.sh && \
wait"








# # 실행 명령어(기존)
# CMD bash -c "\
# echo '🌀 A1(AI는 에이원) : https://www.youtube.com/@A01demort' && \
# jupyter lab --ip=0.0.0.0 --port=8888 --allow-root \
# --ServerApp.root_dir=/workspace \
# --ServerApp.token='' --ServerApp.password='' & \
# python -u /workspace/ComfyUI/main.py --listen 0.0.0.0 --port=8188 \
# --front-end-version Comfy-Org/ComfyUI_frontend@latest & \
# /workspace/A1/init_or_check_nodes.sh && \
# wait"
