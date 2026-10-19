//=============================================================================
// boom_csr_reg_cbs.sv — behavioural hooks of the CSR register model
//-----------------------------------------------------------------------------
// UVM's field access policies (RW/RO/W1C/...) cannot express what a RISC-V
// CSR file really does, so the generated model (boom_csr_reg_block.sv) attaches:
//   boom_csr_alias_cbs  one physical register visible under several CSR
//                       numbers (fcsr = {frm, fflags}; sstatus = view of
//                       mstatus; cycle = mcycle; sie/sip = mie/mip & mideleg)
//   boom_csr_warl_cbs   WARL legalisation on write: sign extension of the
//                       address CSRs, legal-bit masks (medeleg/mideleg),
//                       MPP = 2 -> U, sie/sip bits gated by mideleg, xtvec base
//                       alignment in vectored mode (rocket formTVec)
// mstatus.SD / sstatus.SD (derived from FS == Dirty) are simply volatile:
// a field of a register cannot be re-predicted while that register's own
// frontdoor access is still in flight, so the mirror picks SD up on reads.
// All hooks work through post_predict, so they apply to every prediction
// source alike: explicit RAL accesses, the passive predictor watching CSR
// instructions that flow through the pipeline, and the fflags side effect.
//=============================================================================
typedef struct { int src_lsb; int dst_lsb; int width; } alias_range_t;
typedef enum { WARL_SEXT, WARL_MASK, WARL_MPP, WARL_MIDELEG, WARL_TVEC } warl_kind_e;

typedef class boom_csr_reg_block;

//-----------------------------------------------------------------------------
class boom_csr_alias_cbs extends uvm_reg_cbs;
  `uvm_object_utils(boom_csr_alias_cbs)
  uvm_reg        src, dst;
  alias_range_t  ranges[];
  bit            by_mideleg;          // only delegated bits are shared (sie/sip <-> mie/mip)
  boom_csr_reg_block blk;
  static bit     busy;                // one level of propagation only (A -> B, never B -> A -> B ...)

  function new(string name = "boom_csr_alias_cbs", uvm_reg src = null, uvm_reg dst = null, alias_range_t ranges[] = '{});
    super.new(name);
    this.src = src; this.dst = dst; this.ranges = ranges;
  endfunction

  function void attach();
    uvm_reg_field flds[$];
    src.get_fields(flds);
    foreach (flds[i]) uvm_reg_field_cb::add(flds[i], this);
  endfunction

  virtual function void post_predict(input uvm_reg_field fld, input uvm_reg_data_t previous, inout uvm_reg_data_t value,
                                     input uvm_predict_e kind, input uvm_path_e path, input uvm_reg_map map);
    uvm_reg_data_t sv, dv, mideleg = '1;
    if (busy || dst == null) return;
    // register value as it will be after this field is updated
    sv = src.get_mirrored_value();
    for (int b = 0; b < fld.get_n_bits(); b++) sv[fld.get_lsb_pos() + b] = value[b];
    dv = dst.get_mirrored_value();
    if (by_mideleg && blk != null) mideleg = blk.mideleg.get_mirrored_value();
    foreach (ranges[i]) begin
      for (int b = 0; b < ranges[i].width; b++)
        if (mideleg[ranges[i].src_lsb + b]) dv[ranges[i].dst_lsb + b] = sv[ranges[i].src_lsb + b];
    end
    busy = 1;
    void'(dst.predict(dv, -1, UVM_PREDICT_DIRECT));
    busy = 0;
  endfunction
endclass : boom_csr_alias_cbs

//-----------------------------------------------------------------------------
class boom_csr_warl_cbs extends uvm_reg_cbs;
  `uvm_object_utils(boom_csr_warl_cbs)
  warl_kind_e         mode;
  longint unsigned    arg;
  boom_csr_reg_block  blk;
  function new(string name = "boom_csr_warl_cbs", warl_kind_e mode = WARL_MASK, longint unsigned arg = 0, boom_csr_reg_block blk = null);
    super.new(name); this.mode = mode; this.arg = arg; this.blk = blk;
  endfunction

  virtual function void post_predict(input uvm_reg_field fld, input uvm_reg_data_t previous, inout uvm_reg_data_t value,
                                     input uvm_predict_e kind, input uvm_path_e path, input uvm_reg_map map);
    int n = fld.get_n_bits();
    if (kind != UVM_PREDICT_WRITE) return;
    case (mode)
      WARL_SEXT: begin                     // arg = sign bit (register numbering); the field holds it at arg - lsb
        int sb = int'(arg) - fld.get_lsb_pos();
        if (sb >= 0 && sb < n) begin
          if (value[sb]) begin for (int b = sb + 1; b < n; b++) value[b] = 1; end
          else           begin for (int b = sb + 1; b < n; b++) value[b] = 0; end
        end
      end
      WARL_MASK:   value &= (arg >> fld.get_lsb_pos());
      WARL_MPP:    if (value == 2) value = 0;                    // legalizePrivilege: H -> U
      WARL_MIDELEG: begin                                        // arg = interrupt number; not delegated -> S-view bit is not writable
        uvm_reg_data_t md = (blk != null) ? blk.mideleg.get_mirrored_value() : '0;
        if (!md[arg]) value = previous;
      end
      WARL_TVEC: begin                                           // BASE field of xtvec: vectored mode forces 256-byte alignment,
        uvm_reg_field mode = fld.get_parent().get_field_by_name("MODE");   // then optional sign extension (arg = sign bit, 0 = none)
        if (mode != null && mode.get_mirrored_value() == 1) value &= ~64'h3F;   // register bits [7:2]
        if (arg != 0) begin
          int sb = int'(arg) - fld.get_lsb_pos();
          if (sb >= 0 && sb < n) begin
            if (value[sb]) begin for (int b = sb + 1; b < n; b++) value[b] = 1; end
            else           begin for (int b = sb + 1; b < n; b++) value[b] = 0; end
          end
        end
      end
    endcase
    value &= (64'h1 << n) - 1;
  endfunction
endclass : boom_csr_warl_cbs

