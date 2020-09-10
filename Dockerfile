FROM 0x01be/verilator as verilator
FROM 0x01be/riscv-gnu-toolchain as riscv

FROM 0x01be/fusesoc

COPY --from=verilator /opt/verilator/ /opt/verilator/
COPY --from=riscv /opt/riscv/ /opt/riscv/

ENV PATH $PATH:/opt/verilator/bin:/opt/riscv/bin/

ENV SERV_REVISION master
ENV SERV_VERSION 1.0.2
ENV RISCV_COMPLIANCE_REVISION master

RUN apk add --no-cache --virtual serv-build-dependencies \
    perl \
    bash \
    ccache \
    gettext \
    libintl

RUN git clone --depth 1 --branch $SERV_REVISION https://github.com/olofk/serv /serv
RUN git clone --depth 1 --branch $RISCV_COMPLIANCE_REVISION https://github.com/riscv/riscv-compliance /riscv-compliance

WORKDIR /workspace

RUN fusesoc library add serv /serv
RUN fusesoc run --target=lint serv
RUN fusesoc run --target=verilator_tb --setup --build servant

WORKDIR /riscv-compliance/

RUN sed -i.bak 's/--strip-trailing-cr//g' riscv-test-env/verify.sh
RUN make \
    TARGETDIR=/serv/riscv-target \
    RISCV_TARGET=serv \
    RISCV_DECICE=rv32i \
    RISCV_ISA=rv32i \
    TARGET_SIM=/workspace/build/servant_$SERV_VERSION/verilator_tb-verilator/Vservant_sim

CMD fusesoc run --target=verilator_tb servant --uart_baudrate=57600 --firmware=/serv/sw/zephyr_hello.hex

