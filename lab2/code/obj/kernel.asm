
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00001517          	auipc	a0,0x1
ffffffffc0200050:	55c50513          	addi	a0,a0,1372 # ffffffffc02015a8 <etext+0x6>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	56650513          	addi	a0,a0,1382 # ffffffffc02015c8 <etext+0x26>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	53458593          	addi	a1,a1,1332 # ffffffffc02015a2 <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	57250513          	addi	a0,a0,1394 # ffffffffc02015e8 <etext+0x46>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00006597          	auipc	a1,0x6
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0206018 <is_panic>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	57e50513          	addi	a0,a0,1406 # ffffffffc0201608 <etext+0x66>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00006597          	auipc	a1,0x6
ffffffffc020009a:	ff258593          	addi	a1,a1,-14 # ffffffffc0206088 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	58a50513          	addi	a0,a0,1418 # ffffffffc0201628 <etext+0x86>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00006597          	auipc	a1,0x6
ffffffffc02000ae:	3dd58593          	addi	a1,a1,989 # ffffffffc0206487 <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00001517          	auipc	a0,0x1
ffffffffc02000d0:	57c50513          	addi	a0,a0,1404 # ffffffffc0201648 <etext+0xa6>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00006517          	auipc	a0,0x6
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0206018 <is_panic>
ffffffffc02000e0:	00006617          	auipc	a2,0x6
ffffffffc02000e4:	fa860613          	addi	a2,a2,-88 # ffffffffc0206088 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	4a0010ef          	jal	ra,ffffffffc0201590 <memset>
    dtb_init();
ffffffffc02000f4:	12c000ef          	jal	ra,ffffffffc0200220 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	11e000ef          	jal	ra,ffffffffc0200216 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00001517          	auipc	a0,0x1
ffffffffc0200100:	57c50513          	addi	a0,a0,1404 # ffffffffc0201678 <etext+0xd6>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	62b000ef          	jal	ra,ffffffffc0200f36 <pmm_init>

    /* do nothing */
    while (1)
ffffffffc0200110:	a001                	j	ffffffffc0200110 <kern_init+0x38>

ffffffffc0200112 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200112:	1141                	addi	sp,sp,-16
ffffffffc0200114:	e022                	sd	s0,0(sp)
ffffffffc0200116:	e406                	sd	ra,8(sp)
ffffffffc0200118:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020011a:	0fe000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    (*cnt) ++;
ffffffffc020011e:	401c                	lw	a5,0(s0)
}
ffffffffc0200120:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200122:	2785                	addiw	a5,a5,1
ffffffffc0200124:	c01c                	sw	a5,0(s0)
}
ffffffffc0200126:	6402                	ld	s0,0(sp)
ffffffffc0200128:	0141                	addi	sp,sp,16
ffffffffc020012a:	8082                	ret

