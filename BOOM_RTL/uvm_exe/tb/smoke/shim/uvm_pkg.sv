// Minimal stand-in for uvm_pkg so that boom_exe_txn / boom_exe_ref_model can be
// compiled by Verilator for the non-UVM smoke test. NOT a UVM implementation.
package uvm_pkg;
  typedef enum int { UVM_NONE = 0, UVM_LOW = 100, UVM_MEDIUM = 200, UVM_HIGH = 300, UVM_FULL = 400 } uvm_verbosity;
  int uvm_shim_errors = 0;
  int uvm_shim_verbosity = UVM_LOW;
  class uvm_object;
    string m_name;
    function new(string name = ""); m_name = name; endfunction
    function string get_name(); return m_name; endfunction
    virtual function void do_copy(uvm_object rhs); endfunction
  endclass
  class uvm_sequence_item extends uvm_object;
    function new(string name = ""); super.new(name); endfunction
  endclass
endpackage
