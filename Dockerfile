FROM emscripten/emsdk
WORKDIR /app

# Get wasmer
RUN curl https://get.wasmer.io -sSfL | sh
ENV PATH="/root/.wasmer/bin:${PATH}"

# Get the metamath source code
RUN curl http://us.metamath.org/downloads/metamath.zip -o metamath.zip
RUN unzip metamath.zip -d .

# For convenience also get set.mm
RUN curl https://raw.githubusercontent.com/metamath/set.mm/develop/set.mm -o set.mm

# And when run, launch the shell
WORKDIR /app/metamath
CMD ["sh"]
