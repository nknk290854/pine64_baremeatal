#TOOL_PREFIX=/opt/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-elf/bin/aarch64-elf
TOOL_PREFIX=aarch64-linux-gnu
CC=${TOOL_PREFIX}-gcc
OBJCOPY=${TOOL_PREFIX}-objcopy
OBJDUMP=${TOOL_PREFIX}-objdump
#CFLAGS  = -Wall -O2 -ffreestanding -nostdinc -nostdlib -nostartfiles -nostdlib -nostartfiles
CFLAGS  = -O0 -nostdinc -nostdlib -nostartfiles
#LDFLAGS = -nostdlib -nostartfiles

#CFLAGS = \
#	-fpic -Wall -fno-common -fno-builtin -ffreestanding -nostdinc	\
#	-fno-strict-aliasing -fno-stack-protector -fno-toplevel-reorder	\
#	-Wstrict-prototypes -Wno-format-nonliteral -Wno-format-security -nostdlib
#CFLAGS = \
#	-marm -fpic -Wall -fno-common -fno-builtin -ffreestanding -nostdinc	\
#	-fno-strict-aliasing -mno-thumb-interwork -fno-stack-protector -fno-toplevel-reorder	\
#	-Wstrict-prototypes -Wno-format-nonliteral -Wno-format-security -nostdlib

#SRC = main.c boot.S
#SRC = uart-aarch64.s
SRC = led.c boot.S
TARGET = serial
SD_CARD_PATH = /dev/sdb
AARCH64_START_ADDRESS=0x40008000
SUNXI_FEL=sunxi-fel
all: ${TARGET}.sunxi
${TARGET}.sunxi	: ${SRC}
#	${CC} ${CFLAGS} ${SRC} -o ${TARGET}.elf -T ${TARGET}.lds -Wl,-N
	${CC} ${CFLAGS} ${SRC} -o ${TARGET}.elf -T ${TARGET}.ld -Wl,-N
	${OBJCOPY} -O binary ${TARGET}.elf ${TARGET}.bin
	mksunxiboot ${TARGET}.bin ${TARGET}.sunxi

write	:${TARGET}.sunxi
	sudo dd if=${TARGET}.sunxi of=${SD_CARD_PATH} bs=1024 seek=8
	sudo sync; sudo sync; sudo sync;

test64: sunxi-a64-spl32-ddr3.bin
	${CC} -O0 -nostdlib -nostartfiles -e ${AARCH64_START_ADDRESS} -Wl,-Ttext=${AARCH64_START_ADDRESS} -o ${TARGET}.elf ${SRC}
	${OBJCOPY} --remove-section .note.gnu.build-id ${TARGET}.elf
	${OBJCOPY} --remove-section .ARM.attributes ${TARGET}.elf
	${OBJDUMP} -D ${TARGET}.elf > ${TARGET}.lst
	${OBJCOPY} -O binary ${TARGET}.elf  ${TARGET}.bin
	${OBJCOPY} ${TARGET}.elf -O srec ${TARGET}.srec
	echo sudo ${SUNXI_FEL} spl sunxi-a64-spl32-ddr3.bin
	echo sudo ${SUNXI_FEL} write ${AARCH64_START_ADDRESS} ${TARGET}.bin
	echo sudo ${SUNXI_FEL} reset64 ${AARCH64_START_ADDRESS}


transfer:
	sunxi-fel -l
	sunxi-fel -v spl ${TARGET}.sunxi

boot64:
	sudo ${SUNXI_FEL} spl sunxi-a64-spl32-ddr3.bin
	sudo ${SUNXI_FEL} write ${AARCH64_START_ADDRESS} ${TARGET}.bin
	sudo ${SUNXI_FEL} reset64 ${AARCH64_START_ADDRESS}


sunxi-a64-spl32-ddr3.bin:
	wget https://github.com/apritzel/pine64/raw/master/binaries/sunxi-a64-spl32-ddr3.bin

clean	:
	rm -f ${TARGET}.elf ${TARGET}.bin ${TARGET}.sunxi


