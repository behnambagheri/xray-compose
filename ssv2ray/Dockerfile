FROM alpine:latest

WORKDIR /usr/local/bin/

COPY ./go-shadowsocks /usr/local/bin/
COPY ./v2ray-plugin /usr/local/bin/

RUN chmod +x /usr/local/bin/*

CMD [ "sh", "-c", "go-shadowsocks -s ss://${SS_CIPHER}:${SS_PASS}@:${SS_PORT} -plugin v2ray-plugin -plugin-opts server path=${SS_PATH}" ]
