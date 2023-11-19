ASM=nasm
SRC_DIR=src
BUILD_DIR=build


.PHONY: all floppy_image run uninstall install kernel bootloader always



#
# Floppy image
#
floppy_image: $(BUILD_DIR)/main_floppy.img 

$(BUILD_DIR)/main_floppy.img: bootloader kernel
	@clear
	@echo 'Creando imagen de disquete'
	@dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=512 count=2880
	@mkfs.fat -F 12 -n "NBOS" $(BUILD_DIR)/main_floppy.img
	@dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc
	@mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/kernel.bin "::kernel.bin"
	@qemu-system-i386 -fda $(BUILD_DIR)/main_floppy.img


#
# Bootloader
#
bootloader: $(BUILD_DIR)/bootloader.bin

$(BUILD_DIR)/bootloader.bin: always
	@clear
	@echo 'Compilando el bootloader'
	$(ASM) $(SRC_DIR)/bootloader/boot.asm -f bin -o $(BUILD_DIR)/bootloader.bin
	@time sleep 2

#
# Kernel 
#
kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: always
	@clear
	@echo 'Compilando el kernel'
	$(ASM) $(SRC_DIR)/kernel/main.asm -f bin -o $(BUILD_DIR)/kernel.bin
	@time sleep 2

#
# Always
#
always:
	@mkdir -p $(BUILD_DIR)



install:
	@echo 'Instalando paquetes'
	@sudo apt-get install qemu-system nasm mtools
	@clear
	@time sleep 1.5
	@echo 'Instalacion completada'
	@echo ''
	@echo 'Ingrese make para compilar e iniciar el sistema'
	@echo 'Ingrese make uninstall para desinstalar el sistema'

uninstall:
	@echo 'Desinstalando paquetes'
	@sudo apt-get -y purge qemu-system nasm mtools
	@echo 'Eliminando archivos compilados'
	@rm -rf $(BUILD_DIR)/*
	@echo 'Eliminando directorios'
	@rm -rf $(BUILD_DIR)
	@echo 'Desinstalacion completada'
