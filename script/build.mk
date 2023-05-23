# QEMU options
QEMU = qemu-system-riscv64

MACHINE = virt
BIOS = default
MEMORYSIZE = 128M

QEMUFLAGS = -machine $(MACHINE) \
						-bios $(BIOS) \
						-m $(MEMORYSIZE) \
						-nographic

# C compile options
CFLAGS = -Wall -Werror -ggdb3 \
				 -MD \
				 -ffreestanding -fno-common -nostdlib -mno-relax -mcmodel=medany
INCLUDEPATH = $(WORKDIR)/include
INCLUDEFLAG =  $(addprefix -I, $(INCLUDEPATH))
CFLAGS += $(INCLUDEFLAG)
ASFLAGS += -MD $(INCLUDEFLAG)

# kernel info
KERNELSRC = $(shell find $(K) -name "*.c")
KERNELASM = $(shell find $(K) -name "*.S")
KERNELOBJ = $(subst $(WORKDIR), $(BUILDDIR), $(KERNELSRC:%.c=%.o))
KERNELOBJ += $(subst $(WORKDIR), $(BUILDDIR), $(KERNELASM:%.S=%.o))
-include $(subst $(WORKDIR), $(BUILDDIR), $(KERNELSRC:%.c:%.d))

KERNELBIN = $(BUILDDIR)/kernel.bin
KERNELLD = $(K)/kernel.ld

# user info
USERSRC = $(shell find $(U) -name "*.c")
USEROBJ = $(subst $(WORKDIR), $(BUILDDIR), $(USERSRC:%.c=%.o))
-include $(subst $(WORKDIR), $(BUILDDIR), $(USERSRC:%.c:%.d))

# compile rules
$(BUILDDIR)/%.o: $(WORKDIR)/%.c
	@mkdir -p $(dir $@) && echo + CC $<
	@$(CC) $(CFLAGS) -c -o $@ $<

$(BUILDDIR)/%.o: $(WORKDIR)/%.S
	@mkdir -p $(dir $@) && echo + AS $<
	@$(AS) $(ASFLAGS) -c -o $@ $<

# build kernel
$(KERNELBIN): $(KERNELOBJ) $(KERNELLD)
	$(LD) $(LDFLAGS) -T $(KERNELLD) -o $@ $(KERNELOBJ)

# run qemu
run: $(KERNELBIN)
	$(QEMU) $(QEMUFLAGS) -kernel $(KERNELBIN)

# debug options
QEMUGDBFLAGS = -S -gdb \
							 tcp::26000

# run debug
gdb: $(KERNELBIN)
	@grep -E "set auto-load safe-path /" ~/.gdbinit || echo "set auto-load safe-path /" >> ~/.gdbinit
	@printf "\e[1;31m**********Start gdb on another window********************\e[0;m\n"
	@$(QEMU) $(QEMUFLAGS) -kernel $(KERNELBIN) $(QEMUGDBFLAGS) 

.PHONY: run gdb
