FROM ghcr.io/foundry-rs/foundry

USER root
RUN apt-get update && apt-get install -y make

USER foundry

WORKDIR /app 
COPY . .

RUN forge build
# RUN forge test

CMD ["bash"]
# CMD ["make", "dev-start"]