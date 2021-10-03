FROM docker.io/library/debian:bullseye as bin
RUN apt-get update && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -yq \
        build-essential \
        cmake \
        curl \
        file \
        git \
        python3 \
        python \
        sudo \
        unzip \
        && \
    apt-get clean && rm -rf /var/lib/apt/lists/* 
    
WORKDIR  /work
RUN git clone https://github.com/emscripten-core/emsdk.git
WORKDIR /work/emsdk
RUN ./emsdk install 1.38.43
RUN ./emsdk activate 1.38.43
ENV PATH="/work/emsdk:${PATH}"
ENV PATH="/work/emsdk/node/14.15.5_64bit/bin:${PATH}"
ENV PATH="/work/emsdk/fastcomp/emscripten:${PATH}"
ENV EMSDK_NODE=/work/emsdk/node/14.15.5_64bit/bin/node
ENV EMSDK=/work/emsdk
ENV EM_CONFIG=/work/emsdk/.emscripten
WORKDIR /work
RUN curl http://us.metamath.org/downloads/metamath.zip -o metamath.zip \
        && echo 126fc3eac6699257cfcdbfb2087fb31284fdfe784bb9d6e2ea7c32b8524c3da9 \ metamath.zip | sha256sum -c \
        && unzip metamath.zip -d . \
        && rm metamath.zip
WORKDIR /work/metamath
RUN curl https://raw.githubusercontent.com/metamath/set.mm/develop/set.mm -o set.mm \
        && echo 2a497ca6cbf422e5a58244c7ab064bd62700daa289d9e325d6a9e590ec30d0c4 \ set.mm | sha256sum -c
RUN emcc *.c -s ALLOW_MEMORY_GROWTH=1 -o metamath.wasm

# sorry, this isn't a serious docker image for wasmer. Just using another experiment of mine for testing
FROM liftm/wasmer:binfmt-experiment
COPY --from=bin /work/metamath/metamath.wasm /work/metamath/set.mm /work/metamath/demo0.mm /
ENTRYPOINT ["/wasmer", "run", "--disable-cache", "metamath.wasm", "--"]
