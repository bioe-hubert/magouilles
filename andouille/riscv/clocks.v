//------------------------------------------------------------------------------
//  ANDOUILLE Artifact, MAGOUILLES Project, Distributed under The MIT License.
//  Copyright (c) 2019 Hubert Montas
//------------------------------------------------------------------------------

	//----------------------------------------------------------------------
	// clocks from PLL			cpu:	clka = PLL/2
	//					mem:	clkn = inv(clka)
	//----------------------------------------------------------------------

module clocks(
	input		ref_clk,
	output		cpu_clk,
	output		mem_clk
	);

	wire		pll_clk;
	wire		pll_locked;
	reg		clka = 0;
	wire		clkc = clka;
	wire		clkn = !clka;

	always @(posedge pll_clk) begin
	  if (pll_locked) clka <= !clka;
	end

	`PLL_MODULE   #(.FEEDBACK_PATH("SIMPLE"),.FILTER_RANGE(3'b001),
			.DIVR(`pll_div_r),.DIVF(`pll_div_f),.DIVQ(`pll_div_q))
		pll (.LOCK(pll_locked),.RESETB(1'b1),.BYPASS(1'b0),
			`PLL_REFCLK(ref_clk),.PLLOUTCORE(pll_clk));

	SB_GB glb_cclk (.USER_SIGNAL_TO_GLOBAL_BUFFER(clkc),.GLOBAL_BUFFER_OUTPUT(cpu_clk));
	SB_GB glb_mclk (.USER_SIGNAL_TO_GLOBAL_BUFFER(clkn),.GLOBAL_BUFFER_OUTPUT(mem_clk));

endmodule



