//------------------------------------------------------------------------------
//  ANDOUILLE Artifact, MAGOUILLES Project, Distributed under The MIT License.
//  Copyright (c) 2019 Hubert Montas
//------------------------------------------------------------------------------

//==============================================================
// andouille cpu		(magouilles project)
//==============================================================

module cpu (
	input			clk,		// cpu clock
	input			rstn,		// cpu reset (negated, lo=reset)
	output		[`X1:0]	F_insn_adrs,	// code address for fetch
	output	reg	[`X1:0]	E_LS_adrs,	// data address for read/write
	output	reg	[`X1:0]	E_out,		// data to write to mem/periph
	output			M_mem_load,	// data read  signal output
	output			M_mem_store,	// data write signal output
	output		[`WS:0]	M_wstrb,	// data write strobe output
	input		[`X1:0]	mem_rcode,	// code fetched from memory
	input		[`X1:0]	mem_rdata,	// data fetched from memory
	input		 [15:0]	mem_virq	// asserted irqs from mem/periph
	);

	//----------------------------------------------------------------------
	// cpu registers (integer and system)
	//----------------------------------------------------------------------

	reg	[`X1:0]	cpuregs [0:31];
	reg	[`X1:0]	sysregs [0:3];			// mie, mtvec, mip, mepc
	reg	[`X1:0]	sys_mcause, sys_mtval;
	reg	[ 63:0]	sys_count;

	always @(posedge clk) begin
	  if (!rstn) begin
	    cpuregs[0] <= 0;				// zero
	    sysregs[0] <= 0;				// mie
	    sysregs[1] <= 0;				// mtvec
	    sysregs[2][15:0]  <= 16'h0000;		// mip (lo16)
	    sysregs[2][31:16] <= mem_virq;		// mip (hi16)
  `ifdef rv64
	    sysregs[2][63:32] <= 32'h0000_0000;		// mip (hi32)
  `endif
	    sysregs[3] <= 0;				// mepc
	    sys_count  <= 0;
	    sys_mtval  <= 0;				// dbg
	  end else begin
	    sys_count <= sys_count + 1;
	    sysregs[2][31:16] <= mem_virq;		// mip (hi16)
	  end
	end

	//----------------------------------------------------------------------
	// arbitration
	//----------------------------------------------------------------------
	// 0=load, 1=custom0, 2=op_imm, 3=auipc, 4=store,   5=custom1, 6=op_reg, 7=lui,
	// 8=csr1, 9=csr2,   10=csr3,  11=csr4, 12=branch, 13=jalr,   14=jal,   15=custom3
	//----------------------------------------------------------------------
	// csr1 = mret,wfi,ecall/ebreak,		csr2=rdcycle[h]/rdmcycle[h] (read-only)
	// csr3 = csrr[w|s|c] mie,mtvec,mip,mepc, 	csr4=csrr mcause, mtval     (read-only)
	// (also:  2=fence/fence.i equiv addi/slli x0,x0,imm == nop)
	//----------------------------------------------------------------------

	wire		pipe_stall = (E_insn_typ[8] & E_insn[20] & E_insn[28]) && !E_mipe;	// wfi
	wire		pipe_wait_rs1 = F_rs1 
					&& (F_insn_typ & 16'hb477)	//bits 15,13,12,10,6,5,4,2,1,0
					&& (D_rd == F_rs1 || E_rd == F_rs1 && !E_is_out);
	wire		pipe_wait_rs2 = F_rs2 && (F_insn_typ & 16'h1070)	//bits 12,6,5,4
					&& (D_rd == F_rs2 || E_rd == F_rs2 && !E_is_out);
	wire		pipe_wait_rs3 = F_rs3 && (F_insn_typ & 16'h0022)	//bits 5,1
					&& (D_rd == F_rs3 || E_rd == F_rs3 && !E_is_out);
	wire		pipe_wait     = pipe_wait_rs1 || pipe_wait_rs2 || pipe_wait_rs3;
	wire		E_is_out      = !(E_insn_typ[0] | E_insn_typ[1] | (E_insn_typ[6]&E_insn[25]));

	//----------------------------------------------------------------------
	// F -- Fetch stage
	//----------------------------------------------------------------------
	// 0=load, 1=custom0, 2=op_imm, 3=auipc, 4=store,   5=custom1, 6=op_reg, 7=lui,
	// 8=csr1, 9=csr2,   10=csr3,  11=csr4, 12=branch, 13=jalr,   14=jal,   15=custom3
	//----------------------------------------------------------------------
	// csr1 = mret,wfi,ecall/ebreak,		csr2=rdcycle[h]/rdmcycle[h] (read-only)
	// csr3 = csrr[w|s|c] mie,mtvec,mip,mepc, 	csr4=csrr mcause, mtval     (read-only)
	// (also:  2=fence/fence.i equiv addi/slli x0,x0,imm == nop)
	//----------------------------------------------------------------------

	reg	[`X1:0]	F_next_pc, F_actv_pc;
	reg	[ 31:0]	F_insn;
	reg	[ 15:0]	F_insn_typ;
	wire	[  4:0]	F_rs1		= F_insn[19:15];
	wire	[  4:0]	F_rs2		= F_insn[24:20];
	wire	[  4:0]	F_rs3		= F_insn[31:27];
	wire	[ 31:0]	F_rcode		= F_insn_adrs[2] ? mem_rcode[`X1:`X32] : mem_rcode[31:0];

	assign		F_insn_adrs	= E_take_Br ? E_Br_adrs : F_next_pc;

	always @(posedge clk) begin
	  if (!rstn) begin
	    F_next_pc	<= `reset_address;
	  end else if ((E_take_Br | !pipe_wait) & !pipe_stall) begin
	      F_actv_pc  <= F_insn_adrs;
	      F_insn	 <= F_rcode;			// read instr
	      (* parallel_case *)
	      case (F_rcode[6:3])
		4'b0011: F_insn_typ <= 16'h0004;	// op-imm-32(W, 64-bit ISA) -- bit 2
		4'b0111: F_insn_typ <= 16'h0040;	// op-reg-32(W, 64-bit ISA) -- bit 6
		4'b1110: F_insn_typ <= 16'h0100 << {F_rcode[29]&(F_rcode[22]|F_rcode[26]),
						    F_rcode[31]|F_rcode[21]&F_rcode[26]}; // system
		default: F_insn_typ <= 16'h0001 << (F_rcode[6:3]+{3'b0,F_rcode[2]});	  // others
	      endcase
	      F_next_pc	 <= F_insn_adrs + 4;
	  end
	end

	//----------------------------------------------------------------------
	// D -- decode stage
	//----------------------------------------------------------------------
	// 0=load, 1=custom0, 2=op_imm, 3=auipc, 4=store,   5=custom1, 6=op_reg, 7=lui,
	// 8=csr1, 9=csr2,   10=csr3,  11=csr4, 12=branch, 13=jalr,   14=jal,   15=custom3
	//----------------------------------------------------------------------
	// csr1 = mret,wfi,ecall/ebreak,		csr2=rdcycle[h]/rdmcycle[h] (read-only)
	// csr3 = csrr[w|s|c] mie,mtvec,mip,mepc, 	csr4=csrr mcause, mtval     (read-only)
	// (also:  2=fence/fence.i equiv addi/slli x0,x0,imm == nop)
	//----------------------------------------------------------------------

	reg	[`X1:0]	D_op1, D_op2, D_op3, D_rd, D_actv_pc, D_next_pc;
	reg	[ 31:0]	D_insn;
	reg	[ 15:0]	D_insn_typ;
	reg	[  2:0]	D_funct3;
	reg	[  1:0]	D_sysidx;

	wire	[`X1:0]	cpu_rs1   = cpuregs[F_rs1];
	wire	[`X1:0]	cpu_rs2   = cpuregs[F_rs2];
	wire	[`X1:0]	cpu_rs1_W = {{`X31{cpu_rs1[31]}},cpu_rs1[30:0]};
	wire	[`X1:0]	cpu_rs2_W = {{`X31{cpu_rs2[31]}},cpu_rs2[30:0]};
	wire	[`X1:0]	E_out_W   = {{`X31{E_out[31]}},  E_out[30:0]};

	always @(posedge clk) begin
	  if (!rstn || !pipe_stall && (pipe_wait || E_take_Br)) begin
	    D_rd	<= 0;
	    D_insn	<= 0;
	    D_insn_typ	<= 0;
	  end else if (rstn && !pipe_stall && !pipe_wait) begin
	    D_actv_pc	<= F_actv_pc;
	    D_next_pc	<= F_next_pc;
	    D_insn	<= F_insn;
	    D_insn_typ	<= F_insn_typ;
	    D_funct3	<= F_insn[14:12];
	    D_rd	<= (F_insn_typ & 16'h1130) ? 0 : F_insn[11: 7];	// 12,8,5,4
	    case (1'b1)
	      !F_rs1:	D_op1 <= `XZ0;
	      E_rd == F_rs1 && E_is_out:
			D_op1 <= (F_insn_typ[2]|F_insn_typ[6]) & F_insn[3] ? E_out_W   : E_out;
	      default:	D_op1 <= (F_insn_typ[2]|F_insn_typ[6]) & F_insn[3] ? cpu_rs1_W : cpu_rs1;
	    endcase
	    case (1'b1)
	      F_insn_typ[2]:							// op-imm
			D_op2 <= F_insn[13:12]==2'b01 ? {`X6'b0, F_insn[25:20]}	// shift
					: {{`X12{F_insn[31]}},F_insn[31:20]};	// non-shift
	      !F_rs2:	D_op2 <= 0;
	      E_rd == F_rs2 && E_is_out:
			D_op2 <= F_insn_typ[6] & F_insn[3] ? E_out_W   : E_out;
	      default:	D_op2 <= F_insn_typ[6] & F_insn[3] ? cpu_rs2_W : cpu_rs2;
	    endcase
	    case (1'b1)
	      !F_rs3:	D_op3 <= 0;
	      E_rd == F_rs3 && E_is_out:
			D_op3 <= E_out;
	      default:	D_op3 <= cpuregs[F_rs3];
	    endcase
	    D_sysidx <= {F_insn[26],F_insn[20]};
	  end
	end

	//----------------------------------------------------------------------
	// E -- Execute stage
	//----------------------------------------------------------------------
	// 0=load, 1=custom0, 2=op_imm, 3=auipc, 4=store,   5=custom1, 6=op_reg, 7=lui,
	// 8=csr1, 9=csr2,   10=csr3,  11=csr4, 12=branch, 13=jalr,   14=jal,   15=custom3
	//----------------------------------------------------------------------

	reg	[`X1:0]	E_rd, E_actv_pc, E_next_pc, E_op1, E_Br_adrs, E_mcause, E_mipe;
	reg	[ 31:0]	E_insn;
	reg	[ 15:0]	E_insn_typ;
	reg	[  2:0]	E_funct3;
	reg		E_take_Br;
	reg	[  1:0]	E_sysidx;
	// conditional branch and slt flags
	wire	[  3:0]	E_flags = {D_op1<D_op2,$signed(D_op1)<$signed(D_op2),D_op1==0,D_op1==D_op2};

	// pre-calculcation(s) (re-used)
	wire	[`X1:0]	add_op12    = D_op1 + D_op2;
	wire	[`X1:0]	E_luival    = {{`X31{D_insn[31]}},D_insn[30:12],12'h000};
	wire	[`X1:0]	E_simm11    = {{`X11{D_insn[31]}},D_insn[30:20]};
  `ifdef include_multiplier
	// multiplier (32-bits only)
	wire	[33:0]	umul_lhhl   = {2'b0,umul_lohi} + {2'b0,umul_hilo};
	wire	[31:0]	umul_lolo = D_op1[15: 0] * D_op2[15: 0];
	wire	[31:0]	umul_lohi = D_op1[15: 0] * D_op2[31:16];
	wire	[31:0]	umul_hilo = D_op1[31:16] * D_op2[15: 0];
	wire	[31:0]	umul_hihi = D_op1[31:16] * D_op2[31:16];
	reg	[31:0]	E_mul_lolo, E_mul_lohi, E_mul_hilo, E_mul_hihi;
	reg	[31:0]	E_op2, E_add12;
	reg	[33:0]	E_mul_lhhl;
	wire	[31:0]	mul_val     = E_mul_lolo + {E_mul_lhhl[15:0],16'b0};
	wire	[31:0]	mulhsu_val  = E_op1[31]? mulhu_val-E_op2 : mulhu_val;
	wire	[31:0]	mulh_val    = E_op2[31]? mulhu_val-(E_op1[31]? E_add12 :E_op1) :mulhsu_val;
	reg	[33:0]	E_lllhhl;
	wire	[31:0]	mulhu_val   = E_mul_hihi + {14'b0,E_lllhhl[33:16]};
	wire	[33:0]	umul_lllhhl = {18'b0,umul_lolo[31:16]} + umul_lhhl;
  `endif

	always @(posedge clk) begin
	  if (rstn && pipe_stall && (E_insn_typ[8] & E_insn[20] & E_insn[28])) begin
	    E_mipe	<= sysregs[0] & sysregs[2];		// for wfi
	  end else
	  if (!rstn || !pipe_stall && E_take_Br || !D_insn_typ) begin
	    E_rd	<= 0;
	    E_insn	<= 0;
	    E_insn_typ	<= 0;
	    E_take_Br	<= 0;
	  end else if (rstn && !pipe_stall) begin
	    E_actv_pc	<= D_actv_pc;
	    E_next_pc	<= D_next_pc;
	    E_insn	<= D_insn;
	    E_insn_typ	<= D_insn_typ;
	    E_rd	<= D_rd;
	    E_op1	<= D_insn_typ[10] & D_funct3[2] ? {`X5'b0,D_insn[19:15]} : D_op1;
  `ifdef include_multiplier
	    E_op2	<= D_op2;
	    E_add12	<= add_op12;
	    E_mul_lolo	<= umul_lolo;
	    E_mul_lohi	<= umul_lohi;
	    E_mul_hilo	<= umul_hilo;
	    E_mul_hihi	<= umul_hihi;
	    E_mul_lhhl	<= umul_lhhl;
	    E_lllhhl	<= umul_lllhhl;
  `endif
	    E_funct3	<= D_funct3;
	    E_sysidx	<= D_sysidx;
	    E_mcause	<= sys_mcause;
	    E_mipe	<= sysregs[0] & sysregs[2];
	    E_take_Br	<= D_insn_typ[8] | D_insn_typ[13] | D_insn_typ[14]
				| (D_insn_typ[12] ? D_funct3[0] ^ E_flags[D_funct3[2:1]] : 0)
				| (!D_insn_typ[8] & !sys_mcause & |(sysregs[0] & sysregs[2]));

	    if (!D_insn_typ[8] & !sys_mcause & |(sysregs[0] & sysregs[2])) E_Br_adrs <= sysregs[1];
	    else begin
	    (* parallel_case *)
	    case (1'b1)
	      D_insn_typ[8]:	E_Br_adrs <= sysregs[{D_insn[21],1'b1}]; // mret/ecall...
	      D_insn_typ[13]:	E_Br_adrs <= D_op1;
	      D_insn_typ[14]:	E_Br_adrs <= D_actv_pc + {E_simm11[`X1:20],D_insn[19:12],
							  D_insn[20],D_insn[30:21],1'b0};
	      D_insn_typ[12]:	E_Br_adrs <= D_actv_pc + {E_simm11[`X1:12],D_insn[7],
	    						  D_insn[30:25],D_insn[11:8],1'b0};
	      default:		E_Br_adrs <= sysregs[1];	// for irq
	    endcase
	    end

	    (* parallel_case *)
	    case (1'b1)
	      D_insn_typ[0]:	E_LS_adrs <= D_op1 + E_simm11;
	      D_insn_typ[1]:	E_LS_adrs <= D_op1 + D_op3;
	      D_insn_typ[4]:	E_LS_adrs <= D_op1 + {E_simm11[`X1:5],D_insn[11:7]};
	      D_insn_typ[5]:	E_LS_adrs <= D_op1 + D_op3;
	      default:		E_LS_adrs <= `default_E_LS_adrs; // default (no cs zone)
	    endcase

	    (* parallel_case *)
	    case (1'b1)
	      D_insn_typ[3]:	E_out <= D_actv_pc + E_luival;	// auipc
	      D_insn_typ[7]:	E_out <= E_luival;		// lui
	      D_insn_typ[13]:	E_out <= D_next_pc;		// jalr
	      D_insn_typ[14]:	E_out <= D_next_pc;		// jal
	      D_insn_typ[2] | (D_insn_typ[6] & !D_insn[25]):	// op_imm or op_reg-not-muldiv
		(* parallel_case *)
		case (D_funct3)
		  3'b000:	E_out <= (D_insn_typ[6] & D_insn[30]) ? D_op1-D_op2 : add_op12;
		  3'b001:	E_out <= D_op1 << D_op2[5:0];	// sll
		  3'b010:	E_out <= {`X1'b0, E_flags[2]};	// slt
		  3'b011:	E_out <= {`X1'b0, E_flags[3]};	// sltu
		  3'b100:	E_out <= D_op1 ^  D_op2;	// xor
		  3'b101:	E_out <= $signed({D_insn[30] ? D_op1[`X1] : 1'b0, D_op1})>>>D_op2[5:0];
		  3'b110:	E_out <= D_op1 |  D_op2;	// or
		  3'b111:	E_out <= D_op1 &  D_op2;	// and
		endcase
	      D_insn_typ[4] | D_insn_typ[5]:			// store: sb, sh, sw, custom1
		(* parallel_case *)
		case (D_funct3[1:0])
		  2'b00:	E_out <= {`XB{D_op2[ 7:0]}};	// sb, sb_r
		  2'b01:	E_out <= {`XH{D_op2[15:0]}};	// sh, sh_r
		  2'b10:	E_out <= {`XW{D_op2[31:0]}};	// sw, sw_r
		  2'b11:	E_out <= D_op2;			// sd, sd_r (dummy in 32-bit)
		endcase
	      D_insn_typ[9]:	E_out <= D_insn[27]? sys_count[63:32] : sys_count[`X1:0]; // rdcycle[h]
	      D_insn_typ[11]:	E_out <= D_insn[20] ? sys_mtval : sys_mcause; // mtval, mcause
	      D_insn_typ[10]:	E_out <= sysregs[D_sysidx];	// mie,mtvec,mip,mepc
	      D_insn_typ[8]:	E_out <= D_next_pc;		// ecall,ebreak,mret,wfi
	      default:		E_out <= D_actv_pc;		// for irq
	    endcase
	  end
	end

	//----------------------------------------------------------------------
	// M -- Memory access stage (commit/writeback stage, retire instruction)
	//----------------------------------------------------------------------
	// 0=load, 1=custom0, 2=op_imm, 3=auipc, 4=store,   5=custom1, 6=op_reg, 7=lui,
	// 8=csr1, 9=csr2,   10=csr3,  11=csr4, 12=branch, 13=jalr,   14=jal,   15=custom3
	//----------------------------------------------------------------------

	assign		M_mem_load  = E_insn_typ[0] | E_insn_typ[1];
	assign		M_mem_store = E_insn_typ[4] | E_insn_typ[5];
	assign	 	M_wstrb     = &E_funct3[1:0] ? `WS_ff
					: (E_funct3[1] ? `XB'h0f
					   : (E_funct3[0] ? `XB'h03 : `XB'h01)) << E_LS_adrs[`XW:0];

	// pre-calculcation(s) (re-used)
	wire	[ `X9:0] M_simmb = { `X8{E_funct3[2] ? 1'b0 : mem_rdata[{E_LS_adrs[`XW:0],3'b111}]}};
	wire	[`X17:0] M_simmh = {`X16{E_funct3[2] ? 1'b0 : mem_rdata[{E_LS_adrs[`XW:1],4'b1111}]}};
	wire	[`X33:0] M_simmw = {`X32{E_funct3[2] ? 1'b0 : mem_rdata[{E_LS_adrs[  `XW],5'b11111}]}};

	always @(posedge clk) begin
	  if (rstn && !pipe_stall && E_insn_typ) begin
	    if (!E_insn_typ[8] && !E_mcause && E_mipe) begin
	      sysregs[3] <= M_mem_store ? E_next_pc : E_actv_pc;
	      sys_mcause <= {1'b1,`X1'b0};
	    end else begin

	    if (E_insn_typ[8]) begin
	      sysregs[3] <= E_out;
	      sys_mcause <= {E_insn[22],`X2'b0,!E_insn[28]};
	    end

	    if (E_insn_typ[10]) begin   	// csrrw, csrrs, csrrc for mie,mtvec,mip,mepc
	      (* parallel_case *)
	      case (E_funct3[1:0])
		2'b01:	sysregs[E_sysidx] <= E_op1;		// csrrw
		2'b10:	sysregs[E_sysidx] <= E_out |  E_op1;	// csrrs
		2'b11:	sysregs[E_sysidx] <= E_out & !E_op1;	// csrrc
	      endcase
	    end

	    if (E_rd) begin
	    (* parallel_case *)
	    case (1'b1)
	      E_insn_typ[0] | E_insn_typ[1]:	// load
		(* parallel_case *)
		case (E_funct3[1:0])
		  0:  (* parallel_case *)
		    case (E_LS_adrs[2:0])			// byte
		      0: cpuregs[E_rd] <= {M_simmb,mem_rdata[ 7: 0]};
		      1: cpuregs[E_rd] <= {M_simmb,mem_rdata[15: 8]};
		      2: cpuregs[E_rd] <= {M_simmb,mem_rdata[23:16]};
		      3: cpuregs[E_rd] <= {M_simmb,mem_rdata[31:24]};
		      4: cpuregs[E_rd] <= {M_simmb,mem_rdata[`X25:`X32]};
		      5: cpuregs[E_rd] <= {M_simmb,mem_rdata[`X17:`X24]};
		      6: cpuregs[E_rd] <= {M_simmb,mem_rdata[ `X9:`X16]};
		      7: cpuregs[E_rd] <= {M_simmb,mem_rdata[ `X1: `X8]};
		    endcase
		  1:  (* parallel_case *)
		    case (E_LS_adrs[2:1])			// double-byte
		      0: cpuregs[E_rd] <= {M_simmh,mem_rdata[15: 0]};
		      1: cpuregs[E_rd] <= {M_simmh,mem_rdata[31:16]};
		      2: cpuregs[E_rd] <= {M_simmh,mem_rdata[`X17:`X32]};
		      3: cpuregs[E_rd] <= {M_simmh,mem_rdata[ `X1:`X16]};
		    endcase
		  2:  (* parallel_case *)
		    case (E_LS_adrs[2])				// quad-byte
		      0: cpuregs[E_rd] <= {M_simmw,mem_rdata[ 31:   0]};
		      1: cpuregs[E_rd] <= {M_simmw,mem_rdata[`X1:`X32]};
		    endcase
		  3:	 cpuregs[E_rd] <= mem_rdata;		// word (esp. 64-bit)
		endcase
  `ifdef include_multiplier
	      E_insn_typ[6] & E_insn[25]:			// muldiv
		(* parallel_case *)
		case (E_funct3[1:0])
		  2'b00:     cpuregs[E_rd] <= mul_val;		// mul
		  2'b01:     cpuregs[E_rd] <= mulh_val;		// mulh
		  2'b10:     cpuregs[E_rd] <= mulhsu_val;	// mulhsu
		  2'b11:     cpuregs[E_rd] <= mulhu_val;	// mulhu
		endcase
  `endif
	      (E_insn_typ[2]|E_insn_typ[6]) & E_insn[3]:
			     cpuregs[E_rd] <= E_out_W;
	      default:	     cpuregs[E_rd] <= E_out;
	    endcase
	  end
	 end
	 end
	end

endmodule



