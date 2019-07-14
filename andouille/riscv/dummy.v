//------------------------------------------------------------------------------
//  ANDOUILLE Artifact, MAGOUILLES Project, Distributed under The MIT License.
//  Copyright (c) 2019 Hubert Montas
//------------------------------------------------------------------------------

	//----------------------------------------------------------------------
	// dummy peripheral (placeholder)
	//----------------------------------------------------------------------

module dummy (
	input			clk,	// clock input
	output	reg	[`X1:0]	dout,	// data or code from peripheral
	output			irq	// irq output
	);

	assign		irq  = 1'b0;

	always @(posedge clk) begin
	  dout <= `XZ0;
	end

endmodule



