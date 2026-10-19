//=============================================================================
// boom_csr_txn.sv — one access on the CSRFile read/write port
//-----------------------------------------------------------------------------
// This is the "bus transaction" of the register model: the adapter converts
// uvm_reg_bus_op <-> boom_csr_txn, the driver puts it on csr_if.agt_*, and the
// monitor reconstructs one from csr_if.rw_* whoever drove it (RAL agent or a
// CSR instruction coming out of the execution pipeline).
//=============================================================================
class boom_csr_txn extends uvm_sequence_item;
  `uvm_object_utils(boom_csr_txn)
  rand bit [11:0] addr;
  rand bit [2:0]  cmd;          // CSR_R / CSR_W / CSR_S / CSR_C (rocket encoding, see defs pkg)
  rand bit [63:0] wdata;
  bit [63:0]      rdata;        // old value (combinational read in the access cycle)
  bit             read_illegal, write_illegal;   // from the decode port, sampled before the access
  bit             from_pipeline;                 // monitor: access came from alu1's CSR uop, not the RAL agent
  int             cycle;
  constraint c_cmd { cmd inside {CSR_R, CSR_W, CSR_S, CSR_C}; }
  function new(string name = "boom_csr_txn"); super.new(name); endfunction
  function string cmd_name();
    case (cmd) CSR_R: return "R"; CSR_W: return "W"; CSR_S: return "S"; CSR_C: return "C"; CSR_I: return "I"; default: return "N"; endcase
  endfunction
  // value the CSR holds after this access, as CSRFile computes it (readModifyWriteCSR)
  function bit [63:0] new_value();
    case (cmd)
      CSR_W: return wdata;
      CSR_S: return rdata | wdata;
      CSR_C: return rdata & ~wdata;
      default: return rdata;
    endcase
  endfunction
  function string convert2string();
    return $sformatf("csr %s addr=%03h wdata=%016h rdata=%016h%s%s @%0d", cmd_name(), addr, wdata, rdata,
                     from_pipeline ? " [pipe]" : "", (read_illegal || write_illegal) ? " ILLEGAL" : "", cycle);
  endfunction
endclass : boom_csr_txn

// fflags side effect observed on the CSRFile's fcsr_flags port
class boom_csr_fflags_evt extends uvm_sequence_item;
  `uvm_object_utils(boom_csr_fflags_evt)
  bit [4:0] flags;
  int       cycle;
  function new(string name = "boom_csr_fflags_evt"); super.new(name); endfunction
endclass
