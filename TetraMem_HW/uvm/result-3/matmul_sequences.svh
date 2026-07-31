// Sequences to be driven by drivers

`ifndef MATMUL_SEQUENCES_SVH
`define MATMUL_SEQUENCES_SVH

class matrix_seq extends uvm_sequence #(matmul_item);
  `uvm_object_utils(matrix_seq)
  int num     = 8;
  int fixed_m = 0;         // <=0 => random M in [1..N]
  function new(string name="matrix_seq"); super.new(name); endfunction
  task body();
    for (int i = 0; i < num; i++) begin
      matmul_item it = matmul_item::type_id::create($sformatf("mit_%0d", i));
      start_item(it);
      it.gen(fixed_m);
      finish_item(it);
      `uvm_info("MATRIX_SEQ", $sformatf("drove %s", it.convert2string()), UVM_HIGH)
    end
  endtask
endclass

// send a pre-built list of matrices (used for directed coverage closure)
class matrix_directed_seq extends uvm_sequence #(matmul_item);
  `uvm_object_utils(matrix_directed_seq)
  matmul_item items[$];
  function new(string name="matrix_directed_seq"); super.new(name); endfunction
  task body();
    foreach (items[i]) begin
      start_item(items[i]);
      finish_item(items[i]);
    end
  endtask
endclass

class read_seq extends uvm_sequence #(read_item);
  `uvm_object_utils(read_seq)
  int num = 8*`NN;
  function new(string name="read_seq"); super.new(name); endfunction
  task body();
    for (int i = 0; i < num; i++) begin
      read_item it = read_item::type_id::create("rd");
      start_item(it);
      finish_item(it);
    end
  endtask
endclass

// multi-channel: write channel + read channel concurrently
class ss_vseq extends uvm_sequence;
  `uvm_object_utils(ss_vseq)
  `uvm_declare_p_sequencer(virtual_sequencer)
  int num_matrices = 8;
  int fixed_m      = 0;
  function new(string name="ss_vseq"); super.new(name); endfunction
  task body();
    matrix_seq wseq = matrix_seq::type_id::create("wseq");
    read_seq   rseq = read_seq::type_id::create("rseq");
    wseq.num     = num_matrices;
    wseq.fixed_m = fixed_m;
    rseq.num     = num_matrices * `NN;
    `uvm_info("SS_VSEQ", $sformatf("multi-channel: %0d matrices (fixed_m=%0d)", num_matrices, fixed_m), UVM_LOW)
    fork
      wseq.start(p_sequencer.wr_sqr);
      rseq.start(p_sequencer.rd_sqr);
    join
  endtask
endclass

`endif // MATMUL_SEQUENCES_SVH