ffffffffc020012c <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012c:	1101                	addi	sp,sp,-32
ffffffffc020012e:	862a                	mv	a2,a0
ffffffffc0200130:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200132:	00000517          	auipc	a0,0x0
ffffffffc0200136:	fe050513          	addi	a0,a0,-32 # ffffffffc0200112 <cputch>
ffffffffc020013a:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013c:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013e:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200140:	03a010ef          	jal	ra,ffffffffc020117a <vprintfmt>
    return cnt;
}
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	4532                	lw	a0,12(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret

ffffffffc020014c <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014c:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200152:	8e2a                	mv	t3,a0
ffffffffc0200154:	f42e                	sd	a1,40(sp)
ffffffffc0200156:	f832                	sd	a2,48(sp)
ffffffffc0200158:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb850513          	addi	a0,a0,-72 # ffffffffc0200112 <cputch>
ffffffffc0200162:	004c                	addi	a1,sp,4
ffffffffc0200164:	869a                	mv	a3,t1
ffffffffc0200166:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200168:	ec06                	sd	ra,24(sp)
ffffffffc020016a:	e0ba                	sd	a4,64(sp)
ffffffffc020016c:	e4be                	sd	a5,72(sp)
ffffffffc020016e:	e8c2                	sd	a6,80(sp)
ffffffffc0200170:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200172:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200174:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200176:	004010ef          	jal	ra,ffffffffc020117a <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020017a:	60e2                	ld	ra,24(sp)
ffffffffc020017c:	4512                	lw	a0,4(sp)
ffffffffc020017e:	6125                	addi	sp,sp,96
ffffffffc0200180:	8082                	ret

ffffffffc0200182 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200182:	1101                	addi	sp,sp,-32
ffffffffc0200184:	e822                	sd	s0,16(sp)
ffffffffc0200186:	ec06                	sd	ra,24(sp)
ffffffffc0200188:	e426                	sd	s1,8(sp)
ffffffffc020018a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020018c:	00054503          	lbu	a0,0(a0)
ffffffffc0200190:	c51d                	beqz	a0,ffffffffc02001be <cputs+0x3c>
ffffffffc0200192:	0405                	addi	s0,s0,1
ffffffffc0200194:	4485                	li	s1,1
ffffffffc0200196:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200198:	080000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020019c:	00044503          	lbu	a0,0(s0)
ffffffffc02001a0:	008487bb          	addw	a5,s1,s0
ffffffffc02001a4:	0405                	addi	s0,s0,1
ffffffffc02001a6:	f96d                	bnez	a0,ffffffffc0200198 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a8:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001ac:	4529                	li	a0,10
ffffffffc02001ae:	06a000ef          	jal	ra,ffffffffc0200218 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b2:	60e2                	ld	ra,24(sp)
ffffffffc02001b4:	8522                	mv	a0,s0
ffffffffc02001b6:	6442                	ld	s0,16(sp)
ffffffffc02001b8:	64a2                	ld	s1,8(sp)
ffffffffc02001ba:	6105                	addi	sp,sp,32
ffffffffc02001bc:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001be:	4405                	li	s0,1
ffffffffc02001c0:	b7f5                	j	ffffffffc02001ac <cputs+0x2a>

ffffffffc02001c2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c2:	00006317          	auipc	t1,0x6
ffffffffc02001c6:	e5630313          	addi	t1,t1,-426 # ffffffffc0206018 <is_panic>
ffffffffc02001ca:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ce:	715d                	addi	sp,sp,-80
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	000e0363          	beqz	t3,ffffffffc02001e4 <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x20>
    is_panic = 1;
ffffffffc02001e4:	4785                	li	a5,1
ffffffffc02001e6:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001ee:	862e                	mv	a2,a1
ffffffffc02001f0:	85aa                	mv	a1,a0
ffffffffc02001f2:	00001517          	auipc	a0,0x1
ffffffffc02001f6:	4a650513          	addi	a0,a0,1190 # ffffffffc0201698 <etext+0xf6>
    va_start(ap, fmt);
ffffffffc02001fa:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001fc:	f51ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200200:	65a2                	ld	a1,8(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	f29ff0ef          	jal	ra,ffffffffc020012c <vcprintf>
    cprintf("\n");
ffffffffc0200208:	00001517          	auipc	a0,0x1
ffffffffc020020c:	68050513          	addi	a0,a0,1664 # ffffffffc0201888 <etext+0x2e6>
ffffffffc0200210:	f3dff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200214:	b7f9                	j	ffffffffc02001e2 <__panic+0x20>

ffffffffc0200216 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200216:	8082                	ret

ffffffffc0200218 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200218:	0ff57513          	zext.b	a0,a0
ffffffffc020021c:	2e00106f          	j	ffffffffc02014fc <sbi_console_putchar>

ffffffffc0200220 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200220:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200222:	00001517          	auipc	a0,0x1
ffffffffc0200226:	49650513          	addi	a0,a0,1174 # ffffffffc02016b8 <etext+0x116>
void dtb_init(void) {
ffffffffc020022a:	fc86                	sd	ra,120(sp)
ffffffffc020022c:	f8a2                	sd	s0,112(sp)
ffffffffc020022e:	e8d2                	sd	s4,80(sp)
ffffffffc0200230:	f4a6                	sd	s1,104(sp)
ffffffffc0200232:	f0ca                	sd	s2,96(sp)
ffffffffc0200234:	ecce                	sd	s3,88(sp)
ffffffffc0200236:	e4d6                	sd	s5,72(sp)
ffffffffc0200238:	e0da                	sd	s6,64(sp)
ffffffffc020023a:	fc5e                	sd	s7,56(sp)
ffffffffc020023c:	f862                	sd	s8,48(sp)
ffffffffc020023e:	f466                	sd	s9,40(sp)
ffffffffc0200240:	f06a                	sd	s10,32(sp)
ffffffffc0200242:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200244:	f09ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200248:	00006597          	auipc	a1,0x6
ffffffffc020024c:	db85b583          	ld	a1,-584(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200250:	00001517          	auipc	a0,0x1
ffffffffc0200254:	47850513          	addi	a0,a0,1144 # ffffffffc02016c8 <etext+0x126>
ffffffffc0200258:	ef5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025c:	00006417          	auipc	s0,0x6
ffffffffc0200260:	dac40413          	addi	s0,s0,-596 # ffffffffc0206008 <boot_dtb>
ffffffffc0200264:	600c                	ld	a1,0(s0)
ffffffffc0200266:	00001517          	auipc	a0,0x1
ffffffffc020026a:	47250513          	addi	a0,a0,1138 # ffffffffc02016d8 <etext+0x136>
ffffffffc020026e:	edfff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200272:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200276:	00001517          	auipc	a0,0x1
ffffffffc020027a:	47a50513          	addi	a0,a0,1146 # ffffffffc02016f0 <etext+0x14e>
    if (boot_dtb == 0) {
ffffffffc020027e:	120a0463          	beqz	s4,ffffffffc02003a6 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200282:	57f5                	li	a5,-3
ffffffffc0200284:	07fa                	slli	a5,a5,0x1e
ffffffffc0200286:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020028a:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028c:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200290:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200292:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200296:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029e:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a2:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a8:	8ec9                	or	a3,a3,a0
ffffffffc02002aa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002ae:	1b7d                	addi	s6,s6,-1
ffffffffc02002b0:	0167f7b3          	and	a5,a5,s6
ffffffffc02002b4:	8dd5                	or	a1,a1,a3
ffffffffc02002b6:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002b8:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002bc:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002be:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9e65>
ffffffffc02002c2:	10f59163          	bne	a1,a5,ffffffffc02003c4 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002c6:	471c                	lw	a5,8(a4)
ffffffffc02002c8:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002ca:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002cc:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d0:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002d4:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d8:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002dc:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e0:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e4:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e8:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ec:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f4:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f6:	01146433          	or	s0,s0,a7
ffffffffc02002fa:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002fe:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200302:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200304:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200308:	8c49                	or	s0,s0,a0
ffffffffc020030a:	0166f6b3          	and	a3,a3,s6
ffffffffc020030e:	00ca6a33          	or	s4,s4,a2
ffffffffc0200312:	0167f7b3          	and	a5,a5,s6
ffffffffc0200316:	8c55                	or	s0,s0,a3
ffffffffc0200318:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020031c:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020031e:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200320:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200322:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200326:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200328:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020032e:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200330:	00001917          	auipc	s2,0x1
ffffffffc0200334:	41090913          	addi	s2,s2,1040 # ffffffffc0201740 <etext+0x19e>
ffffffffc0200338:	49bd                	li	s3,15
        switch (token) {
ffffffffc020033a:	4d91                	li	s11,4
ffffffffc020033c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020033e:	00001497          	auipc	s1,0x1
ffffffffc0200342:	3fa48493          	addi	s1,s1,1018 # ffffffffc0201738 <etext+0x196>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200346:	000a2703          	lw	a4,0(s4)
ffffffffc020034a:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020034e:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200352:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200356:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200362:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200364:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200368:	0087171b          	slliw	a4,a4,0x8
ffffffffc020036c:	8fd5                	or	a5,a5,a3
ffffffffc020036e:	00eb7733          	and	a4,s6,a4
ffffffffc0200372:	8fd9                	or	a5,a5,a4
ffffffffc0200374:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200376:	09778c63          	beq	a5,s7,ffffffffc020040e <dtb_init+0x1ee>
ffffffffc020037a:	00fbea63          	bltu	s7,a5,ffffffffc020038e <dtb_init+0x16e>
ffffffffc020037e:	07a78663          	beq	a5,s10,ffffffffc02003ea <dtb_init+0x1ca>
ffffffffc0200382:	4709                	li	a4,2
ffffffffc0200384:	00e79763          	bne	a5,a4,ffffffffc0200392 <dtb_init+0x172>
ffffffffc0200388:	4c81                	li	s9,0
ffffffffc020038a:	8a56                	mv	s4,s5
ffffffffc020038c:	bf6d                	j	ffffffffc0200346 <dtb_init+0x126>
ffffffffc020038e:	ffb78ee3          	beq	a5,s11,ffffffffc020038a <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200392:	00001517          	auipc	a0,0x1
ffffffffc0200396:	42650513          	addi	a0,a0,1062 # ffffffffc02017b8 <etext+0x216>
ffffffffc020039a:	db3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020039e:	00001517          	auipc	a0,0x1
ffffffffc02003a2:	45250513          	addi	a0,a0,1106 # ffffffffc02017f0 <etext+0x24e>
}
ffffffffc02003a6:	7446                	ld	s0,112(sp)
ffffffffc02003a8:	70e6                	ld	ra,120(sp)
ffffffffc02003aa:	74a6                	ld	s1,104(sp)
ffffffffc02003ac:	7906                	ld	s2,96(sp)
ffffffffc02003ae:	69e6                	ld	s3,88(sp)
ffffffffc02003b0:	6a46                	ld	s4,80(sp)
ffffffffc02003b2:	6aa6                	ld	s5,72(sp)
ffffffffc02003b4:	6b06                	ld	s6,64(sp)
ffffffffc02003b6:	7be2                	ld	s7,56(sp)
ffffffffc02003b8:	7c42                	ld	s8,48(sp)
ffffffffc02003ba:	7ca2                	ld	s9,40(sp)
ffffffffc02003bc:	7d02                	ld	s10,32(sp)
ffffffffc02003be:	6de2                	ld	s11,24(sp)
ffffffffc02003c0:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003c2:	b369                	j	ffffffffc020014c <cprintf>
}
ffffffffc02003c4:	7446                	ld	s0,112(sp)
ffffffffc02003c6:	70e6                	ld	ra,120(sp)
ffffffffc02003c8:	74a6                	ld	s1,104(sp)
ffffffffc02003ca:	7906                	ld	s2,96(sp)
ffffffffc02003cc:	69e6                	ld	s3,88(sp)
ffffffffc02003ce:	6a46                	ld	s4,80(sp)
ffffffffc02003d0:	6aa6                	ld	s5,72(sp)
ffffffffc02003d2:	6b06                	ld	s6,64(sp)
ffffffffc02003d4:	7be2                	ld	s7,56(sp)
ffffffffc02003d6:	7c42                	ld	s8,48(sp)
ffffffffc02003d8:	7ca2                	ld	s9,40(sp)
ffffffffc02003da:	7d02                	ld	s10,32(sp)
ffffffffc02003dc:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003de:	00001517          	auipc	a0,0x1
ffffffffc02003e2:	33250513          	addi	a0,a0,818 # ffffffffc0201710 <etext+0x16e>
}
ffffffffc02003e6:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e8:	b395                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003ea:	8556                	mv	a0,s5
ffffffffc02003ec:	12a010ef          	jal	ra,ffffffffc0201516 <strlen>
ffffffffc02003f0:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f2:	4619                	li	a2,6
ffffffffc02003f4:	85a6                	mv	a1,s1
ffffffffc02003f6:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003f8:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	170010ef          	jal	ra,ffffffffc020156a <strncmp>
ffffffffc02003fe:	e111                	bnez	a0,ffffffffc0200402 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200400:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200402:	0a91                	addi	s5,s5,4
ffffffffc0200404:	9ad2                	add	s5,s5,s4
ffffffffc0200406:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020040a:	8a56                	mv	s4,s5
ffffffffc020040c:	bf2d                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020040e:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200412:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020041a:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200422:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200426:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020042a:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042e:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200432:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200436:	00eaeab3          	or	s5,s5,a4
ffffffffc020043a:	00fb77b3          	and	a5,s6,a5
ffffffffc020043e:	00faeab3          	or	s5,s5,a5
ffffffffc0200442:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200444:	000c9c63          	bnez	s9,ffffffffc020045c <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200448:	1a82                	slli	s5,s5,0x20
ffffffffc020044a:	00368793          	addi	a5,a3,3
ffffffffc020044e:	020ada93          	srli	s5,s5,0x20
ffffffffc0200452:	9abe                	add	s5,s5,a5
ffffffffc0200454:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200458:	8a56                	mv	s4,s5
ffffffffc020045a:	b5f5                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020045c:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200460:	85ca                	mv	a1,s2
ffffffffc0200462:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200464:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200468:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046c:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200470:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200474:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200478:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047a:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200482:	8d59                	or	a0,a0,a4
ffffffffc0200484:	00fb77b3          	and	a5,s6,a5
ffffffffc0200488:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020048a:	1502                	slli	a0,a0,0x20
ffffffffc020048c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020048e:	9522                	add	a0,a0,s0
ffffffffc0200490:	0bc010ef          	jal	ra,ffffffffc020154c <strcmp>
ffffffffc0200494:	66a2                	ld	a3,8(sp)
ffffffffc0200496:	f94d                	bnez	a0,ffffffffc0200448 <dtb_init+0x228>
ffffffffc0200498:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200448 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020049c:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004a4:	00001517          	auipc	a0,0x1
ffffffffc02004a8:	2a450513          	addi	a0,a0,676 # ffffffffc0201748 <etext+0x1a6>
           fdt32_to_cpu(x >> 32);
ffffffffc02004ac:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b0:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004b4:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b8:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004bc:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c0:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c4:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0187d693          	srli	a3,a5,0x18
ffffffffc02004cc:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d0:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004d4:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d8:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004dc:	010f6f33          	or	t5,t5,a6
ffffffffc02004e0:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004e4:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e8:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ec:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0186f6b3          	and	a3,a3,s8
ffffffffc02004f4:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02004f8:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fc:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200500:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	8361                	srli	a4,a4,0x18
ffffffffc0200506:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020050a:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020050e:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200512:	00cb7633          	and	a2,s6,a2
ffffffffc0200516:	0088181b          	slliw	a6,a6,0x8
ffffffffc020051a:	0085959b          	slliw	a1,a1,0x8
ffffffffc020051e:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200522:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200526:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200532:	011b78b3          	and	a7,s6,a7
ffffffffc0200536:	005eeeb3          	or	t4,t4,t0
ffffffffc020053a:	00c6e733          	or	a4,a3,a2
ffffffffc020053e:	006c6c33          	or	s8,s8,t1
ffffffffc0200542:	010b76b3          	and	a3,s6,a6
ffffffffc0200546:	00bb7b33          	and	s6,s6,a1
ffffffffc020054a:	01d7e7b3          	or	a5,a5,t4
ffffffffc020054e:	016c6b33          	or	s6,s8,s6
ffffffffc0200552:	01146433          	or	s0,s0,a7
ffffffffc0200556:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200558:	1702                	slli	a4,a4,0x20
ffffffffc020055a:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020055c:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020055e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200560:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200562:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200566:	0167eb33          	or	s6,a5,s6
ffffffffc020056a:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020056c:	be1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200570:	85a2                	mv	a1,s0
ffffffffc0200572:	00001517          	auipc	a0,0x1
ffffffffc0200576:	1f650513          	addi	a0,a0,502 # ffffffffc0201768 <etext+0x1c6>
ffffffffc020057a:	bd3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020057e:	014b5613          	srli	a2,s6,0x14
ffffffffc0200582:	85da                	mv	a1,s6
ffffffffc0200584:	00001517          	auipc	a0,0x1
ffffffffc0200588:	1fc50513          	addi	a0,a0,508 # ffffffffc0201780 <etext+0x1de>
ffffffffc020058c:	bc1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200590:	008b05b3          	add	a1,s6,s0
ffffffffc0200594:	15fd                	addi	a1,a1,-1
ffffffffc0200596:	00001517          	auipc	a0,0x1
ffffffffc020059a:	20a50513          	addi	a0,a0,522 # ffffffffc02017a0 <etext+0x1fe>
ffffffffc020059e:	bafff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005a2:	00001517          	auipc	a0,0x1
ffffffffc02005a6:	24e50513          	addi	a0,a0,590 # ffffffffc02017f0 <etext+0x24e>
        memory_base = mem_base;
ffffffffc02005aa:	00006797          	auipc	a5,0x6
ffffffffc02005ae:	a687bb23          	sd	s0,-1418(a5) # ffffffffc0206020 <memory_base>
        memory_size = mem_size;
ffffffffc02005b2:	00006797          	auipc	a5,0x6
ffffffffc02005b6:	a767bb23          	sd	s6,-1418(a5) # ffffffffc0206028 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005ba:	b3f5                	j	ffffffffc02003a6 <dtb_init+0x186>

ffffffffc02005bc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005bc:	00006517          	auipc	a0,0x6
ffffffffc02005c0:	a6453503          	ld	a0,-1436(a0) # ffffffffc0206020 <memory_base>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005c6:	00006517          	auipc	a0,0x6
ffffffffc02005ca:	a6253503          	ld	a0,-1438(a0) # ffffffffc0206028 <memory_size>
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <buddy_init>:
}

// pmm接口实现
static void buddy_init(void) {
    // 空实现，初始化在init_memmap中完成
}
ffffffffc02005d0:	8082                	ret

ffffffffc02005d2 <buddy_nr_free_pages>:
    // 释放到buddy系统 - 这才是真正释放内存的操作
    buddy_free(buddy_system, block_offset, block_size);
}

static size_t buddy_nr_free_pages(void) {
    if (!buddy_system) return 0;
ffffffffc02005d2:	00006797          	auipc	a5,0x6
ffffffffc02005d6:	a6e7b783          	ld	a5,-1426(a5) # ffffffffc0206040 <buddy_system>
ffffffffc02005da:	c781                	beqz	a5,ffffffffc02005e2 <buddy_nr_free_pages+0x10>
    unsigned free_blocks = nr_free_blocks(buddy_system);
    // 转换为页数（1块 = 1页）
    return free_blocks;
ffffffffc02005dc:	0047e503          	lwu	a0,4(a5)
ffffffffc02005e0:	8082                	ret
    if (!buddy_system) return 0;
ffffffffc02005e2:	4501                	li	a0,0
}
ffffffffc02005e4:	8082                	ret

ffffffffc02005e6 <buddy_free.part.0>:
void buddy_free(struct buddy* self, int block_offset, unsigned block_size) {
ffffffffc02005e6:	7159                	addi	sp,sp,-112
ffffffffc02005e8:	e0d2                	sd	s4,64(sp)
ffffffffc02005ea:	8a2a                	mv	s4,a0
    cprintf("buddy_free: starting free process for offset=%d, size=%u\n", 
ffffffffc02005ec:	00001517          	auipc	a0,0x1
ffffffffc02005f0:	21c50513          	addi	a0,a0,540 # ffffffffc0201808 <etext+0x266>
void buddy_free(struct buddy* self, int block_offset, unsigned block_size) {
ffffffffc02005f4:	eca6                	sd	s1,88(sp)
ffffffffc02005f6:	e8ca                	sd	s2,80(sp)
ffffffffc02005f8:	f85a                	sd	s6,48(sp)
ffffffffc02005fa:	f486                	sd	ra,104(sp)
ffffffffc02005fc:	f0a2                	sd	s0,96(sp)
ffffffffc02005fe:	e4ce                	sd	s3,72(sp)
ffffffffc0200600:	fc56                	sd	s5,56(sp)
ffffffffc0200602:	f45e                	sd	s7,40(sp)
ffffffffc0200604:	f062                	sd	s8,32(sp)
ffffffffc0200606:	ec66                	sd	s9,24(sp)
ffffffffc0200608:	e86a                	sd	s10,16(sp)
ffffffffc020060a:	e46e                	sd	s11,8(sp)
ffffffffc020060c:	8b32                	mv	s6,a2
ffffffffc020060e:	892e                	mv	s2,a1
    cprintf("buddy_free: starting free process for offset=%d, size=%u\n", 
ffffffffc0200610:	b3dff0ef          	jal	ra,ffffffffc020014c <cprintf>
    unsigned node_size = self->size;
ffffffffc0200614:	000a2483          	lw	s1,0(s4)
    cprintf("buddy_free: searching for target node from root (idx=0, size=%u)\n", node_size);
ffffffffc0200618:	00001517          	auipc	a0,0x1
ffffffffc020061c:	23050513          	addi	a0,a0,560 # ffffffffc0201848 <etext+0x2a6>
ffffffffc0200620:	85a6                	mv	a1,s1
ffffffffc0200622:	b2bff0ef          	jal	ra,ffffffffc020014c <cprintf>
    while (node_size != block_size) {
ffffffffc0200626:	189b0863          	beq	s6,s1,ffffffffc02007b6 <buddy_free.part.0+0x1d0>
    unsigned idx = 0;
ffffffffc020062a:	4401                	li	s0,0
    unsigned depth = 0;
ffffffffc020062c:	4981                	li	s3,0
        cprintf("buddy_free: depth=%u, current node idx=%u, size=%u, offset=%d\n", 
ffffffffc020062e:	00001c17          	auipc	s8,0x1
ffffffffc0200632:	262c0c13          	addi	s8,s8,610 # ffffffffc0201890 <etext+0x2ee>
            cprintf("buddy_free:   -> going RIGHT (idx=%u), new offset=%d\n", idx, offset);
ffffffffc0200636:	00001c97          	auipc	s9,0x1
ffffffffc020063a:	2dac8c93          	addi	s9,s9,730 # ffffffffc0201910 <etext+0x36e>
            cprintf("buddy_free:   -> going LEFT (idx=%u), offset remains %d\n", idx, offset);
ffffffffc020063e:	00001b97          	auipc	s7,0x1
ffffffffc0200642:	292b8b93          	addi	s7,s7,658 # ffffffffc02018d0 <etext+0x32e>
        node_size /= 2;
ffffffffc0200646:	0014d49b          	srliw	s1,s1,0x1
        depth++;
ffffffffc020064a:	2985                	addiw	s3,s3,1
        cprintf("buddy_free: depth=%u, current node idx=%u, size=%u, offset=%d\n", 
ffffffffc020064c:	8622                	mv	a2,s0
ffffffffc020064e:	874a                	mv	a4,s2
ffffffffc0200650:	85ce                	mv	a1,s3
ffffffffc0200652:	86a6                	mv	a3,s1
ffffffffc0200654:	8562                	mv	a0,s8
ffffffffc0200656:	af7ff0ef          	jal	ra,ffffffffc020014c <cprintf>
            idx = left_leaf(idx);
ffffffffc020065a:	0004079b          	sext.w	a5,s0
    x |= x>>8;
    x |= x>>16;
    return x+1;
}

static inline int left_leaf(int idx) { return 2 * idx + 1; }
ffffffffc020065e:	0017941b          	slliw	s0,a5,0x1
ffffffffc0200662:	2405                	addiw	s0,s0,1
            cprintf("buddy_free:   -> going LEFT (idx=%u), offset remains %d\n", idx, offset);
ffffffffc0200664:	864a                	mv	a2,s2
ffffffffc0200666:	855e                	mv	a0,s7
static inline int right_leaf(int idx) { return 2 * idx + 2; }
ffffffffc0200668:	2785                	addiw	a5,a5,1
ffffffffc020066a:	85a2                	mv	a1,s0
        if (offset < node_size) {
ffffffffc020066c:	0009071b          	sext.w	a4,s2
ffffffffc0200670:	00996963          	bltu	s2,s1,ffffffffc0200682 <buddy_free.part.0+0x9c>
            idx = right_leaf(idx);
ffffffffc0200674:	0017941b          	slliw	s0,a5,0x1
            offset -= node_size;
ffffffffc0200678:	4097093b          	subw	s2,a4,s1
            cprintf("buddy_free:   -> going RIGHT (idx=%u), new offset=%d\n", idx, offset);
ffffffffc020067c:	864a                	mv	a2,s2
ffffffffc020067e:	85a2                	mv	a1,s0
ffffffffc0200680:	8566                	mv	a0,s9
ffffffffc0200682:	acbff0ef          	jal	ra,ffffffffc020014c <cprintf>
    while (node_size != block_size) {
ffffffffc0200686:	fc9b10e3          	bne	s6,s1,ffffffffc0200646 <buddy_free.part.0+0x60>
    cprintf("buddy_free: found target node! idx=%u, size=%u\n", idx, node_size);
ffffffffc020068a:	8626                	mv	a2,s1
ffffffffc020068c:	85a2                	mv	a1,s0
ffffffffc020068e:	00001517          	auipc	a0,0x1
ffffffffc0200692:	2ba50513          	addi	a0,a0,698 # ffffffffc0201948 <etext+0x3a6>
ffffffffc0200696:	ab7ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    self->longest[idx] = node_size;
ffffffffc020069a:	02041713          	slli	a4,s0,0x20
ffffffffc020069e:	01e75793          	srli	a5,a4,0x1e
ffffffffc02006a2:	97d2                	add	a5,a5,s4
ffffffffc02006a4:	c3c4                	sw	s1,4(a5)
    cprintf("buddy_free: set node idx=%u to free (size=%u)\n", idx, node_size);
ffffffffc02006a6:	8626                	mv	a2,s1
ffffffffc02006a8:	85a2                	mv	a1,s0
ffffffffc02006aa:	00001517          	auipc	a0,0x1
ffffffffc02006ae:	2ce50513          	addi	a0,a0,718 # ffffffffc0201978 <etext+0x3d6>
ffffffffc02006b2:	a9bff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("buddy_free: starting buddy merging process...\n");
ffffffffc02006b6:	00001517          	auipc	a0,0x1
ffffffffc02006ba:	2f250513          	addi	a0,a0,754 # ffffffffc02019a8 <etext+0x406>
ffffffffc02006be:	a8fff0ef          	jal	ra,ffffffffc020014c <cprintf>
    while (merge_idx > 0) {
ffffffffc02006c2:	c44d                	beqz	s0,ffffffffc020076c <buddy_free.part.0+0x186>
        cprintf("buddy_free:   parent idx=%u, size=%u\n", parent_idx, merge_size);
ffffffffc02006c4:	00001c17          	auipc	s8,0x1
ffffffffc02006c8:	314c0c13          	addi	s8,s8,788 # ffffffffc02019d8 <etext+0x436>
        cprintf("buddy_free:     left child idx=%u, free=%u\n", left_idx, left_free);
ffffffffc02006cc:	00001b97          	auipc	s7,0x1
ffffffffc02006d0:	334b8b93          	addi	s7,s7,820 # ffffffffc0201a00 <etext+0x45e>
        cprintf("buddy_free:     right child idx=%u, free=%u\n", right_idx, right_free);
ffffffffc02006d4:	00001b17          	auipc	s6,0x1
ffffffffc02006d8:	35cb0b13          	addi	s6,s6,860 # ffffffffc0201a30 <etext+0x48e>
static inline int parent(int idx) { return (idx - 1) / 2; }
ffffffffc02006dc:	347d                	addiw	s0,s0,-1
ffffffffc02006de:	01f4591b          	srliw	s2,s0,0x1f
ffffffffc02006e2:	0089093b          	addw	s2,s2,s0
ffffffffc02006e6:	4019591b          	sraiw	s2,s2,0x1
static inline int left_leaf(int idx) { return 2 * idx + 1; }
ffffffffc02006ea:	0019179b          	slliw	a5,s2,0x1
ffffffffc02006ee:	0017859b          	addiw	a1,a5,1
        unsigned left_free = self->longest[left_idx];
ffffffffc02006f2:	02059713          	slli	a4,a1,0x20
static inline int right_leaf(int idx) { return 2 * idx + 2; }
ffffffffc02006f6:	2789                	addiw	a5,a5,2
ffffffffc02006f8:	01e75693          	srli	a3,a4,0x1e
        unsigned right_free = self->longest[right_idx];
ffffffffc02006fc:	02079713          	slli	a4,a5,0x20
        unsigned left_free = self->longest[left_idx];
ffffffffc0200700:	96d2                	add	a3,a3,s4
        unsigned right_free = self->longest[right_idx];
ffffffffc0200702:	9301                	srli	a4,a4,0x20
        unsigned left_free = self->longest[left_idx];
ffffffffc0200704:	0046ad83          	lw	s11,4(a3)
        unsigned right_free = self->longest[right_idx];
ffffffffc0200708:	070a                	slli	a4,a4,0x2
        merge_size *= 2;
ffffffffc020070a:	0014949b          	slliw	s1,s1,0x1
        unsigned parent_idx = parent(merge_idx);
ffffffffc020070e:	0009041b          	sext.w	s0,s2
        unsigned right_free = self->longest[right_idx];
ffffffffc0200712:	9752                	add	a4,a4,s4
        unsigned left_idx = left_leaf(parent_idx);
ffffffffc0200714:	00058d1b          	sext.w	s10,a1
        cprintf("buddy_free:   parent idx=%u, size=%u\n", parent_idx, merge_size);
ffffffffc0200718:	8626                	mv	a2,s1
ffffffffc020071a:	85a2                	mv	a1,s0
ffffffffc020071c:	8562                	mv	a0,s8
        unsigned right_free = self->longest[right_idx];
ffffffffc020071e:	00472c83          	lw	s9,4(a4)
        unsigned right_idx = right_leaf(parent_idx);
ffffffffc0200722:	0007899b          	sext.w	s3,a5
        cprintf("buddy_free:   parent idx=%u, size=%u\n", parent_idx, merge_size);
ffffffffc0200726:	a27ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("buddy_free:     left child idx=%u, free=%u\n", left_idx, left_free);
ffffffffc020072a:	866e                	mv	a2,s11
ffffffffc020072c:	85ea                	mv	a1,s10
ffffffffc020072e:	855e                	mv	a0,s7
ffffffffc0200730:	a1dff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("buddy_free:     right child idx=%u, free=%u\n", right_idx, right_free);
ffffffffc0200734:	8666                	mv	a2,s9
ffffffffc0200736:	85ce                	mv	a1,s3
ffffffffc0200738:	855a                	mv	a0,s6
ffffffffc020073a:	a13ff0ef          	jal	ra,ffffffffc020014c <cprintf>
            self->longest[parent_idx] = new_value;
ffffffffc020073e:	02091713          	slli	a4,s2,0x20
ffffffffc0200742:	01e75793          	srli	a5,a4,0x1e
        if (left_free + right_free == merge_size) {
ffffffffc0200746:	019d863b          	addw	a2,s11,s9
            self->longest[parent_idx] = new_value;
ffffffffc020074a:	97d2                	add	a5,a5,s4
            cprintf("buddy_free:     -> NOT merged, parent set to %u\n", new_value);
ffffffffc020074c:	00001517          	auipc	a0,0x1
ffffffffc0200750:	34450513          	addi	a0,a0,836 # ffffffffc0201a90 <etext+0x4ee>
        if (left_free + right_free == merge_size) {
ffffffffc0200754:	04960163          	beq	a2,s1,ffffffffc0200796 <buddy_free.part.0+0x1b0>
static inline int max(int a, int b) { return (a > b) ? a : b; }
ffffffffc0200758:	000d859b          	sext.w	a1,s11
ffffffffc020075c:	019dd463          	bge	s11,s9,ffffffffc0200764 <buddy_free.part.0+0x17e>
ffffffffc0200760:	000c859b          	sext.w	a1,s9
            self->longest[parent_idx] = new_value;
ffffffffc0200764:	c3cc                	sw	a1,4(a5)
            cprintf("buddy_free:     -> NOT merged, parent set to %u\n", new_value);
ffffffffc0200766:	9e7ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    while (merge_idx > 0) {
ffffffffc020076a:	f82d                	bnez	s0,ffffffffc02006dc <buddy_free.part.0+0xf6>
}
ffffffffc020076c:	7406                	ld	s0,96(sp)
    cprintf("buddy_free: free process completed! root now has %u free blocks\n", 
ffffffffc020076e:	004a2583          	lw	a1,4(s4)
}
ffffffffc0200772:	70a6                	ld	ra,104(sp)
ffffffffc0200774:	64e6                	ld	s1,88(sp)
ffffffffc0200776:	6946                	ld	s2,80(sp)
ffffffffc0200778:	69a6                	ld	s3,72(sp)
ffffffffc020077a:	6a06                	ld	s4,64(sp)
ffffffffc020077c:	7ae2                	ld	s5,56(sp)
ffffffffc020077e:	7b42                	ld	s6,48(sp)
ffffffffc0200780:	7ba2                	ld	s7,40(sp)
ffffffffc0200782:	7c02                	ld	s8,32(sp)
ffffffffc0200784:	6ce2                	ld	s9,24(sp)
ffffffffc0200786:	6d42                	ld	s10,16(sp)
ffffffffc0200788:	6da2                	ld	s11,8(sp)
    cprintf("buddy_free: free process completed! root now has %u free blocks\n", 
ffffffffc020078a:	00001517          	auipc	a0,0x1
ffffffffc020078e:	33e50513          	addi	a0,a0,830 # ffffffffc0201ac8 <etext+0x526>
}
ffffffffc0200792:	6165                	addi	sp,sp,112
    cprintf("buddy_free: free process completed! root now has %u free blocks\n", 
ffffffffc0200794:	ba65                	j	ffffffffc020014c <cprintf>
            self->longest[parent_idx] = merge_size;
ffffffffc0200796:	02091793          	slli	a5,s2,0x20
ffffffffc020079a:	01e7d913          	srli	s2,a5,0x1e
ffffffffc020079e:	9952                	add	s2,s2,s4
ffffffffc02007a0:	00992223          	sw	s1,4(s2)
            cprintf("buddy_free:     -> MERGED! parent set to %u\n", merge_size);
ffffffffc02007a4:	85a6                	mv	a1,s1
ffffffffc02007a6:	00001517          	auipc	a0,0x1
ffffffffc02007aa:	2ba50513          	addi	a0,a0,698 # ffffffffc0201a60 <etext+0x4be>
ffffffffc02007ae:	99fff0ef          	jal	ra,ffffffffc020014c <cprintf>
    while (merge_idx > 0) {
ffffffffc02007b2:	f40d                	bnez	s0,ffffffffc02006dc <buddy_free.part.0+0xf6>
ffffffffc02007b4:	bf65                	j	ffffffffc020076c <buddy_free.part.0+0x186>
    cprintf("buddy_free: found target node! idx=%u, size=%u\n", idx, node_size);
ffffffffc02007b6:	865a                	mv	a2,s6
ffffffffc02007b8:	4581                	li	a1,0
ffffffffc02007ba:	00001517          	auipc	a0,0x1
ffffffffc02007be:	18e50513          	addi	a0,a0,398 # ffffffffc0201948 <etext+0x3a6>
ffffffffc02007c2:	98bff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("buddy_free: set node idx=%u to free (size=%u)\n", idx, node_size);
ffffffffc02007c6:	865a                	mv	a2,s6
    self->longest[idx] = node_size;
ffffffffc02007c8:	016a2223          	sw	s6,4(s4)
    cprintf("buddy_free: set node idx=%u to free (size=%u)\n", idx, node_size);
ffffffffc02007cc:	4581                	li	a1,0
ffffffffc02007ce:	00001517          	auipc	a0,0x1
ffffffffc02007d2:	1aa50513          	addi	a0,a0,426 # ffffffffc0201978 <etext+0x3d6>
ffffffffc02007d6:	977ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("buddy_free: starting buddy merging process...\n");
ffffffffc02007da:	00001517          	auipc	a0,0x1
ffffffffc02007de:	1ce50513          	addi	a0,a0,462 # ffffffffc02019a8 <etext+0x406>
ffffffffc02007e2:	96bff0ef          	jal	ra,ffffffffc020014c <cprintf>
    while (merge_idx > 0) {
ffffffffc02007e6:	b759                	j	ffffffffc020076c <buddy_free.part.0+0x186>

ffffffffc02007e8 <buddy_free_pages.part.0>:
static void buddy_free_pages(struct Page* base, size_t n) {
ffffffffc02007e8:	1101                	addi	sp,sp,-32
ffffffffc02007ea:	e822                	sd	s0,16(sp)
    size_t block_offset = base - buddy_page_base;
ffffffffc02007ec:	00006417          	auipc	s0,0x6
ffffffffc02007f0:	84443403          	ld	s0,-1980(s0) # ffffffffc0206030 <buddy_page_base>
ffffffffc02007f4:	40850433          	sub	s0,a0,s0
ffffffffc02007f8:	00002797          	auipc	a5,0x2
ffffffffc02007fc:	e007b783          	ld	a5,-512(a5) # ffffffffc02025f8 <error_string+0x38>
ffffffffc0200800:	840d                	srai	s0,s0,0x3
ffffffffc0200802:	02f40433          	mul	s0,s0,a5
static void buddy_free_pages(struct Page* base, size_t n) {
ffffffffc0200806:	e426                	sd	s1,8(sp)
ffffffffc0200808:	84aa                	mv	s1,a0
    cprintf("buddy_free: freeing %lu pages at block offset %lu\n", n, block_offset);
ffffffffc020080a:	00001517          	auipc	a0,0x1
ffffffffc020080e:	30650513          	addi	a0,a0,774 # ffffffffc0201b10 <etext+0x56e>
static void buddy_free_pages(struct Page* base, size_t n) {
ffffffffc0200812:	e04a                	sd	s2,0(sp)
ffffffffc0200814:	ec06                	sd	ra,24(sp)
ffffffffc0200816:	892e                	mv	s2,a1
    cprintf("buddy_free: freeing %lu pages at block offset %lu\n", n, block_offset);
ffffffffc0200818:	8622                	mv	a2,s0
ffffffffc020081a:	933ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (base->property != n) {
ffffffffc020081e:	488c                	lw	a1,16(s1)
ffffffffc0200820:	02059793          	slli	a5,a1,0x20
ffffffffc0200824:	9381                	srli	a5,a5,0x20
ffffffffc0200826:	00f90963          	beq	s2,a5,ffffffffc0200838 <buddy_free_pages.part.0+0x50>
        cprintf("warning: base->property (%u) != n (%lu)\n", base->property, n);
ffffffffc020082a:	864a                	mv	a2,s2
ffffffffc020082c:	00001517          	auipc	a0,0x1
ffffffffc0200830:	31c50513          	addi	a0,a0,796 # ffffffffc0201b48 <etext+0x5a6>
ffffffffc0200834:	919ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (; p != base + n; p++) {
ffffffffc0200838:	00291713          	slli	a4,s2,0x2
ffffffffc020083c:	974a                	add	a4,a4,s2
ffffffffc020083e:	070e                	slli	a4,a4,0x3
ffffffffc0200840:	9726                	add	a4,a4,s1
ffffffffc0200842:	00e48b63          	beq	s1,a4,ffffffffc0200858 <buddy_free_pages.part.0+0x70>
ffffffffc0200846:	87a6                	mv	a5,s1



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200848:	0007a023          	sw	zero,0(a5)
        p->flags = 0;
ffffffffc020084c:	0007b423          	sd	zero,8(a5)
    for (; p != base + n; p++) {
ffffffffc0200850:	02878793          	addi	a5,a5,40
ffffffffc0200854:	fee79ae3          	bne	a5,a4,ffffffffc0200848 <buddy_free_pages.part.0+0x60>
    ClearPageProperty(base);
ffffffffc0200858:	649c                	ld	a5,8(s1)
    buddy_free(buddy_system, block_offset, block_size);
ffffffffc020085a:	00005517          	auipc	a0,0x5
ffffffffc020085e:	7e653503          	ld	a0,2022(a0) # ffffffffc0206040 <buddy_system>
ffffffffc0200862:	0004059b          	sext.w	a1,s0
    ClearPageProperty(base);
ffffffffc0200866:	9bf5                	andi	a5,a5,-3
ffffffffc0200868:	e49c                	sd	a5,8(s1)
    if (!self || block_offset < 0 || block_offset >= (int)self->size) {
ffffffffc020086a:	c511                	beqz	a0,ffffffffc0200876 <buddy_free_pages.part.0+0x8e>
ffffffffc020086c:	0005c563          	bltz	a1,ffffffffc0200876 <buddy_free_pages.part.0+0x8e>
ffffffffc0200870:	411c                	lw	a5,0(a0)
ffffffffc0200872:	00f5c863          	blt	a1,a5,ffffffffc0200882 <buddy_free_pages.part.0+0x9a>
}
ffffffffc0200876:	60e2                	ld	ra,24(sp)
ffffffffc0200878:	6442                	ld	s0,16(sp)
ffffffffc020087a:	64a2                	ld	s1,8(sp)
ffffffffc020087c:	6902                	ld	s2,0(sp)
ffffffffc020087e:	6105                	addi	sp,sp,32
ffffffffc0200880:	8082                	ret
ffffffffc0200882:	6442                	ld	s0,16(sp)
ffffffffc0200884:	60e2                	ld	ra,24(sp)
ffffffffc0200886:	64a2                	ld	s1,8(sp)
ffffffffc0200888:	0009061b          	sext.w	a2,s2
ffffffffc020088c:	6902                	ld	s2,0(sp)
ffffffffc020088e:	6105                	addi	sp,sp,32
ffffffffc0200890:	bb99                	j	ffffffffc02005e6 <buddy_free.part.0>

ffffffffc0200892 <buddy_free_pages>:
    if (!buddy_system || !base || n == 0) return;
ffffffffc0200892:	00005697          	auipc	a3,0x5
ffffffffc0200896:	7ae6b683          	ld	a3,1966(a3) # ffffffffc0206040 <buddy_system>
ffffffffc020089a:	c299                	beqz	a3,ffffffffc02008a0 <buddy_free_pages+0xe>
ffffffffc020089c:	c111                	beqz	a0,ffffffffc02008a0 <buddy_free_pages+0xe>
ffffffffc020089e:	e191                	bnez	a1,ffffffffc02008a2 <buddy_free_pages+0x10>
}
ffffffffc02008a0:	8082                	ret
ffffffffc02008a2:	b799                	j	ffffffffc02007e8 <buddy_free_pages.part.0>

ffffffffc02008a4 <buddy_new>:
struct buddy* buddy_new(void* addr, unsigned blocks) {
ffffffffc02008a4:	862a                	mv	a2,a0
    if (!addr || blocks < 1 || !is_pow_of_2(blocks))
ffffffffc02008a6:	c929                	beqz	a0,ffffffffc02008f8 <buddy_new+0x54>
ffffffffc02008a8:	c9a1                	beqz	a1,ffffffffc02008f8 <buddy_new+0x54>
    return x && !(x & (x-1));
ffffffffc02008aa:	fff5879b          	addiw	a5,a1,-1
ffffffffc02008ae:	8fed                	and	a5,a5,a1
ffffffffc02008b0:	2781                	sext.w	a5,a5
        return NULL;
ffffffffc02008b2:	4501                	li	a0,0
ffffffffc02008b4:	e3b9                	bnez	a5,ffffffffc02008fa <buddy_new+0x56>
    for (int i = 0; i < 2 * blocks - 1; ++i) {
ffffffffc02008b6:	0015981b          	slliw	a6,a1,0x1
    self->size = blocks;
ffffffffc02008ba:	c20c                	sw	a1,0(a2)
    for (int i = 0; i < 2 * blocks - 1; ++i) {
ffffffffc02008bc:	00460693          	addi	a3,a2,4 # ff0004 <kern_entry-0xffffffffbf20fffc>
ffffffffc02008c0:	387d                	addiw	a6,a6,-1
ffffffffc02008c2:	832e                	mv	t1,a1
ffffffffc02008c4:	a029                	j	ffffffffc02008ce <buddy_new+0x2a>
            self->longest[i] = blocks;
ffffffffc02008c6:	c24c                	sw	a1,4(a2)
    for (int i = 0; i < 2 * blocks - 1; ++i) {
ffffffffc02008c8:	0691                	addi	a3,a3,4
ffffffffc02008ca:	03078563          	beq	a5,a6,ffffffffc02008f4 <buddy_new+0x50>
            if (is_pow_of_2(i + 1))
ffffffffc02008ce:	0017871b          	addiw	a4,a5,1
ffffffffc02008d2:	853e                	mv	a0,a5
ffffffffc02008d4:	2781                	sext.w	a5,a5
ffffffffc02008d6:	8ff9                	and	a5,a5,a4
ffffffffc02008d8:	0007889b          	sext.w	a7,a5
ffffffffc02008dc:	0007079b          	sext.w	a5,a4
        if (i == 0) {
ffffffffc02008e0:	d17d                	beqz	a0,ffffffffc02008c6 <buddy_new+0x22>
ffffffffc02008e2:	00089463          	bnez	a7,ffffffffc02008ea <buddy_new+0x46>
                node_size /= 2;
ffffffffc02008e6:	0013531b          	srliw	t1,t1,0x1
            self->longest[i] = node_size;
ffffffffc02008ea:	0066a023          	sw	t1,0(a3)
    for (int i = 0; i < 2 * blocks - 1; ++i) {
ffffffffc02008ee:	0691                	addi	a3,a3,4
ffffffffc02008f0:	fd079fe3          	bne	a5,a6,ffffffffc02008ce <buddy_new+0x2a>
ffffffffc02008f4:	8532                	mv	a0,a2
ffffffffc02008f6:	8082                	ret
        return NULL;
ffffffffc02008f8:	4501                	li	a0,0
}
ffffffffc02008fa:	8082                	ret

ffffffffc02008fc <buddy_init_memmap>:
static void buddy_init_memmap(struct Page* base, size_t n) {
ffffffffc02008fc:	7179                	addi	sp,sp,-48
ffffffffc02008fe:	f406                	sd	ra,40(sp)
ffffffffc0200900:	f022                	sd	s0,32(sp)
ffffffffc0200902:	ec26                	sd	s1,24(sp)
ffffffffc0200904:	e84a                	sd	s2,16(sp)
ffffffffc0200906:	e44e                	sd	s3,8(sp)
ffffffffc0200908:	e052                	sd	s4,0(sp)
    assert(n > 0);
ffffffffc020090a:	14058263          	beqz	a1,ffffffffc0200a4e <buddy_init_memmap+0x152>
    total_pages = 1;
ffffffffc020090e:	00005a17          	auipc	s4,0x5
ffffffffc0200912:	742a0a13          	addi	s4,s4,1858 # ffffffffc0206050 <total_pages>
ffffffffc0200916:	4785                	li	a5,1
ffffffffc0200918:	00fa3023          	sd	a5,0(s4)
ffffffffc020091c:	872e                	mv	a4,a1
ffffffffc020091e:	842a                	mv	s0,a0
    while (total_pages * 2 <= n) {
ffffffffc0200920:	10f58463          	beq	a1,a5,ffffffffc0200a28 <buddy_init_memmap+0x12c>
ffffffffc0200924:	4789                	li	a5,2
ffffffffc0200926:	85be                	mv	a1,a5
ffffffffc0200928:	0786                	slli	a5,a5,0x1
ffffffffc020092a:	fef77ee3          	bgeu	a4,a5,ffffffffc0200926 <buddy_init_memmap+0x2a>
            total_pages, total_pages * PGSIZE / 1024 / 1024);
ffffffffc020092e:	00c59613          	slli	a2,a1,0xc
ffffffffc0200932:	00ba3023          	sd	a1,0(s4)
    cprintf("buddy: initializing with %lu pages (%lu MB)\n", 
ffffffffc0200936:	8251                	srli	a2,a2,0x14
    total_blocks = total_pages;
ffffffffc0200938:	00005497          	auipc	s1,0x5
ffffffffc020093c:	71048493          	addi	s1,s1,1808 # ffffffffc0206048 <total_blocks>
    cprintf("buddy: initializing with %lu pages (%lu MB)\n", 
ffffffffc0200940:	00001517          	auipc	a0,0x1
ffffffffc0200944:	27050513          	addi	a0,a0,624 # ffffffffc0201bb0 <etext+0x60e>
    total_blocks = total_pages;
ffffffffc0200948:	e08c                	sd	a1,0(s1)
    cprintf("buddy: initializing with %lu pages (%lu MB)\n", 
ffffffffc020094a:	803ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    size_t buddy_struct_size = BUDDY_STRUCT_SIZE(total_blocks);
ffffffffc020094e:	608c                	ld	a1,0(s1)
    buddy_struct_pages = (buddy_struct_size + PGSIZE - 1) / PGSIZE;
ffffffffc0200950:	6605                	lui	a2,0x1
ffffffffc0200952:	166d                	addi	a2,a2,-5
    size_t buddy_struct_size = BUDDY_STRUCT_SIZE(total_blocks);
ffffffffc0200954:	058e                	slli	a1,a1,0x3
    buddy_struct_pages = (buddy_struct_size + PGSIZE - 1) / PGSIZE;
ffffffffc0200956:	962e                	add	a2,a2,a1
ffffffffc0200958:	8231                	srli	a2,a2,0xc
ffffffffc020095a:	00005997          	auipc	s3,0x5
ffffffffc020095e:	6de98993          	addi	s3,s3,1758 # ffffffffc0206038 <buddy_struct_pages>
    cprintf("buddy: structure needs %lu bytes (%lu pages)\n", 
ffffffffc0200962:	15f1                	addi	a1,a1,-4
ffffffffc0200964:	00001517          	auipc	a0,0x1
ffffffffc0200968:	27c50513          	addi	a0,a0,636 # ffffffffc0201be0 <etext+0x63e>
    buddy_struct_pages = (buddy_struct_size + PGSIZE - 1) / PGSIZE;
ffffffffc020096c:	00c9b023          	sd	a2,0(s3)
    cprintf("buddy: structure needs %lu bytes (%lu pages)\n", 
ffffffffc0200970:	fdcff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (buddy_struct_pages >= total_pages) {
ffffffffc0200974:	000a3603          	ld	a2,0(s4)
ffffffffc0200978:	0009b903          	ld	s2,0(s3)
    size_t managed_pages = 1;
ffffffffc020097c:	4785                	li	a5,1
    size_t available_pages = total_pages - buddy_struct_pages;
ffffffffc020097e:	41260733          	sub	a4,a2,s2
    if (buddy_struct_pages >= total_pages) {
ffffffffc0200982:	0ec97663          	bgeu	s2,a2,ffffffffc0200a6e <buddy_init_memmap+0x172>
    while (managed_pages * 2 <= available_pages) {
ffffffffc0200986:	85be                	mv	a1,a5
ffffffffc0200988:	0786                	slli	a5,a5,0x1
ffffffffc020098a:	fef77ee3          	bgeu	a4,a5,ffffffffc0200986 <buddy_init_memmap+0x8a>
    for (; p != base + total_pages; p++) {
ffffffffc020098e:	00261693          	slli	a3,a2,0x2
ffffffffc0200992:	96b2                	add	a3,a3,a2
ffffffffc0200994:	068e                	slli	a3,a3,0x3
    total_blocks = managed_pages;
ffffffffc0200996:	e08c                	sd	a1,0(s1)
    for (; p != base + total_pages; p++) {
ffffffffc0200998:	96a2                	add	a3,a3,s0
ffffffffc020099a:	87a2                	mv	a5,s0
ffffffffc020099c:	00d40f63          	beq	s0,a3,ffffffffc02009ba <buddy_init_memmap+0xbe>
        assert(PageReserved(p));  // 检查页面确实是保留的
ffffffffc02009a0:	6798                	ld	a4,8(a5)
ffffffffc02009a2:	8b05                	andi	a4,a4,1
ffffffffc02009a4:	c749                	beqz	a4,ffffffffc0200a2e <buddy_init_memmap+0x132>
        p->flags = 0;
ffffffffc02009a6:	0007b423          	sd	zero,8(a5)
        p->property = 0;
ffffffffc02009aa:	0007a823          	sw	zero,16(a5)
ffffffffc02009ae:	0007a023          	sw	zero,0(a5)
    for (; p != base + total_pages; p++) {
ffffffffc02009b2:	02878793          	addi	a5,a5,40
ffffffffc02009b6:	fed795e3          	bne	a5,a3,ffffffffc02009a0 <buddy_init_memmap+0xa4>
    buddy_new(buddy_system, total_blocks);
ffffffffc02009ba:	2581                	sext.w	a1,a1
ffffffffc02009bc:	8522                	mv	a0,s0
    buddy_system = (struct buddy*)base;
ffffffffc02009be:	00005797          	auipc	a5,0x5
ffffffffc02009c2:	6887b123          	sd	s0,1666(a5) # ffffffffc0206040 <buddy_system>
    buddy_new(buddy_system, total_blocks);
ffffffffc02009c6:	edfff0ef          	jal	ra,ffffffffc02008a4 <buddy_new>
    buddy_page_base = base + buddy_struct_pages;
ffffffffc02009ca:	00291593          	slli	a1,s2,0x2
ffffffffc02009ce:	95ca                	add	a1,a1,s2
ffffffffc02009d0:	058e                	slli	a1,a1,0x3
ffffffffc02009d2:	95a2                	add	a1,a1,s0
ffffffffc02009d4:	00005917          	auipc	s2,0x5
ffffffffc02009d8:	65c90913          	addi	s2,s2,1628 # ffffffffc0206030 <buddy_page_base>
    cprintf("buddy: start of allocatable pages at %p\n", buddy_page_base);
ffffffffc02009dc:	00001517          	auipc	a0,0x1
ffffffffc02009e0:	26c50513          	addi	a0,a0,620 # ffffffffc0201c48 <etext+0x6a6>
    buddy_page_base = base + buddy_struct_pages;
ffffffffc02009e4:	00b93023          	sd	a1,0(s2)
    cprintf("buddy: start of allocatable pages at %p\n", buddy_page_base);
ffffffffc02009e8:	f64ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    buddy_page_base = base + buddy_struct_pages;
ffffffffc02009ec:	0009b783          	ld	a5,0(s3)
    cprintf("buddy: base=%p, buddy_page_base=%p\n", base, buddy_page_base);
ffffffffc02009f0:	85a2                	mv	a1,s0
ffffffffc02009f2:	00001517          	auipc	a0,0x1
ffffffffc02009f6:	28650513          	addi	a0,a0,646 # ffffffffc0201c78 <etext+0x6d6>
    buddy_page_base = base + buddy_struct_pages;
ffffffffc02009fa:	00279613          	slli	a2,a5,0x2
ffffffffc02009fe:	963e                	add	a2,a2,a5
ffffffffc0200a00:	060e                	slli	a2,a2,0x3
ffffffffc0200a02:	9622                	add	a2,a2,s0
ffffffffc0200a04:	00c93023          	sd	a2,0(s2)
    cprintf("buddy: base=%p, buddy_page_base=%p\n", base, buddy_page_base);
ffffffffc0200a08:	f44ff0ef          	jal	ra,ffffffffc020014c <cprintf>
}
ffffffffc0200a0c:	7402                	ld	s0,32(sp)
    cprintf("buddy: total_blocks=%lu, memory initialization completed\n", total_blocks);
ffffffffc0200a0e:	608c                	ld	a1,0(s1)
}
ffffffffc0200a10:	70a2                	ld	ra,40(sp)
ffffffffc0200a12:	64e2                	ld	s1,24(sp)
ffffffffc0200a14:	6942                	ld	s2,16(sp)
ffffffffc0200a16:	69a2                	ld	s3,8(sp)
ffffffffc0200a18:	6a02                	ld	s4,0(sp)
    cprintf("buddy: total_blocks=%lu, memory initialization completed\n", total_blocks);
ffffffffc0200a1a:	00001517          	auipc	a0,0x1
ffffffffc0200a1e:	28650513          	addi	a0,a0,646 # ffffffffc0201ca0 <etext+0x6fe>
}
ffffffffc0200a22:	6145                	addi	sp,sp,48
    cprintf("buddy: total_blocks=%lu, memory initialization completed\n", total_blocks);
ffffffffc0200a24:	f28ff06f          	j	ffffffffc020014c <cprintf>
    while (total_pages * 2 <= n) {
ffffffffc0200a28:	4585                	li	a1,1
ffffffffc0200a2a:	4601                	li	a2,0
ffffffffc0200a2c:	b731                	j	ffffffffc0200938 <buddy_init_memmap+0x3c>
        assert(PageReserved(p));  // 检查页面确实是保留的
ffffffffc0200a2e:	00001697          	auipc	a3,0x1
ffffffffc0200a32:	2b268693          	addi	a3,a3,690 # ffffffffc0201ce0 <etext+0x73e>
ffffffffc0200a36:	00001617          	auipc	a2,0x1
ffffffffc0200a3a:	14a60613          	addi	a2,a2,330 # ffffffffc0201b80 <etext+0x5de>
ffffffffc0200a3e:	0f600593          	li	a1,246
ffffffffc0200a42:	00001517          	auipc	a0,0x1
ffffffffc0200a46:	15650513          	addi	a0,a0,342 # ffffffffc0201b98 <etext+0x5f6>
ffffffffc0200a4a:	f78ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc0200a4e:	00001697          	auipc	a3,0x1
ffffffffc0200a52:	12a68693          	addi	a3,a3,298 # ffffffffc0201b78 <etext+0x5d6>
ffffffffc0200a56:	00001617          	auipc	a2,0x1
ffffffffc0200a5a:	12a60613          	addi	a2,a2,298 # ffffffffc0201b80 <etext+0x5de>
ffffffffc0200a5e:	0ce00593          	li	a1,206
ffffffffc0200a62:	00001517          	auipc	a0,0x1
ffffffffc0200a66:	13650513          	addi	a0,a0,310 # ffffffffc0201b98 <etext+0x5f6>
ffffffffc0200a6a:	f58ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("buddy: structure too large for available memory\n");
ffffffffc0200a6e:	00001617          	auipc	a2,0x1
ffffffffc0200a72:	1a260613          	addi	a2,a2,418 # ffffffffc0201c10 <etext+0x66e>
ffffffffc0200a76:	0e500593          	li	a1,229
ffffffffc0200a7a:	00001517          	auipc	a0,0x1
ffffffffc0200a7e:	11e50513          	addi	a0,a0,286 # ffffffffc0201b98 <etext+0x5f6>
ffffffffc0200a82:	f40ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200a86 <buddy_alloc>:
int buddy_alloc(struct buddy* self, unsigned required_blocks) {
ffffffffc0200a86:	7159                	addi	sp,sp,-112
ffffffffc0200a88:	f486                	sd	ra,104(sp)
ffffffffc0200a8a:	f0a2                	sd	s0,96(sp)
ffffffffc0200a8c:	eca6                	sd	s1,88(sp)
ffffffffc0200a8e:	e8ca                	sd	s2,80(sp)
ffffffffc0200a90:	e4ce                	sd	s3,72(sp)
ffffffffc0200a92:	e0d2                	sd	s4,64(sp)
ffffffffc0200a94:	fc56                	sd	s5,56(sp)
ffffffffc0200a96:	f85a                	sd	s6,48(sp)
ffffffffc0200a98:	f45e                	sd	s7,40(sp)
ffffffffc0200a9a:	f062                	sd	s8,32(sp)
ffffffffc0200a9c:	ec66                	sd	s9,24(sp)
ffffffffc0200a9e:	e86a                	sd	s10,16(sp)
ffffffffc0200aa0:	e46e                	sd	s11,8(sp)
    if (!self || required_blocks == 0) {
ffffffffc0200aa2:	22050263          	beqz	a0,ffffffffc0200cc6 <buddy_alloc+0x240>
ffffffffc0200aa6:	8a2e                	mv	s4,a1
ffffffffc0200aa8:	20058f63          	beqz	a1,ffffffffc0200cc6 <buddy_alloc+0x240>
ffffffffc0200aac:	fff5879b          	addiw	a5,a1,-1
ffffffffc0200ab0:	8fed                	and	a5,a5,a1
ffffffffc0200ab2:	2781                	sext.w	a5,a5
ffffffffc0200ab4:	892a                	mv	s2,a0
ffffffffc0200ab6:	1a079563          	bnez	a5,ffffffffc0200c60 <buddy_alloc+0x1da>
    cprintf("buddy_alloc: starting allocation for %u blocks\n", required_blocks);
ffffffffc0200aba:	85d2                	mv	a1,s4
ffffffffc0200abc:	00001517          	auipc	a0,0x1
ffffffffc0200ac0:	23450513          	addi	a0,a0,564 # ffffffffc0201cf0 <etext+0x74e>
ffffffffc0200ac4:	e88ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("buddy_alloc: root node has %u free blocks\n", self->longest[0]);
ffffffffc0200ac8:	00492583          	lw	a1,4(s2)
ffffffffc0200acc:	00001517          	auipc	a0,0x1
ffffffffc0200ad0:	25450513          	addi	a0,a0,596 # ffffffffc0201d20 <etext+0x77e>
ffffffffc0200ad4:	e78ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (self->longest[0] < required_blocks) {
ffffffffc0200ad8:	00492583          	lw	a1,4(s2)
ffffffffc0200adc:	1f45e763          	bltu	a1,s4,ffffffffc0200cca <buddy_alloc+0x244>
    unsigned node_size = self->size;
ffffffffc0200ae0:	00092d83          	lw	s11,0(s2)
    cprintf("buddy_alloc: starting search from root (idx=0, size=%u)\n", node_size);
ffffffffc0200ae4:	00001517          	auipc	a0,0x1
ffffffffc0200ae8:	2a450513          	addi	a0,a0,676 # ffffffffc0201d88 <etext+0x7e6>
ffffffffc0200aec:	85ee                	mv	a1,s11
ffffffffc0200aee:	e5eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (; node_size != required_blocks; node_size /= 2) {
ffffffffc0200af2:	19ba0d63          	beq	s4,s11,ffffffffc0200c8c <buddy_alloc+0x206>
    unsigned depth = 0;
ffffffffc0200af6:	4a81                	li	s5,0
    unsigned idx = 0;
ffffffffc0200af8:	4481                	li	s1,0
        cprintf("buddy_alloc: depth=%u, current node idx=%u, size=%u\n", 
ffffffffc0200afa:	00001d17          	auipc	s10,0x1
ffffffffc0200afe:	2ced0d13          	addi	s10,s10,718 # ffffffffc0201dc8 <etext+0x826>
        cprintf("buddy_alloc:   left child idx=%u, free=%u\n", left_idx, left_free);
ffffffffc0200b02:	00001c97          	auipc	s9,0x1
ffffffffc0200b06:	2fec8c93          	addi	s9,s9,766 # ffffffffc0201e00 <etext+0x85e>
        cprintf("buddy_alloc:   right child idx=%u, free=%u\n", right_idx, right_free);
ffffffffc0200b0a:	00001c17          	auipc	s8,0x1
ffffffffc0200b0e:	326c0c13          	addi	s8,s8,806 # ffffffffc0201e30 <etext+0x88e>
ffffffffc0200b12:	a801                	j	ffffffffc0200b22 <buddy_alloc+0x9c>
    for (; node_size != required_blocks; node_size /= 2) {
ffffffffc0200b14:	001ddd9b          	srliw	s11,s11,0x1
            cprintf("buddy_alloc:   -> choosing LEFT child (idx=%u)\n", idx);
ffffffffc0200b18:	e34ff0ef          	jal	ra,ffffffffc020014c <cprintf>
            idx = left_idx;
ffffffffc0200b1c:	84ce                	mv	s1,s3
    for (; node_size != required_blocks; node_size /= 2) {
ffffffffc0200b1e:	07ba0a63          	beq	s4,s11,ffffffffc0200b92 <buddy_alloc+0x10c>
static inline int left_leaf(int idx) { return 2 * idx + 1; }
ffffffffc0200b22:	0014941b          	slliw	s0,s1,0x1
ffffffffc0200b26:	0014099b          	addiw	s3,s0,1
        unsigned left_free = self->longest[left_idx];
ffffffffc0200b2a:	02099793          	slli	a5,s3,0x20
static inline int right_leaf(int idx) { return 2 * idx + 2; }
ffffffffc0200b2e:	2409                	addiw	s0,s0,2
ffffffffc0200b30:	01e7d713          	srli	a4,a5,0x1e
        unsigned right_free = self->longest[right_idx];
ffffffffc0200b34:	02041793          	slli	a5,s0,0x20
        unsigned left_free = self->longest[left_idx];
ffffffffc0200b38:	974a                	add	a4,a4,s2
        unsigned right_free = self->longest[right_idx];
ffffffffc0200b3a:	9381                	srli	a5,a5,0x20
        unsigned left_free = self->longest[left_idx];
ffffffffc0200b3c:	00472b03          	lw	s6,4(a4)
        unsigned right_free = self->longest[right_idx];
ffffffffc0200b40:	078a                	slli	a5,a5,0x2
        depth++;
ffffffffc0200b42:	2a85                	addiw	s5,s5,1
        unsigned right_free = self->longest[right_idx];
ffffffffc0200b44:	97ca                	add	a5,a5,s2
        cprintf("buddy_alloc: depth=%u, current node idx=%u, size=%u\n", 
ffffffffc0200b46:	86ee                	mv	a3,s11
ffffffffc0200b48:	8626                	mv	a2,s1
ffffffffc0200b4a:	85d6                	mv	a1,s5
ffffffffc0200b4c:	856a                	mv	a0,s10
        unsigned right_free = self->longest[right_idx];
ffffffffc0200b4e:	0047ab83          	lw	s7,4(a5)
        cprintf("buddy_alloc: depth=%u, current node idx=%u, size=%u\n", 
ffffffffc0200b52:	dfaff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("buddy_alloc:   left child idx=%u, free=%u\n", left_idx, left_free);
ffffffffc0200b56:	865a                	mv	a2,s6
ffffffffc0200b58:	85ce                	mv	a1,s3
ffffffffc0200b5a:	8566                	mv	a0,s9
ffffffffc0200b5c:	df0ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        unsigned right_idx = right_leaf(idx);
ffffffffc0200b60:	0004049b          	sext.w	s1,s0
        cprintf("buddy_alloc:   right child idx=%u, free=%u\n", right_idx, right_free);
ffffffffc0200b64:	85a6                	mv	a1,s1
ffffffffc0200b66:	865e                	mv	a2,s7
ffffffffc0200b68:	8562                	mv	a0,s8
ffffffffc0200b6a:	de2ff0ef          	jal	ra,ffffffffc020014c <cprintf>
            cprintf("buddy_alloc:   -> choosing LEFT child (idx=%u)\n", idx);
ffffffffc0200b6e:	85ce                	mv	a1,s3
ffffffffc0200b70:	00001517          	auipc	a0,0x1
ffffffffc0200b74:	2f050513          	addi	a0,a0,752 # ffffffffc0201e60 <etext+0x8be>
        if (left_free >= required_blocks) {
ffffffffc0200b78:	f94b7ee3          	bgeu	s6,s4,ffffffffc0200b14 <buddy_alloc+0x8e>
            cprintf("buddy_alloc:   -> choosing RIGHT child (idx=%u)\n", idx);
ffffffffc0200b7c:	85a6                	mv	a1,s1
ffffffffc0200b7e:	00001517          	auipc	a0,0x1
ffffffffc0200b82:	31250513          	addi	a0,a0,786 # ffffffffc0201e90 <etext+0x8ee>
    for (; node_size != required_blocks; node_size /= 2) {
ffffffffc0200b86:	001ddd9b          	srliw	s11,s11,0x1
            cprintf("buddy_alloc:   -> choosing RIGHT child (idx=%u)\n", idx);
ffffffffc0200b8a:	dc2ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (; node_size != required_blocks; node_size /= 2) {
ffffffffc0200b8e:	f9ba1ae3          	bne	s4,s11,ffffffffc0200b22 <buddy_alloc+0x9c>
    cprintf("buddy_alloc: found target node! idx=%u, size=%u\n", idx, node_size);
ffffffffc0200b92:	8652                	mv	a2,s4
ffffffffc0200b94:	85a6                	mv	a1,s1
ffffffffc0200b96:	00001517          	auipc	a0,0x1
ffffffffc0200b9a:	33250513          	addi	a0,a0,818 # ffffffffc0201ec8 <etext+0x926>
ffffffffc0200b9e:	daeff0ef          	jal	ra,ffffffffc020014c <cprintf>
    int block_offset = (idx + 1) * node_size - self->size;
ffffffffc0200ba2:	0014859b          	addiw	a1,s1,1
ffffffffc0200ba6:	03458a3b          	mulw	s4,a1,s4
ffffffffc0200baa:	00092703          	lw	a4,0(s2)
    self->longest[idx] = 0;
ffffffffc0200bae:	02049693          	slli	a3,s1,0x20
ffffffffc0200bb2:	01e6d793          	srli	a5,a3,0x1e
ffffffffc0200bb6:	97ca                	add	a5,a5,s2
ffffffffc0200bb8:	0007a223          	sw	zero,4(a5)
    cprintf("buddy_alloc: allocated node idx=%u, block_offset=%d\n", idx, block_offset);
ffffffffc0200bbc:	85a6                	mv	a1,s1
ffffffffc0200bbe:	00001517          	auipc	a0,0x1
ffffffffc0200bc2:	34250513          	addi	a0,a0,834 # ffffffffc0201f00 <etext+0x95e>
    int block_offset = (idx + 1) * node_size - self->size;
ffffffffc0200bc6:	40ea0a3b          	subw	s4,s4,a4
    cprintf("buddy_alloc: allocated node idx=%u, block_offset=%d\n", idx, block_offset);
ffffffffc0200bca:	8652                	mv	a2,s4
ffffffffc0200bcc:	d80ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("buddy_alloc: updating parent nodes...\n");
ffffffffc0200bd0:	00001517          	auipc	a0,0x1
ffffffffc0200bd4:	36850513          	addi	a0,a0,872 # ffffffffc0201f38 <etext+0x996>
ffffffffc0200bd8:	d74ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    while (update_idx > 0) {
ffffffffc0200bdc:	c8b9                	beqz	s1,ffffffffc0200c32 <buddy_alloc+0x1ac>
        cprintf("buddy_alloc:   parent idx=%u, left=%u, right=%u, new_value=%u\n", 
ffffffffc0200bde:	00001997          	auipc	s3,0x1
ffffffffc0200be2:	38298993          	addi	s3,s3,898 # ffffffffc0201f60 <etext+0x9be>
static inline int parent(int idx) { return (idx - 1) / 2; }
ffffffffc0200be6:	34fd                	addiw	s1,s1,-1
ffffffffc0200be8:	01f4d41b          	srliw	s0,s1,0x1f
ffffffffc0200bec:	9c25                	addw	s0,s0,s1
ffffffffc0200bee:	4014541b          	sraiw	s0,s0,0x1
static inline int left_leaf(int idx) { return 2 * idx + 1; }
ffffffffc0200bf2:	0014179b          	slliw	a5,s0,0x1
        unsigned left = self->longest[left_leaf(parent_idx)];
ffffffffc0200bf6:	0017871b          	addiw	a4,a5,1
        unsigned right = self->longest[right_leaf(parent_idx)];
ffffffffc0200bfa:	2789                	addiw	a5,a5,2
        unsigned left = self->longest[left_leaf(parent_idx)];
ffffffffc0200bfc:	070a                	slli	a4,a4,0x2
        unsigned right = self->longest[right_leaf(parent_idx)];
ffffffffc0200bfe:	078a                	slli	a5,a5,0x2
        unsigned left = self->longest[left_leaf(parent_idx)];
ffffffffc0200c00:	974a                	add	a4,a4,s2
        unsigned right = self->longest[right_leaf(parent_idx)];
ffffffffc0200c02:	97ca                	add	a5,a5,s2
        unsigned left = self->longest[left_leaf(parent_idx)];
ffffffffc0200c04:	4350                	lw	a2,4(a4)
        unsigned right = self->longest[right_leaf(parent_idx)];
ffffffffc0200c06:	43dc                	lw	a5,4(a5)
        unsigned parent_idx = parent(update_idx);
ffffffffc0200c08:	0004049b          	sext.w	s1,s0
        cprintf("buddy_alloc:   parent idx=%u, left=%u, right=%u, new_value=%u\n", 
ffffffffc0200c0c:	854e                	mv	a0,s3
ffffffffc0200c0e:	86be                	mv	a3,a5
ffffffffc0200c10:	85a6                	mv	a1,s1
static inline int max(int a, int b) { return (a > b) ? a : b; }
ffffffffc0200c12:	8ab2                	mv	s5,a2
ffffffffc0200c14:	00f65363          	bge	a2,a5,ffffffffc0200c1a <buddy_alloc+0x194>
ffffffffc0200c18:	8abe                	mv	s5,a5
ffffffffc0200c1a:	000a871b          	sext.w	a4,s5
ffffffffc0200c1e:	d2eff0ef          	jal	ra,ffffffffc020014c <cprintf>
        self->longest[parent_idx] = new_value;
ffffffffc0200c22:	02041793          	slli	a5,s0,0x20
ffffffffc0200c26:	01e7d413          	srli	s0,a5,0x1e
ffffffffc0200c2a:	944a                	add	s0,s0,s2
ffffffffc0200c2c:	01542223          	sw	s5,4(s0)
    while (update_idx > 0) {
ffffffffc0200c30:	f8dd                	bnez	s1,ffffffffc0200be6 <buddy_alloc+0x160>
    cprintf("buddy_alloc: allocation completed! block_offset=%d\n", block_offset);
ffffffffc0200c32:	85d2                	mv	a1,s4
ffffffffc0200c34:	00001517          	auipc	a0,0x1
ffffffffc0200c38:	36c50513          	addi	a0,a0,876 # ffffffffc0201fa0 <etext+0x9fe>
ffffffffc0200c3c:	d10ff0ef          	jal	ra,ffffffffc020014c <cprintf>
}
ffffffffc0200c40:	70a6                	ld	ra,104(sp)
ffffffffc0200c42:	7406                	ld	s0,96(sp)
ffffffffc0200c44:	64e6                	ld	s1,88(sp)
ffffffffc0200c46:	6946                	ld	s2,80(sp)
ffffffffc0200c48:	69a6                	ld	s3,72(sp)
ffffffffc0200c4a:	7ae2                	ld	s5,56(sp)
ffffffffc0200c4c:	7b42                	ld	s6,48(sp)
ffffffffc0200c4e:	7ba2                	ld	s7,40(sp)
ffffffffc0200c50:	7c02                	ld	s8,32(sp)
ffffffffc0200c52:	6ce2                	ld	s9,24(sp)
ffffffffc0200c54:	6d42                	ld	s10,16(sp)
ffffffffc0200c56:	6da2                	ld	s11,8(sp)
ffffffffc0200c58:	8552                	mv	a0,s4
ffffffffc0200c5a:	6a06                	ld	s4,64(sp)
ffffffffc0200c5c:	6165                	addi	sp,sp,112
ffffffffc0200c5e:	8082                	ret
    x |= x>>1;
ffffffffc0200c60:	0015d79b          	srliw	a5,a1,0x1
ffffffffc0200c64:	00f5ea33          	or	s4,a1,a5
    x |= x>>2;
ffffffffc0200c68:	002a579b          	srliw	a5,s4,0x2
ffffffffc0200c6c:	00fa6a33          	or	s4,s4,a5
    x |= x>>4;
ffffffffc0200c70:	004a579b          	srliw	a5,s4,0x4
ffffffffc0200c74:	00fa6a33          	or	s4,s4,a5
    x |= x>>8;
ffffffffc0200c78:	008a579b          	srliw	a5,s4,0x8
ffffffffc0200c7c:	00fa6a33          	or	s4,s4,a5
    x |= x>>16;
ffffffffc0200c80:	010a579b          	srliw	a5,s4,0x10
ffffffffc0200c84:	00fa6a33          	or	s4,s4,a5
    return x+1;
ffffffffc0200c88:	2a05                	addiw	s4,s4,1
ffffffffc0200c8a:	bd05                	j	ffffffffc0200aba <buddy_alloc+0x34>
    cprintf("buddy_alloc: found target node! idx=%u, size=%u\n", idx, node_size);
ffffffffc0200c8c:	8652                	mv	a2,s4
ffffffffc0200c8e:	4581                	li	a1,0
ffffffffc0200c90:	00001517          	auipc	a0,0x1
ffffffffc0200c94:	23850513          	addi	a0,a0,568 # ffffffffc0201ec8 <etext+0x926>
ffffffffc0200c98:	cb4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    int block_offset = (idx + 1) * node_size - self->size;
ffffffffc0200c9c:	00092783          	lw	a5,0(s2)
    self->longest[idx] = 0;
ffffffffc0200ca0:	00092223          	sw	zero,4(s2)
    cprintf("buddy_alloc: allocated node idx=%u, block_offset=%d\n", idx, block_offset);
ffffffffc0200ca4:	4581                	li	a1,0
    int block_offset = (idx + 1) * node_size - self->size;
ffffffffc0200ca6:	40fa0a3b          	subw	s4,s4,a5
    cprintf("buddy_alloc: allocated node idx=%u, block_offset=%d\n", idx, block_offset);
ffffffffc0200caa:	8652                	mv	a2,s4
ffffffffc0200cac:	00001517          	auipc	a0,0x1
ffffffffc0200cb0:	25450513          	addi	a0,a0,596 # ffffffffc0201f00 <etext+0x95e>
ffffffffc0200cb4:	c98ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("buddy_alloc: updating parent nodes...\n");
ffffffffc0200cb8:	00001517          	auipc	a0,0x1
ffffffffc0200cbc:	28050513          	addi	a0,a0,640 # ffffffffc0201f38 <etext+0x996>
ffffffffc0200cc0:	c8cff0ef          	jal	ra,ffffffffc020014c <cprintf>
    while (update_idx > 0) {
ffffffffc0200cc4:	b7bd                	j	ffffffffc0200c32 <buddy_alloc+0x1ac>
        return -1;
ffffffffc0200cc6:	5a7d                	li	s4,-1
ffffffffc0200cc8:	bfa5                	j	ffffffffc0200c40 <buddy_alloc+0x1ba>
        cprintf("buddy_alloc: insufficient memory! root has %u, need %u\n", 
ffffffffc0200cca:	8652                	mv	a2,s4
ffffffffc0200ccc:	00001517          	auipc	a0,0x1
ffffffffc0200cd0:	08450513          	addi	a0,a0,132 # ffffffffc0201d50 <etext+0x7ae>
ffffffffc0200cd4:	c78ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        return -1;
ffffffffc0200cd8:	5a7d                	li	s4,-1
ffffffffc0200cda:	b79d                	j	ffffffffc0200c40 <buddy_alloc+0x1ba>

ffffffffc0200cdc <buddy_alloc_pages.part.0>:
static struct Page* buddy_alloc_pages(size_t n) {
ffffffffc0200cdc:	1101                	addi	sp,sp,-32
ffffffffc0200cde:	e822                	sd	s0,16(sp)
    cprintf("buddy_alloc: requesting %lu pages (%lu blocks)\n", n, required_blocks);
ffffffffc0200ce0:	85aa                	mv	a1,a0
static struct Page* buddy_alloc_pages(size_t n) {
ffffffffc0200ce2:	842a                	mv	s0,a0
    cprintf("buddy_alloc: requesting %lu pages (%lu blocks)\n", n, required_blocks);
ffffffffc0200ce4:	862a                	mv	a2,a0
ffffffffc0200ce6:	00001517          	auipc	a0,0x1
ffffffffc0200cea:	2f250513          	addi	a0,a0,754 # ffffffffc0201fd8 <etext+0xa36>
static struct Page* buddy_alloc_pages(size_t n) {
ffffffffc0200cee:	e04a                	sd	s2,0(sp)
ffffffffc0200cf0:	ec06                	sd	ra,24(sp)
ffffffffc0200cf2:	e426                	sd	s1,8(sp)
    int block_offset = buddy_alloc(buddy_system, required_blocks);
ffffffffc0200cf4:	0004091b          	sext.w	s2,s0
    cprintf("buddy_alloc: requesting %lu pages (%lu blocks)\n", n, required_blocks);
ffffffffc0200cf8:	c54ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    int block_offset = buddy_alloc(buddy_system, required_blocks);
ffffffffc0200cfc:	85ca                	mv	a1,s2
ffffffffc0200cfe:	00005517          	auipc	a0,0x5
ffffffffc0200d02:	34253503          	ld	a0,834(a0) # ffffffffc0206040 <buddy_system>
ffffffffc0200d06:	d81ff0ef          	jal	ra,ffffffffc0200a86 <buddy_alloc>
    if (block_offset < 0) {
ffffffffc0200d0a:	04054163          	bltz	a0,ffffffffc0200d4c <buddy_alloc_pages.part.0+0x70>
    struct Page* page = &buddy_page_base[block_offset];
ffffffffc0200d0e:	00251493          	slli	s1,a0,0x2
ffffffffc0200d12:	94aa                	add	s1,s1,a0
ffffffffc0200d14:	00349793          	slli	a5,s1,0x3
ffffffffc0200d18:	00005497          	auipc	s1,0x5
ffffffffc0200d1c:	3184b483          	ld	s1,792(s1) # ffffffffc0206030 <buddy_page_base>
ffffffffc0200d20:	94be                	add	s1,s1,a5
    SetPageProperty(page);
ffffffffc0200d22:	649c                	ld	a5,8(s1)
    page->property = n;
ffffffffc0200d24:	0124a823          	sw	s2,16(s1)
    SetPageProperty(page);
ffffffffc0200d28:	862a                	mv	a2,a0
ffffffffc0200d2a:	0027e793          	ori	a5,a5,2
ffffffffc0200d2e:	e49c                	sd	a5,8(s1)
    cprintf("buddy_alloc: allocated %lu pages at block offset %d\n", n, block_offset);
ffffffffc0200d30:	85a2                	mv	a1,s0
ffffffffc0200d32:	00001517          	auipc	a0,0x1
ffffffffc0200d36:	30650513          	addi	a0,a0,774 # ffffffffc0202038 <etext+0xa96>
ffffffffc0200d3a:	c12ff0ef          	jal	ra,ffffffffc020014c <cprintf>
}
ffffffffc0200d3e:	60e2                	ld	ra,24(sp)
ffffffffc0200d40:	6442                	ld	s0,16(sp)
ffffffffc0200d42:	6902                	ld	s2,0(sp)
ffffffffc0200d44:	8526                	mv	a0,s1
ffffffffc0200d46:	64a2                	ld	s1,8(sp)
ffffffffc0200d48:	6105                	addi	sp,sp,32
ffffffffc0200d4a:	8082                	ret
        cprintf("buddy_alloc: failed to allocate %lu blocks\n", required_blocks);
ffffffffc0200d4c:	85a2                	mv	a1,s0
ffffffffc0200d4e:	00001517          	auipc	a0,0x1
ffffffffc0200d52:	2ba50513          	addi	a0,a0,698 # ffffffffc0202008 <etext+0xa66>
ffffffffc0200d56:	bf6ff0ef          	jal	ra,ffffffffc020014c <cprintf>
}
ffffffffc0200d5a:	60e2                	ld	ra,24(sp)
ffffffffc0200d5c:	6442                	ld	s0,16(sp)
        return NULL;
ffffffffc0200d5e:	4481                	li	s1,0
}
ffffffffc0200d60:	6902                	ld	s2,0(sp)
ffffffffc0200d62:	8526                	mv	a0,s1
ffffffffc0200d64:	64a2                	ld	s1,8(sp)
ffffffffc0200d66:	6105                	addi	sp,sp,32
ffffffffc0200d68:	8082                	ret

ffffffffc0200d6a <buddy_alloc_pages>:
    if (!buddy_system || n == 0) return NULL;
ffffffffc0200d6a:	00005717          	auipc	a4,0x5
ffffffffc0200d6e:	2d673703          	ld	a4,726(a4) # ffffffffc0206040 <buddy_system>
ffffffffc0200d72:	c319                	beqz	a4,ffffffffc0200d78 <buddy_alloc_pages+0xe>
ffffffffc0200d74:	c111                	beqz	a0,ffffffffc0200d78 <buddy_alloc_pages+0xe>
ffffffffc0200d76:	b79d                	j	ffffffffc0200cdc <buddy_alloc_pages.part.0>
}
ffffffffc0200d78:	4501                	li	a0,0
ffffffffc0200d7a:	8082                	ret

ffffffffc0200d7c <buddy_check>:
    
//     cprintf("buddy_check passed!\n");
// }

// 测试函数 - 更全面地测试buddy system特性
static void buddy_check(void) {
ffffffffc0200d7c:	7179                	addi	sp,sp,-48
    cprintf("\n=== Buddy System Comprehensive Check ===\n");
ffffffffc0200d7e:	00001517          	auipc	a0,0x1
ffffffffc0200d82:	2f250513          	addi	a0,a0,754 # ffffffffc0202070 <etext+0xace>
static void buddy_check(void) {
ffffffffc0200d86:	f022                	sd	s0,32(sp)
ffffffffc0200d88:	f406                	sd	ra,40(sp)
ffffffffc0200d8a:	ec26                	sd	s1,24(sp)
ffffffffc0200d8c:	e84a                	sd	s2,16(sp)
ffffffffc0200d8e:	e44e                	sd	s3,8(sp)
ffffffffc0200d90:	e052                	sd	s4,0(sp)
    if (!buddy_system) return 0;
ffffffffc0200d92:	00005417          	auipc	s0,0x5
ffffffffc0200d96:	2ae40413          	addi	s0,s0,686 # ffffffffc0206040 <buddy_system>
    cprintf("\n=== Buddy System Comprehensive Check ===\n");
ffffffffc0200d9a:	bb2ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (!buddy_system) return 0;
ffffffffc0200d9e:	601c                	ld	a5,0(s0)
ffffffffc0200da0:	10078563          	beqz	a5,ffffffffc0200eaa <buddy_check+0x12e>
    return free_blocks;
ffffffffc0200da4:	0047ea03          	lwu	s4,4(a5)
    
    size_t initial_free = buddy_nr_free_pages();
    cprintf("Initial free pages: %lu\n", initial_free);
ffffffffc0200da8:	85d2                	mv	a1,s4
ffffffffc0200daa:	00001517          	auipc	a0,0x1
ffffffffc0200dae:	2f650513          	addi	a0,a0,758 # ffffffffc02020a0 <etext+0xafe>
ffffffffc0200db2:	b9aff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 测试1: 基本分配释放
    cprintf("\n--- Test 1: Basic Allocation/Free ---\n");
ffffffffc0200db6:	00001517          	auipc	a0,0x1
ffffffffc0200dba:	30a50513          	addi	a0,a0,778 # ffffffffc02020c0 <etext+0xb1e>
ffffffffc0200dbe:	b8eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (!buddy_system || n == 0) return NULL;
ffffffffc0200dc2:	601c                	ld	a5,0(s0)
ffffffffc0200dc4:	0e078963          	beqz	a5,ffffffffc0200eb6 <buddy_check+0x13a>
ffffffffc0200dc8:	4505                	li	a0,1
ffffffffc0200dca:	f13ff0ef          	jal	ra,ffffffffc0200cdc <buddy_alloc_pages.part.0>
ffffffffc0200dce:	84aa                	mv	s1,a0
    struct Page* p1 = buddy_alloc_pages(1);
    assert(p1 != NULL);
ffffffffc0200dd0:	0e050363          	beqz	a0,ffffffffc0200eb6 <buddy_check+0x13a>
    cprintf("allocated 1 page at %p\n", p1);
ffffffffc0200dd4:	85aa                	mv	a1,a0
ffffffffc0200dd6:	00001517          	auipc	a0,0x1
ffffffffc0200dda:	32250513          	addi	a0,a0,802 # ffffffffc02020f8 <etext+0xb56>
ffffffffc0200dde:	b6eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (!buddy_system || n == 0) return NULL;
ffffffffc0200de2:	601c                	ld	a5,0(s0)
ffffffffc0200de4:	0e078963          	beqz	a5,ffffffffc0200ed6 <buddy_check+0x15a>
ffffffffc0200de8:	4509                	li	a0,2
ffffffffc0200dea:	ef3ff0ef          	jal	ra,ffffffffc0200cdc <buddy_alloc_pages.part.0>
ffffffffc0200dee:	892a                	mv	s2,a0
    
    struct Page* p2 = buddy_alloc_pages(2);
    assert(p2 != NULL);
ffffffffc0200df0:	0e050363          	beqz	a0,ffffffffc0200ed6 <buddy_check+0x15a>
    cprintf("allocated 2 pages at %p\n", p2);
ffffffffc0200df4:	85aa                	mv	a1,a0
ffffffffc0200df6:	00001517          	auipc	a0,0x1
ffffffffc0200dfa:	32a50513          	addi	a0,a0,810 # ffffffffc0202120 <etext+0xb7e>
ffffffffc0200dfe:	b4eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (!buddy_system || n == 0) return NULL;
ffffffffc0200e02:	601c                	ld	a5,0(s0)
ffffffffc0200e04:	0e078963          	beqz	a5,ffffffffc0200ef6 <buddy_check+0x17a>
ffffffffc0200e08:	4511                	li	a0,4
ffffffffc0200e0a:	ed3ff0ef          	jal	ra,ffffffffc0200cdc <buddy_alloc_pages.part.0>
ffffffffc0200e0e:	89aa                	mv	s3,a0
    
    struct Page* p4 = buddy_alloc_pages(4);
    assert(p4 != NULL);
ffffffffc0200e10:	0e050363          	beqz	a0,ffffffffc0200ef6 <buddy_check+0x17a>
    cprintf("allocated 4 pages at %p\n", p4);
ffffffffc0200e14:	85aa                	mv	a1,a0
ffffffffc0200e16:	00001517          	auipc	a0,0x1
ffffffffc0200e1a:	33a50513          	addi	a0,a0,826 # ffffffffc0202150 <etext+0xbae>
ffffffffc0200e1e:	b2eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (!buddy_system) return 0;
ffffffffc0200e22:	601c                	ld	a5,0(s0)
ffffffffc0200e24:	c7c9                	beqz	a5,ffffffffc0200eae <buddy_check+0x132>
    return free_blocks;
ffffffffc0200e26:	0047e583          	lwu	a1,4(a5)
    
    size_t after_alloc1 = buddy_nr_free_pages();
    cprintf("Free pages after first allocation: %lu\n", after_alloc1);
ffffffffc0200e2a:	00001517          	auipc	a0,0x1
ffffffffc0200e2e:	34650513          	addi	a0,a0,838 # ffffffffc0202170 <etext+0xbce>
ffffffffc0200e32:	b1aff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (!buddy_system || !base || n == 0) return;
ffffffffc0200e36:	601c                	ld	a5,0(s0)
ffffffffc0200e38:	c789                	beqz	a5,ffffffffc0200e42 <buddy_check+0xc6>
ffffffffc0200e3a:	4585                	li	a1,1
ffffffffc0200e3c:	8526                	mv	a0,s1
ffffffffc0200e3e:	9abff0ef          	jal	ra,ffffffffc02007e8 <buddy_free_pages.part.0>
    
    buddy_free_pages(p1, 1);
    cprintf("freed 1 page\n");
ffffffffc0200e42:	00001517          	auipc	a0,0x1
ffffffffc0200e46:	35650513          	addi	a0,a0,854 # ffffffffc0202198 <etext+0xbf6>
ffffffffc0200e4a:	b02ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (!buddy_system || !base || n == 0) return;
ffffffffc0200e4e:	601c                	ld	a5,0(s0)
ffffffffc0200e50:	c789                	beqz	a5,ffffffffc0200e5a <buddy_check+0xde>
ffffffffc0200e52:	4589                	li	a1,2
ffffffffc0200e54:	854a                	mv	a0,s2
ffffffffc0200e56:	993ff0ef          	jal	ra,ffffffffc02007e8 <buddy_free_pages.part.0>
    
    buddy_free_pages(p2, 2);
    cprintf("freed 2 pages\n");
ffffffffc0200e5a:	00001517          	auipc	a0,0x1
ffffffffc0200e5e:	34e50513          	addi	a0,a0,846 # ffffffffc02021a8 <etext+0xc06>
ffffffffc0200e62:	aeaff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (!buddy_system || !base || n == 0) return;
ffffffffc0200e66:	601c                	ld	a5,0(s0)
ffffffffc0200e68:	c789                	beqz	a5,ffffffffc0200e72 <buddy_check+0xf6>
ffffffffc0200e6a:	4591                	li	a1,4
ffffffffc0200e6c:	854e                	mv	a0,s3
ffffffffc0200e6e:	97bff0ef          	jal	ra,ffffffffc02007e8 <buddy_free_pages.part.0>
    
    buddy_free_pages(p4, 4);
    cprintf("freed 4 pages\n");
ffffffffc0200e72:	00001517          	auipc	a0,0x1
ffffffffc0200e76:	34650513          	addi	a0,a0,838 # ffffffffc02021b8 <etext+0xc16>
ffffffffc0200e7a:	ad2ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (!buddy_system) return 0;
ffffffffc0200e7e:	601c                	ld	a5,0(s0)
ffffffffc0200e80:	cb8d                	beqz	a5,ffffffffc0200eb2 <buddy_check+0x136>
    return free_blocks;
ffffffffc0200e82:	0047e403          	lwu	s0,4(a5)
    
    // 验证测试1后的内存完整性
    size_t after_test1 = buddy_nr_free_pages();
    cprintf("Free pages after test 1: %lu (should be %lu)\n", after_test1, initial_free);
ffffffffc0200e86:	8652                	mv	a2,s4
ffffffffc0200e88:	85a2                	mv	a1,s0
ffffffffc0200e8a:	00001517          	auipc	a0,0x1
ffffffffc0200e8e:	33e50513          	addi	a0,a0,830 # ffffffffc02021c8 <etext+0xc26>
ffffffffc0200e92:	abaff0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(after_test1 == initial_free);
ffffffffc0200e96:	088a1063          	bne	s4,s0,ffffffffc0200f16 <buddy_check+0x19a>
    
    // cprintf("\n=== Buddy System Check Pass ===\n");
    // cprintf("✓ All tests passed! Buddy system is working correctly.\n");
    // cprintf("✓ Memory integrity verified: initial %lu = final %lu pages\n", 
    //         initial_free, final_free);
}
ffffffffc0200e9a:	70a2                	ld	ra,40(sp)
ffffffffc0200e9c:	7402                	ld	s0,32(sp)
ffffffffc0200e9e:	64e2                	ld	s1,24(sp)
ffffffffc0200ea0:	6942                	ld	s2,16(sp)
ffffffffc0200ea2:	69a2                	ld	s3,8(sp)
ffffffffc0200ea4:	6a02                	ld	s4,0(sp)
ffffffffc0200ea6:	6145                	addi	sp,sp,48
ffffffffc0200ea8:	8082                	ret
    if (!buddy_system) return 0;
ffffffffc0200eaa:	4a01                	li	s4,0
ffffffffc0200eac:	bdf5                	j	ffffffffc0200da8 <buddy_check+0x2c>
ffffffffc0200eae:	4581                	li	a1,0
ffffffffc0200eb0:	bfad                	j	ffffffffc0200e2a <buddy_check+0xae>
ffffffffc0200eb2:	4401                	li	s0,0
ffffffffc0200eb4:	bfc9                	j	ffffffffc0200e86 <buddy_check+0x10a>
    assert(p1 != NULL);
ffffffffc0200eb6:	00001697          	auipc	a3,0x1
ffffffffc0200eba:	23268693          	addi	a3,a3,562 # ffffffffc02020e8 <etext+0xb46>
ffffffffc0200ebe:	00001617          	auipc	a2,0x1
ffffffffc0200ec2:	cc260613          	addi	a2,a2,-830 # ffffffffc0201b80 <etext+0x5de>
ffffffffc0200ec6:	18500593          	li	a1,389
ffffffffc0200eca:	00001517          	auipc	a0,0x1
ffffffffc0200ece:	cce50513          	addi	a0,a0,-818 # ffffffffc0201b98 <etext+0x5f6>
ffffffffc0200ed2:	af0ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p2 != NULL);
ffffffffc0200ed6:	00001697          	auipc	a3,0x1
ffffffffc0200eda:	23a68693          	addi	a3,a3,570 # ffffffffc0202110 <etext+0xb6e>
ffffffffc0200ede:	00001617          	auipc	a2,0x1
ffffffffc0200ee2:	ca260613          	addi	a2,a2,-862 # ffffffffc0201b80 <etext+0x5de>
ffffffffc0200ee6:	18900593          	li	a1,393
ffffffffc0200eea:	00001517          	auipc	a0,0x1
ffffffffc0200eee:	cae50513          	addi	a0,a0,-850 # ffffffffc0201b98 <etext+0x5f6>
ffffffffc0200ef2:	ad0ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p4 != NULL);
ffffffffc0200ef6:	00001697          	auipc	a3,0x1
ffffffffc0200efa:	24a68693          	addi	a3,a3,586 # ffffffffc0202140 <etext+0xb9e>
ffffffffc0200efe:	00001617          	auipc	a2,0x1
ffffffffc0200f02:	c8260613          	addi	a2,a2,-894 # ffffffffc0201b80 <etext+0x5de>
ffffffffc0200f06:	18d00593          	li	a1,397
ffffffffc0200f0a:	00001517          	auipc	a0,0x1
ffffffffc0200f0e:	c8e50513          	addi	a0,a0,-882 # ffffffffc0201b98 <etext+0x5f6>
ffffffffc0200f12:	ab0ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(after_test1 == initial_free);
ffffffffc0200f16:	00001697          	auipc	a3,0x1
ffffffffc0200f1a:	2e268693          	addi	a3,a3,738 # ffffffffc02021f8 <etext+0xc56>
ffffffffc0200f1e:	00001617          	auipc	a2,0x1
ffffffffc0200f22:	c6260613          	addi	a2,a2,-926 # ffffffffc0201b80 <etext+0x5de>
ffffffffc0200f26:	19f00593          	li	a1,415
ffffffffc0200f2a:	00001517          	auipc	a0,0x1
ffffffffc0200f2e:	c6e50513          	addi	a0,a0,-914 # ffffffffc0201b98 <etext+0x5f6>
ffffffffc0200f32:	a90ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200f36 <pmm_init>:

static void check_alloc_page(void);

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200f36:	00001797          	auipc	a5,0x1
ffffffffc0200f3a:	2fa78793          	addi	a5,a5,762 # ffffffffc0202230 <buddy_pmm_manager>
    //pmm_manager = &slub_pmm_manager;
    //pmm_manager = &default_pmm_manager;
    //pmm_manager = &best_fit_pmm_manager;
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200f3e:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200f40:	7179                	addi	sp,sp,-48
ffffffffc0200f42:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200f44:	00001517          	auipc	a0,0x1
ffffffffc0200f48:	32450513          	addi	a0,a0,804 # ffffffffc0202268 <buddy_pmm_manager+0x38>
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200f4c:	00005417          	auipc	s0,0x5
ffffffffc0200f50:	11c40413          	addi	s0,s0,284 # ffffffffc0206068 <pmm_manager>
void pmm_init(void) {
ffffffffc0200f54:	f406                	sd	ra,40(sp)
ffffffffc0200f56:	ec26                	sd	s1,24(sp)
ffffffffc0200f58:	e44e                	sd	s3,8(sp)
ffffffffc0200f5a:	e84a                	sd	s2,16(sp)
ffffffffc0200f5c:	e052                	sd	s4,0(sp)
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200f5e:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200f60:	9ecff0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc0200f64:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200f66:	00005497          	auipc	s1,0x5
ffffffffc0200f6a:	11a48493          	addi	s1,s1,282 # ffffffffc0206080 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200f6e:	679c                	ld	a5,8(a5)
ffffffffc0200f70:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200f72:	57f5                	li	a5,-3
ffffffffc0200f74:	07fa                	slli	a5,a5,0x1e
ffffffffc0200f76:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0200f78:	e44ff0ef          	jal	ra,ffffffffc02005bc <get_memory_base>
ffffffffc0200f7c:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0200f7e:	e48ff0ef          	jal	ra,ffffffffc02005c6 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0200f82:	14050d63          	beqz	a0,ffffffffc02010dc <pmm_init+0x1a6>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200f86:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0200f88:	00001517          	auipc	a0,0x1
ffffffffc0200f8c:	32850513          	addi	a0,a0,808 # ffffffffc02022b0 <buddy_pmm_manager+0x80>
ffffffffc0200f90:	9bcff0ef          	jal	ra,ffffffffc020014c <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200f94:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200f98:	864e                	mv	a2,s3
ffffffffc0200f9a:	fffa0693          	addi	a3,s4,-1
ffffffffc0200f9e:	85ca                	mv	a1,s2
ffffffffc0200fa0:	00001517          	auipc	a0,0x1
ffffffffc0200fa4:	32850513          	addi	a0,a0,808 # ffffffffc02022c8 <buddy_pmm_manager+0x98>
ffffffffc0200fa8:	9a4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200fac:	c80007b7          	lui	a5,0xc8000
ffffffffc0200fb0:	8652                	mv	a2,s4
ffffffffc0200fb2:	0d47e463          	bltu	a5,s4,ffffffffc020107a <pmm_init+0x144>
ffffffffc0200fb6:	00006797          	auipc	a5,0x6
ffffffffc0200fba:	0d178793          	addi	a5,a5,209 # ffffffffc0207087 <end+0xfff>
ffffffffc0200fbe:	757d                	lui	a0,0xfffff
ffffffffc0200fc0:	8d7d                	and	a0,a0,a5
ffffffffc0200fc2:	8231                	srli	a2,a2,0xc
ffffffffc0200fc4:	00005797          	auipc	a5,0x5
ffffffffc0200fc8:	08c7ba23          	sd	a2,148(a5) # ffffffffc0206058 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200fcc:	00005797          	auipc	a5,0x5
ffffffffc0200fd0:	08a7ba23          	sd	a0,148(a5) # ffffffffc0206060 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200fd4:	000807b7          	lui	a5,0x80
ffffffffc0200fd8:	002005b7          	lui	a1,0x200
ffffffffc0200fdc:	02f60563          	beq	a2,a5,ffffffffc0201006 <pmm_init+0xd0>
ffffffffc0200fe0:	00261593          	slli	a1,a2,0x2
ffffffffc0200fe4:	00c586b3          	add	a3,a1,a2
ffffffffc0200fe8:	fec007b7          	lui	a5,0xfec00
ffffffffc0200fec:	97aa                	add	a5,a5,a0
ffffffffc0200fee:	068e                	slli	a3,a3,0x3
ffffffffc0200ff0:	96be                	add	a3,a3,a5
ffffffffc0200ff2:	87aa                	mv	a5,a0
        SetPageReserved(pages + i);
ffffffffc0200ff4:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200ff6:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9f9fa0>
        SetPageReserved(pages + i);
ffffffffc0200ffa:	00176713          	ori	a4,a4,1
ffffffffc0200ffe:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201002:	fef699e3          	bne	a3,a5,ffffffffc0200ff4 <pmm_init+0xbe>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201006:	95b2                	add	a1,a1,a2
ffffffffc0201008:	fec006b7          	lui	a3,0xfec00
ffffffffc020100c:	96aa                	add	a3,a3,a0
ffffffffc020100e:	058e                	slli	a1,a1,0x3
ffffffffc0201010:	96ae                	add	a3,a3,a1
ffffffffc0201012:	c02007b7          	lui	a5,0xc0200
ffffffffc0201016:	0af6e763          	bltu	a3,a5,ffffffffc02010c4 <pmm_init+0x18e>
ffffffffc020101a:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020101c:	77fd                	lui	a5,0xfffff
ffffffffc020101e:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201022:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0201024:	04b6ee63          	bltu	a3,a1,ffffffffc0201080 <pmm_init+0x14a>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201028:	601c                	ld	a5,0(s0)
ffffffffc020102a:	7b9c                	ld	a5,48(a5)
ffffffffc020102c:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020102e:	00001517          	auipc	a0,0x1
ffffffffc0201032:	32250513          	addi	a0,a0,802 # ffffffffc0202350 <buddy_pmm_manager+0x120>
ffffffffc0201036:	916ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc020103a:	00004597          	auipc	a1,0x4
ffffffffc020103e:	fc658593          	addi	a1,a1,-58 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201042:	00005797          	auipc	a5,0x5
ffffffffc0201046:	02b7bb23          	sd	a1,54(a5) # ffffffffc0206078 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020104a:	c02007b7          	lui	a5,0xc0200
ffffffffc020104e:	0af5e363          	bltu	a1,a5,ffffffffc02010f4 <pmm_init+0x1be>
ffffffffc0201052:	6090                	ld	a2,0(s1)
}
ffffffffc0201054:	7402                	ld	s0,32(sp)
ffffffffc0201056:	70a2                	ld	ra,40(sp)
ffffffffc0201058:	64e2                	ld	s1,24(sp)
ffffffffc020105a:	6942                	ld	s2,16(sp)
ffffffffc020105c:	69a2                	ld	s3,8(sp)
ffffffffc020105e:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201060:	40c58633          	sub	a2,a1,a2
ffffffffc0201064:	00005797          	auipc	a5,0x5
ffffffffc0201068:	00c7b623          	sd	a2,12(a5) # ffffffffc0206070 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020106c:	00001517          	auipc	a0,0x1
ffffffffc0201070:	30450513          	addi	a0,a0,772 # ffffffffc0202370 <buddy_pmm_manager+0x140>
}
ffffffffc0201074:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201076:	8d6ff06f          	j	ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc020107a:	c8000637          	lui	a2,0xc8000
ffffffffc020107e:	bf25                	j	ffffffffc0200fb6 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201080:	6705                	lui	a4,0x1
ffffffffc0201082:	177d                	addi	a4,a4,-1
ffffffffc0201084:	96ba                	add	a3,a3,a4
ffffffffc0201086:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201088:	00c6d793          	srli	a5,a3,0xc
ffffffffc020108c:	02c7f063          	bgeu	a5,a2,ffffffffc02010ac <pmm_init+0x176>
    pmm_manager->init_memmap(base, n);
ffffffffc0201090:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201092:	fff80737          	lui	a4,0xfff80
ffffffffc0201096:	973e                	add	a4,a4,a5
ffffffffc0201098:	00271793          	slli	a5,a4,0x2
ffffffffc020109c:	97ba                	add	a5,a5,a4
ffffffffc020109e:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02010a0:	8d95                	sub	a1,a1,a3
ffffffffc02010a2:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02010a4:	81b1                	srli	a1,a1,0xc
ffffffffc02010a6:	953e                	add	a0,a0,a5
ffffffffc02010a8:	9702                	jalr	a4
}
ffffffffc02010aa:	bfbd                	j	ffffffffc0201028 <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc02010ac:	00001617          	auipc	a2,0x1
ffffffffc02010b0:	27460613          	addi	a2,a2,628 # ffffffffc0202320 <buddy_pmm_manager+0xf0>
ffffffffc02010b4:	07400593          	li	a1,116
ffffffffc02010b8:	00001517          	auipc	a0,0x1
ffffffffc02010bc:	28850513          	addi	a0,a0,648 # ffffffffc0202340 <buddy_pmm_manager+0x110>
ffffffffc02010c0:	902ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010c4:	00001617          	auipc	a2,0x1
ffffffffc02010c8:	23460613          	addi	a2,a2,564 # ffffffffc02022f8 <buddy_pmm_manager+0xc8>
ffffffffc02010cc:	06300593          	li	a1,99
ffffffffc02010d0:	00001517          	auipc	a0,0x1
ffffffffc02010d4:	1d050513          	addi	a0,a0,464 # ffffffffc02022a0 <buddy_pmm_manager+0x70>
ffffffffc02010d8:	8eaff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("DTB memory info not available");
ffffffffc02010dc:	00001617          	auipc	a2,0x1
ffffffffc02010e0:	1a460613          	addi	a2,a2,420 # ffffffffc0202280 <buddy_pmm_manager+0x50>
ffffffffc02010e4:	04b00593          	li	a1,75
ffffffffc02010e8:	00001517          	auipc	a0,0x1
ffffffffc02010ec:	1b850513          	addi	a0,a0,440 # ffffffffc02022a0 <buddy_pmm_manager+0x70>
ffffffffc02010f0:	8d2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02010f4:	86ae                	mv	a3,a1
ffffffffc02010f6:	00001617          	auipc	a2,0x1
ffffffffc02010fa:	20260613          	addi	a2,a2,514 # ffffffffc02022f8 <buddy_pmm_manager+0xc8>
ffffffffc02010fe:	07e00593          	li	a1,126
ffffffffc0201102:	00001517          	auipc	a0,0x1
ffffffffc0201106:	19e50513          	addi	a0,a0,414 # ffffffffc02022a0 <buddy_pmm_manager+0x70>
ffffffffc020110a:	8b8ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020110e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020110e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201112:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201114:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201118:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020111a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020111e:	f022                	sd	s0,32(sp)
ffffffffc0201120:	ec26                	sd	s1,24(sp)
ffffffffc0201122:	e84a                	sd	s2,16(sp)
ffffffffc0201124:	f406                	sd	ra,40(sp)
ffffffffc0201126:	e44e                	sd	s3,8(sp)
ffffffffc0201128:	84aa                	mv	s1,a0
ffffffffc020112a:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020112c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201130:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201132:	03067e63          	bgeu	a2,a6,ffffffffc020116e <printnum+0x60>
ffffffffc0201136:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201138:	00805763          	blez	s0,ffffffffc0201146 <printnum+0x38>
ffffffffc020113c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020113e:	85ca                	mv	a1,s2
ffffffffc0201140:	854e                	mv	a0,s3
ffffffffc0201142:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201144:	fc65                	bnez	s0,ffffffffc020113c <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201146:	1a02                	slli	s4,s4,0x20
ffffffffc0201148:	00001797          	auipc	a5,0x1
ffffffffc020114c:	26878793          	addi	a5,a5,616 # ffffffffc02023b0 <buddy_pmm_manager+0x180>
ffffffffc0201150:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201154:	9a3e                	add	s4,s4,a5
}
ffffffffc0201156:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201158:	000a4503          	lbu	a0,0(s4)
}
ffffffffc020115c:	70a2                	ld	ra,40(sp)
ffffffffc020115e:	69a2                	ld	s3,8(sp)
ffffffffc0201160:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201162:	85ca                	mv	a1,s2
ffffffffc0201164:	87a6                	mv	a5,s1
}
ffffffffc0201166:	6942                	ld	s2,16(sp)
ffffffffc0201168:	64e2                	ld	s1,24(sp)
ffffffffc020116a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020116c:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020116e:	03065633          	divu	a2,a2,a6
ffffffffc0201172:	8722                	mv	a4,s0
ffffffffc0201174:	f9bff0ef          	jal	ra,ffffffffc020110e <printnum>
ffffffffc0201178:	b7f9                	j	ffffffffc0201146 <printnum+0x38>

ffffffffc020117a <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020117a:	7119                	addi	sp,sp,-128
ffffffffc020117c:	f4a6                	sd	s1,104(sp)
ffffffffc020117e:	f0ca                	sd	s2,96(sp)
ffffffffc0201180:	ecce                	sd	s3,88(sp)
ffffffffc0201182:	e8d2                	sd	s4,80(sp)
ffffffffc0201184:	e4d6                	sd	s5,72(sp)
ffffffffc0201186:	e0da                	sd	s6,64(sp)
ffffffffc0201188:	fc5e                	sd	s7,56(sp)
ffffffffc020118a:	f06a                	sd	s10,32(sp)
ffffffffc020118c:	fc86                	sd	ra,120(sp)
ffffffffc020118e:	f8a2                	sd	s0,112(sp)
ffffffffc0201190:	f862                	sd	s8,48(sp)
ffffffffc0201192:	f466                	sd	s9,40(sp)
ffffffffc0201194:	ec6e                	sd	s11,24(sp)
ffffffffc0201196:	892a                	mv	s2,a0
ffffffffc0201198:	84ae                	mv	s1,a1
ffffffffc020119a:	8d32                	mv	s10,a2
ffffffffc020119c:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020119e:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02011a2:	5b7d                	li	s6,-1
ffffffffc02011a4:	00001a97          	auipc	s5,0x1
ffffffffc02011a8:	240a8a93          	addi	s5,s5,576 # ffffffffc02023e4 <buddy_pmm_manager+0x1b4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02011ac:	00001b97          	auipc	s7,0x1
ffffffffc02011b0:	414b8b93          	addi	s7,s7,1044 # ffffffffc02025c0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02011b4:	000d4503          	lbu	a0,0(s10)
ffffffffc02011b8:	001d0413          	addi	s0,s10,1
ffffffffc02011bc:	01350a63          	beq	a0,s3,ffffffffc02011d0 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02011c0:	c121                	beqz	a0,ffffffffc0201200 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02011c2:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02011c4:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02011c6:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02011c8:	fff44503          	lbu	a0,-1(s0)
ffffffffc02011cc:	ff351ae3          	bne	a0,s3,ffffffffc02011c0 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02011d0:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02011d4:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02011d8:	4c81                	li	s9,0
ffffffffc02011da:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02011dc:	5c7d                	li	s8,-1
ffffffffc02011de:	5dfd                	li	s11,-1
ffffffffc02011e0:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02011e4:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02011e6:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02011ea:	0ff5f593          	zext.b	a1,a1
ffffffffc02011ee:	00140d13          	addi	s10,s0,1
ffffffffc02011f2:	04b56263          	bltu	a0,a1,ffffffffc0201236 <vprintfmt+0xbc>
ffffffffc02011f6:	058a                	slli	a1,a1,0x2
ffffffffc02011f8:	95d6                	add	a1,a1,s5
ffffffffc02011fa:	4194                	lw	a3,0(a1)
ffffffffc02011fc:	96d6                	add	a3,a3,s5
ffffffffc02011fe:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201200:	70e6                	ld	ra,120(sp)
ffffffffc0201202:	7446                	ld	s0,112(sp)
ffffffffc0201204:	74a6                	ld	s1,104(sp)
ffffffffc0201206:	7906                	ld	s2,96(sp)
ffffffffc0201208:	69e6                	ld	s3,88(sp)
ffffffffc020120a:	6a46                	ld	s4,80(sp)
ffffffffc020120c:	6aa6                	ld	s5,72(sp)
ffffffffc020120e:	6b06                	ld	s6,64(sp)
ffffffffc0201210:	7be2                	ld	s7,56(sp)
ffffffffc0201212:	7c42                	ld	s8,48(sp)
ffffffffc0201214:	7ca2                	ld	s9,40(sp)
ffffffffc0201216:	7d02                	ld	s10,32(sp)
ffffffffc0201218:	6de2                	ld	s11,24(sp)
ffffffffc020121a:	6109                	addi	sp,sp,128
ffffffffc020121c:	8082                	ret
            padc = '0';
ffffffffc020121e:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201220:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201224:	846a                	mv	s0,s10
ffffffffc0201226:	00140d13          	addi	s10,s0,1
ffffffffc020122a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020122e:	0ff5f593          	zext.b	a1,a1
ffffffffc0201232:	fcb572e3          	bgeu	a0,a1,ffffffffc02011f6 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201236:	85a6                	mv	a1,s1
ffffffffc0201238:	02500513          	li	a0,37
ffffffffc020123c:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020123e:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201242:	8d22                	mv	s10,s0
ffffffffc0201244:	f73788e3          	beq	a5,s3,ffffffffc02011b4 <vprintfmt+0x3a>
ffffffffc0201248:	ffed4783          	lbu	a5,-2(s10)
ffffffffc020124c:	1d7d                	addi	s10,s10,-1
ffffffffc020124e:	ff379de3          	bne	a5,s3,ffffffffc0201248 <vprintfmt+0xce>
ffffffffc0201252:	b78d                	j	ffffffffc02011b4 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201254:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201258:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020125c:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc020125e:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201262:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201266:	02d86463          	bltu	a6,a3,ffffffffc020128e <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020126a:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020126e:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201272:	0186873b          	addw	a4,a3,s8
ffffffffc0201276:	0017171b          	slliw	a4,a4,0x1
ffffffffc020127a:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc020127c:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201280:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201282:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201286:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020128a:	fed870e3          	bgeu	a6,a3,ffffffffc020126a <vprintfmt+0xf0>
            if (width < 0)
ffffffffc020128e:	f40ddce3          	bgez	s11,ffffffffc02011e6 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201292:	8de2                	mv	s11,s8
ffffffffc0201294:	5c7d                	li	s8,-1
ffffffffc0201296:	bf81                	j	ffffffffc02011e6 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201298:	fffdc693          	not	a3,s11
ffffffffc020129c:	96fd                	srai	a3,a3,0x3f
ffffffffc020129e:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012a2:	00144603          	lbu	a2,1(s0)
ffffffffc02012a6:	2d81                	sext.w	s11,s11
ffffffffc02012a8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02012aa:	bf35                	j	ffffffffc02011e6 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02012ac:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012b0:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02012b4:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012b6:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02012b8:	bfd9                	j	ffffffffc020128e <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02012ba:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02012bc:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02012c0:	01174463          	blt	a4,a7,ffffffffc02012c8 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02012c4:	1a088e63          	beqz	a7,ffffffffc0201480 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02012c8:	000a3603          	ld	a2,0(s4)
ffffffffc02012cc:	46c1                	li	a3,16
ffffffffc02012ce:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02012d0:	2781                	sext.w	a5,a5
ffffffffc02012d2:	876e                	mv	a4,s11
ffffffffc02012d4:	85a6                	mv	a1,s1
ffffffffc02012d6:	854a                	mv	a0,s2
ffffffffc02012d8:	e37ff0ef          	jal	ra,ffffffffc020110e <printnum>
            break;
ffffffffc02012dc:	bde1                	j	ffffffffc02011b4 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02012de:	000a2503          	lw	a0,0(s4)
ffffffffc02012e2:	85a6                	mv	a1,s1
ffffffffc02012e4:	0a21                	addi	s4,s4,8
ffffffffc02012e6:	9902                	jalr	s2
            break;
ffffffffc02012e8:	b5f1                	j	ffffffffc02011b4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02012ea:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02012ec:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02012f0:	01174463          	blt	a4,a7,ffffffffc02012f8 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02012f4:	18088163          	beqz	a7,ffffffffc0201476 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02012f8:	000a3603          	ld	a2,0(s4)
ffffffffc02012fc:	46a9                	li	a3,10
ffffffffc02012fe:	8a2e                	mv	s4,a1
ffffffffc0201300:	bfc1                	j	ffffffffc02012d0 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201302:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201306:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201308:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020130a:	bdf1                	j	ffffffffc02011e6 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc020130c:	85a6                	mv	a1,s1
ffffffffc020130e:	02500513          	li	a0,37
ffffffffc0201312:	9902                	jalr	s2
            break;
ffffffffc0201314:	b545                	j	ffffffffc02011b4 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201316:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020131a:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020131c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020131e:	b5e1                	j	ffffffffc02011e6 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201320:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201322:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201326:	01174463          	blt	a4,a7,ffffffffc020132e <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020132a:	14088163          	beqz	a7,ffffffffc020146c <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc020132e:	000a3603          	ld	a2,0(s4)
ffffffffc0201332:	46a1                	li	a3,8
ffffffffc0201334:	8a2e                	mv	s4,a1
ffffffffc0201336:	bf69                	j	ffffffffc02012d0 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201338:	03000513          	li	a0,48
ffffffffc020133c:	85a6                	mv	a1,s1
ffffffffc020133e:	e03e                	sd	a5,0(sp)
ffffffffc0201340:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201342:	85a6                	mv	a1,s1
ffffffffc0201344:	07800513          	li	a0,120
ffffffffc0201348:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020134a:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc020134c:	6782                	ld	a5,0(sp)
ffffffffc020134e:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201350:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201354:	bfb5                	j	ffffffffc02012d0 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201356:	000a3403          	ld	s0,0(s4)
ffffffffc020135a:	008a0713          	addi	a4,s4,8
ffffffffc020135e:	e03a                	sd	a4,0(sp)
ffffffffc0201360:	14040263          	beqz	s0,ffffffffc02014a4 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201364:	0fb05763          	blez	s11,ffffffffc0201452 <vprintfmt+0x2d8>
ffffffffc0201368:	02d00693          	li	a3,45
ffffffffc020136c:	0cd79163          	bne	a5,a3,ffffffffc020142e <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201370:	00044783          	lbu	a5,0(s0)
ffffffffc0201374:	0007851b          	sext.w	a0,a5
ffffffffc0201378:	cf85                	beqz	a5,ffffffffc02013b0 <vprintfmt+0x236>
ffffffffc020137a:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020137e:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201382:	000c4563          	bltz	s8,ffffffffc020138c <vprintfmt+0x212>
ffffffffc0201386:	3c7d                	addiw	s8,s8,-1
ffffffffc0201388:	036c0263          	beq	s8,s6,ffffffffc02013ac <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc020138c:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020138e:	0e0c8e63          	beqz	s9,ffffffffc020148a <vprintfmt+0x310>
ffffffffc0201392:	3781                	addiw	a5,a5,-32
ffffffffc0201394:	0ef47b63          	bgeu	s0,a5,ffffffffc020148a <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201398:	03f00513          	li	a0,63
ffffffffc020139c:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020139e:	000a4783          	lbu	a5,0(s4)
ffffffffc02013a2:	3dfd                	addiw	s11,s11,-1
ffffffffc02013a4:	0a05                	addi	s4,s4,1
ffffffffc02013a6:	0007851b          	sext.w	a0,a5
ffffffffc02013aa:	ffe1                	bnez	a5,ffffffffc0201382 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02013ac:	01b05963          	blez	s11,ffffffffc02013be <vprintfmt+0x244>
ffffffffc02013b0:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02013b2:	85a6                	mv	a1,s1
ffffffffc02013b4:	02000513          	li	a0,32
ffffffffc02013b8:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02013ba:	fe0d9be3          	bnez	s11,ffffffffc02013b0 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02013be:	6a02                	ld	s4,0(sp)
ffffffffc02013c0:	bbd5                	j	ffffffffc02011b4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02013c2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02013c4:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02013c8:	01174463          	blt	a4,a7,ffffffffc02013d0 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02013cc:	08088d63          	beqz	a7,ffffffffc0201466 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02013d0:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02013d4:	0a044d63          	bltz	s0,ffffffffc020148e <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02013d8:	8622                	mv	a2,s0
ffffffffc02013da:	8a66                	mv	s4,s9
ffffffffc02013dc:	46a9                	li	a3,10
ffffffffc02013de:	bdcd                	j	ffffffffc02012d0 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02013e0:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02013e4:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc02013e6:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02013e8:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02013ec:	8fb5                	xor	a5,a5,a3
ffffffffc02013ee:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02013f2:	02d74163          	blt	a4,a3,ffffffffc0201414 <vprintfmt+0x29a>
ffffffffc02013f6:	00369793          	slli	a5,a3,0x3
ffffffffc02013fa:	97de                	add	a5,a5,s7
ffffffffc02013fc:	639c                	ld	a5,0(a5)
ffffffffc02013fe:	cb99                	beqz	a5,ffffffffc0201414 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201400:	86be                	mv	a3,a5
ffffffffc0201402:	00001617          	auipc	a2,0x1
ffffffffc0201406:	fde60613          	addi	a2,a2,-34 # ffffffffc02023e0 <buddy_pmm_manager+0x1b0>
ffffffffc020140a:	85a6                	mv	a1,s1
ffffffffc020140c:	854a                	mv	a0,s2
ffffffffc020140e:	0ce000ef          	jal	ra,ffffffffc02014dc <printfmt>
ffffffffc0201412:	b34d                	j	ffffffffc02011b4 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201414:	00001617          	auipc	a2,0x1
ffffffffc0201418:	fbc60613          	addi	a2,a2,-68 # ffffffffc02023d0 <buddy_pmm_manager+0x1a0>
ffffffffc020141c:	85a6                	mv	a1,s1
ffffffffc020141e:	854a                	mv	a0,s2
ffffffffc0201420:	0bc000ef          	jal	ra,ffffffffc02014dc <printfmt>
ffffffffc0201424:	bb41                	j	ffffffffc02011b4 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201426:	00001417          	auipc	s0,0x1
ffffffffc020142a:	fa240413          	addi	s0,s0,-94 # ffffffffc02023c8 <buddy_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020142e:	85e2                	mv	a1,s8
ffffffffc0201430:	8522                	mv	a0,s0
ffffffffc0201432:	e43e                	sd	a5,8(sp)
ffffffffc0201434:	0fc000ef          	jal	ra,ffffffffc0201530 <strnlen>
ffffffffc0201438:	40ad8dbb          	subw	s11,s11,a0
ffffffffc020143c:	01b05b63          	blez	s11,ffffffffc0201452 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201440:	67a2                	ld	a5,8(sp)
ffffffffc0201442:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201446:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201448:	85a6                	mv	a1,s1
ffffffffc020144a:	8552                	mv	a0,s4
ffffffffc020144c:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020144e:	fe0d9ce3          	bnez	s11,ffffffffc0201446 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201452:	00044783          	lbu	a5,0(s0)
ffffffffc0201456:	00140a13          	addi	s4,s0,1
ffffffffc020145a:	0007851b          	sext.w	a0,a5
ffffffffc020145e:	d3a5                	beqz	a5,ffffffffc02013be <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201460:	05e00413          	li	s0,94
ffffffffc0201464:	bf39                	j	ffffffffc0201382 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201466:	000a2403          	lw	s0,0(s4)
ffffffffc020146a:	b7ad                	j	ffffffffc02013d4 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc020146c:	000a6603          	lwu	a2,0(s4)
ffffffffc0201470:	46a1                	li	a3,8
ffffffffc0201472:	8a2e                	mv	s4,a1
ffffffffc0201474:	bdb1                	j	ffffffffc02012d0 <vprintfmt+0x156>
ffffffffc0201476:	000a6603          	lwu	a2,0(s4)
ffffffffc020147a:	46a9                	li	a3,10
ffffffffc020147c:	8a2e                	mv	s4,a1
ffffffffc020147e:	bd89                	j	ffffffffc02012d0 <vprintfmt+0x156>
ffffffffc0201480:	000a6603          	lwu	a2,0(s4)
ffffffffc0201484:	46c1                	li	a3,16
ffffffffc0201486:	8a2e                	mv	s4,a1
ffffffffc0201488:	b5a1                	j	ffffffffc02012d0 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc020148a:	9902                	jalr	s2
ffffffffc020148c:	bf09                	j	ffffffffc020139e <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc020148e:	85a6                	mv	a1,s1
ffffffffc0201490:	02d00513          	li	a0,45
ffffffffc0201494:	e03e                	sd	a5,0(sp)
ffffffffc0201496:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201498:	6782                	ld	a5,0(sp)
ffffffffc020149a:	8a66                	mv	s4,s9
ffffffffc020149c:	40800633          	neg	a2,s0
ffffffffc02014a0:	46a9                	li	a3,10
ffffffffc02014a2:	b53d                	j	ffffffffc02012d0 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02014a4:	03b05163          	blez	s11,ffffffffc02014c6 <vprintfmt+0x34c>
ffffffffc02014a8:	02d00693          	li	a3,45
ffffffffc02014ac:	f6d79de3          	bne	a5,a3,ffffffffc0201426 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02014b0:	00001417          	auipc	s0,0x1
ffffffffc02014b4:	f1840413          	addi	s0,s0,-232 # ffffffffc02023c8 <buddy_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014b8:	02800793          	li	a5,40
ffffffffc02014bc:	02800513          	li	a0,40
ffffffffc02014c0:	00140a13          	addi	s4,s0,1
ffffffffc02014c4:	bd6d                	j	ffffffffc020137e <vprintfmt+0x204>
ffffffffc02014c6:	00001a17          	auipc	s4,0x1
ffffffffc02014ca:	f03a0a13          	addi	s4,s4,-253 # ffffffffc02023c9 <buddy_pmm_manager+0x199>
ffffffffc02014ce:	02800513          	li	a0,40
ffffffffc02014d2:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02014d6:	05e00413          	li	s0,94
ffffffffc02014da:	b565                	j	ffffffffc0201382 <vprintfmt+0x208>

ffffffffc02014dc <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02014dc:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02014de:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02014e2:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02014e4:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02014e6:	ec06                	sd	ra,24(sp)
ffffffffc02014e8:	f83a                	sd	a4,48(sp)
ffffffffc02014ea:	fc3e                	sd	a5,56(sp)
ffffffffc02014ec:	e0c2                	sd	a6,64(sp)
ffffffffc02014ee:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02014f0:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02014f2:	c89ff0ef          	jal	ra,ffffffffc020117a <vprintfmt>
}
ffffffffc02014f6:	60e2                	ld	ra,24(sp)
ffffffffc02014f8:	6161                	addi	sp,sp,80
ffffffffc02014fa:	8082                	ret

ffffffffc02014fc <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc02014fc:	4781                	li	a5,0
ffffffffc02014fe:	00005717          	auipc	a4,0x5
ffffffffc0201502:	b1273703          	ld	a4,-1262(a4) # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201506:	88ba                	mv	a7,a4
ffffffffc0201508:	852a                	mv	a0,a0
ffffffffc020150a:	85be                	mv	a1,a5
ffffffffc020150c:	863e                	mv	a2,a5
ffffffffc020150e:	00000073          	ecall
ffffffffc0201512:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201514:	8082                	ret

ffffffffc0201516 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201516:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc020151a:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc020151c:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc020151e:	cb81                	beqz	a5,ffffffffc020152e <strlen+0x18>
        cnt ++;
ffffffffc0201520:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201522:	00a707b3          	add	a5,a4,a0
ffffffffc0201526:	0007c783          	lbu	a5,0(a5)
ffffffffc020152a:	fbfd                	bnez	a5,ffffffffc0201520 <strlen+0xa>
ffffffffc020152c:	8082                	ret
    }
    return cnt;
}
ffffffffc020152e:	8082                	ret

ffffffffc0201530 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201530:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201532:	e589                	bnez	a1,ffffffffc020153c <strnlen+0xc>
ffffffffc0201534:	a811                	j	ffffffffc0201548 <strnlen+0x18>
        cnt ++;
ffffffffc0201536:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201538:	00f58863          	beq	a1,a5,ffffffffc0201548 <strnlen+0x18>
ffffffffc020153c:	00f50733          	add	a4,a0,a5
ffffffffc0201540:	00074703          	lbu	a4,0(a4)
ffffffffc0201544:	fb6d                	bnez	a4,ffffffffc0201536 <strnlen+0x6>
ffffffffc0201546:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201548:	852e                	mv	a0,a1
ffffffffc020154a:	8082                	ret

ffffffffc020154c <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020154c:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201550:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201554:	cb89                	beqz	a5,ffffffffc0201566 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201556:	0505                	addi	a0,a0,1
ffffffffc0201558:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020155a:	fee789e3          	beq	a5,a4,ffffffffc020154c <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020155e:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201562:	9d19                	subw	a0,a0,a4
ffffffffc0201564:	8082                	ret
ffffffffc0201566:	4501                	li	a0,0
ffffffffc0201568:	bfed                	j	ffffffffc0201562 <strcmp+0x16>

ffffffffc020156a <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020156a:	c20d                	beqz	a2,ffffffffc020158c <strncmp+0x22>
ffffffffc020156c:	962e                	add	a2,a2,a1
ffffffffc020156e:	a031                	j	ffffffffc020157a <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201570:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201572:	00e79a63          	bne	a5,a4,ffffffffc0201586 <strncmp+0x1c>
ffffffffc0201576:	00b60b63          	beq	a2,a1,ffffffffc020158c <strncmp+0x22>
ffffffffc020157a:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc020157e:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201580:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201584:	f7f5                	bnez	a5,ffffffffc0201570 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201586:	40e7853b          	subw	a0,a5,a4
}
ffffffffc020158a:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020158c:	4501                	li	a0,0
ffffffffc020158e:	8082                	ret

ffffffffc0201590 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201590:	ca01                	beqz	a2,ffffffffc02015a0 <memset+0x10>
ffffffffc0201592:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201594:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201596:	0785                	addi	a5,a5,1
ffffffffc0201598:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020159c:	fec79de3          	bne	a5,a2,ffffffffc0201596 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02015a0:	8082                	ret
