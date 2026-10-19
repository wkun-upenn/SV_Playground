"""
csr_spec.py — the CSR register map of the BOOM core (rocket-chip CSRFile as
elaborated for MediumBoomV3Config: RV64GC, M/S/U, Sv39, 8 PMPs, 6 HPM counters,
paddrBits = 32, vaddrBits = 39, no debug-mode access, no triggers).

Everything below was *measured* on the RTL with sim/smoke (make smoke, "CSR
characterisation" table + WARL probes) rather than copied from the spec, then
cross-checked with CSR.scala. gen_ral.py turns it into tb/ral/boom_csr_reg_block.sv.

Field tuple: (name, lsb, width, access, reset, volatile)
  access: RW / RO. WARL behaviour is not an access type in UVM: it is attached as a
  callback (see 'warl') or a do_predict override (see 'predict').
Register keys:
  addr, name, fields, reset (whole-register reset, for documentation only),
  warl: list of (field, kind, arg) -> boom_csr_warl_cbs
        kind: 'sext' (arg = sign bit position in register bits), 'mask' (arg = legal-bit mask),
              'mpp' (2 -> 0), 'mideleg' (write masked by mideleg mirror),
              'tvec' (vectored mode aligns the base to 256 bytes; arg = sign bit or 0)
  alias: list of (dst_reg, [(src_lsb, dst_lsb, width), ...])  -> boom_csr_alias_cbs (src = this reg)
  attrs: RAL built-in test opt-outs (NO_REG_BIT_BASH_TEST, NO_REG_HW_RESET_TEST, NO_REG_ACCESS_TEST, NO_REG_TESTS)
  hdl:   (name, width) of the backing register inside CSRFile for backdoor access — only where
         the read path returns the register as-is (stvec/mtvec/mcause/counteren/medeleg post-process
         the raw register on read, so a raw poke would not match a frontdoor read)
  predict: 'satp' | 'pmpcfg' -> hand-written do_predict override emitted by the generator
"""

FLAG_FIELDS = [('NX', 0, 1, 'RW', 0, 1), ('UF', 1, 1, 'RW', 0, 1), ('OF', 2, 1, 'RW', 0, 1),
               ('DZ', 3, 1, 'RW', 0, 1), ('NV', 4, 1, 'RW', 0, 1)]

def status_fields(machine):
    f = [('SIE', 1, 1, 'RW', 0, 0), ('SPIE', 5, 1, 'RW', 0, 0), ('SPP', 8, 1, 'RW', 0, 0),
         ('FS', 13, 2, 'RW', 0, 1), ('XS', 15, 2, 'RO', 0, 0), ('SUM', 18, 1, 'RW', 0, 0), ('MXR', 19, 1, 'RW', 0, 0),
         ('UXL', 32, 2, 'RO', 2, 0), ('SD', 63, 1, 'RO', 0, 1)]
    if machine:
        f += [('MIE', 3, 1, 'RW', 0, 0), ('MPIE', 7, 1, 'RW', 0, 0), ('MPP', 11, 2, 'RW', 3, 0),
              ('MPRV', 17, 1, 'RW', 0, 0), ('TVM', 20, 1, 'RW', 0, 0), ('TW', 21, 1, 'RW', 0, 0), ('TSR', 22, 1, 'RW', 0, 0),
              ('SXL', 34, 2, 'RO', 2, 0)]
    return sorted(f, key=lambda x: x[1])

SSTATUS_BITS = [(1, 1, 1), (5, 5, 1), (8, 8, 1), (13, 13, 2), (18, 18, 1), (19, 19, 1), (63, 63, 1)]

