# ANDOUILLE

The Andouille artifact is a small System On Chip (SOC) based around
a 4-stage pipelined RISC-V processor core implementing the RV32IM (without division)
or RV64I instruction set. The core includes custom-0 and custom-1
instructions to perform load/store operations using a register offset.
A small startup program (in assembly language) demonstrates some memory
accesses, addition/subtraction and response to uart interrupts.
The andouille runs at 16 MHz.

The artifact targets boards with Lattice Semiconductor(TM) iCE40 FPGAs:

* iCE40 UltraPlus Breakout Board, Rev. A, iCE40UP5K-B-EVN
* Gnarly Grey UPDuino V2.0
* iCE40-HX8K Breakout Board, Rev. A, iCE40HX8K-B-EVN

The Andouille SOC (`riscv` folder) is written in Verilog and designed to be synthesized,
place-and-routed, and programmed into an FPGA using the open-source
[Icestorm software](http://www.clifford.at/icestorm/).
The components used are
 [yosys](http://www.clifford.at/yosys/),
 [nextpnr](https://github.com/YosysHQ/nextpnr),
 and the [icestorm tools](https://github.com/cliffordwolf/icestorm)
(icetime, icepack, icebram and iceprog).

The Andouille boot program (`boot` folder) and startup program (`aps` folder) are
designed to be assembled using [GNU binutils 2.32](https://www.gnu.org/software/binutils/)
 with patches to
accept the double-slash (`//`) as comment indicator, and to allow aliasing
of CPU register names (`gas_patch` folder).

## QUICK-START

Make sure that you have downloaded, built and installed the `iceprog` program from the
icestorm project.

### iCE40UP5K-B-EVN (RV32IM)

Solder a male or female pin socket on Header C of the board. Pin 16A on this header 
is the SOC's uart's Tx line and pin 13B is the SOC's uart's Rx line (gpios
 include pins 22A and 23B).
 
Plug a USB cable from your PC to the board's USB connector and also a USB-to-uart
cable (3.3 Volt) from your PC to the uart's Tx and Rx pins on Header C (and to ground).
Open a terminal to communicate with the uart.

Execute the following commands to upload the FPGA bistream and to upload the startup
code (both will be stored in the on-board flash memory chip):

	$ iceprog bin/up5kbevn.bin
	$ iceprog -o 1M bin/aps32.bin

Observe the result in your terminal communication program. Press a key to see
the response to interrupts. Press the board's reset button if desired.

### UPDuino V2.0 (RV32IM)

Plug a jumper cable from pin J8 (FTDI clock out, near USB plug) across to pin 35
(FPGA clock in, near center on opposite side header).
Plug a USB cable from your PC to the board's USB connector.

Execute the following commands to upload the FPGA bistream and startup
code to the on-board flash chip (unplug and re-plug USB if programming
gets stuck at flash-erase stage):

	$ iceprog bin/upduino.bin
	$ iceprog -o 1M bin/aps32.bin

Unplug and then re-plug your USB cable (repeat if RGB LED doesn't turn on).
Open a terminal on /dev/ttyUSB0 and press
a key to see the response to interrupts (the SOC's uart is routed through the USB
interface).

### iCE40HX8K-B-EVN (RV64I)

Plug a USB cable from your PC to the board's USB connector.
Open a terminal on /dev/ttyUSB1 (the SOC's uart is routed through this USB interface).

Execute the following to upload the bistream and startup to the on-board flash:

	$ iceprog bin/hx8kbevn.bin
	$ iceprog -o 1M bin/aps64.bin

Observe the result in your terminal and press a key to see interrupt response.


## SLOW-START

Perform relevant hardware adjustments and setup, as described above in Quick-Start.

Download, build and install the Icestorm software.
Download, patch, build and install GNU binutils 2.32.
Modify the verilog code in the `riscv` folder and/or the assembly language programs
in the `boot` and `aps` folders.
Run synthesis and place-and-route by executing (example for iCE40UP5K-B-EVN, RV32IM):

	$ ./build_riscv 32 up5k up5kbevn

Rebuild boot code and/or aps with (for RV32IM):

	$ ./build_boot 32
	$ ./build_aps  32

Incorporate boot code into bitstream, and upload bitstream and aps onto FPGA
board flash chip, using (iCE40UP5K-B-EVN, RV32IM):

	$ ./build_prog 32 up5kbevn


## IMPLEMENTATION NOTES

The andouille has a four-stage pipeline:

* (F) Fetch
* (D) Decode
* (E) Execute
* (M) Memory access and register writeback

Bubbles are injected to clear-out fetched and decoded instructions on branch,
and to wait on register writeback (or E_out) on data dependencies.
The pipeline is stalled only on wfi.
The design is otherwise synchronous, with memory assumed accessible in a
single clock cycle.

It is essentially a Harvard design where code and data come from
different memories. In particular, data cannot be read from the same RAM segment
in which code is running (in any segment, code read has priority over data).
The design allows for a total of 16 equally-sized address-space segments for
memories and peripherals.

At reset, code executes from the boot RAM segment (eg. 0xf0000000).
The bootloader located there copies the startup (aka aps) code from
flash (using the SPI peripheral) to both the code RAM (eg. 0x00000000)
and the data RAM (eg. 0x10000000) and then jumps to the start of code RAM.
The aps, running from code RAM, can then manipulate data from boot RAM,
data RAM, and some potential extra RAM segment.
Where the aps code includes data (eg. output strings for prompts), the
data is available in data RAM when the boot process completes.
The aps should copy these data to their expected location (if any) as part of its
initialization process (as done in the example startup code).

The andouille does not fault on illegal instructions. It executes them as one of
its known instructions (it is non-standard in that respect).

For decoding and dispatch purposes, instructions are grouped into 16 types
 (stored in the `_insn_typ` bitfield in `riscv/cpu.v`):

| Type | Instructions | Type | Instructions |
| --- | ---    | --- | --- |
|  0  | load   |  1  | custom0: load with register offset |
|  2  | op-imm |  3  | auipc |
|  4  | store  |  5  | custom1:	store with register offset |
|  6  | op-reg	(incl. mul/mulh...) | 7  | lui |
|  8  | csr1: mret, wfi, ecall/ebreak | 9 | csr2: rdcycle(h)/rdmcycle(h) (read-only) |
| 10  | csr3: csrr(w|s|c) for mie, mtvec, mip, mepc | 11 | csr4: csrr for mcause, mtval (read-only) |
| 12  | conditonal branch | 13 | jalr |
| 14  | jal    |  15 | custom3 (unused) |

The remapping makes fence/fence.i equivalent to nop.


## SYNTHESIS NOTES

The RV32IM andouille occupies approximately 4500 Logic Cells on the target (up5k)
FPGAs and the RV64I core occupies approximately 7300 Logic Cells (on hx8k).

The seed used for the place-and-route phase of design reconstruction can have
a significant effect, both on the time it takes for synthesis to complete, and
on whether the eventual artifact runs correctly.
With the default algorithm in nextpnr (this has yet to be checked with HEAP)
a given design may take 20 minutes with one seed but 4 hours with another seed.
It is suggested to try various seeds and record the value of "remaining arcs"
at IterCnt = 50000, in the "Routing.." phase, right after "Setting up routing queue"
in the nextpnr on-screen output (ctrl-c out of the routing and try another seed once that
value has appeared). A value of 6080 remaining arcs might mean
that routing will take one more hour, while 5990 could mean just 45 more minutes
(small differences in remaining arcs lead to large differences in how long
one has to wait for routing to complete -- the relationship is nonlinear).
 It is suggested to choose the seed that
produces the smallest number of remaining arcs at IterCnt = 50000, and run the
full place-and-route with that seed.

For the RV32IM andouille on up5k fpga, a seed of 2 produced an artifact that ran correctly
at 16 MHz
and was routed quickly.
A seed of 4 gave similar results (but longer to route) for the RV64I (hx8k fpga).
The RV32IM andouille was also routed quickly with a seed of 4 but did not run correctly
at 16 MHz,
possibly due to strict timing requirements imposed by the synchronous design of the artifact.
The RV64I was routed very slowly with a seed of 2 (several hours).


## REFERENCES

Andrew Waterman and Krste Asanovic, 2017a.
The RISC-V Instruction Set Manual Volume I: User-Level ISA Document Version 2.2.
[pdf](https://content.riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf).

Andrew Waterman and Krste Asanovic, 2017b.
The RISC-V Instruction Set Manual Volume II: Privileged Architecture; Privileged Architecture Version 1.10; Document Version 1.10.
[pdf](https://content.riscv.org/wp-content/uploads/2017/05/riscv-privileged-v1.10.pdf).

Lattice Semiconductor, 2016. iCE40HX-8K Breakout Board User Guide, EB85 Version 1.1, January 2016.
[pdf](http://www.latticesemi.com/view_document?document_id=50373).

Lattice Semiconductor, 2017. iCE40 UltraPlus Breakout Board User Guide, FPGA-UG-02001 Version 1.1, March 2017.
[pdf](https://www.latticesemi.com/view_document?document_id=51987).

UPduino v2.0 Design Documentation on
[github](https://github.com/gtjennings1/UPDuino_v2_0).

Lattice Semiconductor, 2018. Himax HM01B0 UPduino Shield User Guide, FPGA-UG-02081 Version 1.0, November 2018.
[pdf](http://www.latticesemi.com/view_document?document_id=52555).



