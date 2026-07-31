//=============================================================================
// UVM factory override example
//   Shows TYPE override and INSTANCE override, for both a transaction
//   (uvm_object) and a component (uvm_component).
//
//   Golden rule: overrides ONLY work if the object/component is created
//   through the factory with  type_id::create(...)  — never plain new().
//=============================================================================
import uvm_pkg::*;
`include "uvm_macros.svh"

//----------------------------------------------------------------------
// 1) A transaction and a derived variant
//----------------------------------------------------------------------
class base_txn extends uvm_sequence_item;
  rand bit [7:0] data;
  `uvm_object_utils(base_txn)
  function new(string name = "base_txn"); super.new(name); endfunction
  virtual function void show(); `uvm_info("TXN", "base_txn: normal data", UVM_LOW) endfunction
endclass

class err_txn extends base_txn;                 // e.g. an "error injection" flavour
  `uvm_object_utils(err_txn)
  function new(string name = "err_txn"); super.new(name); endfunction
  constraint c_err { data == 8'hFF; }           // always corrupt
  virtual function void show(); `uvm_info("TXN", "err_txn: forced 0xFF", UVM_LOW) endfunction
endclass

//----------------------------------------------------------------------
// 2) A component and a derived variant
//----------------------------------------------------------------------
class base_driver extends uvm_driver #(base_txn);
  `uvm_component_utils(base_driver)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase); `uvm_info("DRV", "base_driver running", UVM_LOW) endtask
endclass

class fast_driver extends base_driver;
  `uvm_component_utils(fast_driver)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase); `uvm_info("DRV", "fast_driver running", UVM_LOW) endtask
endclass

//----------------------------------------------------------------------
// 3) A sequence that creates the transaction VIA THE FACTORY
//----------------------------------------------------------------------
class my_seq extends uvm_sequence #(base_txn);
  `uvm_object_utils(my_seq)
  function new(string name = "my_seq"); super.new(name); endfunction
  task body();
    base_txn tr;
    tr = base_txn::type_id::create("tr");   // <-- factory create; override applies here
    tr.show();                              // prints err_txn's message if overridden
  endtask
endclass

//----------------------------------------------------------------------
// 4) The test : install the overrides in build_phase
//----------------------------------------------------------------------
class my_test extends uvm_test;
  `uvm_component_utils(my_test)
  base_driver drv;                          // will actually become fast_driver
  function new(string name, uvm_component parent); super.new(name, parent); endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // (a) TYPE override -- every base_txn made by the factory becomes err_txn,
    //     everywhere in the whole testbench.
    set_type_override_by_type(base_txn::get_type(), err_txn::get_type());
    // equivalent string form:
    // factory.set_type_override_by_name("base_txn", "err_txn");

    // (b) INSTANCE override -- only the driver at this specific path becomes
    //     fast_driver; base_drivers elsewhere are untouched.
    set_inst_override_by_type("drv",
                              base_driver::get_type(),
                              fast_driver::get_type());

    // both created through the factory, so the overrides take effect:
    drv = base_driver::type_id::create("drv", this);
  endfunction

  task run_phase(uvm_phase phase);
    my_seq s;
    phase.raise_objection(this);
    s = my_seq::type_id::create("s");
    s.body();                               // will build an err_txn
    phase.drop_objection(this);
  endtask
endclass