REGS = [
  # ---------------------------------------------------------------- floating point (the ones this env drives for real)
  dict(addr=0x001, name='fflags', fields=FLAG_FIELDS, reset=0, hdl=('reg_fflags', 5),
       alias=[('fcsr', [(0, 0, 5)])]),
  dict(addr=0x002, name='frm', fields=[('FRM', 0, 3, 'RW', 0, 0)], reset=0, hdl=('reg_frm', 3),
       alias=[('fcsr', [(0, 5, 3)])]),
  dict(addr=0x003, name='fcsr', fields=[('FFLAGS', 0, 5, 'RW', 0, 1), ('FRM', 5, 3, 'RW', 0, 0)], reset=0,
       alias=[('fflags', [(0, 0, 5)]), ('frm', [(5, 0, 3)])]),
  # ---------------------------------------------------------------- supervisor
  dict(addr=0x100, name='sstatus', fields=status_fields(False), reset=0x200000000,
       alias=[('mstatus', SSTATUS_BITS)], attrs=['NO_REG_BIT_BASH_TEST'], sd_from_fs=True),
  dict(addr=0x104, name='sie', fields=[('SSIE', 1, 1, 'RW', 0, 0), ('STIE', 5, 1, 'RW', 0, 0), ('SEIE', 9, 1, 'RW', 0, 0)], reset=0,
       warl=[('SSIE', 'mideleg', 1), ('STIE', 'mideleg', 5), ('SEIE', 'mideleg', 9)],
       alias=[('mie', [(1, 1, 1), (5, 5, 1), (9, 9, 1)])], attrs=['NO_REG_BIT_BASH_TEST', 'NO_REG_ACCESS_TEST']),
  dict(addr=0x105, name='stvec', fields=[('MODE', 0, 1, 'RW', 0, 0), ('ZERO', 1, 1, 'RO', 0, 0), ('BASE', 2, 62, 'RW', 0, 0)], reset=0,
       warl=[('BASE', 'tvec', 38)], attrs=['NO_REG_BIT_BASH_TEST']),
  dict(addr=0x106, name='scounteren', fields=[('CY', 0, 1, 'RW', 0, 0), ('TM', 1, 1, 'RW', 0, 0), ('IR', 2, 1, 'RW', 0, 0), ('HPM', 3, 6, 'RW', 0, 0)], reset=0),
  dict(addr=0x140, name='sscratch', fields=[('VALUE', 0, 64, 'RW', 0, 0)], reset=0, hdl=('reg_sscratch', 64)),
  dict(addr=0x141, name='sepc', fields=[('ZERO', 0, 1, 'RO', 0, 0), ('EPC', 1, 63, 'RW', 0, 0)], reset=0, hdl=('reg_sepc', 40),
       warl=[('EPC', 'sext', 39)], attrs=['NO_REG_BIT_BASH_TEST']),
  dict(addr=0x142, name='scause', fields=[('CODE', 0, 5, 'RW', 0, 0), ('INT', 63, 1, 'RW', 0, 0)], reset=0),
  dict(addr=0x143, name='stval', fields=[('VALUE', 0, 64, 'RW', 0, 0)], reset=0, hdl=('reg_stval', 40),
       warl=[('VALUE', 'sext', 39)], attrs=['NO_REG_BIT_BASH_TEST']),
  dict(addr=0x144, name='sip', fields=[('SSIP', 1, 1, 'RW', 0, 0), ('STIP', 5, 1, 'RO', 0, 1), ('SEIP', 9, 1, 'RO', 0, 1)], reset=0,
       warl=[('SSIP', 'mideleg', 1)], alias=[('mip', [(1, 1, 1)])], attrs=['NO_REG_BIT_BASH_TEST', 'NO_REG_ACCESS_TEST']),
  dict(addr=0x180, name='satp', fields=[('PPN', 0, 20, 'RW', 0, 0), ('ASID', 44, 16, 'RO', 0, 0), ('MODE', 60, 4, 'RW', 0, 0)], reset=0,
       predict='satp', attrs=['NO_REG_BIT_BASH_TEST']),
  # ---------------------------------------------------------------- machine information
  dict(addr=0xF11, name='mvendorid', fields=[('VALUE', 0, 64, 'RO', 0, 0)], reset=0),
  dict(addr=0xF12, name='marchid',   fields=[('VALUE', 0, 64, 'RO', 2, 0)], reset=2),
  dict(addr=0xF13, name='mimpid',    fields=[('VALUE', 0, 64, 'RO', 0, 0)], reset=0),
  dict(addr=0xF14, name='mhartid',   fields=[('VALUE', 0, 64, 'RO', 0, 0)], reset=0),
  # ---------------------------------------------------------------- machine trap setup
  dict(addr=0x300, name='mstatus', fields=status_fields(True), reset=0xa00001800,
       warl=[('MPP', 'mpp', 0)], alias=[('sstatus', SSTATUS_BITS)], attrs=['NO_REG_BIT_BASH_TEST'], sd_from_fs=True),
  dict(addr=0x301, name='misa', fields=[('EXTENSIONS', 0, 26, 'RO', 0x14112d, 0), ('MXL', 62, 2, 'RO', 2, 0)], reset=0x800000000014112d),
  dict(addr=0x302, name='medeleg', fields=[('VALUE', 0, 16, 'RW', 0, 0)], reset=0,
       warl=[('VALUE', 'mask', 0xb15d)], attrs=['NO_REG_BIT_BASH_TEST']),
  dict(addr=0x303, name='mideleg', fields=[('VALUE', 0, 12, 'RW', 0, 0)], reset=0,
       warl=[('VALUE', 'mask', 0x222)], attrs=['NO_REG_BIT_BASH_TEST']),
  dict(addr=0x304, name='mie', fields=[('SSIE', 1, 1, 'RW', 0, 0), ('MSIE', 3, 1, 'RW', 0, 0), ('STIE', 5, 1, 'RW', 0, 0),
                                       ('MTIE', 7, 1, 'RW', 0, 0), ('SEIE', 9, 1, 'RW', 0, 0), ('MEIE', 11, 1, 'RW', 0, 0)], reset=0,
       alias=[('sie', [(1, 1, 1), (5, 5, 1), (9, 9, 1)])]),
  dict(addr=0x305, name='mtvec', fields=[('MODE', 0, 1, 'RW', 0, 0), ('ZERO', 1, 1, 'RO', 0, 0), ('BASE', 2, 30, 'RW', 0, 0)], reset=0,
       warl=[('BASE', 'tvec', 0)], attrs=['NO_REG_BIT_BASH_TEST']),
  dict(addr=0x306, name='mcounteren', fields=[('CY', 0, 1, 'RW', 0, 0), ('TM', 1, 1, 'RW', 0, 0), ('IR', 2, 1, 'RW', 0, 0), ('HPM', 3, 6, 'RW', 0, 0)], reset=0),
  dict(addr=0x320, name='mcountinhibit', fields=[('CY', 0, 1, 'RW', 0, 0), ('IR', 2, 1, 'RW', 0, 0), ('HPM', 3, 6, 'RW', 0, 0)], reset=0),
  # ---------------------------------------------------------------- machine trap handling
  dict(addr=0x340, name='mscratch', fields=[('VALUE', 0, 64, 'RW', 0, 0)], reset=0, hdl=('reg_mscratch', 64)),
  dict(addr=0x341, name='mepc', fields=[('ZERO', 0, 1, 'RO', 0, 0), ('EPC', 1, 63, 'RW', 0, 0)], reset=0, hdl=('reg_mepc', 40),
       warl=[('EPC', 'sext', 39)], attrs=['NO_REG_BIT_BASH_TEST']),
  dict(addr=0x342, name='mcause', fields=[('CODE', 0, 4, 'RW', 0, 0), ('INT', 63, 1, 'RW', 0, 0)], reset=0),
  dict(addr=0x343, name='mtval', fields=[('VALUE', 0, 64, 'RW', 0, 0)], reset=0, hdl=('reg_mtval', 40),
       warl=[('VALUE', 'sext', 39)], attrs=['NO_REG_BIT_BASH_TEST']),
  dict(addr=0x344, name='mip', fields=[('SSIP', 1, 1, 'RW', 0, 0), ('MSIP', 3, 1, 'RO', 0, 1), ('STIP', 5, 1, 'RW', 0, 0),
                                       ('MTIP', 7, 1, 'RO', 0, 1), ('SEIP', 9, 1, 'RW', 0, 0), ('MEIP', 11, 1, 'RO', 0, 1)], reset=0,
       alias=[('sip', [(1, 1, 1)])]),
  # ---------------------------------------------------------------- physical memory protection (8 entries)
  dict(addr=0x3A0, name='pmpcfg0', fields=[f for i in range(8) for f in
        [('R%d' % i, 8*i, 1, 'RW', 0, 0), ('W%d' % i, 8*i+1, 1, 'RW', 0, 0), ('X%d' % i, 8*i+2, 1, 'RW', 0, 0),
         ('A%d' % i, 8*i+3, 2, 'RW', 0, 0), ('L%d' % i, 8*i+7, 1, 'RW', 0, 0)]], reset=0,
       predict='pmpcfg', attrs=['NO_REG_TESTS']),
] + [
  dict(addr=0x3B0 + i, name='pmpaddr%d' % i, fields=[('ADDR', 0, 30, 'RW', 0, 0)], reset=0, attrs=['NO_REG_TESTS'])
  for i in range(8)
] + [
  # ---------------------------------------------------------------- counters
  dict(addr=0xB00, name='mcycle',   fields=[('VALUE', 0, 64, 'RW', 0, 1)], reset=0, alias=[('cycle', [(0, 0, 64)])], attrs=['NO_REG_BIT_BASH_TEST']),
  dict(addr=0xB02, name='minstret', fields=[('VALUE', 0, 64, 'RW', 0, 1)], reset=0, alias=[('instret', [(0, 0, 64)])], attrs=['NO_REG_BIT_BASH_TEST']),
] + [
  dict(addr=0xB03 + i, name='mhpmcounter%d' % (i + 3), fields=[('VALUE', 0, 40, 'RW', 0, 1)], reset=0,
       alias=[('hpmcounter%d' % (i + 3), [(0, 0, 40)])], attrs=['NO_REG_BIT_BASH_TEST'])
  for i in range(6)
] + [
  dict(addr=0x323 + i, name='mhpmevent%d' % (i + 3), fields=[('CLASS', 0, 2, 'RW', 0, 0), ('MASK', 8, 6, 'RW', 0, 0)], reset=0)
  for i in range(6)
] + [
  dict(addr=0xC00, name='cycle',   fields=[('VALUE', 0, 64, 'RO', 0, 1)], reset=0),
  dict(addr=0xC02, name='instret', fields=[('VALUE', 0, 64, 'RO', 0, 1)], reset=0),
] + [
  dict(addr=0xC03 + i, name='hpmcounter%d' % (i + 3), fields=[('VALUE', 0, 40, 'RO', 0, 1)], reset=0)
  for i in range(6)
] + [
  # ---------------------------------------------------------------- BOOM custom "chicken" CSR (rocket CustomCSRs, 0x7c1); one writable bit in this config
  dict(addr=0x7C1, name='chicken', fields=[('BIT3', 3, 1, 'RW', 0, 0)], reset=0),
]

# CSR numbers that must decode as illegal (used by the illegal-access test)
ILLEGAL_ADDRS = [0x008, 0x7B0, 0x7B1, 0x7B2, 0xC01, 0x7FF, 0x5A8, 0x000]
