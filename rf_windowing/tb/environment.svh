// ----------------------------------------------------------------------------
// Title: Tester Environment
// Author: Federico Fruttero
// Affiliation: Politecnico di Torino
// Description: This file defines the environment for the testbench. It includes
//              the setup and connections of various components like the test
//              sequence, driver, monitor, predictor, scoreboard, and printers.
// ----------------------------------------------------------------------------

class environment extends uvm_env;
   `uvm_component_utils(environment);

   // Declare testbench components
   test_seq   tst_seq;                // The test sequence 
   driver     drv;                // The driver component
   coverage   cov;                // Coverage collector

   // Sequencer
   uvm_sequencer #(rf_req, rf_data) seqr;


   // Declare printers for printing transactions
   printer   #(rf_req)  printer_req; // Printer for request transactions

   // Declare monitor, predictor, and scoreboard components
   monitor      mon;            // The monitor component
   predictor    pred;           // The predictor component
   scoreboard   scb;            // The scoreboard component

   // Declare FIFO for connecting predictor and scoreboard
   uvm_tlm_fifo #(rf_data) pred2scb; // TLM FIFO connecting predictor and scoreboard

   // Constructor for the environment class
   function new(string name = "environment", uvm_component parent = null );
      super.new(name, parent);
   endfunction : new

   // Build phase of the environment
   function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      // Create and initialize test, driver, and FIFOs
      tst_seq = test_seq::type_id::create("tst_seq",this);
      drv = driver::type_id::create("drv",this);
      seqr = new("seqr",this);                       // NEW SEQUENCER

      // Create and initialize printers for request and response transactions
      printer_req = printer#(rf_req)::type_id::create("printer_req",this);

      // Create and initialize monitor, predictor, scoreboard and coverage
      mon = monitor::type_id::create("mon", this);
      cov = coverage::type_id::create("cov", this);
      pred = predictor::type_id::create("pred", this);
      scb = scoreboard::type_id::create("scb", this);

      // Create and initialize FIFO for connecting predictor and scoreboard
      pred2scb  = new("pred2scb", this);
   endfunction : build_phase

   // Connect phase of the environment
   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);

      // Connect components using their ports and analysis exports
      drv.seq_item_port.connect(seqr.seq_item_export);

      // Connect ports between predictor and scoreboard
      scb.predicted_p.connect(pred2scb.get_export); // Connect predicted port of scoreboard to get port of predictor
      pred.rsp_p.connect(pred2scb.put_export);       // Connect response port of predictor to put port of scoreboard

      // Connect monitor's request and response analysis exports to predictor and scoreboard
      mon.req_a.connect(pred.req_fifo.analysis_export); // Connect monitor's request analysis port to predictor's FIFO
      mon.req_a.connect(cov.req_fifo.analysis_export);
      mon.rsp_a.connect(scb.actual_f.analysis_export);  // Connect monitor's response analysis port to scoreboard's FIFO

      if (rf_pkg::verbose) begin
          // Connect monitor's analysis ports to printers' analysis exports
          mon.req_a.connect(printer_req.a_fifo.analysis_export); // Connect monitor's request analysis port to request printer
          //mon.rsp_a.connect(rsp_prt.a_fifo.analysis_export); // Connect monitor's response analysis port to response printer
      end
   endfunction : connect_phase

   task run_phase(uvm_phase phase);
       phase.raise_objection(this);
       // Start the test sequence
       tst_seq.start(seqr);
       phase.drop_objection(this);
   endtask

endclass : environment
